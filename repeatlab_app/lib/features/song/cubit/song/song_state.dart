part of 'song_cubit.dart';

/// Tempo control mode - either speed multiplier (0.5x-2.0x) or BPM-based
@MappableEnum()
enum TempoMode { multiplier, bpm }

/// Pitch control mode - either raw semitones or musical-key based
/// (mirrors [TempoMode]'s multiplier/BPM split)
@MappableEnum()
enum PitchMode { semitones, key }

/// Why the metronome click grid is being (re)aligned. Every playback event
/// that could move the beat grid routes through
/// `SongCubit._realignMetronome` with one of these reasons, so future
/// beat-grid sync only needs changes in that one switch. `seeked` and
/// `loopJumped` are no-ops in v1 (free-run); note that native loop wraps
/// never reach the cubit today — grid sync will need a handler-side stream.
enum MetronomeRealignReason { playStarted, seeked, loopJumped, tempoChanged }

/// Metronome subdivision — how each audible beat is split into pulses.
/// [pulsesPerBeat] is what the native engine consumes (via SongMetronome).
@MappableEnum()
enum MetronomeSubdivision {
  none(1),
  eighths(2),
  triplets(3),
  sixteenths(4);

  const MetronomeSubdivision(this.pulsesPerBeat);

  final int pulsesPerBeat;
}

@MappableClass()
class SongState with SongStateMappable {
  final double speed;
  final SongStatus status;
  final Song song;
  final Loop? activeLoop;
  final bool isLoopModeEnabled;
  final bool isTutorialCompleted;
  final bool isFullSongRepeatEnabled;
  final bool isAutoPlayEnabled;

  /// AudioPlayer
  final PlayerState? playerState;

  final String? error;

  /// Speed control fields
  final TempoMode tempoMode;

  /// Original BPM of the song (set by user, null if not set)
  final int? originalBpm;

  /// Current BPM (derived from speed * originalBpm when originalBpm is set)
  final int? currentBpm;

  /// Minimum BPM (originalBpm * 0.5, null if originalBpm not set)
  final int? minBpm;

  /// Maximum BPM (originalBpm * 2.0, null if originalBpm not set)
  final int? maxBpm;

  /// Pitch shift in semitones (-12..+12), 0 = original pitch. Restored from
  /// [Song.pitchSemitones] on song open.
  final int pitchSemitones;

  /// Pitch control mode (semitones or key-based)
  final PitchMode pitchMode;

  /// Whether the metronome clicks along while the song plays. Not persisted —
  /// off on every song open (mirrors speed resetting to 1.0) so users never
  /// get surprise clicks. Per-song offset/time signature live on [song].
  final bool isMetronomeEnabled;

  /// Metronome output volume (0.0..1.0). Global preference, seeded from
  /// LocalConfigRepository on song open.
  final double metronomeVolume;

  /// Metronome subdivision. Global preference, seeded from
  /// LocalConfigRepository on song open.
  final MetronomeSubdivision metronomeSubdivision;

  const SongState({
    this.speed = 1.0,
    this.status = SongStatus.loading,
    required this.song,
    this.error,
    this.activeLoop,
    this.isLoopModeEnabled = false,
    this.isTutorialCompleted = false,
    this.isFullSongRepeatEnabled = false,
    this.isAutoPlayEnabled = true,
    this.playerState,
    this.tempoMode = TempoMode.multiplier,
    this.originalBpm,
    this.currentBpm,
    this.minBpm,
    this.maxBpm,
    this.pitchSemitones = 0,
    this.pitchMode = PitchMode.semitones,
    this.isMetronomeEnabled = false,
    this.metronomeVolume = 0.5,
    this.metronomeSubdivision = MetronomeSubdivision.none,
  });
}

@MappableEnum()
enum SongStatus {
  loading,
  loadSuccess,
  loadError,
  error,
  loopAdded,
  loopDeleted,
  loopModeToggled,
  updated,
  updating,
  songDeleted,
  speedChangeFailed,
  pitchChangeFailed,
}
