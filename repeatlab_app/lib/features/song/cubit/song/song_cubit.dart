// ignore_for_file: avoid_redundant_argument_values

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:repeatlab/core/utils/cubit_extension.dart';
import 'package:repeatlab/core/utils/duration_extension.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/repositories/crash_reporting_repository.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
import 'package:repeatlab/data/repositories/song_repository.dart';

// part 'song_cubit.mapper.dart';
part 'song_cubit.mapper.dart';
part 'song_state.dart';

class SongCubit extends Cubit<SongState> {
  final Song song;

  final SoLoud soloud;
  final AudioPlayer audioPlayer;

  final SongRepository songRepository;
  final LocalConfigRepository localConfigRepository;
  final CrashReportingRepository crashReportingRepository;

  StreamSubscription<List<Song>>? _songSubscription;
  Timer? _positionTimer;

  // Add static cache map
  static final Map<String, Float32List> _waveformCache = {};

  // bool get isPaused => state.handle == null || soloud.getPause(state.handle!);
  // Duration get currentPosition =>
  //     state.handle == null ? Duration.zero : soloud.getPosition(state.handle!);

  SongCubit({
    required this.song,
    required this.audioPlayer,
    required this.soloud,
    required this.songRepository,
    required this.localConfigRepository,
    required this.crashReportingRepository,
  }) : super(SongState(song: song)) {
    // song data subscription
    _songSubscription = songRepository.songs.listen((songs) {
      final updatedSong = songs.firstWhere(
        (localSong) => localSong.id == song.id,
        orElse: () => state.song,
      );

      emit(state.copyWith(status: SongStatus.updated, song: updatedSong));
    });

    /// audio player subscriptions for playerstate
    playerStateSubscription = audioPlayer.onPlayerStateChanged.listen((event) {
      log('playerStateSubscription: $event');

      if (event == PlayerState.completed) {
        stopSong();
      }
      maybeEmit(state.copyWith(status: SongStatus.updated, playerState: event));
    });

    /// audio player subscriptions for position
    positionSubscription = audioPlayer.onPositionChanged.listen((event) {
      maybeEmit(state.copyWith(position: event));
    });

    /// audio player subscriptions for duration
    durationSubscription = audioPlayer.onDurationChanged.listen((event) {
      maybeEmit(state.copyWith(duration: event));
    });
  }

  /// AudioPlayer subscriptions
  StreamSubscription<PlayerState>? playerStateSubscription;
  StreamSubscription<Duration>? positionSubscription;
  StreamSubscription<Duration>? durationSubscription;

  /// Soloud subscriptions - not needed anymore
  /* Stream<Duration> get positionStream {
    // Create a broadcast stream to allow multiple listeners
    final controller = StreamController<Duration>.broadcast();

    Timer? timer;
    timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!controller.isClosed && state.handle != null) {
        final position = soloud.getPosition(state.handle!);
        controller.add(position);
      }
    });

    // Clean up when the stream is cancelled
    controller.onCancel = () {
      timer?.cancel();
      controller.close();
    };

    return controller.stream.distinct();
  } */

  @override
  Future<void> close() async {
    await audioPlayer.stop();

    await _songSubscription?.cancel();
    _positionTimer?.cancel();

    /// audio player subscriptions
    playerStateSubscription?.cancel();
    positionSubscription?.cancel();
    durationSubscription?.cancel();

    await audioPlayer.dispose();

    /* if (state.handle != null) {
      soloud.setPause(state.handle!, true);
      await soloud.stop(state.handle!);
    } */

    // Optional: Clear cache when cubit is closed
    // _waveformCache.remove(state.song.path);

    return super.close();
  }

  Future<void> initSong() async {
    emit(state.copyWith(status: SongStatus.loading));

    try {
      final path = await state.song.path;
      final file = File(path);

      if (!file.existsSync()) {
        crashReportingRepository.reportError(
          Exception('File not found: $path'),
          StackTrace.current,
        );
        emit(
          state.copyWith(
            status: SongStatus.loadError,
            error: 'File not found: $path',
          ),
        );
        return;
      }

      final waveformData = await _getWaveformData(path);

      // Initialize audio player with the file but keep it paused
      await audioPlayer.play(DeviceFileSource(path));
      await audioPlayer.pause();

      // check if tutorial is completed
      final isTutorialCompleted = localConfigRepository.hasCompletedTutorial;

      emit(
        state.copyWith(
          data: waveformData,
          status: SongStatus.loadSuccess,
          song: state.song,
          isTutorialCompleted: isTutorialCompleted,
        ),
      );
    } catch (e, stackTrace) {
      await crashReportingRepository.reportError(e, stackTrace);

      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to initialize song: $e',
        ),
      );
    }
  }

  Future<Float32List> _getWaveformData(String path) async {
    // Check cache first
    Float32List? waveformData = _waveformCache[path];

    if (waveformData == null) {
      log('NO CACHE AVAILABLE FOR $path');
      // Only read bytes and generate waveform if not cached
      final file = File(path);

      final bytes = await file.readAsBytes();
      waveformData = await soloud.readSamplesFromMem(
        bytes,
        200 * 10,
      );
      // Store in cache
      _waveformCache[path] = waveformData;
    }

    return waveformData;
  }

  Future<void> updateTutorialCompleted() async {
    await localConfigRepository.setHasCompletedTutorial(hasCompleted: true);

    emit(state.copyWith(isTutorialCompleted: true));
  }

  Future<void> togglePlaySong() async {
    log('togglePlaySong state.playerState: ${state.playerState}');

    final path = await state.song.path;

    try {
      switch (state.playerState) {
        case PlayerState.paused:
          await audioPlayer.resume();
        case PlayerState.playing:
          await audioPlayer.pause();
        case null:
        case PlayerState.stopped:
        case PlayerState.completed:
        case PlayerState.disposed:
          await audioPlayer.play(DeviceFileSource(path));
      }
    } catch (e, stackTrace) {
      crashReportingRepository.reportError(e, stackTrace);
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to play audio file. The file format might not be supported: $e',
        ),
      );
    }
  }

  Future<void> stopSong() async {
    _positionTimer?.cancel();
    // await soloud.stop(state.handle!);
    await audioPlayer.stop();
    log('STOP song at ${state.position!.toFormattedString()}');
  }

  Future<void> pauseSong() async {
    log('PAUSE song at ${state.position?.toFormattedString()}');
    _positionTimer?.cancel();
    // soloud.setPause(state.handle!, true);
    await audioPlayer.pause();
  }

  Future<void> seekSong(Duration position) async {
    try {
      final path = await state.song.path;

      // If player is not initialized or in an error state, reinitialize it
      if (state.playerState == null ||
          state.playerState == PlayerState.disposed ||
          state.playerState == PlayerState.stopped) {
        await audioPlayer.play(DeviceFileSource(path));
        await audioPlayer.pause();
      }

      // Add timeout to seek operation
      await audioPlayer.seek(position);
      log('SEEK song to ${position.toFormattedString()}');

      emit(state.copyWith(status: SongStatus.updated));
    } catch (e, stackTrace) {
      crashReportingRepository.reportError(e, stackTrace);
      // Try to recover by stopping and restarting playback
      final wasPlaying = state.playerState == PlayerState.playing;
      final path = await state.song.path;

      await audioPlayer.stop();
      await audioPlayer.play(DeviceFileSource(path));
      if (!wasPlaying) {
        await audioPlayer.pause();
      }
      // Try seek operation again
      await audioPlayer.seek(position);
    }
  }

  Future<void> setLoopStart() async {
    log('setLoopStart to ${state.position}');

    if (state.position == null || state.activeLoop == null) return;
    // if (state.handle == null) return;

    // // get current position
    // final startPosition = soloud.getPosition(state.handle!);

    final startPosition = state.position ?? Duration.zero;

    await updateLoop(state.activeLoop!.copyWith(start: startPosition));
  }

  Future<void> setLoopEnd() async {
    log('setLoopEnd: ${state.activeLoop}');
    // if (state.handle == null) return;

    // get current position
    // final endPosition = soloud.getPosition(state.handle!);

    final endPosition = await audioPlayer.getCurrentPosition();

    await updateLoop(state.activeLoop!.copyWith(end: endPosition));
  }

  void unselectLoop() {
    emit(
      state.copyWith(
        status: SongStatus.loopModeToggled,
        activeLoop: null,
        isLoopModeEnabled: false,
      ),
    );
  }

  Future<void> selectLoop(Loop loop) async {
    emit(
      state.copyWith(
        status: SongStatus.loopModeToggled,
        activeLoop: loop,
        isLoopModeEnabled: true,
      ),
    );

    if (loop.start == null) return;

    try {
      // Add timeout to audio operations
      await audioPlayer.pause();
      await audioPlayer.seek(loop.start!);
    } catch (e, stackTrace) {
      log('Failed to select loop: $e', name: 'SongCubit');
      crashReportingRepository.reportError(e, stackTrace);

      // Reset state on error
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to select loop. Please try again.',
          activeLoop: null,
          isLoopModeEnabled: false,
        ),
      );

      // Try to reset audio player
      try {
        final path = await state.song.path;
        await audioPlayer.stop();
        await audioPlayer.play(DeviceFileSource(path));
        await audioPlayer.pause();
        await audioPlayer.seek(loop.start!);
      } catch (e2) {
        // Ignore errors during cleanup
        log('Failed to recover from seek error: $e2', name: 'SongCubit');
      }
    }
  }

  Future<void> togglePlayLoop(Loop loop) async {
    // if (state.handle == null || loop.start == null) return;

    emit(
      state.copyWith(
        status: SongStatus.updated,
        activeLoop: loop,
        isLoopModeEnabled: true,
      ),
    );

    // soloud.setPause(state.handle!, true);
    // soloud.seek(state.handle!, loop.start!);
    // soloud.setPause(state.handle!, false);

    // // Optimize loop boundary checking
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      // ~60fps
      if (state.activeLoop?.end == null) return;

      final position = state.position;
      if (position != null && position >= state.activeLoop!.end!) {
        // Prevent potential audio glitch by doing seek only when necessary
        if (position - state.activeLoop!.end! > const Duration(milliseconds: 32)) {
          audioPlayer.seek(state.activeLoop!.start!);
        }
      }
    });

    if (state.playerState != PlayerState.playing) {
      await audioPlayer.resume();

      if (state.position == null) return;

      // check if loop end is reached
      // if reached, start over
      if (loop.end != null && state.position! >= loop.end!) {
        await audioPlayer.seek(loop.start!);
      }
    } else {
      await audioPlayer.pause();
    }
  }

  void pauseLoop(Loop loop) {
    if (state.activeLoop == null) return;

    _positionTimer?.cancel();

    audioPlayer.pause();
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

    final startPosition = await audioPlayer.getCurrentPosition();

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
    } catch (e, stackTrace) {
      crashReportingRepository.reportError(e, stackTrace);
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
    } catch (e, stackTrace) {
      crashReportingRepository.reportError(e, stackTrace);
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
        unselectLoop();
      }

      emit(
        state.copyWith(
          song: updatedSong,
          status: SongStatus.loopDeleted,
        ),
      );
    } catch (e, stackTrace) {
      crashReportingRepository.reportError(e, stackTrace);
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
      crashReportingRepository.reportError(e, stackTrace);
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
      // stop the song
      pauseSong();
    }
  }

  Future<void> back(int seconds) async {
    final position = state.position;

    // only seek if the position is greater than the duration
    if (position != null && position > Duration(seconds: seconds)) {
      await audioPlayer.seek(position - Duration(seconds: seconds));
    }
  }

  Future<void> forward(int seconds) async {
    log('forward: $seconds');
    final position = state.position;

    // only seek if the position is less than the duration
    if (position != null && position < state.song.duration - Duration(seconds: seconds)) {
      final newPosition = position + Duration(seconds: seconds);
      await audioPlayer.seek(newPosition);
    }

    emit(state.copyWith(status: SongStatus.updated));
  }

  // Add new method
  Future<void> updateSpeed(double newSpeed) async {
    await audioPlayer.setPlaybackRate(newSpeed);

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
      crashReportingRepository.reportError(e, stackTrace);
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to update loop order: $e',
        ),
      );
    }
  }
}
