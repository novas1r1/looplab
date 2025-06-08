part of 'song_cubit.dart';

@MappableClass()
class SongState with SongStateMappable {
  final double speed;
  final SongStatus status;
  final Song song;
  final Loop? activeLoop;
  final Float32List? data;
  final bool isLoopModeEnabled;
  final bool isTutorialCompleted;

  final File? file;
  final WaveformProgress? waveformProgress;

  /// AudioPlayer
  final PlayerState? playerState;
  final Duration? position;
  final Duration? duration;

  final String? error;

  const SongState({
    this.speed = 1.0,
    this.status = SongStatus.loading,
    required this.song,
    this.error,
    this.data,
    this.activeLoop,
    this.isLoopModeEnabled = false,
    this.isTutorialCompleted = false,
    this.playerState,
    this.position,
    this.duration,
    this.file,
    this.waveformProgress,
  });

  bool get isPlaying => playerState?.playing ?? false;
  bool get isPaused => !isPlaying;
  bool get isCompleted => playerState?.processingState == ProcessingState.completed;
  bool get isBuffering => playerState?.processingState == ProcessingState.buffering;
  bool get isReady => playerState?.processingState == ProcessingState.ready;
  bool get isIdle => playerState?.processingState == ProcessingState.idle;
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
  songDeleted
}
