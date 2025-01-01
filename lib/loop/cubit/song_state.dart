part of 'song_cubit.dart';

// @MappableClass()
class SongState {
  final SongStatus status;
  final Song song;
  final AudioSource? audioSource;
  final SoundHandle? handle;
  final Loop? activeLoop;
  final Float32List? data;
  final String? error;

  const SongState({
    this.status = SongStatus.loading,
    required this.song,
    this.audioSource,
    this.handle,
    this.error,
    this.data,
    this.activeLoop,
  });

  SongState copyWith({
    SongStatus? status,
    Song? song,
    AudioSource? audioSource,
    SoundHandle? handle,
    Loop? activeLoop,
    Float32List? data,
    String? error,
  }) {
    return SongState(
      status: status ?? this.status,
      song: song ?? this.song,
      audioSource: audioSource ?? this.audioSource,
      handle: handle ?? this.handle,
      activeLoop: activeLoop ?? this.activeLoop,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}

// @MappableEnum()
enum SongStatus { loading, loaded, error, songDeleted }
