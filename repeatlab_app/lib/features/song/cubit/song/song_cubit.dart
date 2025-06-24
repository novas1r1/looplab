// ignore_for_file: avoid_redundant_argument_values

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:async/async.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:repeatlab/core/utils/cubit_extension.dart';
import 'package:repeatlab/core/utils/duration_extension.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/repositories/crash_reporting_repository.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
import 'package:repeatlab/data/repositories/song_repository.dart';
import 'package:repeatlab/data/services/audio_player_service.dart';
import 'package:repeatlab/data/services/wave_data_visualizer_service.dart';

// part 'song_cubit.mapper.dart';
part 'song_cubit.mapper.dart';
part 'song_state.dart';

class SongCubit extends Cubit<SongState> {
  final Song song;

  final SongRepository songRepository;
  final LocalConfigRepository localConfigRepository;
  final CrashReportingRepository crashReportingRepository;
  final AudioPlayerService audioPlayerService;
  final WaveDataVisualizerService waveDataVisualizerService;

  StreamSubscription<List<Song>>? _songSubscription;

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;

  Duration? positionToSeek;

  CancelableOperation? _seekOperation;

  // Throttle position emissions to ~10 FPS (every 100 ms)
  static const Duration _kMinPositionUpdateInterval = Duration(milliseconds: 100);
  DateTime _lastPositionEmit = DateTime.fromMillisecondsSinceEpoch(0);

  SongCubit({
    required this.song,
    required this.songRepository,
    required this.localConfigRepository,
    required this.crashReportingRepository,
    required this.audioPlayerService,
    required this.waveDataVisualizerService,
  }) : super(SongState(song: song));

  @override
  Future<void> close() async {
    await audioPlayerService.dispose();

    if (state.playerState?.playing ?? false) {
      await stopSong();
    }

    await _songSubscription?.cancel();

    return super.close();
  }

  Future<void> initSong() async {
    emit(state.copyWith(status: SongStatus.loading));

    try {
      // Cancel any existing subscriptions before reinitializing
      await _playerStateSubscription?.cancel();
      await _positionSubscription?.cancel();
      await _durationSubscription?.cancel();

      await audioPlayerService.init(state.song);

      // Initialize subscriptions before any other operations
      _playerStateSubscription = audioPlayerService.playerStateSubscription;
      _playerStateSubscription?.onData((playerState) {
        log('playerState: $playerState', name: 'SongCubit');
        maybeEmit(
          state.copyWith(
            playerState: playerState,
            status: SongStatus.updated,
          ),
        );
      });

      /// audio player subscriptions for position (throttled)
      _positionSubscription = audioPlayerService.positionSubscription;
      _positionSubscription?.onData((position) {
        log('position: $position', name: 'SongCubit');
        final now = DateTime.now();
        if (now.difference(_lastPositionEmit) >= _kMinPositionUpdateInterval) {
          log('position emitted: $position', name: 'SongCubit');
          _lastPositionEmit = now;
          maybeEmit(
            state.copyWith(
              position: position,
              status: SongStatus.updated,
            ),
          );
        }
      });

      /// audio player subscriptions for duration
      _durationSubscription = audioPlayerService.durationSubscription;
      _durationSubscription?.onData((duration) {
        log('duration: $duration', name: 'SongCubit');
        maybeEmit(
          state.copyWith(
            duration: duration,
            status: SongStatus.updated,
          ),
        );
      });

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

      final waveformData = await waveDataVisualizerService.getWaveformData(path);

      // check if tutorial is completed
      final isTutorialCompleted = localConfigRepository.hasCompletedTutorial;

      // Get initial position and duration
      final initialPosition = audioPlayerService.position;
      final initialDuration = audioPlayerService.duration;

      emit(
        state.copyWith(
          data: waveformData,
          status: SongStatus.loadSuccess,
          song: state.song,
          isTutorialCompleted: isTutorialCompleted,
          playerState: PlayerState(false, ProcessingState.ready),
          position: initialPosition,
          duration: initialDuration,
          error: null,
        ),
      );
    } catch (e, stackTrace) {
      unawaited(crashReportingRepository.reportError(e, stackTrace));

      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to initialize song: $e',
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
      if (state.playerState?.playing ?? false) {
        await audioPlayerService.pause();
      } else {
        // Check if we need to seek to loop start before playing
        if (state.isLoopModeEnabled && state.activeLoop != null) {
          final loop = state.activeLoop!;
          if (loop.start != null && loop.end != null) {
            final currentPosition = audioPlayerService.position;
            if (currentPosition < loop.start! || currentPosition > loop.end!) {
              log('Position outside loop boundaries, seeking to loop start before playing');
              await audioPlayerService.seek(loop.start!);
            }
          }
        }

        await audioPlayerService.play();
      }
    } catch (e, stackTrace) {
      unawaited(crashReportingRepository.reportError(e, stackTrace));
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to play audio file. The file format might not be supported: $e',
        ),
      );
    }
  }

  Future<void> stopSong() async {
    log('STOP song at ${state.position!.toFormattedString()}');

    _seekOperation?.cancel();

    await audioPlayerService.stop();
  }

  Future<void> pauseSong() async {
    log('PAUSE song at ${state.position?.toFormattedString()}');

    await audioPlayerService.pause();
  }

  Future<void> seekSong(Duration position) async {
    if (positionToSeek == position) return;

    positionToSeek = position;
    var newPosition = position;

    // Only seek if the position change is significant
    /* if (state.position != null &&
        (newPosition - state.position!).abs() <= const Duration(milliseconds: 100)) {
      log('SEEK song to $position skipped - change too small (<100ms)');
      return;
    } */

    if (newPosition == state.position || newPosition > state.song.duration) {
      log('SEEK song to $position skipped - position is out of range');
      return;
    }

    log('SEEK song to $position');
    // cancel any existing seek
    _seekOperation?.cancel();

    try {
      // Ensure position is within valid range
      if (newPosition < Duration.zero) {
        newPosition = Duration.zero;
      } else if (newPosition > state.song.duration) {
        newPosition = state.song.duration;
      }

      // Seek to position
      _seekOperation = CancelableOperation.fromFuture(audioPlayerService.seek(newPosition));
      await _seekOperation?.valueOrCancellation();

      // Update state immediately after successful seek
      emit(
        state.copyWith(
          status: SongStatus.updated,
          position: newPosition,
        ),
      );
    } on TimeoutException catch (e) {
      log('seek timeout: $e');
      return;
    } catch (e, stackTrace) {
      unawaited(crashReportingRepository.reportError(e, stackTrace));
      log('seek error: $e');
      emit(
        state.copyWith(
          status: SongStatus.error,
          position: positionToSeek,
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
    log('setLoopStart to ${state.position}');

    final activeLoop = state.activeLoop;
    if (activeLoop == null) return;

    // Get current position directly from audio player
    final currentPosition = audioPlayerService.position;

    log('setLoopStart to $currentPosition');

    final updatedLoop = activeLoop.copyWith(start: currentPosition);
    await updateLoop(updatedLoop);

    // Update the loop in the audio service if loop mode is enabled
    if (state.isLoopModeEnabled) {
      await audioPlayerService.updateActiveLoop(updatedLoop);
    }
  }

  /// Sets the end of a loop
  /// The end can only be placed after the start
  /// When the audio player is playing and looping already and a new end is set,
  /// the loop will be updated and the audio player will continue playing and
  /// as soon as the new end is reached, the loop will start over
  Future<void> setLoopEnd() async {
    log('setLoopEnd: ${state.activeLoop}');

    final activeLoop = state.activeLoop;
    final position = state.position;

    if (activeLoop == null) return;

    if (position == null) throw Exception('Position is null');

    // Get current position directly from audio player
    var endPosition = position;

    // Ensure end position is not greater than song duration
    if (endPosition > state.song.duration) {
      endPosition = state.song.duration;
    }

    log('setLoopEnd: got current position $endPosition');

    final updatedLoop = activeLoop.copyWith(end: endPosition);
    await updateLoop(updatedLoop);

    // Update the loop in the audio service if loop mode is enabled
    if (state.isLoopModeEnabled) {
      await audioPlayerService.updateActiveLoop(updatedLoop);
    }
  }

  void unselectLoop() {
    log('UNSELECT LOOP: ${state.activeLoop}');

    // Disable loop in audio service
    audioPlayerService.disableLoop();

    emit(
      state.copyWith(
        status: SongStatus.loopModeToggled,
        activeLoop: null,
        isLoopModeEnabled: false,
      ),
    );
  }

  Future<void> selectLoop(Loop loop) async {
    log('SELECT LOOP: $loop');
    emit(
      state.copyWith(
        status: SongStatus.updated,
      ),
    );

    if (loop.start == null) return;

    try {
      // Add timeout to audio operations
      // _seekOperation?.cancel();
      await audioPlayerService.pause();
      await audioPlayerService.seek(loop.start!);

      // Enable loop mode in audio service
      await audioPlayerService.enableLoop(loop);

      emit(
        state.copyWith(
          status: SongStatus.loopModeToggled,
          activeLoop: loop,
          isLoopModeEnabled: true,
          error: null,
          position: loop.start,
        ),
      );
    } catch (e, stackTrace) {
      unawaited(crashReportingRepository.reportError(e, stackTrace));

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
    emit(
      state.copyWith(
        status: SongStatus.updated,
        activeLoop: loop,
        isLoopModeEnabled: true,
      ),
    );

    Loop updatedLoop = loop;

    // if loop has no end set but is playing, set end to the duration of the song
    if (loop.end == null) {
      updatedLoop = loop.copyWith(end: state.song.duration);
      await updateLoop(updatedLoop);
    }

    // Enable loop mode in audio service
    await audioPlayerService.enableLoop(updatedLoop);

    final isPlaying = state.playerState?.playing ?? false;

    if (!isPlaying) {
      // Check if we need to seek to loop start before playing
      if (updatedLoop.start != null && updatedLoop.end != null) {
        final currentPosition = audioPlayerService.position;
        if (currentPosition < updatedLoop.start! || currentPosition > updatedLoop.end!) {
          log('Position outside loop boundaries, seeking to loop start before playing');
          await audioPlayerService.seek(updatedLoop.start!);
        }
      }

      await audioPlayerService.play();
    } else {
      await audioPlayerService.pause();
    }
  }

  void pauseLoop(Loop loop) {
    if (state.activeLoop == null) return;

    audioPlayerService.pause();
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

    final startPosition = state.position;

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

      final updatedSong = await songRepository.addLoopToSong(song: state.song, loop: loop);

      emit(
        state.copyWith(
          status: SongStatus.loopAdded,
          song: updatedSong,
          activeLoop: loop,
          isLoopModeEnabled: true,
        ),
      );

      // Enable loop mode in audio service for the new loop
      await audioPlayerService.enableLoop(loop);
    } catch (e, stackTrace) {
      unawaited(crashReportingRepository.reportError(e, stackTrace));
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to add loop: $e',
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
        ),
      );

      // Update the loop in the audio service if this is the active loop
      if (state.isLoopModeEnabled && state.activeLoop?.id == updatedLoop.id) {
        await audioPlayerService.updateActiveLoop(updatedLoop);
      }
    } catch (e, stackTrace) {
      unawaited(crashReportingRepository.reportError(e, stackTrace));
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to update loop: $e',
        ),
      );
    }
  }

  Future<void> deleteLoop(Loop loop) async {
    log('deleteLoop: $loop');
    try {
      final updatedSong = await songRepository.deleteLoopForSong(
        song: state.song,
        loop: loop,
      );

      if (loop == state.activeLoop) {
        // Disable loop mode in audio service
        await audioPlayerService.disableLoop();
        unselectLoop();
      }

      emit(
        state.copyWith(
          song: updatedSong,
          status: SongStatus.loopDeleted,
        ),
      );
    } catch (e, stackTrace) {
      unawaited(crashReportingRepository.reportError(e, stackTrace));
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to delete loop: $e',
        ),
      );
    }
  }

  Future<void> deleteSong() async {
    try {
      await songRepository.deleteSong(state.song);
      emit(
        state.copyWith(
          status: SongStatus.songDeleted,
          song: null,
        ),
      );
    } catch (e, stackTrace) {
      unawaited(crashReportingRepository.reportError(e, stackTrace));
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to delete song: $e',
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

    if (!state.isLoopModeEnabled) {
      // Disable loop mode in audio service
      await audioPlayerService.disableLoop();
    }
  }

  Future<void> back(int seconds) async {
    final position = state.position;

    // only seek if the position is greater than the duration
    if (position != null && position > Duration(seconds: seconds)) {
      final newPosition = position - Duration(seconds: seconds);

      await audioPlayerService.seek(newPosition);

      emit(state.copyWith(status: SongStatus.updated, position: newPosition));
    }
  }

  Future<void> forward(int seconds) async {
    log('forward: $seconds');
    final position = state.position;

    // only seek if the position is less than the duration
    if (position != null && position < state.song.duration - Duration(seconds: seconds)) {
      final newPosition = position + Duration(seconds: seconds);

      await audioPlayerService.seek(newPosition);

      emit(state.copyWith(status: SongStatus.updated, position: newPosition));
    }
  }

  // Add new method
  Future<void> updateSpeed(double newSpeed) async {
    await audioPlayerService.setSpeed(newSpeed);

    emit(
      state.copyWith(
        status: SongStatus.updated,
        speed: newSpeed,
      ),
    );
  }

  Future<void> updateLoopOrder(List<Loop> newLoops) async {
    try {
      final updatedSong = state.song.copyWith(loops: newLoops);
      await songRepository.updateSong(updatedSong);

      emit(
        state.copyWith(
          status: SongStatus.updated,
          song: updatedSong,
        ),
      );
    } catch (e, stackTrace) {
      unawaited(crashReportingRepository.reportError(e, stackTrace));
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to update loop order: $e',
        ),
      );
    }
  }
}
