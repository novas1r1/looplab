// ignore_for_file: avoid_redundant_argument_values

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:repeatlab/core/utils/duration_extension.dart';
import 'package:repeatlab/data/repositories/song_repository.dart';
import 'package:repeatlab/models/loop.dart';
import 'package:repeatlab/models/song.dart';

// part 'song_cubit.mapper.dart';
part 'song_cubit.mapper.dart';
part 'song_state.dart';

class SongCubit extends Cubit<SongState> {
  final SongRepository songRepository;
  final SoLoud soloud;
  final Song song;

  StreamSubscription<List<Song>>? _songSubscription;
  Timer? _positionTimer;

  // Add static cache map
  static final Map<String, Float32List> _waveformCache = {};

  bool get isPaused => state.handle == null || soloud.getPause(state.handle!);
  Duration get currentPosition =>
      state.handle == null ? Duration.zero : soloud.getPosition(state.handle!);

  SongCubit({
    required this.songRepository,
    required this.soloud,
    required this.song,
  }) : super(SongState(song: song)) {
    _songSubscription = songRepository.songs.listen((songs) {
      final updatedSong = songs.firstWhere(
        (localSong) => localSong.id == song.id,
        orElse: () => state.song,
      );

      emit(state.copyWith(status: SongStatus.updated, song: updatedSong));
    });
  }

  Stream<Duration> get positionStream {
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
  }

  @override
  Future<void> close() async {
    await _songSubscription?.cancel();
    _positionTimer?.cancel();

    if (state.handle != null) {
      soloud.setPause(state.handle!, true);
      await soloud.stop(state.handle!);
    }

    if (state.audioSource != null) {
      await soloud.disposeSource(state.audioSource!);
    }

    // Optional: Clear cache when cubit is closed
    // _waveformCache.remove(state.song.path);

    return super.close();
  }

  Future<void> initSong() async {
    emit(state.copyWith(status: SongStatus.loading));

    try {
      final file = File(state.song.path);
      if (!file.existsSync()) {
        throw Exception('File not found: ${state.song.path}');
      }

      // Check cache first
      Float32List? waveformData = _waveformCache[state.song.path];

      if (waveformData == null) {
        log('NO CACHE AVAILABLE FOR ${state.song.path}');
        // Only read bytes and generate waveform if not cached
        final bytes = await file.readAsBytes();
        waveformData = await soloud.readSamplesFromMem(
          bytes,
          200 * 10,
        );
        // Store in cache
        _waveformCache[state.song.path] = waveformData;
      }

      final source = await soloud.loadFile(state.song.path);
      final handle = await soloud.play(source, paused: true);

      emit(
        state.copyWith(
          audioSource: source,
          data: waveformData,
          status: SongStatus.loaded,
          handle: handle,
          song: state.song,
        ),
      );
    } catch (e, stackTrace) {
      log('Failed to initialize song: $e', stackTrace: stackTrace);
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to initialize song: $e',
        ),
      );
    }
  }

  void updatePosition(Duration position) {
    if (state.handle == null) return;

    // Debounce rapid seek operations
    Future.microtask(() {
      soloud.seek(state.handle!, position);
    });
  }

  Future<void> playSong() async {
    if (state.handle == null) {
      final handle = await soloud.play(state.audioSource!);
      emit(state.copyWith(status: SongStatus.updated, handle: handle));
    } else {
      soloud.setPause(state.handle!, false);
    }
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

  void unselectLoop() {
    emit(state.copyWith(status: SongStatus.updated, activeLoop: null));
  }

  void selectLoop(Loop loop) {
    emit(state.copyWith(status: SongStatus.updated, activeLoop: loop));

    if (state.handle == null || loop.start == null) return;

    // set active loop
    // set to current position
    soloud.setPause(state.handle!, true);
    soloud.seek(state.handle!, loop.start!);
  }

  void playLoop(Loop loop) {
    if (state.handle == null || loop.start == null) return;

    emit(
      state.copyWith(
        status: SongStatus.updated,
        activeLoop: loop,
        isLoopModeEnabled: true,
      ),
    );

    soloud.setPause(state.handle!, true);
    soloud.seek(state.handle!, loop.start!);
    soloud.setPause(state.handle!, false);

    // Optimize loop boundary checking
    _positionTimer?.cancel();
    _positionTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      // ~60fps
      if (state.activeLoop?.end == null) return;

      final position = soloud.getPosition(state.handle!);
      if (position >= state.activeLoop!.end!) {
        // Prevent potential audio glitch by doing seek only when necessary
        if (position - state.activeLoop!.end! >
            const Duration(milliseconds: 32)) {
          soloud.seek(state.handle!, state.activeLoop!.start!);
        }
      }
    });
  }

  void pauseLoop(Loop loop) {
    if (state.activeLoop == null) return;

    soloud.setPause(state.handle!, true);
    _positionTimer?.cancel();
  }

  void nextLoop() {
    // get current loop
    final currentLoop = state.activeLoop;

    // if not null get the next loop
    if (currentLoop != null) {
      final currentLoopIndex =
          state.song.loops.indexWhere((loop) => loop.id == currentLoop.id);
      final nextLoopIndex = currentLoopIndex + 1;
      // check if last loop
      if (nextLoopIndex >= state.song.loops.length) {
        // play the first loop
        final firstLoop = state.song.loops.first;
        playLoop(firstLoop);
      } else {
        final nextLoop = state.song.loops[nextLoopIndex];
        playLoop(nextLoop);
      }
    } else {
      // play the first loop
      final firstLoop = state.song.loops.first;
      playLoop(firstLoop);
    }
  }

  void previousLoop() {
    // get current loop
    final currentLoop = state.activeLoop;

    // if not null get the previous loop
    if (currentLoop != null) {
      final currentLoopIndex =
          state.song.loops.indexWhere((loop) => loop.id == currentLoop.id);
      final previousLoopIndex = currentLoopIndex - 1;
      // check if first loop
      if (previousLoopIndex < 0) {
        // play the last loop
        final lastLoop = state.song.loops.last;
        playLoop(lastLoop);
      } else {
        final previousLoop = state.song.loops[previousLoopIndex];
        playLoop(previousLoop);
      }
    }
  }

  Future<void> addLoop() async {
    log('ADDING LOOP: ${state.activeLoop}', name: 'SongCubit');
    try {
      // create a new loop
      final loop = Loop(
        id: state.song.loops.length,
        name: 'Loop ${state.song.loops.length + 1}',
        songId: state.song.id,
        // for each new loop assign a color based on LoopColor.values
        // for the first loop, first color, for the second loop, second color, etc.
        // if the number of loops is greater than the number of colors, start again from the first color
        color:
            LoopColor.values[state.song.loops.length % LoopColor.values.length],
        start: soloud.getPosition(state.handle!),
      );

      final updatedSong =
          await songRepository.addLoopToSong(song: state.song, loop: loop);

      emit(
        state.copyWith(
          status: SongStatus.loopAdded,
          song: updatedSong,
          activeLoop: loop,
        ),
      );
    } catch (e) {
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
        ),
      );
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to delete song: $e',
        ),
      );
    }
  }

  Future<void> toggleLoopMode() async {
    emit(state.copyWith(isLoopModeEnabled: !state.isLoopModeEnabled));
  }
}
