part of 'song_cubit.dart';

/// Tempo control mode - either speed multiplier (0.5x-2.0x) or BPM-based
@MappableEnum()
enum TempoMode { multiplier, bpm }

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
}
