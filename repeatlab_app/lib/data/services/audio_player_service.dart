import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';

class AudioPlayerService {
  // final audioplayers.AudioPlayer audioPlayer;
  final AudioPlayer justAudioPlayer;

  StreamSubscription<PlayerState>? playerStateSubscription;
  StreamSubscription<Duration>? positionSubscription;
  StreamSubscription<Duration?>? durationSubscription;

  // Loop state management
  Loop? _activeLoop;
  bool _isLoopModeEnabled = false;
  StreamSubscription<Duration>? _loopPositionSubscription;

  AudioPlayerService({
    // required this.audioPlayer,
    required this.justAudioPlayer,
  });

  Duration get position => justAudioPlayer.position;
  Duration? get duration => justAudioPlayer.duration;
  PlayerState? get playerState => justAudioPlayer.playerState;

  // Loop state getters
  Loop? get activeLoop => _activeLoop;
  bool get isLoopModeEnabled => _isLoopModeEnabled;

  Future<void> init(Song song) async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    final path = await song.path;
    final audioSource = AudioSource.uri(
      Uri.file(path),
      tag: MediaItem(
        id: song.id,
        title: song.title,
        artist: song.artist,
        duration: song.duration,
      ),
    );
    await justAudioPlayer.setAudioSource(audioSource);

    await justAudioPlayer.setSpeed(1.0);
    // await justAudioPlayer.pause();

    playerStateSubscription = justAudioPlayer.playerStateStream.listen((playerState) {
      // TODO: Implement player state
    });

    positionSubscription = justAudioPlayer.positionStream.listen((position) {
      // TODO: Implement position
    });

    durationSubscription = justAudioPlayer.durationStream.listen((duration) {
      // TODO: Implement duration
    });
  }

  Future<void> play() async {
    await justAudioPlayer.play();
  }

  /// Plays a loop
  /// The loop is played from the start to the end
  /// Checks if the loop end is reached and if so, starts over
  Future<void> playLoop(Loop loop) async {
    if (loop.start == null) return;

    await justAudioPlayer.seek(loop.start);
    await justAudioPlayer.play();
  }

  /// Enable loop mode with automatic restart
  /// When the position reaches the loop end, it automatically seeks to the loop start
  Future<void> enableLoop(Loop loop) async {
    // Cancel any existing loop monitoring
    await _loopPositionSubscription?.cancel();

    _activeLoop = loop;
    _isLoopModeEnabled = true;

    // Only start monitoring if we have valid start and end points
    if (loop.start != null && loop.end != null) {
      _loopPositionSubscription = justAudioPlayer.positionStream.listen((position) {
        _checkAndRestartLoop(position);
      });
    }
  }

  /// Disable loop mode
  Future<void> disableLoop() async {
    await _loopPositionSubscription?.cancel();
    _activeLoop = null;
    _isLoopModeEnabled = false;
  }

  /// Check if position has reached loop end and restart if needed
  void _checkAndRestartLoop(Duration position) {
    if (!_isLoopModeEnabled || _activeLoop == null) return;

    final loop = _activeLoop!;
    if (loop.start == null || loop.end == null) return;

    // Check if we've reached or passed the loop end
    if (position >= loop.end!) {
      // Seek back to loop start
      justAudioPlayer.seek(loop.start);
    }
  }

  /// Update the active loop (useful when loop boundaries change)
  Future<void> updateActiveLoop(Loop updatedLoop) async {
    if (_activeLoop?.id == updatedLoop.id) {
      _activeLoop = updatedLoop;

      // Restart monitoring if needed
      if (_isLoopModeEnabled && updatedLoop.start != null && updatedLoop.end != null) {
        await _loopPositionSubscription?.cancel();
        _loopPositionSubscription = justAudioPlayer.positionStream.listen((position) {
          _checkAndRestartLoop(position);
        });
      }
    }
  }

  Future<void> pause() async {
    await justAudioPlayer.pause();
  }

  Future<void> stop() async {
    await justAudioPlayer.stop();
  }

  Future<void> setSpeed(double speed) async {
    await justAudioPlayer.setSpeed(speed);
  }

  Future<void> seek(Duration position) async {
    await justAudioPlayer.seek(position);
  }

  Future<void> setVolume(double volume) async {
    await justAudioPlayer.setVolume(volume);
  }

  Future<void> setLoop(bool loop) async {
    // This method is kept for compatibility but loop functionality is now handled by enableLoop/disableLoop
    if (!loop) {
      await disableLoop();
    }
  }

  Future<void> dispose() async {
    await playerStateSubscription?.cancel();
    await positionSubscription?.cancel();
    await durationSubscription?.cancel();
    await _loopPositionSubscription?.cancel();

    await justAudioPlayer.dispose();
  }
}
