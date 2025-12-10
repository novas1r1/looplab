// ignore_for_file: use_setters_to_change_properties

import 'dart:async';
import 'dart:developer';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
// ignore: depend_on_referenced_packages
import 'package:meta/meta.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';

/// AudioHandler implementation for background audio playback
class RepeatlabAudioplayersServiceHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer audioPlayer;

  static const double _minPlaybackSpeed = 0.5;
  static const double _maxPlaybackSpeed = 2.0;

  Loop? _activeLoop;

  Stream<PlayerState>? playerStateStream;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  Stream<Duration>? positionStream;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _loopPositionSubscription;
  Timer? _loopCheckTimer;

  Future<Duration> get position async => await audioPlayer.getCurrentPosition() ?? Duration.zero;

  Duration? _pendingSeekTarget;
  Future<void>? _seekQueue;
  Source? _currentSource;
  double _playbackSpeed = 1.0;
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
                MediaControl.pause,
                MediaControl.stop,
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
                MediaControl.play,
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
                MediaControl.play,
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
          if (_activeLoop != null && _activeLoop!.start != null && _activeLoop!.end != null) {
            _handleLoopCompletionRestart();
            return;
          }

          playbackState.add(
            playbackState.value.copyWith(
              controls: const [
                MediaControl.play,
                MediaControl.stop,
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
                MediaControl.play,
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

  /// Play a song from a file path
  Future<void> playSong(Song song) async {
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

      await audioPlayer.setReleaseMode(ReleaseMode.stop);
      await audioPlayer.play(source);
      await audioPlayer.setPlaybackRate(_playbackSpeed);
      playbackState.add(
        playbackState.value.copyWith(
          controls: const [
            MediaControl.pause,
            MediaControl.stop,
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
      playbackState.add(
        playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
        ),
      );
      rethrow;
    }
  }

  Future<void> resume() async {
    // check if is in loop mode
    if (_activeLoop != null) {
      // check if is in loop mode
      if (_activeLoop!.start != null && _activeLoop!.end != null) {
        final position = await audioPlayer.getCurrentPosition() ?? Duration.zero;
        // check if is in loop mode
        if (position >= _activeLoop!.end!) {
          await audioPlayer.seek(_activeLoop!.start!);
        } else if (position < _activeLoop!.start!) {
          await audioPlayer.seek(_activeLoop!.start!);
        }
      }
    }

    await audioPlayer.resume();
    playbackState.add(
      playbackState.value.copyWith(
        controls: const [
          MediaControl.pause,
          MediaControl.stop,
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

    final start = loop.start;
    final end = loop.end;

    if (start == null || end == null) {
      return;
    }

    // Use stream for responsive UI updates when app is in foreground
    final positionUpdates = positionStream ?? audioPlayer.onPositionChanged;
    _loopPositionSubscription = positionUpdates.listen(_handleLoopPositionUpdate);

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
    _loopSeekInProgress = false;
  }

  @override
  Future<void> play() async {
    await audioPlayer.resume();
    playbackState.add(
      playbackState.value.copyWith(
        controls: const [
          MediaControl.pause,
          MediaControl.stop,
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
          MediaControl.play,
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
          MediaControl.play,
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
  Future<void> setSpeed(double speed) {
    final targetSpeed = _normalizePlaybackSpeed(speed);
    log('setSpeed: $targetSpeed');
    _playbackSpeed = targetSpeed;

    return _setPlaybackRateSafely(targetSpeed);
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
        if (extras != null && extras['pitch'] != null) {
          final pitch = extras['pitch'] as double;
          // Note: audioplayers doesn't directly support pitch shifting
          // This is a placeholder - actual implementation would need a different approach
          log('Pitch change requested: $pitch (not implemented in audioplayers)');
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
  }

  // if loop is not null, check if position is within loop start and end,
  // if not, seek to loop start
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
  }

  // Close resources when the audio handler is no longer needed
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

    final trackDuration = await audioPlayer.getDuration() ?? mediaItem.value?.duration;
    final currentPosition = await audioPlayer.getCurrentPosition() ?? Duration.zero;

    var clampedPosition = requestedPosition;
    if (clampedPosition < Duration.zero) {
      clampedPosition = Duration.zero;
    }

    if (trackDuration != null && trackDuration > Duration.zero && clampedPosition > trackDuration) {
      clampedPosition = trackDuration;
    }

    if ((clampedPosition - currentPosition).abs() < const Duration(milliseconds: 20)) {
      return;
    }

    await audioPlayer.seek(clampedPosition);
  }

  Future<void> _reloadSourceIfNeeded() async {
    if (_currentSource == null) return;

    final playerState = audioPlayer.state;
    if (playerState == PlayerState.completed ||
        playerState == PlayerState.stopped ||
        playerState == PlayerState.disposed) {
      await audioPlayer.setSource(_currentSource!);
      await audioPlayer.setPlaybackRate(_playbackSpeed);
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
            MediaControl.pause,
            MediaControl.stop,
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

  Future<void> _ensureWithinLoopBounds(Loop loop) async {
    final start = loop.start;
    final end = loop.end;
    if (start == null || end == null) return;

    final currentPosition = await audioPlayer.getCurrentPosition() ?? Duration.zero;

    if (currentPosition >= end || currentPosition < start) {
      await seek(start);
    }
  }

  Future<void> _setPlaybackRateSafely(double speed) async {
    await _awaitActiveSeek();
    await audioPlayer.setPlaybackRate(speed);
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
