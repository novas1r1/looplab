import 'dart:async';
import 'dart:developer';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';

/// AudioHandler implementation for background audio playback
class RepeatlabAudioplayersServiceHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer audioPlayer;

  Timer? _loopTimer;
  Loop? _activeLoop;

  Stream<PlayerState>? playerStateStream;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  Stream<Duration>? positionStream;
  StreamSubscription<Duration>? _positionSubscription;

  Future<Duration> get position async => await audioPlayer.getCurrentPosition() ?? Duration.zero;

  Duration? _pendingSeekTarget;
  Future<void>? _seekQueue;
  Source? _currentSource;
  double _playbackSpeed = 1.0;

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
  void enableLoopMode(Loop loop) {
    // Cancel any existing timer first
    _loopTimer?.cancel();
    _activeLoop = loop;

    // Only start the loop timer if we have valid start and end points
    // TODO: this doesnt work
    if (loop.start != null && loop.end != null) {
      _loopTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
        // Check if loop is still active before proceeding
        if (_activeLoop == null) {
          _loopTimer?.cancel();
          return;
        }

        audioPlayer.getCurrentPosition().then((position) {
          // Check again if loop is still active before using it
          if (_activeLoop == null || position == null) return;

          // only if is playing
          if (audioPlayer.state == PlayerState.playing && position >= _activeLoop!.end!) {
            audioPlayer.seek(_activeLoop!.start!);
          }
        });
      });
    }
  }

  /// Disable loop mode
  void disableLoopMode() {
    _loopTimer?.cancel();
    _activeLoop = null;
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
    _playbackSpeed = speed;
    return audioPlayer.setPlaybackRate(speed);
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'enableLoop':
        if (extras != null && extras['loop'] != null) {
          final loop = extras['loop'] as Loop;

          enableLoopMode(loop);
        }
      case 'disableLoop':
        await pause();

        disableLoopMode();
      case 'setPitch':
        if (extras != null && extras['pitch'] != null) {
          final pitch = extras['pitch'] as double;
          // Note: audioplayers doesn't directly support pitch shifting
          // This is a placeholder - actual implementation would need a different approach
          log('Pitch change requested: $pitch (not implemented in audioplayers)');
        }
      default:
        super.customAction(name, extras);
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
    _loopTimer?.cancel();
    _pendingSeekTarget = null;
    await _awaitActiveSeek();

    await audioPlayer.dispose();

    await _playerStateSubscription?.cancel();
    await _positionSubscription?.cancel();
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
    if (playerState == PlayerState.completed || playerState == PlayerState.stopped || playerState == PlayerState.disposed) {
      await audioPlayer.setSource(_currentSource!);
      await audioPlayer.setPlaybackRate(_playbackSpeed);
    }
  }

  @visibleForTesting
  void debugSetCurrentSource(Source source) {
    _currentSource = source;
  }
}
