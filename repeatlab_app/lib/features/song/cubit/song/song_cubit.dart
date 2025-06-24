// ignore_for_file: avoid_redundant_argument_values

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/utils/cubit_extension.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/repositories/crash_reporting_repository.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
import 'package:repeatlab/data/repositories/song_repository.dart';
import 'package:repeatlab/data/services/audio_service_provider.dart';
import 'package:repeatlab/data/services/repeatlab_audioplayers_service_handler.dart';

// part 'song_cubit.mapper.dart';
part 'song_cubit.mapper.dart';
part 'song_state.dart';

class SongCubit extends Cubit<SongState> {
  final Song song;

  final SongRepository songRepository;
  final LocalConfigRepository localConfigRepository;
  final CrashReportingRepository crashReportingRepository;

  // audio player subscriptions
  late final RepeatlabAudioplayersServiceHandler audioHandler;
  StreamSubscription<List<Song>>? _songSubscription;

  Stream<PlayerState>? playerStateStream;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  Stream<Duration>? positionStream;
  StreamSubscription<Duration>? _positionSubscription;

  Stream<Duration>? durationStream;
  StreamSubscription<Duration>? _durationSubscription;

  Duration? positionToSeek;

  Future<Duration> get position async => await audioHandler.position;

  SongCubit({
    required this.song,
    required this.songRepository,
    required this.localConfigRepository,
    required this.crashReportingRepository,
  }) : super(SongState(song: song));

  @override
  Future<void> close() async {
    if (state.playerState == PlayerState.playing) {
      await stopSong();
    }

    await _songSubscription?.cancel();

    // Clean up audio service if available
    await audioHandler.stop();

    return super.close();
  }

  Future<void> initSong(AudioPlayer audioPlayer) async {
    emit(state.copyWith(status: SongStatus.loading));

    try {
      // Cancel any existing subscriptions before reinitializing
      await _playerStateSubscription?.cancel();
      await _positionSubscription?.cancel();
      await _durationSubscription?.cancel();

      // Initialize audio handler first
      audioHandler = await AudioServiceProvider.init(audioPlayer);

      // Initialize subscriptions before any other operations
      playerStateStream = audioHandler.playerStateStream;
      _playerStateSubscription = playerStateStream?.listen((playerState) {
        if (playerState == PlayerState.completed) {
          stopSong();
        }

        maybeEmit(
          state.copyWith(
            status: SongStatus.updated,
            playerState: playerState,
            error: null,
          ),
        );
      });

      /// audio player subscriptions for position
      positionStream = audioHandler.positionStream;
      _positionSubscription = positionStream?.listen((position) {});

      // song data subscription
      _songSubscription = songRepository.songs.listen((songs) {
        final updatedSong = songs.firstWhere(
          (localSong) => localSong.id == song.id,
          orElse: () => state.song,
        );

        if (updatedSong != state.song) {
          emit(
            state.copyWith(
              status: SongStatus.updated,
              song: updatedSong,
            ),
          );
        }
      });

      final path = await state.song.path;
      final file = File(path);

      if (!file.existsSync()) {
        unawaited(
          crashReportingRepository.reportError(
            Exception('File not found: $path'),
            StackTrace.current,
          ),
        );
        emit(
          state.copyWith(
            status: SongStatus.loadError,
            error: 'File not found: $path',
          ),
        );
        return;
      }

      // Initialize audio player with the file but keep it paused
      await audioHandler.setSpeed(1.0);
      await audioHandler.playSong(state.song);
      await audioHandler.pause();

      // check if tutorial is completed
      final isTutorialCompleted = localConfigRepository.hasCompletedTutorial;

      emit(
        state.copyWith(
          status: SongStatus.loadSuccess,
          song: state.song,
          isTutorialCompleted: isTutorialCompleted,
          playerState: PlayerState.paused,
          error: null,
        ),
      );
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));

      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to initialize song: $ex',
        ),
      );
    }
  }

  Future<void> updateTutorialCompleted() async {
    await localConfigRepository.setHasCompletedTutorial(hasCompleted: true);

    emit(state.copyWith(isTutorialCompleted: true));
  }

  Future<void> togglePlaySong() async {
    log('togglePlaySong state.playerState was: ${state.playerState}');

    try {
      // If audio handler is available, use it for background playback
      switch (state.playerState) {
        case PlayerState.paused:
          await audioHandler.resume();
        case PlayerState.playing:
          await audioHandler.pause();
        case PlayerState.stopped:
        case PlayerState.completed:
        case PlayerState.disposed:
          // Reinitialize the audio handler if it's in a bad state
          await audioHandler.playSong(state.song);
        case null:
          // Initialize the audio handler if it's null
          await audioHandler.playSong(state.song);
      }
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to play audio file. The file format might not be supported: $ex',
        ),
      );
    }
  }

  Future<void> stopSong() async {
    try {
      await audioHandler.stop();
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to stop song: $ex',
        ),
      );
    }
  }

  Future<void> pauseSong() async {
    try {
      await audioHandler.pause();
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to pause song: $ex',
        ),
      );
    }
  }

  Future<void> seekSong(Duration position) async {
    try {
      await audioHandler.seek(position);
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to seek song: $ex',
        ),
      );
    }
  }

  /// Sets the start of a loop
  /// The start can only be placed before the end
  /// When the audio player is playing and looping already and a new start is set,
  /// the loop will be updated and the audio player will continue playing and
  /// as soon as the end is reached, the loop will start over from the new start
  Future<void> setLoopStart() async {
    // log('setLoopStart to ${state.position}');

    final activeLoop = state.activeLoop;
    if (activeLoop == null) return;

    // Get current position directly from audio player
    final currentPosition = await position;

    log('setLoopStart to $currentPosition');

    await updateLoop(activeLoop.copyWith(start: currentPosition));
  }

  /// Sets the end of a loop
  /// The end can only be placed after the start
  /// When the audio player is playing and looping already and a new end is set,
  /// the loop will be updated and the audio player will continue playing and
  /// as soon as the new end is reached, the loop will start over
  Future<void> setLoopEnd() async {
    log('setLoopEnd: ${state.activeLoop}');

    final activeLoop = state.activeLoop;
    if (activeLoop == null) return;

    try {
      // Get current position directly from audio player
      var endPosition = await position;

      // Ensure end position is not greater than song duration
      if (endPosition > state.song.duration) {
        endPosition = state.song.duration;
      }

      log('setLoopEnd: got current position $endPosition');

      // Update the loop in the audio handler immediately
      if (state.isLoopModeEnabled) {
        audioHandler.customAction(
          'enableLoop',
          {
            'loop': activeLoop.copyWith(end: endPosition),
          },
        );
      }

      await updateLoop(activeLoop.copyWith(end: endPosition));
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to set loop end: $ex',
        ),
      );
    }
  }

  Future<void> unselectLoop() async {
    log('UNSELECT LOOP: ${state.activeLoop}');
    try {
      await audioHandler.customAction('disableLoop');

      emit(
        state.copyWith(
          status: SongStatus.loopModeToggled,
          activeLoop: null,
          isLoopModeEnabled: false,
          error: null,
        ),
      );
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to unselect loop: $ex',
        ),
      );
    }
  }

  Future<void> selectLoop(Loop loop) async {
    log('SELECT LOOP: $loop');
    if (loop.start == null) return;

    try {
      await audioHandler.pause();
      await audioHandler.seek(loop.start!);

      // Update the loop in the audio handler immediately
      await audioHandler.customAction('enableLoop', {'loop': loop});

      emit(
        state.copyWith(
          status: SongStatus.loopModeToggled,
          activeLoop: loop,
          isLoopModeEnabled: true,
          error: null,
        ),
      );
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));

      // Reset state on error
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to select loop. Please try again.',
          activeLoop: null,
          isLoopModeEnabled: false,
        ),
      );
    }
  }

  Future<void> togglePlayLoop(Loop loop) async {
    Loop updatedLoop = loop;

    // if loop has no end set but is playing, set end to the duration of the song
    if (loop.end == null) {
      updatedLoop = loop.copyWith(end: state.song.duration);
      await updateLoop(updatedLoop);
    }

    emit(
      state.copyWith(
        status: SongStatus.updated,
        activeLoop: updatedLoop,
        isLoopModeEnabled: true,
        error: null,
      ),
    );

    try {
      // Use audio service for background playback with loop
      audioHandler.customAction('enableLoop', {'loop': updatedLoop});

      if (state.playerState != PlayerState.playing) {
        await audioHandler.play();

        final currentPosition = await position;

        // check if loop end is reached
        // if reached, start over
        if (updatedLoop.end != null && currentPosition >= updatedLoop.end!) {
          await audioHandler.seek(updatedLoop.start!);
        } else if (updatedLoop.start != null && currentPosition < updatedLoop.start!) {
          await audioHandler.seek(updatedLoop.start!);
        }
      } else {
        await audioHandler.pause();
      }
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to toggle play loop: $ex',
        ),
      );
    }
  }

  Future<void> pauseLoop() async {
    if (state.activeLoop == null) return;

    try {
      await audioHandler.pause();
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to pause loop: $ex',
        ),
      );
    }
  }

  void nextLoop() {
    // get current loop
    final currentLoop = state.activeLoop;

    // if not null get the next loop
    if (currentLoop != null) {
      final currentLoopIndex = state.song.loops.indexWhere((loop) => loop.id == currentLoop.id);
      final nextLoopIndex = currentLoopIndex + 1;
      // check if last loop
      if (nextLoopIndex >= state.song.loops.length) {
        // play the first loop
        final firstLoop = state.song.loops.first;
        selectLoop(firstLoop);
      } else {
        final nextLoop = state.song.loops[nextLoopIndex];
        selectLoop(nextLoop);
      }
    } else {
      // play the first loop
      final firstLoop = state.song.loops.first;
      selectLoop(firstLoop);
    }
  }

  void previousLoop() {
    // get current loop
    final currentLoop = state.activeLoop;

    // if not null get the previous loop
    if (currentLoop != null) {
      final currentLoopIndex = state.song.loops.indexWhere((loop) => loop.id == currentLoop.id);
      final previousLoopIndex = currentLoopIndex - 1;
      // check if first loop
      if (previousLoopIndex < 0) {
        // play the last loop
        final lastLoop = state.song.loops.last;
        selectLoop(lastLoop);
      } else {
        final previousLoop = state.song.loops[previousLoopIndex];
        selectLoop(previousLoop);
      }
    }
  }

  Future<void> addLoop() async {
    log('ADDING LOOP: ${state.activeLoop}', name: 'SongCubit');

    final startPosition = await position;

    try {
      // create a new loop
      final loop = Loop(
        id: state.song.loops.length,
        name: 'Loop ${state.song.loops.length + 1}',
        songId: state.song.id,
        // for each new loop assign a color based on LoopColor.values
        // for the first loop, first color, for the second loop, second color, etc.
        // if the number of loops is greater than the number of colors, start again from the first color
        color: LoopColor.values[state.song.loops.length % LoopColor.values.length],
        start: startPosition,
      );

      final updatedSong = await songRepository.addLoopToSong(
        song: state.song,
        loop: loop,
      );

      emit(
        state.copyWith(
          status: SongStatus.loopAdded,
          song: updatedSong,
          activeLoop: loop,
          isLoopModeEnabled: true,
          error: null,
        ),
      );
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to add loop: $ex',
        ),
      );
    }
  }

  Future<void> updateLoop(Loop updatedLoop) async {
    log('updateLoop: $updatedLoop');
    emit(state.copyWith(status: SongStatus.updating));

    try {
      final updatedSong = await songRepository.updateLoopForSong(
        song: state.song,
        loop: updatedLoop,
      );

      emit(
        state.copyWith(
          status: SongStatus.updated,
          song: updatedSong,
          activeLoop: updatedLoop,
          isLoopModeEnabled: true,
          error: null,
        ),
      );
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to update loop: $ex',
        ),
      );
    }
  }

  Future<void> deleteLoop(Loop loop) async {
    log('deleteLoop: $loop');
    emit(state.copyWith(status: SongStatus.updating));

    try {
      final updatedSong = await songRepository.deleteLoopForSong(
        song: state.song,
        loop: loop,
      );

      if (loop == state.activeLoop) {
        unselectLoop();
      }

      emit(
        state.copyWith(
          song: updatedSong,
          status: SongStatus.loopDeleted,
          error: null,
        ),
      );
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to delete loop: $ex',
        ),
      );
    }
  }

  Future<void> deleteSong() async {
    emit(state.copyWith(status: SongStatus.updating));

    try {
      await songRepository.deleteSong(state.song);
      emit(
        state.copyWith(
          status: SongStatus.songDeleted,
          song: null,
          error: null,
        ),
      );
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to delete song: $ex',
        ),
      );
    }
  }

  Future<void> toggleLoopMode() async {
    emit(
      state.copyWith(
        isLoopModeEnabled: !state.isLoopModeEnabled,
        activeLoop: null,
        status: SongStatus.loopModeToggled,
      ),
    );

    try {
      if (!state.isLoopModeEnabled) {
        // stop the song
        await pauseSong();
        // Disable loop mode in audio handler
        await audioHandler.customAction('disableLoop');
      }
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(
        state.copyWith(status: SongStatus.error, error: 'Failed to toggle loop mode: $ex'),
      );
    }
  }

  Future<void> back(int seconds) async {
    try {
      await audioHandler.back(seconds, state.activeLoop);
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to back: $ex',
        ),
      );
    }
  }

  Future<void> forward(int seconds) async {
    log('forward: $seconds');
    try {
      await audioHandler.forward(seconds, state.activeLoop);
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to forward: $ex',
        ),
      );
    }
  }

  // Add new method
  Future<void> updateSpeed(double newSpeed) async {
    try {
      await audioHandler.setSpeed(newSpeed);

      emit(
        state.copyWith(
          status: SongStatus.updated,
          speed: newSpeed,
        ),
      );
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to update speed: $ex',
        ),
      );
    }
  }

  Future<void> updateLoopOrder(List<Loop> newLoops) async {
    try {
      final updatedSong = state.song.copyWith(loops: newLoops);
      await songRepository.updateSong(updatedSong);

      emit(
        state.copyWith(
          status: SongStatus.updated,
          song: updatedSong,
          error: null,
        ),
      );
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to update loop order: $ex',
        ),
      );
    }
  }
}
