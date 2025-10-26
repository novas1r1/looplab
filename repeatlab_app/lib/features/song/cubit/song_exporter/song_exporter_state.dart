part of 'song_exporter_cubit.dart';

@MappableClass()
class SongExporterState with SongExporterStateMappable {
  final SongExporterStatus status;
  final String? errorMessage;
  final String? exportedFilePath;
  final AudioExportFormat? format;
  final Uint8List? pendingBytes;
  final String? suggestedFileName;

  SongExporterState({
    this.status = SongExporterStatus.initial,
    this.errorMessage,
    this.exportedFilePath,
    this.format,
    this.pendingBytes,
    this.suggestedFileName,
  });
}

@MappableEnum()
enum SongExporterStatus {
  initial,
  exporting,
  awaitingSave,
  exportSuccess,
  exportError,
  exportCanceled,
}
