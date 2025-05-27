part of 'song_exporter_cubit.dart';

@MappableClass()
class SongExporterState with SongExporterStateMappable {
  final SongExporterStatus status;
  final String? errorMessage;

  SongExporterState({
    this.status = SongExporterStatus.initial,
    this.errorMessage,
  });
}

@MappableEnum()
enum SongExporterStatus {
  initial,
  exporting,
  exportSuccess,
  exportError,
}
