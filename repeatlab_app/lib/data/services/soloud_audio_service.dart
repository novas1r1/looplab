import 'dart:async';
import 'dart:developer' as dev;
import 'dart:math';

import 'package:audio_session/audio_session.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';

/// SoLoud-based audio service with pitch shifting support
class SoLoudAudioService {
  final SoLoud soloud;

  // Audio state
  AudioSource? _audioSource;
  SoundHandle? _soundHandle;
  Timer? _positionTimer;
  Timer? _loopTimer;

  // Stream controllers
  final StreamController<bool> _playingController = StreamController<bool>.broadcast();
  final StreamController<Duration> _positionController = StreamController<Duration>.broadcast();

  // Current state
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _duration = Duration.zero;
  double _currentPitch = 1.0; // 1.0 = original pitch
  double _currentSpeed = 1.0; // 1.0 = original speed
  DateTime? _playStartTime;
  Duration _pausedDuration = Duration.zero;

  // Loop state
  Loop? _activeLoop;
  bool _isLoopModeEnabled = false;

  // Streams
  Stream<bool> get playingStream => _playingController.stream;
  Stream<Duration> get positionStream => _positionController.stream;

  // Getters
  bool get isPlaying => _isPlaying;
  Duration get position => _currentPosition;
  Duration get duration => _duration;
  double get currentPitch => _currentPitch;
  double get currentSpeed => _currentSpeed;
  Loop? get activeLoop => _activeLoop;
  bool get isLoopModeEnabled => _isLoopModeEnabled;

  SoLoudAudioService({required this.soloud});

  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Start position tracking timer
    _positionTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _updatePosition();
    });
  }

  Future<void> loadSong(Song song) async {
    try {
      // Stop current playback if any
      await stop();

      final path = await song.path;
      dev.log('SoLoud: Loading song from path: $path');

      _audioSource = await soloud.loadFile(path);
      dev.log('SoLoud: Audio source loaded: $_audioSource');

      _duration = soloud.getLength(_audioSource!);
      dev.log('SoLoud: Loaded song ${song.title}, duration: $_duration');

      if (_audioSource == null) {
        throw Exception('Failed to load audio source');
      }
    } catch (e, stackTrace) {
      dev.log('SoLoud: Error loading song: $e');
      dev.log('SoLoud: Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> play() async {
    if (_audioSource == null) {
      dev.log('SoLoud: Cannot play - audio source is null');
      return;
    }

    try {
      // Stop any existing playback
      if (_soundHandle != null) {
        await soloud.stop(_soundHandle!);
        dev.log('SoLoud: Stopped existing playback');
      }

      // Start playback
      dev.log('SoLoud: Starting playback of audio source');
      _soundHandle = await soloud.play(_audioSource!);
      dev.log('SoLoud: Got sound handle: $_soundHandle');

      if (_soundHandle == null) {
        dev.log('SoLoud: ERROR - Sound handle is null after play!');
        return;
      }

      // Apply current pitch and speed if different from defaults
      if (_currentPitch != 1.0) {
        await _applyPitchShift(_currentPitch);
      }
      if (_currentSpeed != 1.0) {
        await _applySpeedChange(_currentSpeed);
      }

      _isPlaying = true;
      _playStartTime = DateTime.now();
      _pausedDuration = Duration.zero;
      _playingController.add(_isPlaying);

      // Start loop monitoring if needed
      if (_isLoopModeEnabled && _activeLoop != null) {
        _startLoopMonitoring();
      }

      dev.log('SoLoud: Started playback successfully');
    } catch (e, stackTrace) {
      dev.log('SoLoud: Error starting playback: $e');
      dev.log('SoLoud: Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> pause() async {
    if (_soundHandle != null) {
      soloud.setPause(_soundHandle!, true);
      _isPlaying = false;

      // Save the current position before pausing
      if (_playStartTime != null) {
        final elapsedTime = DateTime.now().difference(_playStartTime!);
        final adjustedElapsedTime = Duration(
          milliseconds: (elapsedTime.inMilliseconds * _currentSpeed).round(),
        );
        _pausedDuration = _pausedDuration + adjustedElapsedTime;
        _currentPosition = _pausedDuration;
        dev.log('SoLoud: Paused at position: $_pausedDuration');
      }

      _playingController.add(_isPlaying);
      _stopLoopMonitoring();
      dev.log('SoLoud: Paused playback');
    }
  }

  Future<void> resume() async {
    // If we don't have a sound handle yet, we need to play first
    if (_soundHandle == null) {
      dev.log('SoLoud: No sound handle, calling play() first');
      return await play();
    }

    if (_soundHandle != null) {
      soloud.setPause(_soundHandle!, false);
      _isPlaying = true;
      _playStartTime = DateTime.now(); // Reset start time for resume
      _playingController.add(_isPlaying);

      if (_isLoopModeEnabled && _activeLoop != null) {
        _startLoopMonitoring();
      }

      dev.log('SoLoud: Resumed playback from position: $_pausedDuration');
    }
  }

  Future<void> stop() async {
    if (_soundHandle != null) {
      await soloud.stop(_soundHandle!);
      _soundHandle = null;
    }

    _isPlaying = false;
    _currentPosition = Duration.zero;
    _playStartTime = null;
    _pausedDuration = Duration.zero;
    _playingController.add(_isPlaying);
    _positionController.add(_currentPosition);
    _stopLoopMonitoring();

    dev.log('SoLoud: Stopped playback');
  }

  Future<void> seek(Duration position) async {
    if (_soundHandle != null && _audioSource != null) {
      soloud.seek(_soundHandle!, position);
      _currentPosition = position;
      _pausedDuration = position; // Update paused duration to the seek position
      _playStartTime = DateTime.now(); // Reset start time
      _positionController.add(_currentPosition);
      dev.log('SoLoud: Seeked to $position');
    }
  }

  /// Set pitch in semitones (-12 to +12)
  Future<void> setPitch(int semitones) async {
    // Convert semitones to pitch multiplier
    final pitchMultiplier = pow(2.0, semitones / 12.0).toDouble();
    await setPitchMultiplier(pitchMultiplier);
  }

  /// Set pitch multiplier (1.0 = original pitch)
  Future<void> setPitchMultiplier(double pitch) async {
    _currentPitch = pitch;

    if (_soundHandle != null) {
      await _applyPitchShift(pitch);
    }

    dev.log('SoLoud: Set pitch to $pitch');
  }

  /// Set playback speed (1.0 = original speed)
  Future<void> setSpeed(double speed) async {
    _currentSpeed = speed;

    if (_soundHandle != null) {
      await _applySpeedChange(speed);
    }

    dev.log('SoLoud: Set speed to $speed');
  }

  /// Enable loop mode with the specified loop
  void enableLoopMode(Loop loop) {
    _activeLoop = loop;
    _isLoopModeEnabled = true;

    if (_isPlaying) {
      _startLoopMonitoring();
    }

    dev.log('SoLoud: Enabled loop mode: ${loop.name}');
  }

  /// Disable loop mode
  void disableLoopMode() {
    _activeLoop = null;
    _isLoopModeEnabled = false;
    _stopLoopMonitoring();

    dev.log('SoLoud: Disabled loop mode');
  }

  Future<void> _applyPitchShift(double pitch) async {
    if (_soundHandle == null) return;

    try {
      // SoLoud pitch shifting using setRelativePlaySpeed
      // Note: This affects both pitch and speed together
      // For true pitch shifting without speed change, we'd need filters
      // but SoLoud's basic API doesn't separate them easily
      soloud.setRelativePlaySpeed(_soundHandle!, pitch);
      dev.log('SoLoud: Applied pitch shift: $pitch');
    } catch (e) {
      dev.log('SoLoud: Error applying pitch shift: $e');
    }
  }

  Future<void> _applySpeedChange(double speed) async {
    if (_soundHandle == null) return;

    try {
      // For now, this will affect both pitch and speed
      // In a full implementation, we'd need to combine with pitch correction
      soloud.setRelativePlaySpeed(_soundHandle!, speed);
      dev.log('SoLoud: Applied speed change: $speed');
    } catch (e) {
      dev.log('SoLoud: Error applying speed change: $e');
    }
  }

  void _updatePosition() {
    if (_soundHandle != null && _isPlaying && _playStartTime != null) {
      // Calculate elapsed time since play started, accounting for speed changes
      final elapsedTime = DateTime.now().difference(_playStartTime!);
      final adjustedElapsedTime = Duration(
        milliseconds: (elapsedTime.inMilliseconds * _currentSpeed).round(),
      );

      // Current position = paused duration + adjusted elapsed time
      _currentPosition = _pausedDuration + adjustedElapsedTime;
      _positionController.add(_currentPosition);

      // Check if playback has ended
      if (_currentPosition >= _duration) {
        _isPlaying = false;
        _playingController.add(_isPlaying);
        _stopLoopMonitoring();
        dev.log('SoLoud: Playback completed');
      }
    }
  }

  void _startLoopMonitoring() {
    _stopLoopMonitoring(); // Stop any existing timer

    if (_activeLoop?.start == null || _activeLoop?.end == null) return;

    _loopTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!_isPlaying || _activeLoop == null) {
        _stopLoopMonitoring();
        return;
      }

      final loopEnd = _activeLoop!.end!;
      final loopStart = _activeLoop!.start!;

      if (_currentPosition >= loopEnd) {
        seek(loopStart);
        dev.log('SoLoud: Looped back to $loopStart');
      }
    });
  }

  void _stopLoopMonitoring() {
    _loopTimer?.cancel();
    _loopTimer = null;
  }

  Future<void> dispose() async {
    await stop();

    _positionTimer?.cancel();
    _loopTimer?.cancel();

    await _playingController.close();
    await _positionController.close();

    if (_audioSource != null) {
      soloud.disposeSource(_audioSource!);
    }

    dev.log('SoLoud: Audio service disposed');
  }
}
