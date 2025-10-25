import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';

class AudioplayerService {
  final AudioPlayer audioPlayer;

  late Stream<PlayerState> playerStateStream;
  late Stream<Duration> positionStream;

  // Loop state management
  Loop? _activeLoop;
  bool _isLoopModeEnabled = false;
  StreamSubscription<Duration>? _loopPositionSubscription;

  // Constants
  static const double _defaultSpeed = 1.0;
  static const double _minSpeed = 0.25;
  static const double _maxSpeed = 4.0;

  AudioplayerService({
    required this.audioPlayer,
  });

  Future<Duration> get position async => await audioPlayer.getCurrentPosition() ?? Duration.zero;
  Future<Duration> get duration async => await audioPlayer.getDuration() ?? Duration.zero;
  PlayerState? get playerState => audioPlayer.state;

  // Loop state getters
  Loop? get activeLoop => _activeLoop;
  bool get isLoopModeEnabled => _isLoopModeEnabled;

  DeviceFileSource? audioSource;

  Future<void> init(Song song) async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    final path = await song.path;
    audioSource = DeviceFileSource(path);

    await audioPlayer.setSource(audioSource!);

    await audioPlayer.setPlaybackRate(_defaultSpeed);
    // await justAudioPlayer.pause();

    playerStateStream = audioPlayer.onPlayerStateChanged;
    positionStream = audioPlayer.onPositionChanged;
  }

  Future<void> play() async {
    if (audioSource == null) return;

    await audioPlayer.play(audioSource!);
  }

  /// Plays a loop
  /// The loop is played from the start to the end
  /// Checks if the loop end is reached and if so, starts over
  Future<void> playLoop(Loop loop) async {
    if (loop.start == null) return;

    await audioPlayer.seek(loop.start!);
    await audioPlayer.play(audioSource!);
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
      _loopPositionSubscription = audioPlayer.onPositionChanged.listen((
        position,
      ) {
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
  Future<void> _checkAndRestartLoop(Duration position) async {
    if (!_isLoopModeEnabled || _activeLoop == null) return;

    final loop = _activeLoop!;
    if (loop.start == null || loop.end == null) return;

    // Check if we've reached or passed the loop end
    if (position >= loop.end!) {
      // Seek back to loop start
      await audioPlayer.seek(loop.start!);
    }
  }

  /// Update the active loop (useful when loop boundaries change)
  Future<void> updateActiveLoop(Loop updatedLoop) async {
    if (_activeLoop?.id == updatedLoop.id) {
      _activeLoop = updatedLoop;

      // Restart monitoring if needed
      if (_isLoopModeEnabled && updatedLoop.start != null && updatedLoop.end != null) {
        await _loopPositionSubscription?.cancel();
        _loopPositionSubscription = audioPlayer.onPositionChanged.listen((
          position,
        ) {
          _checkAndRestartLoop(position);
        });
      }
    }
  }

  Future<void> pause() async {
    await audioPlayer.pause();
  }

  Future<void> stop() async {
    await audioPlayer.stop();
  }

  Future<void> setSpeed(double speed) async {
    var validatedSpeed = speed;

    if (speed < _minSpeed) {
      validatedSpeed = _minSpeed;
    } else if (speed > _maxSpeed) {
      validatedSpeed = _maxSpeed;
    }

    await audioPlayer.setPlaybackRate(validatedSpeed);
  }

  Future<void> seek(Duration position) async {
    await audioPlayer.seek(position);
  }

  Future<void> setVolume(double volume) async {
    await audioPlayer.setVolume(volume);
  }

  Future<void> setLoop(bool loop) async {
    // This method is kept for compatibility but loop functionality is now handled by enableLoop/disableLoop
    if (!loop) {
      await disableLoop();
    }
  }

  Future<void> dispose() async {
    await audioPlayer.stop();
    await audioPlayer.dispose();
    await playerStateStream.drain();
    await positionStream.drain();

    await _loopPositionSubscription?.cancel();
  }
}
