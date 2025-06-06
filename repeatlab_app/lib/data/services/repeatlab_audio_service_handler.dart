import 'dart:async';
import 'dart:developer';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';

/// AudioHandler implementation for background audio playback
class RepeatlabAudioServiceHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer audioPlayer;

  Timer? _loopTimer;
  Loop? _activeLoop;

  StreamSubscription<PlayerState>? playerStateSubscription;
  StreamSubscription<Duration>? positionSubscription;
  StreamSubscription<Duration?>? durationSubscription;

  RepeatlabAudioServiceHandler({required this.audioPlayer}) {
    log('SoloudAudioServiceHandler constructor');

    _initAudioSession();

    playerStateSubscription = audioPlayer.playerStateStream.listen((state) {
      log('playerStateSubscription: $state');

      playbackState.add(
        playbackState.value.copyWith(
          playing: state.playing,
          processingState: _getAudioProcessingState(state.processingState),
        ),
      );
    });

    positionSubscription = audioPlayer.positionStream.listen((position) {
      playbackState.add(
        playbackState.value.copyWith(
          updatePosition: position,
        ),
      );
    });

    durationSubscription = audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        mediaItem.add(mediaItem.value?.copyWith(duration: duration));
      }
    });
  }

  AudioProcessingState _getAudioProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.buffering;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
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
      await audioPlayer.setFilePath(path);
      await audioPlayer.play();
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
    await audioPlayer.play();
    playbackState.add(
      playbackState.value.copyWith(
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
    if (loop.start != null && loop.end != null) {
      _loopTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        // Check if loop is still active before proceeding
        if (_activeLoop == null) {
          _loopTimer?.cancel();
          return;
        }

        final position = audioPlayer.position;
        // Check again if loop is still active before using it
        if (_activeLoop == null) return;

        // only if is playing
        if (audioPlayer.playing && position >= _activeLoop!.end!) {
          audioPlayer.seek(_activeLoop!.start);
        }
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
    await audioPlayer.play();
    playbackState.add(
      playbackState.value.copyWith(
        playing: true,
        processingState: AudioProcessingState.ready,
      ),
    );
  }

  @override
  Future<void> pause() async {
    await audioPlayer.pause();
    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.ready,
      ),
    );
  }

  @override
  Future<void> stop() async {
    await audioPlayer.stop();
    playbackState.add(
      playbackState.value.copyWith(
        playing: false,
        processingState: AudioProcessingState.completed,
      ),
    );
  }

  @override
  Future<void> seek(Duration position) => audioPlayer.seek(position);

  @override
  Future<void> setSpeed(double speed) => audioPlayer.setSpeed(speed);

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
