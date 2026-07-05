import 'dart:async';
import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/repositories/crash_reporting_repository.dart';
import 'package:repeatlab/data/repositories/file_repository.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
import 'package:repeatlab/data/repositories/song_repository.dart';

part 'all_songs_cubit.mapper.dart';
part 'all_songs_state.dart';

class AllSongsCubit extends Cubit<AllSongsState> {
  final SongRepository songRepository;
  final FileRepository fileRepository;
  final CrashReportingRepository crashReportingRepository;
  final LocalConfigRepository localConfigRepository;

  StreamSubscription<List<Song>>? _songSubscription;

  AllSongsCubit({
    required this.songRepository,
    required this.fileRepository,
    required this.crashReportingRepository,
    required this.localConfigRepository,
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
    emit(state.copyWith(status: AllSongsStatus.importing));

    List<File> files;
    try {
      files = await fileRepository.pickAudioFiles();
    } catch (ex, stack) {
      crashReportingRepository.reportError(ex, stack);
      emit(state.copyWith(status: AllSongsStatus.error));
      return;
    }

    if (files.isEmpty) {
      emit(state.copyWith(status: AllSongsStatus.initial));
      return;
    }

    var addedAny = false;
    // First failure encountered across the batch. Successfully added files are
    // still imported; the failure is surfaced after the whole batch is done.
    AllSongsStatus? failureStatus;
    String? failureMessage;

    for (final (index, file) in files.indexed) {
      emit(
        state.copyWith(importCurrent: index + 1, importTotal: files.length),
      );
      try {
        await songRepository.addSongFile(file);
        addedAny = true;
        AppAnalytics.trackEvent(
          AppAnalytics.songAddSuccess,
          data: {'source': 'audio_file', 'format': _fileFormat(file)},
        );
      } on UnsupportedAudioFormatException catch (ex, stack) {
        crashReportingRepository.reportError(
          ex,
          stack,
          properties: {'file': file.path},
        );
        failureStatus ??= AllSongsStatus.error;
        failureMessage ??= ex.format;
      } on AudioFileLoadException catch (ex, stack) {
        // A supported format that still failed to load — report the diagnostic
        // context as structured properties so we can pin down the cause.
        crashReportingRepository.reportError(
          ex,
          stack,
          properties: {
            'file': file.path,
            'fileName': ex.fileName,
            'extension': ex.extension,
            'exists': ex.exists,
            'sizeBytes': ex.sizeBytes,
            'cause': ex.cause,
          },
        );
        failureStatus ??= AllSongsStatus.error;
        failureMessage ??= ex.toString();
      } catch (ex, stack) {
        crashReportingRepository.reportError(
          ex,
          stack,
          properties: {'file': file.path},
        );
        failureStatus ??= AllSongsStatus.error;
        failureMessage ??= ex.toString();
      }
    }

    if (addedAny) {
      await _trackFirstSongIfNeeded();
    }

    await _finishBatch(failureStatus, failureMessage);
  }

  Future<void> addVideo() async {
    emit(state.copyWith(status: AllSongsStatus.importing));

    List<File> files;
    try {
      files = await fileRepository.pickVideoFiles();
    } catch (ex, stack) {
      crashReportingRepository.reportError(ex, stack);
      emit(state.copyWith(status: AllSongsStatus.error));
      return;
    }

    if (files.isEmpty) {
      emit(state.copyWith(status: AllSongsStatus.initial));
      return;
    }

    var addedAny = false;
    AllSongsStatus? failureStatus;
    String? failureMessage;

    for (final (index, file) in files.indexed) {
      emit(
        state.copyWith(importCurrent: index + 1, importTotal: files.length),
      );
      try {
        await songRepository.addVideoFile(file);
        addedAny = true;
        AppAnalytics.trackEvent(
          AppAnalytics.songAddSuccess,
          data: {'source': 'video', 'format': _fileFormat(file)},
        );
      } on UnsupportedVideoFormatException catch (ex, stack) {
        crashReportingRepository.reportError(
          ex,
          stack,
          properties: {'file': file.path},
        );
        failureStatus ??= AllSongsStatus.errorVideoFormat;
        failureMessage ??= ex.format;
      } catch (ex, stack) {
        crashReportingRepository.reportError(
          ex,
          stack,
          properties: {'file': file.path},
        );
        failureStatus ??= AllSongsStatus.error;
        failureMessage ??= ex.toString();
      }
    }

    if (addedAny) {
      await _trackFirstSongIfNeeded();
    }

    await _finishBatch(failureStatus, failureMessage);
  }

  /// Refresh the song list, then emit either the first failure encountered
  /// during the batch or a clean `loaded` state when everything succeeded.
  Future<void> _finishBatch(
    AllSongsStatus? failureStatus,
    String? failureMessage,
  ) async {
    List<Song> songs;
    try {
      songs = await songRepository.getAllSongs();
    } catch (ex, stack) {
      crashReportingRepository.reportError(ex, stack);
      emit(
        state.copyWith(
          status: AllSongsStatus.error,
          errorMessage: ex.toString(),
        ),
      );
      return;
    }

    if (failureStatus != null) {
      emit(
        state.copyWith(
          status: failureStatus,
          songs: songs,
          errorMessage: failureMessage,
          importCurrent: null,
          importTotal: null,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: AllSongsStatus.loaded,
          songs: songs,
          importCurrent: null,
          importTotal: null,
        ),
      );
    }
  }

  /// Lowercased file extension (e.g. `mp3`, `mp4`) used as the `format`
  /// property on `song_add_success`. Falls back to `unknown` when absent.
  String _fileFormat(File file) {
    final name = file.path;
    final dot = name.lastIndexOf('.');
    if (dot == -1 || dot == name.length - 1) return 'unknown';
    return name.substring(dot + 1).toLowerCase();
  }

  /// Fires the `first_song_added` activation event exactly once per install.
  Future<void> _trackFirstSongIfNeeded() async {
    if (localConfigRepository.firstSongTracked) return;
    AppAnalytics.trackEvent(AppAnalytics.firstSongAdded);
    await localConfigRepository.markFirstSongTracked();
  }

  Future<bool> clearDb() async {
    try {
      await songRepository.clearDb();
      await loadSongs();
      return true;
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      return false;
    }
  }

  Future<void> reorderSongs(int oldIndex, int newIndex) async {
    final songs = List<Song>.from(state.songs);

    // ReorderableListView adjusts newIndex when moving down
    var adjustedNewIndex = newIndex;
    if (oldIndex < adjustedNewIndex) {
      adjustedNewIndex -= 1;
    }

    final song = songs.removeAt(oldIndex);
    songs.insert(adjustedNewIndex, song);

    // Reassign sortOrder based on new positions
    final reordered = [
      for (int i = 0; i < songs.length; i++) songs[i].copyWith(sortOrder: i),
    ];

    // Optimistic update
    emit(state.copyWith(songs: reordered));

    try {
      await songRepository.reorderSongs(reordered);
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

  Future<void> deleteSong(Song song) async {
    try {
      await songRepository.deleteSong(song);
      // The songs stream will automatically update via the subscription
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

  @override
  Future<void> close() {
    _songSubscription?.cancel();

    return super.close();
  }
}
