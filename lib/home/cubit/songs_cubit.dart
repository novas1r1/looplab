import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:looplab/data/repositories/song_repository.dart';
import 'package:looplab/models/song.dart';

part 'songs_state.dart';

class SongsCubit extends Cubit<SongsState> {
  final SongRepository songRepository;

  SongsCubit({required this.songRepository}) : super(const SongsState());

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
      await songRepository.addSongFile(file);
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

  Future<void> clearDb() async {
    await songRepository.clearDb();
    await loadSongs();
  }
}
