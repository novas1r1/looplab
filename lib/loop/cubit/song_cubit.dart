import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:looplab/data/repositories/loop_repository.dart';
import 'package:looplab/models/loop.dart';

part 'song_cubit.mapper.dart';
part 'song_state.dart';

class SongCubit extends Cubit<SongState> {
  final LoopRepository loopRepository;

  SongCubit(this.loopRepository) : super(const SongState());

  Future<void> loadLoops(String songId) async {
    emit(state.copyWith(status: LoopStatus.loading));

    try {
      final loops = await loopRepository.getLoopsBySongId(songId);
      emit(state.copyWith(loops: loops, status: LoopStatus.loaded));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to load loops: $e'));
    }
  }

  Future<void> addLoop(Loop loop) async {
    try {
      final newLoop = await loopRepository.addLoop(loop);
      emit(state.copyWith(loops: [...state.loops, newLoop]));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to add loop: $e'));
    }
  }

  Future<void> updateLoop(Loop updatedLoop) async {
    try {
      await loopRepository.updateLoop(updatedLoop);
      emit(
        state.copyWith(
          loops: state.loops.map((loop) => loop.id == updatedLoop.id ? updatedLoop : loop).toList(),
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: 'Failed to update loop: $e'));
    }
  }
}
