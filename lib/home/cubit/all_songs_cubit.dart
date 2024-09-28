import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:looplab/data/repositories/song_repository.dart';
import 'package:looplab/models/song.dart';

part 'all_songs_cubit.mapper.dart';
part 'all_songs_state.dart';

class AllSongsCubit extends Cubit<AllSongsState> {
  final SongRepository songRepository;

  AllSongsCubit({required this.songRepository}) : super(const AllSongsState());

  Future<void> loadSongs() async {
    emit(state.copyWith(status: AllSongsStatus.loading));
    try {
      final songs = await songRepository.getAllSongs();
      emit(state.copyWith(status: AllSongsStatus.loaded, songs: songs));
    } catch (e) {
      emit(
        state.copyWith(
          status: AllSongsStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> addSong(File file) async {
    emit(state.copyWith(status: AllSongsStatus.loading));
    try {
      await songRepository.addSongFile(file);
      await loadSongs();
    } catch (e) {
      emit(
        state.copyWith(
          status: AllSongsStatus.error,
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
