import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:looplab/core/utils/duration_extension.dart';
import 'package:looplab/data/repositories/loop_repository.dart';
import 'package:looplab/data/repositories/song_repository.dart';
import 'package:looplab/models/loop.dart';
import 'package:looplab/models/song.dart';

// part 'song_cubit.mapper.dart';
part 'song_state.dart';

class SongCubit extends Cubit<SongState> {
  final LoopRepository loopRepository;
  final SongRepository songRepository;
  final SoLoud soloud;
  final Song song;

  Timer? _positionTimer;

  bool get isPaused => state.handle == null || soloud.getPause(state.handle!);
  Duration get currentPosition =>
      state.handle == null ? Duration.zero : soloud.getPosition(state.handle!);

  SongCubit({
    required this.loopRepository,
    required this.songRepository,
    required this.soloud,
    required this.song,
  }) : super(const SongState());

  Stream<Duration> get positionStream => Stream.periodic(
        const Duration(milliseconds: 50),
        (_) {
          return (state.handle == null) ? Duration.zero : soloud.getPosition(state.handle!);
        },
      );

  @override
  Future<void> close() async {
    _positionTimer?.cancel();
    if (state.handle != null) {
      await soloud.stop(state.handle!);
    }

    if (state.audioSource != null) {
      soloud.disposeSource(state.audioSource!);
    }

    super.close();
  }

  Future<void> initSong() async {
    emit(state.copyWith(status: LoopStatus.loading));

    try {
      // check if file exists
      final file = File(song.path);
      if (!file.existsSync()) {
        throw Exception('File not found: ${song.path}');
      }

      final source = await soloud.loadFile(song.path);

      final bytes = file.readAsBytesSync();

      final data = await soloud.readSamplesFromMem(
        bytes,
        200 * 10,
      );

      emit(
        state.copyWith(
          audioSource: source,
          data: data,
          status: LoopStatus.loaded,
        ),
      );
    } catch (e, stackTrace) {
      log('Failed to initialize song: $e', stackTrace: stackTrace);
      emit(
        state.copyWith(
          status: LoopStatus.error,
          error: 'Failed to initialize song: $e',
        ),
      );
    }
  }

  void updatePosition(Duration position) {
    // _currentPlayerPosition = position;

    soloud.seek(state.handle!, position);
    // emit(state.copyWith(position: position));
  }

  Future<void> playSong() async {
    if (state.handle == null) {
      final handle = await soloud.play(state.audioSource!);
      emit(state.copyWith(handle: handle));
    }

    // Start the position timer
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      // if loop is active, check if the current position is greater than the end position
      if (state.activeLoop != null &&
          state.activeLoop!.start != null &&
          state.activeLoop!.end != null) {
        final position = soloud.getPosition(state.handle!);

        if (position >= state.activeLoop!.end!) {
          soloud.setPause(state.handle!, true);
          soloud.seek(state.handle!, state.activeLoop!.start!);
          soloud.setPause(state.handle!, false);
        }
      } else {
        log('seek to ${currentPosition.toFormattedString()}');
        soloud.seek(state.handle!, currentPosition);
        soloud.setPause(state.handle!, false);
      }
    });
  }

  Future<void> stopSong() async {
    _positionTimer?.cancel();
    await soloud.stop(state.handle!);
    log('STOP song at ${currentPosition.toFormattedString()}');
  }

  void pauseSong() {
    _positionTimer?.cancel();
    soloud.setPause(state.handle!, true);
    log('PAUSE song at ${currentPosition.toFormattedString()}');
  }

  void seekSong(Duration position) {
    soloud.seek(state.handle!, position);
    log('SEEK song to ${position.toFormattedString()}');
  }

  void resumeSong() {
    soloud.setPause(state.handle!, false);
    log('RESUME song at ${currentPosition.toFormattedString()}');
  }

  Future<void> setLoopStart() async {
    log('setLoopStart: ${state.activeLoop}');
    if (state.handle == null) return;

    // get current position
    final startPosition = soloud.getPosition(state.handle!);

    await updateLoop(state.activeLoop!.copyWith(start: startPosition));

    // check if active loop exists
    // if yes update start position
    // if no create a new loop

    /*
    Loop? loop = _currentLoop;

    // if loop is null, create a new one
    if (_currentLoop == null) {
      loop = Loop(
        id: const Uuid().v4(),
        name: 'Loop ${_loops.length + 1}',
        songId: widget.song.id,
        microsecondStart: _currentPlayerPosition.inMicroseconds,
        microsecondEnd: _currentPlayerPosition.inMicroseconds,
      );

      _loops.add(loop);
      setState(() => _currentLoop = loop);
    } else {
      final updatedLoop = _currentLoop!.copyWith(
        microsecondStart: _currentPlayerPosition.inMicroseconds,
      );

      setState(() => _currentLoop = updatedLoop);

      final currentLoopIndex = _loops.indexWhere((loop) => loop.id == _currentLoop?.id);

      if (currentLoopIndex == -1) return;

      // update the loop in the list
      setState(() {
        _loops[currentLoopIndex] = updatedLoop;
        _startPosition = Duration(microseconds: updatedLoop.microsecondStart);
      });
    */
  }

  Future<void> setLoopEnd() async {
    if (state.handle == null) return;

    log('setLoopEnd: ${state.activeLoop}');
    // get current position
    final endPosition = soloud.getPosition(state.handle!);

    await updateLoop(state.activeLoop!.copyWith(end: endPosition));
    // check if active loop exists
    // if yes update end position
    // if no create a new loop

    /* if (_currentLoop == null) return;

    final updatedLoop = _currentLoop!.copyWith(
      microsecondEnd: _currentPlayerPosition.inMicroseconds,
    );

    setState(() => _currentLoop = updatedLoop);

    final currentLoopIndex = _loops.indexWhere((loop) => loop.id == _currentLoop?.id);

    if (currentLoopIndex == -1) return;

    // update the loop in the list
    setState(() {
      _loops[currentLoopIndex] = updatedLoop;
      _endPosition = Duration(microseconds: updatedLoop.microsecondEnd);
    }); */
  }

  void selectLoop(Loop loop) {
    // set active loop
    emit(state.copyWith(activeLoop: loop));
  }

  void playLoop(Loop loop) {
    selectLoop(loop);
    // play the loop if start is not null
    if (loop.start != null) {
      soloud.seek(state.handle!, loop.start!);
      soloud.setPause(state.handle!, false);
    }
  }

  Future<void> loadLoops(String songId) async {
    emit(state.copyWith(status: LoopStatus.loading));

    try {
      final loops = await loopRepository.getLoopsBySongId(songId);
      emit(state.copyWith(loops: loops, status: LoopStatus.loaded));
    } catch (e) {
      emit(state.copyWith(error: 'Failed to load loops: $e'));
    }
  }

  void nextLoop() {
    // get current loop
    final currentLoop = state.activeLoop;

    // if not null get the next loop
    if (currentLoop != null) {
      final currentLoopIndex = state.loops.indexWhere((loop) => loop.id == currentLoop.id);
      final nextLoopIndex = currentLoopIndex + 1;
      // check if last loop
      if (nextLoopIndex >= state.loops.length) {
        // play the first loop
        final firstLoop = state.loops.first;
        playLoop(firstLoop);
      } else {
        final nextLoop = state.loops[nextLoopIndex];
        playLoop(nextLoop);
      }
    } else {
      // play the first loop
      final firstLoop = state.loops.first;
      playLoop(firstLoop);
    }
  }

  void previousLoop() {
    // get current loop
    final currentLoop = state.activeLoop;

    // if not null get the previous loop
    if (currentLoop != null) {
      final currentLoopIndex = state.loops.indexWhere((loop) => loop.id == currentLoop.id);
      final previousLoopIndex = currentLoopIndex - 1;
      // check if first loop
      if (previousLoopIndex < 0) {
        // play the last loop
        final lastLoop = state.loops.last;
        playLoop(lastLoop);
      } else {
        final previousLoop = state.loops[previousLoopIndex];
        playLoop(previousLoop);
      }
    }
  }

  Future<void> addLoop() async {
    try {
      // create a new loop
      final loop = Loop(
        name: 'Loop ${state.loops.length + 1}',
        songId: song.id,
      );

      final newLoop = await loopRepository.addLoop(loop);

      emit(
        state.copyWith(
          loops: [...state.loops, newLoop],
          activeLoop: newLoop,
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: 'Failed to add loop: $e'));
    }
  }

  Future<void> updateLoop(Loop updatedLoop) async {
    log('updateLoop: $updatedLoop');

    try {
      await loopRepository.updateLoop(updatedLoop);
      final updatedLoops =
          state.loops.map((loop) => loop.id == updatedLoop.id ? updatedLoop : loop).toList();

      emit(
        state.copyWith(
          loops: updatedLoops,
          activeLoop: updatedLoop,
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: 'Failed to update loop: $e'));
    }
  }
}
