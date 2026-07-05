part of 'all_songs_cubit.dart';

@MappableClass()
class AllSongsState with AllSongsStateMappable {
  final AllSongsStatus status;
  final List<Song> songs;
  final String? errorMessage;

  /// 1-based index of the media file currently being imported, set together
  /// with [importTotal] once the batch size is known (after picking); both
  /// are `null` otherwise.
  final int? importCurrent;
  final int? importTotal;

  const AllSongsState({
    this.status = AllSongsStatus.initial,
    this.songs = const [],
    this.errorMessage,
    this.importCurrent,
    this.importTotal,
  });
}

@MappableEnum()
enum AllSongsStatus {
  initial,
  loading,
  importing,
  loaded,
  error,

  /// A picked audio file has an unsupported format; [AllSongsState.errorMessage]
  /// carries the offending file extension.
  errorAudioFormat,

  /// A picked video file has an unsupported format; [AllSongsState.errorMessage]
  /// carries the offending file extension.
  errorVideoFormat,

  /// A new pick was requested while a previous one is still running (e.g. a
  /// large video still downloading from cloud storage).
  errorImportInProgress,
}
