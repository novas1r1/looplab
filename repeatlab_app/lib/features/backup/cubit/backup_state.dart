part of 'backup_cubit.dart';

enum BackupStatus {
  idle,
  exporting,
  exportSuccess,
  importing,
  importSuccess,
  failure,
}

@MappableClass()
class BackupState with BackupStateMappable {
  final BackupStatus status;
  final String? errorMessage;
  final BackupImportSummary? lastImportSummary;

  const BackupState({
    this.status = BackupStatus.idle,
    this.errorMessage,
    this.lastImportSummary,
  });
}
