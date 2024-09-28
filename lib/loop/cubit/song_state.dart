part of 'song_cubit.dart';

// @MappableClass()
class SongState {
  final LoopStatus status;
  final List<Loop> loops;
  final AudioSource? audioSource;
  final SoundHandle? handle;
  final Loop? activeLoop;
  final Float32List? data;
  final String? error;

  const SongState({
    this.status = LoopStatus.loading,
    this.loops = const [],
    this.audioSource,
    this.handle,
    this.error,
    this.data,
    this.activeLoop,
  });

  SongState copyWith({
    LoopStatus? status,
    List<Loop>? loops,
    AudioSource? audioSource,
    SoundHandle? handle,
    Loop? activeLoop,
    Float32List? data,
    String? error,
  }) {
    return SongState(
      status: status ?? this.status,
      loops: loops ?? this.loops,
      audioSource: audioSource ?? this.audioSource,
      handle: handle ?? this.handle,
      activeLoop: activeLoop ?? this.activeLoop,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}

// @MappableEnum()
enum LoopStatus { loading, loaded, error }
