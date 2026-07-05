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
enum AllSongsStatus { initial, loading, importing, loaded, error, errorVideoFormat }
