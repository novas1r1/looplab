part of 'songs_cubit.dart';

class SongsState {
  final SongsStatus status;
  final List<Song> songs;
  final String? errorMessage;

  const SongsState({
    this.status = SongsStatus.initial,
    this.songs = const [],
    this.errorMessage,
  });

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

enum SongsStatus { initial, loading, loaded, error }
