import 'dart:async';
import 'dart:developer' as dev;

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/services/soloud_audio_service.dart';

/// AudioHandler implementation for SoLoud with pitch shifting support
class SoLoudAudioServiceHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final SoLoud soloud;
  late final SoLoudAudioService _audioService;

  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<Duration>? _positionSubscription;

  SoLoudAudioServiceHandler({required this.soloud}) {
    dev.log('SoLoudAudioServiceHandler constructor');
    _audioService = SoLoudAudioService(soloud: soloud);
    _initAudioSession();
    _setupSubscriptions();
  }

  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    await _audioService.init();
    dev.log('AudioSession initialized: ${session.isConfigured}');
  }

  void _setupSubscriptions() {
    _playingSubscription = _audioService.playingStream.listen((isPlaying) {
      playbackState.add(
        playbackState.value.copyWith(
          controls: isPlaying
              ? [MediaControl.pause, MediaControl.stop]
              : [MediaControl.play, MediaControl.stop],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          playing: isPlaying,
          processingState: isPlaying ? AudioProcessingState.ready : AudioProcessingState.ready,
        ),
      );
    });

    _positionSubscription = _audioService.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(updatePosition: position));
    });
  }

  /// Play a song from a file path
  Future<void> playSong(Song song) async {
    try {
      // Create a MediaItem for the song
      final item = MediaItem(
        id: song.id,
        title: song.title,
        artist: song.artist,
        duration: song.duration,
      );

      mediaItem.add(item);

      // Load the song (but don't play yet - wait for user to press play)
      await _audioService.loadSong(song);

      playbackState.add(
        playbackState.value.copyWith(
          controls: const [MediaControl.play, MediaControl.stop],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          playing: false,
          processingState: AudioProcessingState.ready,
        ),
      );

      dev.log('SoLoud: Song loaded and ready: ${song.title}');
    } catch (e) {
      playbackState.add(
        playbackState.value.copyWith(
          processingState: AudioProcessingState.error,
        ),
      );
      dev.log('SoLoud: Error playing song: $e');
      rethrow;
    }
  }

  @override
  Future<void> play() async {
    await _audioService.play();
  }

  Future<void> resume() async {
    await _audioService.resume();
  }

  @override
  Future<void> pause() async {
    await _audioService.pause();
  }

  @override
  Future<void> stop() async {
    await _audioService.stop();
    playbackState.add(
      playbackState.value.copyWith(
        controls: const [MediaControl.play],
        playing: false,
        processingState: AudioProcessingState.idle,
      ),
    );
  }

  @override
  Future<void> seek(Duration position) async {
    await _audioService.seek(position);
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _audioService.setSpeed(speed);
  }

  /// Get current position
  Future<Duration> get position async => _audioService.position;

  /// Get position stream
  Stream<Duration>? get positionStream => _audioService.positionStream;

  /// Get player state stream (converted from playing stream)
  Stream<bool>? get playerStateStream => _audioService.playingStream;

  /// Skip forward by specified seconds
  Future<void> forward(int seconds, Loop? activeLoop) async {
    final currentPos = _audioService.position;
    var newPos = currentPos + Duration(seconds: seconds);

    // If in loop mode, don't go beyond loop end
    if (activeLoop?.end != null && newPos > activeLoop!.end!) {
      newPos = activeLoop.end!;
    }

    await seek(newPos);
  }

  /// Skip backward by specified seconds
  Future<void> back(int seconds, Loop? activeLoop) async {
    final currentPos = _audioService.position;
    var newPos = currentPos - Duration(seconds: seconds);

    // If in loop mode, don't go before loop start
    if (activeLoop?.start != null && newPos < activeLoop!.start!) {
      newPos = activeLoop.start!;
    } else if (newPos < Duration.zero) {
      newPos = Duration.zero;
    }

    await seek(newPos);
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'enableLoop':
        if (extras != null && extras['loop'] != null) {
          final loop = extras['loop'] as Loop;
          _audioService.enableLoopMode(loop);
        }
      case 'disableLoop':
        _audioService.disableLoopMode();
      case 'setPitch':
        if (extras != null && extras['pitch'] != null) {
          final pitch = extras['pitch'] as double;
          await _audioService.setPitchMultiplier(pitch);
          dev.log('SoLoud: Pitch set to $pitch');
        }
      case 'setPitchSemitones':
        if (extras != null && extras['semitones'] != null) {
          final semitones = extras['semitones'] as int;
          await _audioService.setPitch(semitones);
          dev.log('SoLoud: Pitch set to $semitones semitones');
        }
      default:
        super.customAction(name, extras);
    }
  }

  @override
  Future<void> onTaskRemoved() async {
    // Keep playing when the app is removed from the recent apps list
    dev.log('SoLoud: Task removed, continuing playback');
  }

  Future<void> dispose() async {
    await _playingSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _audioService.dispose();
    dev.log('SoLoud: Audio service handler disposed');
  }
}
