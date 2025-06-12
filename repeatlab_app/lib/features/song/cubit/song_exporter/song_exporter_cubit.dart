import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:repeatlab/data/repositories/crash_reporting_repository.dart';

part 'song_exporter_cubit.mapper.dart';
part 'song_exporter_state.dart';

class SongExporterCubit extends Cubit<SongExporterState> {
  final CrashReportingRepository crashReportingRepository;

  SongExporterCubit({required this.crashReportingRepository}) : super(SongExporterState());

  Future<void> exportAudioSegment({
    required String inputPath,
    required String outputPath,
    required Duration startTime,
    required Duration duration,
  }) async {
    emit(state.copyWith(status: SongExporterStatus.exporting));

    try {
      final startSeconds = startTime.inSeconds;
      final durationSeconds = duration.inSeconds;

      final command = '-i "$inputPath" -ss $startSeconds -t $durationSeconds -c copy "$outputPath"';

      await FFmpegKit.execute(command);
    } catch (ex, stackTrace) {
      unawaited(crashReportingRepository.reportError(ex, stackTrace));
      emit(
        state.copyWith(
          status: SongExporterStatus.exportError,
          errorMessage: ex.toString(),
        ),
      );
    }
  }
}
