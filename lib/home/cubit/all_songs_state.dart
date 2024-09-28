part of 'all_songs_cubit.dart';

@MappableClass()
class AllSongsState {
  final AllSongsStatus status;
  final List<Song> songs;
  final String? errorMessage;

  const AllSongsState({
    this.status = AllSongsStatus.initial,
    this.songs = const [],
    this.errorMessage,
  });
}

@MappableEnum()
enum AllSongsStatus { initial, loading, loaded, error }
