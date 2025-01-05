part of 'song_cubit.dart';

@MappableClass()
class SongState with SongStateMappable {
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
  loaded,
  error,
  loopAdded,
  loopDeleted,
  updated,
  songDeleted
}
