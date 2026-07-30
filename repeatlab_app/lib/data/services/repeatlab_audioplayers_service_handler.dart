// ignore_for_file: use_setters_to_change_properties

import 'dart:async';
import 'dart:developer';
import 'dart:math' show pow;

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:meta/meta.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/services/loop_navigation_event.dart';
import 'package:repeatlab/data/services/media_player_handler.dart';

export 'package:repeatlab/data/services/loop_navigation_event.dart';

/// AudioHandler implementation for background audio playback
class RepeatlabAudioplayersServiceHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler
    implements MediaPlayerHandler {
  final AudioPlayer audioPlayer;

  static const double _minPlaybackSpeed = 0.5;
  static const double _maxPlaybackSpeed = 2.0;

  static const int _minPitchSemitones = -12;
  static const int _maxPitchSemitones = 12;

  /// Double-tap detection threshold for skip previous
  static const Duration _doubleTapThreshold = Duration(milliseconds: 400);

  Loop? _activeLoop;
  List<Loop> _loops = [];
  int _currentLoopIndex = -1;
  bool _fullSongRepeatEnabled = false;

  /// Stream controller for navigation events that the cubit can listen to
  final _navigationEventController =
      StreamController<LoopNavigationEvent>.broadcast();
  @override
  Stream<LoopNavigationEvent> get navigationEvents =>
      _navigationEventController.stream;

  /// Track last skip previous tap time for double-tap detection
  DateTime? _lastSkipPreviousTime;

  /// Every position discontinuity (user seek, forward/back, loop wrap,
  /// repeat restart) is reported here so the metronome can realign its
  /// click grid — native loop wraps are invisible to the cubit otherwise.
  final _seekEventController = StreamController<Duration>.broadcast();
  @override
  Stream<Duration> get seekEvents => _seekEventController.stream;

  void _notifySeek(Duration target) {
    if (!_seekEventController.isClosed) {
      _seekEventController.add(target);
    }
  }

  @override
  Stream<PlayerState>? playerStateStream;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  @override
  Stream<Duration>? positionStream;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _loopPositionSubscription;
  Timer? _loopCheckTimer;

  /// One-shot timer armed to fire the loop wrap exactly when the playhead
  /// reaches the loop end, instead of reacting after a position update
  /// reports that the end has already been passed.
  Timer? _loopWrapTimer;

  /// True while the platform player wraps the loop natively (Android:
  /// PlayerMessage-scheduled seek inside ExoPlayer). All Dart-side wrap
  /// machinery stands down then; the 200 ms poll stays as a watchdog only.
  bool _nativeLoopRegionActive = false;
  StreamSubscription<Duration>? _loopWrapSubscription;

  /// How far past the loop end the watchdog lets the playhead run before
  /// concluding the native wrap missed (e.g. after a user seek beyond the
  /// end, which native messages deliberately don't fire on). Must stay well
  /// above the native wrap latency so both never race to seek.
  static const Duration _nativeWrapMissMargin = Duration(milliseconds: 250);

  @override
  Future<Duration> get position async =>
      await audioPlayer.getCurrentPosition() ?? Duration.zero;

  Duration? _pendingSeekTarget;
  bool _pendingSeekIsLoopWrap = false;
  Future<void>? _seekQueue;
  Source? _currentSource;
  double _playbackSpeed = 1.0;
  int _pitchSemitones = 0;
  bool _loopSeekInProgress = false;

  RepeatlabAudioplayersServiceHandler({required this.audioPlayer}) {
    log('SoloudAudioServiceHandler constructor');

    _initAudioSession();

    playerStateStream = audioPlayer.onPlayerStateChanged;
    _playerStateSubscription = playerStateStream?.listen((state) {
      log('playerStateSubscription: $state');

      switch (state) {
        case PlayerState.playing:
          playbackState.add(
            playbackState.value.copyWith(
              controls: const [
                MediaControl.skipToPrevious,
                MediaControl.pause,
                MediaControl.skipToNext,
              ],
              systemActions: const {
                MediaAction.seek,
                MediaAction.seekForward,
                MediaAction.seekBackward,
              },
              playing: true,
              processingState: AudioProcessingState.ready,
            ),
          );
        case PlayerState.paused:
          playbackState.add(
            playbackState.value.copyWith(
              controls: const [
                MediaControl.skipToPrevious,
                MediaControl.play,
                MediaControl.skipToNext,
              ],
              systemActions: const {
                MediaAction.seek,
                MediaAction.seekForward,
                MediaAction.seekBackward,
              },
              playing: false,
              processingState: AudioProcessingState.ready,
            ),
          );
        case PlayerState.stopped:
          playbackState.add(
            playbackState.value.copyWith(
              controls: const [
                MediaControl.skipToPrevious,
                MediaControl.play,
                MediaControl.skipToNext,
              ],
              systemActions: const {
                MediaAction.seek,
                MediaAction.seekForward,
                MediaAction.seekBackward,
              },
              playing: false,
              processingState: AudioProcessingState.idle,
            ),
          );
        case PlayerState.completed:
          // Handle loop restart when song completes - this is especially important
          // for background playback where position updates may be throttled
          if (_activeLoop != null &&
              _activeLoop!.start != null &&
              _activeLoop!.end != null) {
            _handleLoopCompletionRestart();
            return;
          }

          // Handle full song repeat when no loop is active
          if (_fullSongRepeatEnabled && _activeLoop == null) {
            _handleFullSongRepeat();
            return;
          }

          playbackState.add(
            playbackState.value.copyWith(
              controls: const [
                MediaControl.skipToPrevious,
                MediaControl.play,
                MediaControl.skipToNext,
              ],
              systemActions: const {
                MediaAction.seek,
                MediaAction.seekForward,
                MediaAction.seekBackward,
              },
              playing: false,
              processingState: AudioProcessingState.completed,
            ),
          );
        case PlayerState.disposed:
          playbackState.add(
            playbackState.value.copyWith(
              controls: const [
                MediaControl.skipToPrevious,
                MediaControl.play,
                MediaControl.skipToNext,
              ],
              systemActions: const {
                MediaAction.seek,
                MediaAction.seekForward,
                MediaAction.seekBackward,
              },
              playing: false,
              processingState: AudioProcessingState.idle,
            ),
          );
      }
    });

    positionStream = audioPlayer.onPositionChanged;
    _positionSubscription = positionStream?.listen((position) {
      playbackState.add(playbackState.value.copyWith(updatePosition: position));
    });

    // Native loop wraps happen entirely inside the platform player; surface
    // them as seek events so the metronome realigns — "native loop wraps the
    // cubit never initiates".
    _loopWrapSubscription = audioPlayer.onLoopWrap.listen((position) {
      _notifySeek(position);
      playbackState.add(playbackState.value.copyWith(updatePosition: position));
    });
  }

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      log('AudioSession initialized: ${session.isConfigured}');
    } on MissingPluginException catch (error, stackTrace) {
      log('AudioSession unavailable: $error', stackTrace: stackTrace);
    } on PlatformException catch (error, stackTrace) {
      log('AudioSession configuration failed: $error', stackTrace: stackTrace);
    }
  }

  /// Play a song from a file path.
  ///
  /// When [autoStart] is false, the source is loaded but playback does not
  /// start. This avoids a brief audible blip on platforms where `play()`
  /// followed by `pause()` round-trips through the platform channel.
  @override
  Future<void> playSong(Song song, {bool autoStart = true}) async {
    final path = await song.path;

    // Create a MediaItem for the song
    final item = MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      duration: song.duration,
    );

    mediaItem.add(item);

    try {
      final source = DeviceFileSource(path);
      _currentSource = source;

      // Reset playback speed to 1.0 for new songs to ensure consistent behavior
      _playbackSpeed = 1.0;
      // Reset pitch: the native Signalsmith processor survives source changes,
      // so a previous song's pitch would leak into the next song otherwise.
      // The cubit reapplies the persisted per-song pitch afterwards.
      _pitchSemitones = 0;
      // Same for the native click processor: clear its grid so a new song
      // never inherits the previous song's clicks. The cubit re-sends the
      // config when the metronome is (re)enabled. Implemented on Android and
      // iOS/macOS in the fork; the catches are a safety net for platforms
      // without an implementation.
      try {
        await audioPlayer.setClickTrack(enabled: false);
        // "Not implemented here" arrives as UnsupportedError (platform
        // interface default) or MissingPluginException (method channel with
        // no native handler). Both mean the same thing: nothing to clear.
        // ignore: avoid_catching_errors
      } on UnsupportedError {
        // Native click track not available on this platform.
      } on MissingPluginException {
        // Native click track not implemented on this platform.
      }
      // Same for the native loop region: a new song never inherits the
      // previous song's loop bounds.
      await _clearNativeLoopRegionSafely();

      await audioPlayer.setReleaseMode(ReleaseMode.stop);
      if (autoStart) {
        await audioPlayer.play(source);
      } else {
        await audioPlayer.setSource(source);
      }
      await audioPlayer.setPlaybackRate(_playbackSpeed);
      await _applyPitchShiftSafely();
      playbackState.add(
        playbackState.value.copyWith(
          controls: [
            MediaControl.skipToPrevious,
            if (autoStart) MediaControl.pause else MediaControl.play,
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          playing: autoStart,
          processingState: AudioProcessingState.ready,
        ),
      );
    } catch (e) {
      playbackState.add(
        playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
        ),
      );
      rethrow;
    }
  }

  @override
  Future<void> resume() async {
    // check if is in loop mode
    if (_activeLoop != null) {
      // check if is in loop mode
      if (_activeLoop!.start != null && _activeLoop!.end != null) {
        final position =
            await audioPlayer.getCurrentPosition() ?? Duration.zero;
        // check if is in loop mode
        if (position >= _activeLoop!.end!) {
          await audioPlayer.seek(_activeLoop!.start!);
          _notifySeek(_activeLoop!.start!);
        } else if (position < _activeLoop!.start!) {
          await audioPlayer.seek(_activeLoop!.start!);
          _notifySeek(_activeLoop!.start!);
        }
      }
    }

    await audioPlayer.resume();
    unawaited(_rearmLoopWrapTimerFromCurrentPosition());
    playbackState.add(
      playbackState.value.copyWith(
        controls: const [
          MediaControl.skipToPrevious,
          MediaControl.pause,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        playing: true,
        processingState: AudioProcessingState.ready,
      ),
    );
  }

  /// Enable loop mode with the specified loop
  Future<void> enableLoopMode(Loop loop) async {
    await _loopPositionSubscription?.cancel();
    _loopPositionSubscription = null;
    _loopCheckTimer?.cancel();
    _loopCheckTimer = null;
    _loopWrapTimer?.cancel();
    _activeLoop = loop;

    // Update current loop index for navigation
    _currentLoopIndex = _loops.indexWhere((l) => l.id == loop.id);

    final start = loop.start;
    final end = loop.end;

    if (start == null || end == null) {
      return;
    }

    // Prefer the native loop region (Android): the engine wraps at the
    // boundary itself, with no detection or platform-channel latency. Dart
    // wrapping below stays as the fallback for platforms without it. Native
    // is strictly an optimization, so *any* failure — UnsupportedError from
    // the interface default, MissingPluginException/PlatformException from a
    // platform whose native side doesn't implement it — falls back to Dart.
    _nativeLoopRegionActive = false;
    try {
      await audioPlayer.setLoopRegion(enabled: true, start: start, end: end);
      _nativeLoopRegionActive = true;
    } catch (e) {
      log('Native loop region unavailable, wrapping from Dart: $e');
    }

    // Use stream for responsive UI updates when app is in foreground
    final positionUpdates = positionStream ?? audioPlayer.onPositionChanged;
    _loopPositionSubscription = positionUpdates.listen(
      _handleLoopPositionUpdate,
    );

    // Use timer as fallback for background mode where stream events may be throttled
    // The timer actively polls position which works even when the app is backgrounded
    _startLoopCheckTimer();

    await _ensureWithinLoopBounds(loop);
    await _rearmLoopWrapTimerFromCurrentPosition();
  }

  void _startLoopCheckTimer() {
    _loopCheckTimer?.cancel();
    _loopCheckTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _checkLoopBoundsAsync();
    });
  }

  /// Cancels the polling timers so the process can go fully idle while the
  /// app is backgrounded without active playback. The loop machinery itself
  /// stays armed ([_activeLoop] is untouched); [play] re-arms both timers.
  void suspendBackgroundPolling() {
    _loopCheckTimer?.cancel();
    _loopCheckTimer = null;
    _loopWrapTimer?.cancel();
    _loopWrapTimer = null;
  }

  /// Disable loop mode
  Future<void> disableLoopMode() async {
    await _loopPositionSubscription?.cancel();
    _loopPositionSubscription = null;
    _loopCheckTimer?.cancel();
    _loopCheckTimer = null;
    _loopWrapTimer?.cancel();
    _loopWrapTimer = null;
    _activeLoop = null;
    _currentLoopIndex = -1;
    _loopSeekInProgress = false;
    if (_nativeLoopRegionActive) {
      await _clearNativeLoopRegionSafely();
    }
  }

  /// Clears the native loop region, swallowing every failure mode: platforms
  /// without the feature throw (UnsupportedError, MissingPluginException or
  /// PlatformException depending on the layer that rejects it), and none of
  /// that may break song loading or loop teardown.
  Future<void> _clearNativeLoopRegionSafely() async {
    _nativeLoopRegionActive = false;
    try {
      await audioPlayer.setLoopRegion(enabled: false);
    } catch (e) {
      log('Failed to clear native loop region: $e');
    }
  }

  @override
  Future<void> play() async {
    await audioPlayer.resume();
    // Re-arm the loop poll if it was suspended while backgrounded
    // (e.g. play pressed on the lock screen after a background suspension).
    if (_activeLoop != null && _loopCheckTimer == null) {
      _startLoopCheckTimer();
    }
    unawaited(_rearmLoopWrapTimerFromCurrentPosition());
    playbackState.add(
      playbackState.value.copyWith(
        controls: const [
          MediaControl.skipToPrevious,
          MediaControl.pause,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        playing: true,
        processingState: AudioProcessingState.ready,
      ),
    );
  }

  @override
  Future<void> pause() async {
    _loopWrapTimer?.cancel();
    await _awaitActiveSeek();

    await audioPlayer.pause();
    playbackState.add(
      playbackState.value.copyWith(
        controls: const [
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        playing: false,
        processingState: AudioProcessingState.ready,
      ),
    );
  }

  @override
  Future<void> stop() async {
    _loopWrapTimer?.cancel();
    _pendingSeekTarget = null;
    await _awaitActiveSeek();

    await audioPlayer.stop();
    playbackState.add(
      playbackState.value.copyWith(
        controls: const [
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        playing: false,
        processingState: AudioProcessingState.completed,
      ),
    );
  }

  @override
  Future<void> seek(Duration position) {
    // A user seek supersedes any scheduled loop wrap; position updates after
    // the seek rearm the boundary timer.
    _loopWrapTimer?.cancel();
    _pendingSeekTarget = position;
    _pendingSeekIsLoopWrap = false;
    _seekQueue ??= _processSeekQueue();
    return _seekQueue!;
  }

  /// Fast path for loop wraps: shares the seek queue (so a wrap never
  /// interleaves with an in-flight user seek) but skips [_performSeek]'s
  /// duration/position guards — the target is a validated loop start, and
  /// every extra platform-channel round trip is audible as re-entry delay.
  Future<void> _seekToLoopStart(Duration start) {
    _pendingSeekTarget = start;
    _pendingSeekIsLoopWrap = true;
    _seekQueue ??= _processSeekQueue();
    return _seekQueue!;
  }

  @override
  Future<void> setNativeClickTrack({
    required bool enabled,
    int? bpm,
    int? anchorMs,
    int offsetMs = 0,
    int beatsPerBar = 4,
    int pulsesPerBeat = 1,
    double volume = 1.0,
  }) {
    return audioPlayer.setClickTrack(
      enabled: enabled,
      bpm: bpm,
      anchorMs: anchorMs,
      offsetMs: offsetMs,
      beatsPerBar: beatsPerBar,
      pulsesPerBeat: pulsesPerBeat,
      volume: volume,
    );
  }

  @override
  Future<void> skipToPrevious() async {
    log(
      'skipToPrevious called, currentLoopIndex: $_currentLoopIndex, loops: ${_loops.length}',
    );

    final now = DateTime.now();
    final isDoubleTap =
        _lastSkipPreviousTime != null &&
        now.difference(_lastSkipPreviousTime!) < _doubleTapThreshold;
    _lastSkipPreviousTime = now;

    if (isDoubleTap && _loops.length > 1) {
      // Double tap: go to previous loop (cubit handles wrapping)
      log('Double tap detected, going to previous loop');
      _navigationEventController.add(LoopNavigationEvent.previousLoop);
    } else {
      // Single tap: restart current loop or song
      log('Single tap, restarting current loop/song');
      await _restartCurrentPlayback();
    }
  }

  @override
  Future<void> skipToNext() async {
    log('skipToNext called');

    if (_loops.isEmpty) {
      // No loops: restart song
      log('No loops, restarting song');
      await seek(Duration.zero);
    } else {
      // Go to next loop
      log('Going to next loop');
      _navigationEventController.add(LoopNavigationEvent.nextLoop);
    }
  }

  /// Restart the current playback (loop start or song start)
  Future<void> _restartCurrentPlayback() async {
    if (_activeLoop != null && _activeLoop!.start != null) {
      // Restart current loop
      await seek(_activeLoop!.start!);
    } else {
      // Restart song from beginning
      await seek(Duration.zero);
    }
  }

  /// Update the list of loops for navigation
  void setLoops(List<Loop> loops) {
    _loops = loops;
    // Update current loop index if active loop exists
    if (_activeLoop != null) {
      _currentLoopIndex = _loops.indexWhere((l) => l.id == _activeLoop!.id);
    }
  }

  /// Set the current loop index
  void setCurrentLoopIndex(int index) {
    _currentLoopIndex = index;
  }

  /// Enable or disable full song repeat mode
  void setFullSongRepeatEnabled(bool enabled) {
    _fullSongRepeatEnabled = enabled;
    log('Full song repeat enabled: $enabled');
  }

  /// Check if full song repeat is enabled
  bool get isFullSongRepeatEnabled => _fullSongRepeatEnabled;

  /// Returns the current internal playback speed
  @override
  double get currentPlaybackSpeed => _playbackSpeed;

  @override
  Future<bool> setSpeed(double speed) async {
    final targetSpeed = _normalizePlaybackSpeed(speed);
    log('setSpeed: $targetSpeed');

    final success = await _setPlaybackRateSafely(targetSpeed);
    if (success) {
      _playbackSpeed = targetSpeed;
      // A speed change shifts when the playhead reaches the loop end, so the
      // currently scheduled wrap (if any) fires at the wrong time.
      unawaited(_rearmLoopWrapTimerFromCurrentPosition());
    }
    return success;
  }

  /// Returns the currently applied pitch shift in semitones
  @override
  int get currentPitchSemitones => _pitchSemitones;

  @override
  Future<bool> setPitchSemitones(int semitones) async {
    final target = semitones.clamp(_minPitchSemitones, _maxPitchSemitones);
    log('setPitchSemitones: $target');

    try {
      await audioPlayer.setPitchShift(_pitchMultiplierForSemitones(target));
      _pitchSemitones = target;
      return true;
    } catch (e) {
      log('Failed to set pitch shift: $e');
      return false;
    }
  }

  double _pitchMultiplierForSemitones(int semitones) =>
      pow(2.0, semitones / 12.0).toDouble();

  /// Reapplies the current pitch shift, swallowing platform errors (pitch is
  /// unsupported outside Android; playback must not fail because of it).
  Future<void> _applyPitchShiftSafely() async {
    try {
      await audioPlayer.setPitchShift(
        _pitchMultiplierForSemitones(_pitchSemitones),
      );
    } catch (e) {
      log('Failed to apply pitch shift: $e');
    }
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'enableLoop':
        if (extras != null && extras['loop'] != null) {
          final loop = extras['loop'] as Loop;

          await enableLoopMode(loop);
        }
        return;
      case 'disableLoop':
        await pause();

        await disableLoopMode();
        return;
      case 'setPitch':
        if (extras != null && extras['semitones'] != null) {
          final semitones = extras['semitones'] as int;
          await setPitchSemitones(semitones);
        }
        return;
      case 'setLoops':
        if (extras != null && extras['loops'] != null) {
          final loops = extras['loops'] as List<Loop>;
          setLoops(loops);
        }
        return;
      case 'setFullSongRepeat':
        if (extras != null && extras['enabled'] != null) {
          final enabled = extras['enabled'] as bool;
          setFullSongRepeatEnabled(enabled);
        }
        return;
      default:
        return super.customAction(name, extras);
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    // Keep playing when the app is removed from the recent apps list
    // This is important for background playback
    return;
  }

  // if loop is not null, check if position is within loop start and end,
  // if not, seek to loop start
  @override
  Future<void> forward(int seconds, Loop? loop) async {
    final position = await audioPlayer.getCurrentPosition() ?? Duration.zero;
    final duration = await audioPlayer.getDuration() ?? Duration.zero;

    // If we are already at or beyond the track length, nothing to do.
    if (position >= duration) return;

    // Desired target after forwarding.
    var target = position + Duration(seconds: seconds);

    // Respect loop end only while playing: paused skipping is how the user
    // parks the playhead past the end to set a new one (mirrors the paused
    // exemption in _handleLoopPositionUpdate).
    final respectLoop = audioPlayer.state == PlayerState.playing;

    if (respectLoop && loop?.end != null) {
      if (target > loop!.end!) {
        target = loop.end!;
      }
    } else if (target > duration) {
      // Clamp to the end of the track.
      target = duration;
    }

    await audioPlayer.seek(target);
    _notifySeek(target);
  }

  // if loop is not null, check if position is within loop start and end,
  // if not, seek to loop start
  @override
  Future<void> back(int seconds, Loop? loop) async {
    final position = await audioPlayer.getCurrentPosition() ?? Duration.zero;

    // Desired target after rewinding.
    var target = position - Duration(seconds: seconds);

    // Clamp to zero (start of track).
    if (target < Duration.zero) {
      target = Duration.zero;
    }

    // Respect loop start only while playing — see [forward].
    if (audioPlayer.state == PlayerState.playing &&
        loop?.start != null &&
        target < loop!.start!) {
      target = loop.start!;
    }

    await audioPlayer.seek(target);
    _notifySeek(target);
  }

  // Close resources when the audio handler is no longer needed
  @override
  Future<void> close() async {
    _pendingSeekTarget = null;
    await _awaitActiveSeek();

    await audioPlayer.dispose();

    await _playerStateSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _loopPositionSubscription?.cancel();
    await _loopWrapSubscription?.cancel();
    _loopCheckTimer?.cancel();
    _loopCheckTimer = null;
    _loopWrapTimer?.cancel();
    _loopWrapTimer = null;
    _currentSource = null;
    _loops = [];
    _currentLoopIndex = -1;
    await _navigationEventController.close();
    await _seekEventController.close();
  }

  Future<void> _awaitActiveSeek() async {
    final activeSeek = _seekQueue;
    if (activeSeek == null) return;

    try {
      await activeSeek;
    } catch (_) {
      // Errors are surfaced to the original seek caller; suppress here.
    }
  }

  Future<void> _processSeekQueue() async {
    try {
      while (_pendingSeekTarget != null) {
        final target = _pendingSeekTarget!;
        final isLoopWrap = _pendingSeekIsLoopWrap;
        _pendingSeekTarget = null;
        _pendingSeekIsLoopWrap = false;
        if (isLoopWrap) {
          await _performLoopWrapSeek(target);
        } else {
          await _performSeek(target);
        }
      }
    } finally {
      _seekQueue = null;
    }
  }

  Future<void> _performLoopWrapSeek(Duration target) async {
    await _reloadSourceIfNeeded();
    await audioPlayer.seek(target);
    _notifySeek(target);
  }

  Future<void> _performSeek(Duration requestedPosition) async {
    await _reloadSourceIfNeeded();

    final trackDuration =
        await audioPlayer.getDuration() ?? mediaItem.value?.duration;
    final currentPosition =
        await audioPlayer.getCurrentPosition() ?? Duration.zero;

    var clampedPosition = requestedPosition;
    if (clampedPosition < Duration.zero) {
      clampedPosition = Duration.zero;
    }

    if (trackDuration != null &&
        trackDuration > Duration.zero &&
        clampedPosition > trackDuration) {
      clampedPosition = trackDuration;
    }

    if ((clampedPosition - currentPosition).abs() <
        const Duration(milliseconds: 20)) {
      return;
    }

    await audioPlayer.seek(clampedPosition);
    _notifySeek(clampedPosition);
  }

  Future<void> _reloadSourceIfNeeded() async {
    if (_currentSource == null) return;

    final playerState = audioPlayer.state;
    if (playerState == PlayerState.completed ||
        playerState == PlayerState.stopped ||
        playerState == PlayerState.disposed) {
      await audioPlayer.setSource(_currentSource!);
      await audioPlayer.setPlaybackRate(_playbackSpeed);
      await _applyPitchShiftSafely();
    }
  }

  @visibleForTesting
  void debugSetCurrentSource(Source source) {
    _currentSource = source;
  }

  void _handleLoopPositionUpdate(Duration position) {
    final loop = _activeLoop;
    if (loop == null) return;

    final start = loop.start;
    final end = loop.end;
    if (start == null || end == null) return;

    // Only enforce the loop wrap during active playback. While paused, the user
    // may drag the playhead past the loop end to set a new end — snapping back
    // to start here would make the loop impossible to edit. (The play button
    // handles jumping back into the loop via resume().)
    if (audioPlayer.state != PlayerState.playing) {
      _loopWrapTimer?.cancel();
      return;
    }

    // The engine wraps by itself — reacting here too would race it into a
    // double seek. The 200 ms watchdog poll covers genuine native misses.
    if (_nativeLoopRegionActive) return;

    if (_loopSeekInProgress) return;

    if (position >= end) {
      // Late detection (e.g. first update after returning to the foreground):
      // wrap immediately.
      unawaited(_wrapToLoopStart());
    } else {
      // Predictive wrap: fire the seek when the playhead reaches the boundary
      // instead of waiting for a position update to report it was passed.
      _armLoopWrapTimer(end - position);
    }
  }

  /// Schedules the loop wrap for the moment the playhead reaches the loop
  /// end, scaled by playback speed. Rearmed on every position update while
  /// playing, so scheduling drift stays within one update interval.
  void _armLoopWrapTimer(Duration remaining) {
    // Predictive wraps are Dart-fallback machinery; never arm them while the
    // native loop region owns the boundary.
    if (_nativeLoopRegionActive) return;

    _loopWrapTimer?.cancel();

    final scaledMicroseconds = (remaining.inMicroseconds / _playbackSpeed)
        .round();
    _loopWrapTimer = Timer(
      Duration(microseconds: scaledMicroseconds < 0 ? 0 : scaledMicroseconds),
      () {
        if (audioPlayer.state != PlayerState.playing) return;
        unawaited(_wrapToLoopStart());
      },
    );
  }

  /// Rearms the boundary timer from the player's current position — used
  /// after resume, speed changes, and loop activation, where a previously
  /// scheduled fire time (if any) is stale.
  Future<void> _rearmLoopWrapTimerFromCurrentPosition() async {
    final end = _activeLoop?.end;
    if (end == null) return;
    if (audioPlayer.state != PlayerState.playing) return;

    try {
      final position = await audioPlayer.getCurrentPosition();
      if (position == null || _loopSeekInProgress) return;

      if (position < end) {
        _armLoopWrapTimer(end - position);
      }
    } catch (e) {
      log('Error rearming loop wrap timer: $e');
    }
  }

  /// Seeks back to the active loop's start via the fast seek path.
  Future<void> _wrapToLoopStart() async {
    final loop = _activeLoop;
    final start = loop?.start;
    final end = loop?.end;
    if (loop == null || start == null || end == null) return;
    if (_loopSeekInProgress) return;

    _loopSeekInProgress = true;
    _loopWrapTimer?.cancel();
    try {
      await _seekToLoopStart(start);
    } finally {
      _loopSeekInProgress = false;
    }

    // In the background frame-driven position updates stop, so nothing would
    // rearm the boundary timer for the next pass — schedule it from the loop
    // length. Foreground position updates simply keep refining it.
    if (identical(_activeLoop, loop) &&
        audioPlayer.state == PlayerState.playing) {
      _armLoopWrapTimer(end - start);
    }
  }

  /// Timer-based loop check that actively polls position.
  /// This works in background mode where stream events may be throttled.
  Future<void> _checkLoopBoundsAsync() async {
    final loop = _activeLoop;
    if (loop == null) return;

    final start = loop.start;
    final end = loop.end;
    if (start == null || end == null) return;

    // Only check when playing
    if (audioPlayer.state != PlayerState.playing) return;

    if (_loopSeekInProgress) return;

    try {
      final position = await audioPlayer.getCurrentPosition();
      if (position == null) return;

      if (_nativeLoopRegionActive) {
        // Watchdog only: the native message doesn't fire when a user seek
        // jumps past the loop end (messages trigger on playback reaching the
        // position, not on seeks over it). Well past the boundary — where a
        // native wrap can no longer be in flight — pull the playhead back.
        if (position >= end + _nativeWrapMissMargin) {
          await _wrapToLoopStart();
        }
        return;
      }

      if (position >= end) {
        // The predictive timer missed (or was never armed) — wrap now.
        await _wrapToLoopStart();
      } else if (!(_loopWrapTimer?.isActive ?? false)) {
        // Self-healing for background mode: keep a boundary timer scheduled
        // even when no position updates arrive to arm one.
        _armLoopWrapTimer(end - position);
      }
    } catch (e) {
      log('Error checking loop bounds: $e');
    }
  }

  /// Handles loop restart when the song completes.
  /// This is a fallback for when position updates are throttled in background mode.
  Future<void> _handleLoopCompletionRestart() async {
    final loop = _activeLoop;
    if (loop == null || loop.start == null) return;

    if (_loopSeekInProgress) return;

    _loopSeekInProgress = true;
    try {
      await _seekToLoopStart(loop.start!);
      await audioPlayer.resume();
      if (loop.end != null) {
        _armLoopWrapTimer(loop.end! - loop.start!);
      }
      playbackState.add(
        playbackState.value.copyWith(
          controls: const [
            MediaControl.skipToPrevious,
            MediaControl.pause,
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          playing: true,
          processingState: AudioProcessingState.ready,
        ),
      );
    } finally {
      _loopSeekInProgress = false;
    }
  }

  /// Handles full song repeat when the song completes and repeat is enabled.
  Future<void> _handleFullSongRepeat() async {
    log('Handling full song repeat');

    // Prevent re-entry while handling repeat
    if (_loopSeekInProgress) return;
    _loopSeekInProgress = true;

    try {
      // Reload source since player is in completed state
      if (_currentSource != null) {
        await audioPlayer.setSource(_currentSource!);
        await audioPlayer.setPlaybackRate(_playbackSpeed);
        await _applyPitchShiftSafely();
      }

      // Seek to beginning and play
      await audioPlayer.seek(Duration.zero);
      _notifySeek(Duration.zero);
      await audioPlayer.resume();

      playbackState.add(
        playbackState.value.copyWith(
          controls: const [
            MediaControl.skipToPrevious,
            MediaControl.pause,
            MediaControl.skipToNext,
          ],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          playing: true,
          processingState: AudioProcessingState.ready,
        ),
      );
    } catch (e) {
      log('Error handling full song repeat: $e');
    } finally {
      _loopSeekInProgress = false;
    }
  }

  Future<void> _ensureWithinLoopBounds(Loop loop) async {
    final start = loop.start;
    final end = loop.end;
    if (start == null || end == null) return;

    // Only pull the playhead into the loop while playing. When paused — e.g.
    // right after the user parks the playhead at a new end via setLoopEnd — a
    // forced seek to start would fight editing. resume() handles jumping into
    // the loop when playback actually starts.
    if (audioPlayer.state != PlayerState.playing) return;

    final currentPosition =
        await audioPlayer.getCurrentPosition() ?? Duration.zero;

    if (currentPosition >= end || currentPosition < start) {
      await seek(start);
    }
  }

  /// Timeout for waiting on active seeks before applying speed
  static const Duration _speedChangeTimeout = Duration(milliseconds: 500);

  Future<bool> _setPlaybackRateSafely(double speed) async {
    try {
      // Wait for active seek with timeout - don't block indefinitely
      final activeSeek = _seekQueue;
      if (activeSeek != null) {
        await activeSeek.timeout(
          _speedChangeTimeout,
          onTimeout: () {
            log('Timeout waiting for seek, applying speed anyway');
          },
        );
      }

      await audioPlayer.setPlaybackRate(speed);
      log('setPlaybackRate applied: $speed');
      return true;
    } catch (e) {
      log('Failed to set playback rate: $e');
      return false;
    }
  }

  double _normalizePlaybackSpeed(double speed) {
    if (!speed.isFinite || speed <= 0) {
      log('Ignoring invalid playback speed $speed, defaulting to 1.0');
      return 1.0;
    }

    if (speed < _minPlaybackSpeed) {
      return _minPlaybackSpeed;
    }

    if (speed > _maxPlaybackSpeed) {
      return _maxPlaybackSpeed;
    }

    return speed;
  }
}
