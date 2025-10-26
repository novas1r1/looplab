import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';
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
  static const String invalidLoopRangeErrorKey = 'loopExportValidationError';

  final CrashReportingRepository crashReportingRepository;

  SongExporterCubit({required this.crashReportingRepository}) : super(SongExporterState());

  Future<void> exportLoop({
    required Song song,
    required Loop loop,
    required AudioExportFormat format,
    required int sampleRateHz,
    int? bitrateKbps,
  }) async {
    final loopStart = loop.start ?? Duration.zero;
    final loopEnd = loop.end ?? song.duration;

    if (loopEnd <= loopStart) {
      emit(
        state.copyWith(
          status: SongExporterStatus.exportError,
          errorMessage: invalidLoopRangeErrorKey,
          pendingBytes: null,
          suggestedFileName: null,
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
        pendingBytes: null,
        suggestedFileName: null,
      ),
    );

    File? tempFile;

    try {
      final inputPath = await song.path;
      final outputFileName = _buildSuggestedFileName(
        songTitle: song.title,
        loopName: loop.name,
        format: format,
        sampleRateHz: sampleRateHz,
        bitrateKbps: bitrateKbps,
      );

      final tempDirectory = await getTemporaryDirectory();
      final tempPath = p.join(tempDirectory.path, outputFileName);
      tempFile = File(tempPath);
      final file = tempFile;

      if (await file.exists()) {
        await file.delete();
      }

      final session = await FFmpegKit.execute(
        _buildCommand(
          inputPath: inputPath,
          outputPath: tempPath,
          startTime: loopStart,
          duration: loopEnd - loopStart,
          format: format,
          sampleRateHz: sampleRateHz,
          bitrateKbps: bitrateKbps,
        ),
      );
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        final bytes = await file.readAsBytes();
        await _deleteLocalFile(file);

        emit(
          state.copyWith(
            status: SongExporterStatus.awaitingSave,
            pendingBytes: bytes,
            suggestedFileName: outputFileName,
          ),
        );
      } else if (ReturnCode.isCancel(returnCode)) {
        await _deleteLocalFile(file);

        emit(
          state.copyWith(
            status: SongExporterStatus.exportCanceled,
            pendingBytes: null,
            suggestedFileName: null,
          ),
        );
      } else {
        await _deleteLocalFile(file);

        final logs = await session.getOutput();
        final error = 'FFmpeg failed with code ${returnCode?.getValue() ?? 'unknown'}';

        unawaited(
          crashReportingRepository.reportError(Exception(error), StackTrace.current),
        );

        emit(
          state.copyWith(
            status: SongExporterStatus.exportError,
            errorMessage: logs?.isNotEmpty == true ? '$error\n$logs' : error,
            pendingBytes: null,
            suggestedFileName: null,
          ),
        );
      }
    } catch (ex, stackTrace) {
      if (tempFile != null) {
        await _deleteLocalFile(tempFile);
      }
      unawaited(crashReportingRepository.reportError(ex, stackTrace));
      emit(
        state.copyWith(
          status: SongExporterStatus.exportError,
          errorMessage: ex.toString(),
          pendingBytes: null,
          suggestedFileName: null,
        ),
      );
    }
  }

  void completePendingSave(String? savedPath) {
    if (savedPath == null) {
      emit(
        state.copyWith(
          status: SongExporterStatus.exportCanceled,
          pendingBytes: null,
          suggestedFileName: null,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: SongExporterStatus.exportSuccess,
        exportedFilePath: savedPath,
        pendingBytes: null,
        suggestedFileName: null,
      ),
    );
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

  String _buildSuggestedFileName({
    required String songTitle,
    required String loopName,
    required AudioExportFormat format,
    required int sampleRateHz,
    required int? bitrateKbps,
  }) {
    final sanitizedSong = _sanitizeFileName(songTitle);
    final sanitizedLoop = _sanitizeFileName(
      loopName.isNotEmpty ? loopName : 'loop',
    );
    final bitrateSuffix = format == AudioExportFormat.mp3 && bitrateKbps != null
        ? '-${bitrateKbps}kbps'
        : '';

    return '$sanitizedSong-$sanitizedLoop-${sampleRateHz}Hz$bitrateSuffix.${format.fileExtension}';
  }

  String _sanitizeFileName(String input) {
    final sanitized = input.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return sanitized.isEmpty ? 'loop' : sanitized;
  }

  Future<void> _deleteLocalFile(File file) async {
    await file.delete().catchError((_) {
      unawaited(
        crashReportingRepository.reportError(
          Exception('Failed to delete temp file'),
          StackTrace.current,
        ),
      );
      return file;
    });
  }
}
