import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:looplab/data/repositories/song_repository.dart';
import 'package:looplab/models/song.dart';

part 'songs_state.dart';

class SongsCubit extends Cubit<SongsState> {
  SongsCubit({required this.songRepository}) : super(const SongsState());
  final SongRepository songRepository;

  Future<void> loadSongs() async {
    emit(state.copyWith(status: SongsStatus.loading));
    try {
      final songs = await songRepository.getAllSongs();
      emit(state.copyWith(status: SongsStatus.loaded, songs: songs));
    } catch (e) {
      emit(
        state.copyWith(
          status: SongsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> addSong(File file) async {
    emit(state.copyWith(status: SongsStatus.loading));
    try {
      final song = Song(
        id: '',
        title: file.path.split('/').last,
        artist: '',
        path: file.path,
      );

      await songRepository.addSong(song);
      await loadSongs();
    } catch (e) {
      emit(
        state.copyWith(
          status: SongsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
