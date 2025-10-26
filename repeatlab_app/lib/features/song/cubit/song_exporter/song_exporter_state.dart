part of 'song_exporter_cubit.dart';

@MappableClass()
class SongExporterState with SongExporterStateMappable {
  final SongExporterStatus status;
  final String? errorMessage;
  final String? exportedFilePath;
  final AudioExportFormat? format;

  SongExporterState({
    this.status = SongExporterStatus.initial,
    this.errorMessage,
    this.exportedFilePath,
    this.format,
  });
}

@MappableEnum()
enum SongExporterStatus {
  initial,
  exporting,
  exportSuccess,
  exportError,
}
