part of 'song_cubit.dart';

@MappableClass()
class SongState with SongStateMappable {
  final LoopStatus status;
  final List<Loop> loops;
  final String? error;

  const SongState({
    this.status = LoopStatus.initial,
    this.loops = const [],
    this.error,
  });
}

@MappableEnum()
enum LoopStatus { initial, loading, loaded, error }
