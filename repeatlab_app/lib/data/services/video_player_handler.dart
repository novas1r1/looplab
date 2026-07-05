// ignore_for_file: use_setters_to_change_properties

import 'dart:async';
import 'dart:developer';
import 'dart:math' show pow;

import 'package:audioplayers/audioplayers.dart' show PlayerState;
import 'package:flutter/foundation.dart';
// media_kit also exports a `PlayerState` type; hide it so `PlayerState` in
// this file unambiguously refers to the audioplayers enum we use as the
// lingua franca across handlers + cubit + widgets.
import 'package:media_kit/media_kit.dart' hide PlayerState;
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/services/loop_navigation_event.dart';
import 'package:repeatlab/data/services/media_player_handler.dart';

/// Media handler for video playback (mp4, mov, mkv, webm, avi, …).
///
/// Mirrors the public surface of [RepeatlabAudioplayersServiceHandler] that
/// [SongCubit] talks to, so the shared widgets, [SongState] shape, and cubit
/// logic can be reused without changes. Internally it drives a [media_kit]
/// [Player]; externally it speaks the `audioplayers.PlayerState` enum that
/// the rest of the app uses as a lingua franca.
///
/// Unlike the audio handler, this class does NOT extend `BaseAudioHandler` —
/// video playback intentionally has no `audio_service` background notification
/// integration. Video pauses when the app is backgrounded; that's enforced by
/// the [VideoSongView] lifecycle observer.
class VideoPlayerHandler implements MediaPlayerHandler {
  final Player player;

  static const double _minPlaybackSpeed = 0.5;
  static const double _maxPlaybackSpeed = 2.0;

  static const int _minPitchSemitones = -12;
  static const int _maxPitchSemitones = 12;

  /// Double-tap detection threshold for skip previous, mirroring the audio
  /// handler's behavior.
  static const Duration _doubleTapThreshold = Duration(milliseconds: 400);

  Loop? _activeLoop;
  List<Loop> _loops = [];
  int _currentLoopIndex = -1;
  bool _fullSongRepeatEnabled = false;

  double _playbackSpeed = 1.0;
  int _pitchSemitones = 0;
  bool _loopSeekInProgress = false;

  DateTime? _lastSkipPreviousTime;

  final _navigationEventController =
      StreamController<LoopNavigationEvent>.broadcast();
  @override
  Stream<LoopNavigationEvent> get navigationEvents =>
      _navigationEventController.stream;

  /// Bridged `audioplayers.PlayerState` so the cubit and widgets keep working
  /// unchanged. Backed by [_playerStateController].
  final _playerStateController = StreamController<PlayerState>.broadcast();
  @override
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;

  /// Position stream — surfaced directly from media_kit.
  @override
  Stream<Duration> get positionStream => player.stream.position;

  @override
  Future<Duration> get position async => player.state.position;

  /// Current internal playback speed (mirrors the audio handler API).
  @override
  double get currentPlaybackSpeed => _playbackSpeed;

  /// Currently applied pitch shift in semitones (mirrors the audio handler).
  @override
  int get currentPitchSemitones => _pitchSemitones;

  bool get isFullSongRepeatEnabled => _fullSongRepeatEnabled;

  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<bool>? _completedSubscription;
  StreamSubscription<Duration>? _loopPositionSubscription;
  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<PlayerLog>? _logSubscription;

  /// Tracks the last emitted bridged state, so we don't double-emit
  /// `paused`/`playing` when buffering toggles.
  PlayerState? _lastEmittedState;

  VideoPlayerHandler({Player? player})
    : player =
          player ??
          Player(
            // Verbose libmpv logs in debug builds surface file-open / decoder /
            // audio-device failures that would otherwise be silent. Release
            // builds use `error` to keep logs and Sentry breadcrumbs quiet.
            // pitch: true enables Player.setPitch (libmpv scaletempo);
            // without it media_kit throws on every setPitch call.
            configuration: const PlayerConfiguration(
              logLevel: kDebugMode ? MPVLogLevel.debug : MPVLogLevel.error,
              pitch: true,
            ),
          ) {
    log('VideoPlayerHandler constructor');

    // libmpv reports load/decode failures asynchronously on these streams —
    // NOT as exceptions from open()/play(). Without these listeners an iOS
    // failure (e.g. "cannot open file://…" or "no decoder for hevc") is
    // completely invisible: the screen just stays black with nothing playing.
    _errorSubscription = this.player.stream.error.listen((error) {
      log('VideoPlayerHandler mpv ERROR: $error');
    });
    _logSubscription = this.player.stream.log.listen((entry) {
      log(
        'VideoPlayerHandler mpv[${entry.level}] ${entry.prefix}: ${entry.text}',
      );
    });

    _playingSubscription = this.player.stream.playing.listen((playing) {
      final next = playing ? PlayerState.playing : PlayerState.paused;
      _emitPlayerState(next);
    });

    _completedSubscription = this.player.stream.completed.listen((completed) {
      if (!completed) return;

      // Loop active → restart from loop start.
      if (_activeLoop != null &&
          _activeLoop!.start != null &&
          _activeLoop!.end != null) {
        _handleLoopCompletionRestart();
        return;
      }

      // Full-song repeat → restart from zero.
      if (_fullSongRepeatEnabled && _activeLoop == null) {
        _handleFullSongRepeat();
        return;
      }

      _emitPlayerState(PlayerState.completed);
    });
  }

  void _emitPlayerState(PlayerState state) {
    if (_lastEmittedState == state) return;
    _lastEmittedState = state;
    _playerStateController.add(state);
  }

  /// Open a video song and (optionally) start playback.
  @override
  Future<void> playSong(Song song, {bool autoStart = true}) async {
    final path = await song.path;
    _playbackSpeed = 1.0;
    _pitchSemitones = 0;

    // iOS's bundled libmpv won't reliably open a bare POSIX path like
    // /var/mobile/.../Documents/foo.mp4 (Android's tolerates it). Hand it a
    // proper file:// URI, which is the cross-platform-safe form.
    final mediaUri = Uri.file(path).toString();

    log('VideoPlayerHandler.playSong uri=$mediaUri autoStart=$autoStart');

    try {
      // media_kit on Windows has a quirk where `open(media, play: false)`
      // doesn't fully initialize libmpv's playback state — a subsequent
      // `play()` may then silently no-op. Workaround: always open with
      // play=true, then immediately pause if the caller didn't want autoStart.
      // This forces a full media load and leaves the player cleanly paused.
      await player.open(Media(mediaUri));
      if (!autoStart) {
        await player.pause();
      }
      await player.setRate(_playbackSpeed);
    } catch (e, stack) {
      log('VideoPlayerHandler.playSong failed: $e\n$stack');
      _emitPlayerState(PlayerState.stopped);
      rethrow;
    }

    // Reset pitch separately and non-fatally: opening a video must never
    // fail because pitch is unsupported on some platform/build.
    try {
      await player.setPitch(1);
    } catch (e) {
      log('VideoPlayerHandler.playSong: pitch reset failed (ignored): $e');
    }
  }

  @override
  Future<void> play() async {
    log('VideoPlayerHandler.play');
    await player.play();
  }

  @override
  Future<void> pause() async {
    log('VideoPlayerHandler.pause');
    await player.pause();
  }

  @override
  Future<void> stop() async {
    log('VideoPlayerHandler.stop');
    await player.stop();
    _emitPlayerState(PlayerState.stopped);
  }

  /// Resume playback respecting active loop bounds.
  @override
  Future<void> resume() async {
    log(
      'VideoPlayerHandler.resume activeLoop=$_activeLoop '
      'position=${player.state.position}',
    );
    final loop = _activeLoop;
    if (loop != null && loop.start != null && loop.end != null) {
      final pos = player.state.position;
      if (pos >= loop.end! || pos < loop.start!) {
        await player.seek(loop.start!);
      }
    }
    await player.play();
  }

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<bool> setSpeed(double speed) async {
    final target = _normalizePlaybackSpeed(speed);
    try {
      await player.setRate(target);
      _playbackSpeed = target;
      return true;
    } catch (e) {
      log('VideoPlayerHandler.setSpeed failed: $e');
      return false;
    }
  }

  @override
  Future<bool> setPitchSemitones(int semitones) async {
    final target = semitones.clamp(_minPitchSemitones, _maxPitchSemitones);
    try {
      await player.setPitch(pow(2.0, target / 12.0).toDouble());
      _pitchSemitones = target;
      return true;
    } catch (e) {
      log('VideoPlayerHandler.setPitchSemitones failed: $e');
      return false;
    }
  }

  /// Enable loop mode with the given loop. media_kit's position stream cadence
  /// (50–250 ms on most platforms) is sufficient since we don't need
  /// background-mode resilience here — no `Timer.periodic` fallback.
  Future<void> enableLoopMode(Loop loop) async {
    await _loopPositionSubscription?.cancel();
    _loopPositionSubscription = null;
    _activeLoop = loop;
    _currentLoopIndex = _loops.indexWhere((l) => l.id == loop.id);

    final start = loop.start;
    final end = loop.end;
    if (start == null || end == null) return;

    _loopPositionSubscription = player.stream.position.listen(
      _handleLoopPositionUpdate,
    );

    await _ensureWithinLoopBounds(loop);
  }

  Future<void> disableLoopMode() async {
    await _loopPositionSubscription?.cancel();
    _loopPositionSubscription = null;
    _activeLoop = null;
    _currentLoopIndex = -1;
    _loopSeekInProgress = false;
  }

  @override
  Future<void> skipToPrevious() async {
    log(
      'VideoPlayerHandler.skipToPrevious '
      'currentLoopIndex=$_currentLoopIndex loops=${_loops.length}',
    );

    final now = DateTime.now();
    final isDoubleTap =
        _lastSkipPreviousTime != null &&
        now.difference(_lastSkipPreviousTime!) < _doubleTapThreshold;
    _lastSkipPreviousTime = now;

    if (isDoubleTap && _loops.length > 1) {
      _navigationEventController.add(LoopNavigationEvent.previousLoop);
    } else {
      await _restartCurrentPlayback();
    }
  }

  @override
  Future<void> skipToNext() async {
    log('VideoPlayerHandler.skipToNext');

    if (_loops.isEmpty) {
      await seek(Duration.zero);
    } else {
      _navigationEventController.add(LoopNavigationEvent.nextLoop);
    }
  }

  Future<void> _restartCurrentPlayback() async {
    if (_activeLoop != null && _activeLoop!.start != null) {
      await seek(_activeLoop!.start!);
    } else {
      await seek(Duration.zero);
    }
  }

  void setLoops(List<Loop> loops) {
    _loops = loops;
    if (_activeLoop != null) {
      _currentLoopIndex = _loops.indexWhere((l) => l.id == _activeLoop!.id);
    }
  }

  void setCurrentLoopIndex(int index) {
    _currentLoopIndex = index;
  }

  void setFullSongRepeatEnabled(bool enabled) {
    _fullSongRepeatEnabled = enabled;
    // Mirror to media_kit's native playlist-loop mode so single-track repeat
    // works automatically when no per-loop bounds are active.
    player.setPlaylistMode(enabled ? PlaylistMode.single : PlaylistMode.none);
    log('VideoPlayerHandler full song repeat: $enabled');
  }

  /// Forward by [seconds], clamped to song duration or active loop end.
  @override
  Future<void> forward(int seconds, Loop? loop) async {
    final position = player.state.position;
    final duration = player.state.duration;

    if (duration > Duration.zero && position >= duration) return;

    var target = position + Duration(seconds: seconds);

    if (loop != null && loop.end != null) {
      if (target > loop.end!) target = loop.end!;
    } else if (duration > Duration.zero && target > duration) {
      target = duration;
    }

    await player.seek(target);
  }

  /// Rewind by [seconds], clamped to zero or active loop start.
  @override
  Future<void> back(int seconds, Loop? loop) async {
    final position = player.state.position;
    var target = position - Duration(seconds: seconds);

    if (target < Duration.zero) target = Duration.zero;
    if (loop != null && loop.start != null && target < loop.start!) {
      target = loop.start!;
    }

    await player.seek(target);
  }

  /// Mirror the audio handler's `customAction` dispatcher so [SongCubit]'s
  /// `customAction(...)` calls work transparently for video without changing
  /// the cubit. The video subclass overrides where needed, but this lets the
  /// base-class code paths (`setLoops`, `enableLoop`, `disableLoop`, etc.)
  /// keep functioning if they ever reach here.
  @override
  Future<dynamic> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {
    switch (name) {
      case 'enableLoop':
        final loop = extras?['loop'] as Loop?;
        if (loop != null) await enableLoopMode(loop);
        return;
      case 'disableLoop':
        await pause();
        await disableLoopMode();
        return;
      case 'setPitch':
        final semitones = extras?['semitones'] as int?;
        if (semitones != null) {
          await setPitchSemitones(semitones);
        }
        return;
      case 'setLoops':
        final loops = extras?['loops'] as List<Loop>?;
        if (loops != null) setLoops(loops);
        return;
      case 'setFullSongRepeat':
        final enabled = extras?['enabled'] as bool?;
        if (enabled != null) setFullSongRepeatEnabled(enabled);
        return;
      default:
        return;
    }
  }

  @override
  Future<void> close() async {
    await _playingSubscription?.cancel();
    await _completedSubscription?.cancel();
    await _loopPositionSubscription?.cancel();
    await _errorSubscription?.cancel();
    await _logSubscription?.cancel();
    await _navigationEventController.close();
    await _playerStateController.close();
    await player.dispose();
    _loops = [];
    _currentLoopIndex = -1;
  }

  void _handleLoopPositionUpdate(Duration position) {
    final loop = _activeLoop;
    if (loop == null) return;

    final start = loop.start;
    final end = loop.end;
    if (start == null || end == null) return;

    if (position >= end) {
      if (_loopSeekInProgress) return;
      _loopSeekInProgress = true;
      seek(start).whenComplete(() {
        _loopSeekInProgress = false;
      });
    }
  }

  Future<void> _handleLoopCompletionRestart() async {
    final loop = _activeLoop;
    if (loop == null || loop.start == null) return;
    if (_loopSeekInProgress) return;

    _loopSeekInProgress = true;
    try {
      await seek(loop.start!);
      await player.play();
    } finally {
      _loopSeekInProgress = false;
    }
  }

  Future<void> _handleFullSongRepeat() async {
    log('VideoPlayerHandler: handling full song repeat');
    if (_loopSeekInProgress) return;
    _loopSeekInProgress = true;
    try {
      await seek(Duration.zero);
      await player.play();
    } catch (e) {
      log('VideoPlayerHandler full-song-repeat failed: $e');
    } finally {
      _loopSeekInProgress = false;
    }
  }

  Future<void> _ensureWithinLoopBounds(Loop loop) async {
    final start = loop.start;
    final end = loop.end;
    if (start == null || end == null) return;

    final pos = player.state.position;
    if (pos >= end || pos < start) {
      await seek(start);
    }
  }

  double _normalizePlaybackSpeed(double speed) {
    if (!speed.isFinite || speed <= 0) return 1.0;
    if (speed < _minPlaybackSpeed) return _minPlaybackSpeed;
    if (speed > _maxPlaybackSpeed) return _maxPlaybackSpeed;
    return speed;
  }
}
