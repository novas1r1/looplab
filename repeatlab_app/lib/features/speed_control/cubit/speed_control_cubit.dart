import 'dart:developer' as dev;

import 'package:bloc/bloc.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:repeatlab/data/models/song.dart';

part 'speed_control_cubit.mapper.dart';
part 'speed_control_state.dart';

class SpeedControlCubit extends Cubit<SpeedControlState> {
  final Song song;

  SpeedControlCubit({required this.song})
    : super(
        song.bpm != null
            ? SpeedControlState(
                originalBpm: song.bpm,
                currentBpm: song.bpm,
                minBpm: (song.bpm! * 0.5).round().clamp(1, song.bpm!),
                maxBpm: (song.bpm! * 2.0).round().clamp(song.bpm!, 400),
              )
            : const SpeedControlState(),
      );

  void setTempoMode(TempoMode tempoMode) {
    emit(state.copyWith(tempoMode: tempoMode));
  }

  void setSpeedMultiplier(double speedMultiplier) {
    emit(state.copyWith(speedMultiplier: speedMultiplier));
  }

  /// Set the original bpm from the song
  /// Can be null.
  void setOriginalBpm(int? originalBpm) {
    dev.log('setOriginalBpm: $originalBpm', name: 'SpeedControlCubit');
    // if not null, calculate min and max bpm
    if (originalBpm != null) {
      dev.log('setOriginalBpm: original bpm is set', name: 'SpeedControlCubit');
      // min bpm are calculated by multiplying the original bpm by 0.5
      final minBpm = (originalBpm * 0.5).round().clamp(1, originalBpm);
      // max bpm are calculated by multiplying the original bpm by 2.0
      final maxBpm = (originalBpm * 2.0).round().clamp(originalBpm, 400);

      emit(
        state.copyWith(
          originalBpm: originalBpm,
          currentBpm: originalBpm,
          minBpm: minBpm,
          maxBpm: maxBpm,
        ),
      );
    } else {
      dev.log('setOriginalBpm: original bpm is not set', name: 'SpeedControlCubit');
      emit(
        state.copyWith(
          originalBpm: null,
          currentBpm: null,
          minBpm: null,
          maxBpm: null,
        ),
      );
    }

    // update the song and set original bpm
  }

  void setCurrentBpm(int currentBpm) {
    emit(state.copyWith(currentBpm: currentBpm));
  }

  void resetSpeed() {
    dev.log('resetSpeed: ${state.originalBpm}', name: 'SpeedControlCubit');

    // if original bpm is set, set current bpm to original bpm
    if (state.originalBpm != null) {
      dev.log('resetSpeed: original bpm is set', name: 'SpeedControlCubit');
      emit(
        state.copyWith(
          speedMultiplier: 1.0,
          originalBpm: state.originalBpm,
          currentBpm: state.originalBpm,
          minBpm: (state.originalBpm! * 0.5).round().clamp(1, state.originalBpm!),
          maxBpm: (state.originalBpm! * 2.0).round().clamp(state.originalBpm!, 400),
        ),
      );
    } else {
      dev.log('resetSpeed: original bpm is not set', name: 'SpeedControlCubit');
      emit(
        state.copyWith(
          speedMultiplier: 1.0,
          originalBpm: null,
          currentBpm: null,
          minBpm: null,
          maxBpm: null,
        ),
      );
    }
  }
}
