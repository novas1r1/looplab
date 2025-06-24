import 'dart:async';
import 'dart:developer';

import 'package:async/async.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audioplayers/audioplayers.dart';
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

  CancelableOperation? _seekOperation;

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
              playing: true,
              processingState: AudioProcessingState.ready,
            ),
          );
        case PlayerState.paused:
          playbackState.add(
            playbackState.value.copyWith(
              playing: false,
              processingState: AudioProcessingState.ready,
            ),
          );
        case PlayerState.stopped:
          playbackState.add(
            playbackState.value.copyWith(
              playing: false,
              processingState: AudioProcessingState.idle,
            ),
          );
        case PlayerState.completed:
          playbackState.add(
            playbackState.value.copyWith(
              playing: false,
              processingState: AudioProcessingState.completed,
            ),
          );
        case PlayerState.disposed:
          playbackState.add(
            playbackState.value.copyWith(
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
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    log('AudioSession initialized: ${session.isConfigured}');
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
      await audioPlayer.play(DeviceFileSource(path));
      playbackState.add(
        playbackState.value.copyWith(
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
    await audioPlayer.resume();
    playbackState.add(
      playbackState.value.copyWith(playing: true, processingState: AudioProcessingState.ready),
    );
  }

  /// Enable loop mode with the specified loop
  void enableLoopMode(Loop loop) {
    // Cancel any existing timer first
    _loopTimer?.cancel();
    _activeLoop = loop;

    // Only start the loop timer if we have valid start and end points
    if (loop.start != null && loop.end != null) {
      _loopTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
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
      playbackState.value.copyWith(playing: true, processingState: AudioProcessingState.ready),
    );
  }

  @override
  Future<void> pause() async {
    _seekOperation?.cancel();

    await audioPlayer.pause();
    playbackState.add(
      playbackState.value.copyWith(playing: false, processingState: AudioProcessingState.ready),
    );
  }

  @override
  Future<void> stop() async {
    _seekOperation?.cancel();

    await audioPlayer.stop();
    playbackState.add(
      playbackState.value.copyWith(playing: false, processingState: AudioProcessingState.completed),
    );
  }

  @override
  Future<void> seek(Duration position) async {
    var newPosition = position;

    // Only seek if the position change is significant
    /* if (state.position != null &&
        (newPosition - state.position!).abs() <= const Duration(milliseconds: 100)) {
      log('SEEK song to $position skipped - change too small (<100ms)');
      return;
    } */

    final duration = await audioPlayer.getDuration() ?? Duration.zero;

    final currentPosition = await audioPlayer.getCurrentPosition();
    if (newPosition == currentPosition || newPosition > duration) {
      log('SEEK song to $position skipped - position is out of range');
      return;
    }

    log('SEEK song to $position');
    // cancel any existing seek
    _seekOperation?.cancel();

    // Ensure position is within valid range
    if (newPosition < Duration.zero) {
      newPosition = Duration.zero;
    } else if (newPosition > duration) {
      newPosition = duration;
    }

    // Seek to position
    _seekOperation = CancelableOperation.fromFuture(audioPlayer.seek(newPosition));
    await _seekOperation?.valueOrCancellation();

    await audioPlayer.seek(position);
  }

  @override
  Future<void> setSpeed(double speed) => audioPlayer.setPlaybackRate(speed);

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

  Future<void> forward(int seconds) async {
    final position = await audioPlayer.getCurrentPosition();
    final duration = await audioPlayer.getDuration() ?? Duration.zero;

    if (position != null && position < duration - Duration(seconds: seconds)) {
      final newPosition = position + Duration(seconds: seconds);
      await audioPlayer.seek(newPosition);
    }
  }

  Future<void> back(int seconds) async {
    final position = await audioPlayer.getCurrentPosition();
    if (position != null && position > Duration(seconds: seconds)) {
      final newPosition = position - Duration(seconds: seconds);
      await audioPlayer.seek(newPosition);
    }
  }

  // Close resources when the audio handler is no longer needed
  Future<void> close() async {
    _loopTimer?.cancel();
    _seekOperation?.cancel();

    await audioPlayer.dispose();

    await _playerStateSubscription?.cancel();
    await _positionSubscription?.cancel();
  }
}
