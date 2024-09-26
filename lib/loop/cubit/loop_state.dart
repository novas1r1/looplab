part of 'loop_cubit.dart';

@MappableClass()
class LoopState with LoopStateMappable {
  final LoopStatus status;
  final List<Loop> loops;
  final String? error;

  const LoopState({
    this.status = LoopStatus.initial,
    this.loops = const [],
    this.error,
  });
}

@MappableEnum()
enum LoopStatus { initial, loading, loaded, error }
