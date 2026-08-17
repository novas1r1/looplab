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

  /// Configures the native in-pipeline metronome click track (clicks
  /// synthesized inside the playback pipeline on the media-time beat grid,
  /// sample-locked across seeks/loops/speed changes). Android and iOS audio
  /// only — other handlers/platforms throw [UnsupportedError]; the cubit
  /// gates callers accordingly. Pass `enabled: false` to silence the clicks.
  Future<void> setNativeClickTrack({
    required bool enabled,
    int? bpm,
    int? anchorMs,
    int offsetMs,
    int beatsPerBar,
    int pulsesPerBeat,
    double volume,
  });

  /// Applies a total pitch offset in cents (-1250..+1250, i.e. ±12 semitones
  /// plus ±50 cents of fine tune), independent of speed. Callers keep the
  /// semitone/cents split for the UI and combine it here, because the DSP
  /// stage only ever needs one ratio: `2^(totalCents / 1200)`.
  /// Returns false if the platform rejected the change; the caller should
  /// revert to the values it held before the call rather than reading back
  /// from [currentPitchCents], which cannot be split unambiguously.
  Future<bool> setPitchCents(int totalCents);

  Future<void> forward(int seconds, Loop? loop);
  Future<void> back(int seconds, Loop? loop);

  Future<void> skipToPrevious();
  Future<void> skipToNext();

  /// Generic command dispatcher (mirrors `BaseAudioHandler.customAction`).
  /// Supported actions: `enableLoop`, `disableLoop`, `setLoops`,
  /// `setFullSongRepeat`.
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

  /// Currently applied total pitch offset in cents (0 = original pitch).
  int get currentPitchCents;

  Future<void> close();
}
