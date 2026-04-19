import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/data/repositories/backup/backup_exceptions.dart';
import 'package:repeatlab/data/repositories/backup/backup_manifest.dart';
import 'package:repeatlab/data/repositories/backup/backup_repository.dart';
import 'package:repeatlab/data/repositories/crash_reporting_repository.dart';
import 'package:share_plus/share_plus.dart';

part 'backup_cubit.mapper.dart';
part 'backup_state.dart';

/// Wraps the [BackupRepository] with BLoC-facing state transitions for the
/// Settings UI. Exposes two flows: export-and-share and pick-and-import.
class BackupCubit extends Cubit<BackupState> {
  final BackupRepository backupRepository;
  final CrashReportingRepository crashReportingRepository;

  // Injected for tests. In production these resolve to share_plus + file_picker.
  final Future<ShareResultStatus> Function(File file) _shareFile;
  final Future<File?> Function() _pickBackupFile;

  BackupCubit({
    required this.backupRepository,
    required this.crashReportingRepository,
    Future<ShareResultStatus> Function(File file)? shareFile,
    Future<File?> Function()? pickBackupFile,
  }) : _shareFile = shareFile ?? _defaultShareFile,
       _pickBackupFile = pickBackupFile ?? _defaultPickBackupFile,
       super(const BackupState());

  Future<void> exportAndShare() async {
    AppAnalytics.trackEvent(AppAnalytics.clickBackupExport);
    emit(state.copyWith(status: BackupStatus.exporting, errorMessage: null));

    File? file;
    try {
      file = await backupRepository.exportToFile();
    } catch (ex, stack) {
      log('BackupCubit.exportAndShare: export failed: $ex');
      crashReportingRepository.reportError(ex, stack);
      AppAnalytics.trackEvent(AppAnalytics.backupExportFailure);
      emit(
        state.copyWith(
          status: BackupStatus.failure,
          errorMessage: ex.toString(),
        ),
      );
      return;
    }

    final sizeBytes = await file.length();

    try {
      final shareStatus = await _shareFile(file);
      if (shareStatus == ShareResultStatus.dismissed) {
        AppAnalytics.trackEvent(AppAnalytics.backupExportShareCanceled);
      }
    } catch (ex, stack) {
      // Share sheet failures shouldn't look like export failures — the file
      // is valid and still on disk, the user just can't reach it.
      log('BackupCubit.exportAndShare: share failed: $ex');
      crashReportingRepository.reportError(ex, stack);
    }

    AppAnalytics.trackEvent(
      AppAnalytics.backupExportSuccess,
      data: {'size_bucket': _sizeBucket(sizeBytes)},
    );
    emit(state.copyWith(status: BackupStatus.exportSuccess));
  }

  /// Lets the user pick a backup file and returns its manifest so the UI can
  /// show a confirmation dialog ("12 songs, 230 MB — merge or replace?").
  /// Emits [BackupStatus.failure] if picking/reading/parsing fails.
  Future<BackupImportCandidate?> pickBackupForImport() async {
    AppAnalytics.trackEvent(AppAnalytics.clickBackupImport);

    File? file;
    try {
      file = await _pickBackupFile();
    } catch (ex, stack) {
      log('BackupCubit.pickBackupForImport: file pick failed: $ex');
      crashReportingRepository.reportError(ex, stack);
      emit(
        state.copyWith(
          status: BackupStatus.failure,
          errorMessage: ex.toString(),
        ),
      );
      return null;
    }

    if (file == null) {
      AppAnalytics.trackEvent(AppAnalytics.backupImportCanceled);
      return null;
    }

    try {
      final manifest = await backupRepository.peekImport(file);
      AppAnalytics.trackEvent(
        AppAnalytics.backupImportPicked,
        data: {'song_count': manifest.songCount},
      );
      return BackupImportCandidate(file: file, manifest: manifest);
    } on BackupSchemaVersionException catch (ex, stack) {
      log('BackupCubit.pickBackupForImport: schema newer than app: $ex');
      crashReportingRepository.reportError(ex, stack);
      emit(
        state.copyWith(
          status: BackupStatus.failure,
          errorMessage: ex.toString(),
        ),
      );
      return null;
    } on BackupFormatException catch (ex, stack) {
      log('BackupCubit.pickBackupForImport: malformed backup: $ex');
      crashReportingRepository.reportError(ex, stack);
      emit(
        state.copyWith(
          status: BackupStatus.failure,
          errorMessage: ex.toString(),
        ),
      );
      return null;
    } catch (ex, stack) {
      log('BackupCubit.pickBackupForImport: unexpected: $ex');
      crashReportingRepository.reportError(ex, stack);
      emit(
        state.copyWith(
          status: BackupStatus.failure,
          errorMessage: ex.toString(),
        ),
      );
      return null;
    }
  }

  Future<void> confirmImport({
    required File file,
    required BackupImportMode mode,
  }) async {
    emit(state.copyWith(status: BackupStatus.importing, errorMessage: null));

    try {
      final summary = await backupRepository.importFromFile(file, mode: mode);
      AppAnalytics.trackEvent(
        AppAnalytics.backupImportSuccess,
        data: {
          'mode': mode.name,
          'imported': summary.songsImported,
          'skipped': summary.songsSkipped,
          'renamed': summary.filesRenamed,
        },
      );
      emit(
        state.copyWith(
          status: BackupStatus.importSuccess,
          lastImportSummary: summary,
        ),
      );
    } catch (ex, stack) {
      log('BackupCubit.confirmImport: import failed: $ex');
      crashReportingRepository.reportError(ex, stack);
      AppAnalytics.trackEvent(
        AppAnalytics.backupImportFailure,
        data: {'mode': mode.name},
      );
      emit(
        state.copyWith(
          status: BackupStatus.failure,
          errorMessage: ex.toString(),
        ),
      );
    }
  }

  void reset() {
    emit(const BackupState());
  }

  static String _sizeBucket(int bytes) {
    const mb = 1024 * 1024;
    if (bytes < 10 * mb) return 'lt_10mb';
    if (bytes < 50 * mb) return 'lt_50mb';
    if (bytes < 200 * mb) return 'lt_200mb';
    if (bytes < 500 * mb) return 'lt_500mb';
    return 'gte_500mb';
  }
}

class BackupImportCandidate {
  final File file;
  final BackupManifest manifest;

  const BackupImportCandidate({required this.file, required this.manifest});
}

Future<ShareResultStatus> _defaultShareFile(File file) async {
  final result = await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path)]),
  );
  return result.status;
}

Future<File?> _defaultPickBackupFile() async {
  final result = await FilePicker.pickFiles();
  final path = result?.files.single.path;
  if (path == null) return null;
  return File(path);
}
