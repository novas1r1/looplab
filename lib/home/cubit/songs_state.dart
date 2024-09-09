part of 'songs_cubit.dart';

enum SongsStatus { initial, loading, loaded, error }

class SongsState {
  const SongsState({
    this.status = SongsStatus.initial,
    this.songs = const [],
    this.errorMessage,
  });
  final SongsStatus status;
  final List<Song> songs;
  final String? errorMessage;

  SongsState copyWith({
    SongsStatus? status,
    List<Song>? songs,
    String? errorMessage,
  }) {
    return SongsState(
      status: status ?? this.status,
      songs: songs ?? this.songs,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
