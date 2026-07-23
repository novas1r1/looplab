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

  @override
  Future<Duration> get position async =>
      await audioPlayer.getCurrentPosition() ?? Duration.zero;

  Duration? _pendingSeekTarget;
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
      // config when the metronome is (re)enabled. Non-Android platforms
      // throw UnsupportedError — nothing to clear there.
      try {
        await audioPlayer.setClickTrack(enabled: false);
        // The platform interface signals "not implemented here" via
        // UnsupportedError by design (same pattern as setPitchShift) —
        // catching it is the intended cross-platform usage.
        // ignore: avoid_catching_errors
      } on UnsupportedError {
        // Native click track not available on this platform.
      }

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
    _activeLoop = loop;

    // Update current loop index for navigation
    _currentLoopIndex = _loops.indexWhere((l) => l.id == loop.id);

    final start = loop.start;
    final end = loop.end;

    if (start == null || end == null) {
      return;
    }

    // Use stream for responsive UI updates when app is in foreground
    final positionUpdates = positionStream ?? audioPlayer.onPositionChanged;
    _loopPositionSubscription = positionUpdates.listen(
      _handleLoopPositionUpdate,
    );

    // Use timer as fallback for background mode where stream events may be throttled
    // The timer actively polls position which works even when the app is backgrounded
    _loopCheckTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _checkLoopBoundsAsync();
    });

    await _ensureWithinLoopBounds(loop);
  }

  /// Disable loop mode
  Future<void> disableLoopMode() async {
    await _loopPositionSubscription?.cancel();
    _loopPositionSubscription = null;
    _loopCheckTimer?.cancel();
    _loopCheckTimer = null;
    _activeLoop = null;
    _currentLoopIndex = -1;
    _loopSeekInProgress = false;
  }

  @override
  Future<void> play() async {
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
  }

  @override
  Future<void> pause() async {
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
    _pendingSeekTarget = position;
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
  Future<void> swapSourceFile(String path) async {
    await _awaitActiveSeek();

    final wasPlaying = audioPlayer.state == PlayerState.playing;
    final currentPosition =
        await audioPlayer.getCurrentPosition() ?? Duration.zero;

    final source = DeviceFileSource(path);
    _currentSource = source;

    // setSource resets the platform player, so speed and pitch must be
    // reapplied — same as _reloadSourceIfNeeded.
    await audioPlayer.setSource(source);
    await audioPlayer.setPlaybackRate(_playbackSpeed);
    await _applyPitchShiftSafely();

    await audioPlayer.seek(currentPosition);
    if (wasPlaying) {
      await audioPlayer.resume();
    }
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

    // Respect loop end if a loop is active.
    if (loop != null && loop.end != null) {
      if (target > loop.end!) {
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

    // Respect loop start if a loop is active.
    if (loop != null && loop.start != null && target < loop.start!) {
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
    _loopCheckTimer?.cancel();
    _loopCheckTimer = null;
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
        _pendingSeekTarget = null;
        await _performSeek(target);
      }
    } finally {
      _seekQueue = null;
    }
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

    if (position >= end) {
      if (_loopSeekInProgress) {
        return;
      }

      _loopSeekInProgress = true;
      seek(start).whenComplete(() {
        _loopSeekInProgress = false;
      });
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

      if (position >= end) {
        _loopSeekInProgress = true;
        await seek(start);
        _loopSeekInProgress = false;
      }
    } catch (e) {
      log('Error checking loop bounds: $e');
      _loopSeekInProgress = false;
    } finally {
      _loopSeekInProgress = false;
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
      await seek(loop.start!);
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
