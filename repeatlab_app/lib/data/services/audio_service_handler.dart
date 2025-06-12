import 'dart:async';
import 'dart:developer';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';

/// TODO NOT USED
/// AudioHandler implementation for background audio playback
class RepeatLabAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer audioPlayer;

  Timer? _loopTimer;
  Loop? _activeLoop;

  StreamSubscription<PlayerState>? playerStateSubscription;
  StreamSubscription<Duration>? positionSubscription;
  StreamSubscription<Duration>? durationSubscription;

  RepeatLabAudioHandler({required this.audioPlayer}) {
    log('RepeatLabAudioHandler constructor');

    _initAudioSession();

    playerStateSubscription = audioPlayer.onPlayerStateChanged.listen((state) {
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

    positionSubscription = audioPlayer.onPositionChanged.listen((position) {
      playbackState.add(playbackState.value.copyWith(updatePosition: position));
    });

    durationSubscription = audioPlayer.onDurationChanged.listen((duration) {
      mediaItem.add(mediaItem.value?.copyWith(duration: duration));
    });
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
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
        playbackState.value.copyWith(playing: true, processingState: AudioProcessingState.ready),
      );
    } catch (e) {
      playbackState.add(playbackState.value.copyWith(processingState: AudioProcessingState.error));
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

        audioPlayer.getCurrentPosition().then((position) async {
          // Check again if loop is still active before using it
          if (_activeLoop == null || position == null) return;

          if (position >= _activeLoop!.end!) {
            await audioPlayer.seek(_activeLoop!.start!);
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
    await audioPlayer.pause();
    playbackState.add(
      playbackState.value.copyWith(playing: false, processingState: AudioProcessingState.ready),
    );
  }

  @override
  Future<void> stop() async {
    await audioPlayer.stop();
    playbackState.add(
      playbackState.value.copyWith(playing: false, processingState: AudioProcessingState.idle),
    );
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      // First pause playback to ensure clean seek
      await pause();

      // Update state to indicate seeking
      playbackState.add(
        playbackState.value.copyWith(processingState: AudioProcessingState.buffering),
      );

      // Perform the seek operation with a shorter timeout
      await audioPlayer.seek(position);

      // Update state after successful seek
      playbackState.add(
        playbackState.value.copyWith(
          processingState: AudioProcessingState.ready,
          updatePosition: position,
        ),
      );

      // Resume playback
      await resume();
    } catch (e) {
      log('Error during seek: $e');
      // Reset to previous state on error
      playbackState.add(playbackState.value.copyWith(processingState: AudioProcessingState.error));
      rethrow;
    }
  }

  @override
  Future<void> setSpeed(double speed) => audioPlayer.setPlaybackRate(speed);

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'enableLoop':
        if (extras != null && extras['loop'] != null) {
          enableLoopMode(extras['loop'] as Loop);
        }
      case 'disableLoop':
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

  // Close resources when the audio handler is no longer needed
  Future<void> close() async {
    _loopTimer?.cancel();
    await audioPlayer.dispose();

    await playerStateSubscription?.cancel();
    await positionSubscription?.cancel();
    await durationSubscription?.cancel();
  }
}
