part of 'song_cubit.dart';

@MappableClass()
class SongState with SongStateMappable {
  final double speed;
  final SongStatus status;
  final Song song;
  final Loop? activeLoop;
  final bool isLoopModeEnabled;
  final bool isTutorialCompleted;

  /// AudioPlayer
  final PlayerState? playerState;
  // final Duration? duration;

  final String? error;

  const SongState({
    this.speed = 1.0,
    this.status = SongStatus.loading,
    required this.song,
    this.error,
    this.activeLoop,
    this.isLoopModeEnabled = false,
    this.isTutorialCompleted = false,
    this.playerState,
    // this.duration,
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
}
