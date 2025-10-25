import 'dart:async';
import 'dart:developer';

import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart' show PlayerState;
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:meta/meta.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/services/repeatlab_audio_handler.dart';

/// AudioHandler implementation backed by just_audio.
class RepeatlabJustAudioServiceHandler extends RepeatlabAudioHandler {
  RepeatlabJustAudioServiceHandler({required this.audioPlayer}) {
    _initAudioSession();
    _listenToPlayerState();
    _listenToPositionChanges();
    _listenToDurationChanges();
  }

  final ja.AudioPlayer audioPlayer;

  Loop? _activeLoop;
  StreamSubscription<ja.PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<Duration>? _loopPositionSubscription;
  Stream<PlayerState>? _playerStateBroadcast;
  Stream<Duration>? _positionBroadcast;

  ja.AudioSource? _currentSource;
  double _playbackSpeed = 1.0;
  double _pitch = 1.0;
  bool _loopSeekInProgress = false;
  bool _pluginAvailable = true;

  @override
  Future<Duration> get position async => audioPlayer.position;

  @override
  Stream<PlayerState>? get playerStateStream => _playerStateBroadcast;

  @override
  Stream<Duration>? get positionStream => _positionBroadcast;

  @override
  bool get supportsPitch {
    if (!_pluginAvailable) return false;
    if (kIsWeb) return true;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return true;
      default:
        return false;
    }
  }

  @override
  bool get usesJustAudio => true;

  Future<void> _initAudioSession() async {
    await _guardPluginCall(() async {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      log('AudioSession initialized: ${session.isConfigured}');
    }, fallbackOnMissingPlugin: false);
  }

  void _listenToPlayerState() {
    _playerStateBroadcast = audioPlayer.playerStateStream.map(_mapPlayerState).asBroadcastStream();

    _playerStateSubscription = audioPlayer.playerStateStream.listen((playerState) {
      final playing = playerState.playing;
      final processingState = switch (playerState.processingState) {
        ja.ProcessingState.idle => AudioProcessingState.idle,
        ja.ProcessingState.loading => AudioProcessingState.loading,
        ja.ProcessingState.buffering => AudioProcessingState.buffering,
        ja.ProcessingState.ready => AudioProcessingState.ready,
        ja.ProcessingState.completed => AudioProcessingState.completed,
      };

      playbackState.add(
        playbackState.value.copyWith(
          controls: playing
              ? const [MediaControl.pause, MediaControl.stop]
              : const [MediaControl.play],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekBackward,
            MediaAction.seekForward,
          },
          processingState: processingState,
          playing: playing,
        ),
      );
    });
  }

  void _listenToPositionChanges() {
    _positionBroadcast = audioPlayer.positionStream.asBroadcastStream();
    _positionSubscription = _positionBroadcast?.listen((position) {
      playbackState.add(playbackState.value.copyWith(updatePosition: position));
    });
  }

  void _listenToDurationChanges() {
    _durationSubscription = audioPlayer.durationStream.listen((duration) {
      if (duration == null) return;
      final current = mediaItem.value;
      if (current != null) {
        mediaItem.add(current.copyWith(duration: duration));
      }
    });
  }

  @override
  Future<void> playSong(Song song) async {
    final path = await song.path;

    final item = MediaItem(
      id: song.id,
      title: song.title,
      artist: song.artist,
      duration: song.duration,
    );
    mediaItem.add(item);

    final source = ja.AudioSource.uri(Uri.file(path));
    _currentSource = source;

    try {
      await _guardPluginCall(() => audioPlayer.setLoopMode(ja.LoopMode.off));
      await _guardPluginCall(() => audioPlayer.setAudioSource(source));
      await _guardPluginCall(() => audioPlayer.setSpeed(_playbackSpeed));
      if (supportsPitch) {
        await _guardPluginCall(() => audioPlayer.setPitch(_pitch));
      }
      playbackState.add(
        playbackState.value.copyWith(
          controls: const [MediaControl.play],
          systemActions: const {
            MediaAction.seek,
            MediaAction.seekForward,
            MediaAction.seekBackward,
          },
          playing: false,
          processingState: AudioProcessingState.ready,
        ),
      );
    } catch (error, stackTrace) {
      log('Failed to play song with just_audio: $error', stackTrace: stackTrace);
      playbackState.add(
        playbackState.value.copyWith(processingState: AudioProcessingState.error),
      );
      rethrow;
    }
  }

  @override
  Future<void> resume() async {
    await _ensureWithinLoopBounds();
    await _guardPluginCall(() => audioPlayer.play());
  }

  @override
  Future<void> enableLoopMode(Loop loop) async {
    await _loopPositionSubscription?.cancel();
    _activeLoop = loop;

    final start = loop.start;
    final end = loop.end;
    if (start == null || end == null) return;

    _loopPositionSubscription = audioPlayer.positionStream.listen(_handleLoopPositionUpdate);
    await _ensureWithinLoopBounds();
  }

  @override
  Future<void> disableLoopMode() async {
    await _loopPositionSubscription?.cancel();
    _loopPositionSubscription = null;
    _activeLoop = null;
    _loopSeekInProgress = false;
  }

  @override
  Future<void> play() async {
    await resume();
  }

  @override
  Future<void> pause() async {
    await _guardPluginCall(() => audioPlayer.pause());
  }

  @override
  Future<void> stop() async {
    await _guardPluginCall(() => audioPlayer.stop());
  }

  @override
  Future<void> seek(Duration position) async {
    await _reloadSourceIfNeeded();
    await _guardPluginCall(() => audioPlayer.seek(position));
  }

  @override
  Future<void> setSpeed(double speed) async {
    _playbackSpeed = speed;
    await _guardPluginCall(() => audioPlayer.setSpeed(speed));
  }

  @override
  Future<void> setPitch(double pitch) async {
    if (!supportsPitch) {
      throw UnsupportedError('Pitch shifting is not supported on this platform.');
    }

    _pitch = pitch;
    await _guardPluginCall(() => audioPlayer.setPitch(pitch));
  }

  @override
  Future<void> forward(int seconds, Loop? loop) async {
    final current = audioPlayer.position;
    final duration = audioPlayer.duration ?? Duration.zero;

    if (current >= duration) return;

    var target = current + Duration(seconds: seconds);
    if (loop?.end != null && target > loop!.end!) {
      target = loop.end!;
    } else if (target > duration) {
      target = duration;
    }

    await seek(target);
  }

  @override
  Future<void> back(int seconds, Loop? loop) async {
    final current = audioPlayer.position;
    var target = current - Duration(seconds: seconds);

    if (target < Duration.zero) {
      target = Duration.zero;
    }

    if (loop?.start != null && target < loop!.start!) {
      target = loop.start!;
    }

    await seek(target);
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    switch (name) {
      case 'enableLoop':
        final loop = extras?['loop'] as Loop?;
        if (loop != null) {
          await enableLoopMode(loop);
        }
        return;
      case 'disableLoop':
        await pause();
        await disableLoopMode();
        return;
      case 'setPitch':
        final pitch = (extras?['pitch'] as num?)?.toDouble();
        if (pitch != null) {
          await setPitch(pitch);
        }
        return;
      default:
        return super.customAction(name, extras);
    }
  }

  Future<void> _handleLoopPositionUpdate(Duration position) async {
    final loop = _activeLoop;
    if (loop == null) return;

    final start = loop.start;
    final end = loop.end;
    if (start == null || end == null) return;

    if (position >= end) {
      if (_loopSeekInProgress) return;

      _loopSeekInProgress = true;
      await seek(start);
      _loopSeekInProgress = false;
    }
  }

  Future<void> _ensureWithinLoopBounds() async {
    final loop = _activeLoop;
    if (loop == null) return;

    final start = loop.start;
    final end = loop.end;
    if (start == null || end == null) return;

    final current = audioPlayer.position;
    if (current >= end || current < start) {
    await seek(start);
  }
  }

  Future<void> _reloadSourceIfNeeded() async {
    final source = _currentSource;
    if (source == null) return;

    final processingState = audioPlayer.processingState;
    if (processingState == ja.ProcessingState.completed || processingState == ja.ProcessingState.idle) {
      await _guardPluginCall(() => audioPlayer.setAudioSource(source));
      await _guardPluginCall(() => audioPlayer.setSpeed(_playbackSpeed));
      if (supportsPitch) {
        await _guardPluginCall(() => audioPlayer.setPitch(_pitch));
      }
    }
  }

  Future<void> close() async {
    await disableLoopMode();
    await _playerStateSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();
    await _guardPluginCall(() => audioPlayer.dispose());
  }

  @override
  Future<void> onTaskRemoved() async {
    // Keep playing when removed from recents; no-op for just_audio.
    return;
  }

  @visibleForTesting
  void debugSetCurrentSource(ja.AudioSource source) {
    _currentSource = source;
  }

  PlayerState _mapPlayerState(ja.PlayerState state) {
    if (state.playing) {
      return PlayerState.playing;
    }

    switch (state.processingState) {
      case ja.ProcessingState.completed:
        return PlayerState.completed;
      case ja.ProcessingState.idle:
        return PlayerState.stopped;
      default:
        return PlayerState.paused;
    }
  }

  Future<T> _guardPluginCall<T>(Future<T> Function() action, {bool fallbackOnMissingPlugin = true}) async {
    try {
      return await action();
    } on MissingPluginException catch (error, stackTrace) {
      _pluginAvailable = false;
      log('just_audio plugin call failed: $error', stackTrace: stackTrace);
      if (fallbackOnMissingPlugin) {
        throw UnsupportedError('just_audio plugin is not available on this platform.');
      }
      rethrow;
    }
  }
}
