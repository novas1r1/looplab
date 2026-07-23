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

  /// Swaps the underlying audio file while preserving position, playing
  /// state, speed and pitch. Used by the baked-click-track metronome to
  /// switch between the original song and the song+click mix mid-session.
  /// Video handlers may throw [UnsupportedError] — the cubit only routes
  /// audio songs here.
  Future<void> swapSourceFile(String path);

  /// Applies a pitch shift in semitones (-12..+12), independent of speed.
  /// Returns false if the platform rejected the change (the caller should
  /// revert its state from [currentPitchSemitones]).
  Future<bool> setPitchSemitones(int semitones);

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

  /// Emits the target position after every position discontinuity — user
  /// seeks, skip/restart actions and native loop wraps (which never surface
  /// anywhere else). The metronome realigns its click grid from this single
  /// signal, so every handler-internal seek must be reported here.
  Stream<Duration> get seekEvents;

  Future<Duration> get position;

  /// Loop navigation events (e.g. from notification skip buttons). Video
  /// handlers may emit only previousLoop/nextLoop; the audio handler also
  /// surfaces restartCurrentLoop double-tap behavior.
  Stream<LoopNavigationEvent> get navigationEvents;

  double get currentPlaybackSpeed;

  /// Currently applied pitch shift in semitones (0 = original pitch).
  int get currentPitchSemitones;

  Future<void> close();
}
