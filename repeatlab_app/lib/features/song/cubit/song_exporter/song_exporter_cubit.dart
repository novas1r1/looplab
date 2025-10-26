import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:repeatlab/data/repositories/crash_reporting_repository.dart';

part 'song_exporter_cubit.mapper.dart';
part 'song_exporter_state.dart';

@MappableEnum()
enum AudioExportFormat {
  mp3,
  wav,
}

extension AudioExportFormatX on AudioExportFormat {
  String get fileExtension {
    switch (this) {
      case AudioExportFormat.mp3:
        return 'mp3';
      case AudioExportFormat.wav:
        return 'wav';
    }
  }

  String ffmpegCodecArgs({int? bitrateKbps}) {
    switch (this) {
      case AudioExportFormat.mp3:
        final bitrate = bitrateKbps ?? 192;
        return '-c:a libmp3lame -b:a ${bitrate}k';
      case AudioExportFormat.wav:
        return '-c:a pcm_s16le';
    }
  }
}

class SongExporterCubit extends Cubit<SongExporterState> {
  final CrashReportingRepository crashReportingRepository;

  SongExporterCubit({required this.crashReportingRepository})
    : super(SongExporterState());

  Future<void> exportLoop({
    required String inputPath,
    required String outputPath,
    required Duration startTime,
    required Duration duration,
    required AudioExportFormat format,
    required int sampleRateHz,
    int? bitrateKbps,
  }) async {
    if (duration <= Duration.zero) {
      emit(
        state.copyWith(
          status: SongExporterStatus.exportError,
          errorMessage: 'Invalid loop duration',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: SongExporterStatus.exporting,
        errorMessage: null,
        exportedFilePath: null,
        format: format,
      ),
    );

    try {
      final command = _buildCommand(
        inputPath: inputPath,
        outputPath: outputPath,
        startTime: startTime,
        duration: duration,
        format: format,
        sampleRateHz: sampleRateHz,
        bitrateKbps: bitrateKbps,
      );

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        emit(
          state.copyWith(
            status: SongExporterStatus.exportSuccess,
            exportedFilePath: outputPath,
          ),
        );
      } else if (ReturnCode.isCancel(returnCode)) {
        emit(
          state.copyWith(
            status: SongExporterStatus.initial,
            exportedFilePath: null,
            errorMessage: null,
          ),
        );
      } else {
        final failStackTrace = await session.getFailStackTrace();
        final logs = await session.getOutput();
        final error =
            'FFmpeg failed with code ${returnCode?.getValue() ?? 'unknown'}';

        unawaited(
          crashReportingRepository.reportError(
            Exception(error),
            StackTrace.current,
          ),
        );

        emit(
          state.copyWith(
            status: SongExporterStatus.exportError,
            errorMessage: logs?.isNotEmpty == true ? '$error\n$logs' : error,
          ),
        );
      }
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

  void reset() => emit(SongExporterState());

  String _buildCommand({
    required String inputPath,
    required String outputPath,
    required Duration startTime,
    required Duration duration,
    required AudioExportFormat format,
    required int sampleRateHz,
    int? bitrateKbps,
  }) {
    final start = _formatDuration(startTime);
    final length = _formatDuration(duration);
    final codecArgs = format.ffmpegCodecArgs(bitrateKbps: bitrateKbps);

    return '-ss $start -i "$inputPath" -t $length -ar $sampleRateHz $codecArgs -y "$outputPath"';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final milliseconds = (duration.inMilliseconds % 1000).toString().padLeft(
      3,
      '0',
    );

    return '$hours:$minutes:$seconds.$milliseconds';
  }
}
