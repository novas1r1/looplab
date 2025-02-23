import 'dart:async';
import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/repositories/crash_reporting_repository.dart';
import 'package:repeatlab/data/repositories/file_repository.dart';
import 'package:repeatlab/data/repositories/song_repository.dart';

part 'all_songs_cubit.mapper.dart';
part 'all_songs_state.dart';

class AllSongsCubit extends Cubit<AllSongsState> {
  final SongRepository songRepository;
  final FileRepository fileRepository;
  final CrashReportingRepository crashReportingRepository;

  StreamSubscription<List<Song>>? _songSubscription;

  AllSongsCubit({
    required this.songRepository,
    required this.fileRepository,
    required this.crashReportingRepository,
  }) : super(const AllSongsState()) {
    _songSubscription = songRepository.songs.listen((songs) {
      emit(state.copyWith(songs: songs));
    });
  }

  Future<void> loadSongs() async {
    emit(state.copyWith(status: AllSongsStatus.loading));

    try {
      final songs = await songRepository.getAllSongs();
      emit(state.copyWith(status: AllSongsStatus.loaded, songs: songs));
    } catch (ex, stack) {
      crashReportingRepository.reportError(ex, stack);
      emit(
        state.copyWith(
          status: AllSongsStatus.error,
          errorMessage: ex.toString(),
        ),
      );
    }
  }

  Future<void> addSong() async {
    emit(state.copyWith(status: AllSongsStatus.loading));

    File? file;

    try {
      file = await fileRepository.pickSingleAudioFile();

      if (file == null) {
        emit(state.copyWith(status: AllSongsStatus.initial));

        return;
      }

      await songRepository.addSongFile(file);
      await loadSongs();
    } catch (ex, stack) {
      crashReportingRepository.reportError(ex, stack);
      emit(
        state.copyWith(
          status: AllSongsStatus.error,
          errorMessage: ex.toString(),
        ),
      );
    }
  }

  Future<void> clearDb() async {
    try {
      await songRepository.clearDb();
      await loadSongs();
    } catch (ex, stack) {
      crashReportingRepository.reportError(ex, stack);
    }
  }

  @override
  Future<void> close() {
    _songSubscription?.cancel();

    return super.close();
  }
}
