import 'dart:async';

import 'package:audioplayers/audioplayers.dart' show PlayerState;
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/services/loop_navigation_event.dart';

/// Common contract for playback handlers used by [SongCubit].
///
/// Implemented by:
///   * [RepeatlabAudioplayersServiceHandler] — audio (audioplayers + audio_service
///     for background playback / notifications).
///   * [VideoPlayerHandler] — video (media_kit / libmpv, no background).
///
/// The cubit and shared widgets talk to handlers only through this interface,
/// using `audioplayers.PlayerState` as the lingua franca for playback state.
abstract class MediaPlayerHandler {
  /// Open [song] and (optionally) start playback. Resets internal speed to 1.0
  /// so opening a new song behaves consistently.
  Future<void> playSong(Song song, {bool autoStart = true});

  Future<void> play();
  Future<void> pause();
  Future<void> stop();
  Future<void> resume();

  Future<void> seek(Duration position);
  Future<bool> setSpeed(double speed);

  Future<void> forward(int seconds, Loop? loop);
  Future<void> back(int seconds, Loop? loop);

  Future<void> skipToPrevious();
  Future<void> skipToNext();

  /// Generic command dispatcher (mirrors `BaseAudioHandler.customAction`).
  /// Supported actions: `enableLoop`, `disableLoop`, `setLoops`,
  /// `setFullSongRepeat`, `setPitch`.
  Future<dynamic> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]);

  /// Bridged `audioplayers.PlayerState` so the cubit + widgets stay unchanged.
  /// Nullable to match the audio handler's existing surface.
  Stream<PlayerState>? get playerStateStream;

  /// Position updates. Nullable to match the audio handler's existing surface.
  Stream<Duration>? get positionStream;

  Future<Duration> get position;

  /// Loop navigation events (e.g. from notification skip buttons). Video
  /// handlers may emit only previousLoop/nextLoop; the audio handler also
  /// surfaces restartCurrentLoop double-tap behavior.
  Stream<LoopNavigationEvent> get navigationEvents;

  double get currentPlaybackSpeed;

  Future<void> close();
}
