import 'dart:async';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/repositories/file_repository.dart';
import 'package:repeatlab/data/repositories/song_repository.dart';

part 'all_songs_cubit.mapper.dart';
part 'all_songs_state.dart';

class AllSongsCubit extends Cubit<AllSongsState> {
  final SongRepository songRepository;
  final FileRepository fileRepository;

  StreamSubscription<List<Song>>? _songSubscription;

  AllSongsCubit({
    required this.songRepository,
    required this.fileRepository,
  }) : super(const AllSongsState()) {
    // Subscribe to song updates when created
    _songSubscription = songRepository.songs.listen((songs) {
      emit(state.copyWith(songs: songs));
    });
  }

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

  Future<void> addSong() async {
    emit(state.copyWith(status: AllSongsStatus.loading));

    try {
      final file = await fileRepository.pickSingleAudioFile();

      if (file == null) {
        emit(state.copyWith(status: AllSongsStatus.initial));

        return;
      }

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

  @override
  Future<void> close() {
    _songSubscription?.cancel();

    return super.close();
  }
}
