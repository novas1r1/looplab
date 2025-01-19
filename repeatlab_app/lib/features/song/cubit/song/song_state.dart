part of 'song_cubit.dart';

@MappableClass()
class SongState with SongStateMappable {
  final double speed;
  final SongStatus status;
  final Song song;
  final AudioSource? audioSource;
  final SoundHandle? handle;
  final Loop? activeLoop;
  final Float32List? data;
  final String? error;
  final bool isLoopModeEnabled;
  final bool isTutorialCompleted;

  const SongState({
    this.speed = 1.0,
    this.status = SongStatus.loading,
    required this.song,
    this.audioSource,
    this.handle,
    this.error,
    this.data,
    this.activeLoop,
    this.isLoopModeEnabled = false,
    this.isTutorialCompleted = false,
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
  updated,
  songDeleted
}
