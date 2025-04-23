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
import 'package:repeatlab/data/services/audio_service_handler.dart';
import 'package:repeatlab/data/services/audio_service_provider.dart';

// part 'song_cubit.mapper.dart';
part 'song_cubit.mapper.dart';
part 'song_state.dart';

class SongCubit extends Cubit<SongState> {
  final Song song;

  final SoLoud soloud;

  final SongRepository songRepository;
  final LocalConfigRepository localConfigRepository;
  final CrashReportingRepository crashReportingRepository;

  late final RepeatLabAudioHandler audioHandler;
  StreamSubscription<List<Song>>? _songSubscription;
  Timer? _positionTimer;

  // Add static cache map
  static final Map<String, Float32List> _waveformCache = {};

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;

  SongCubit({
    required this.song,
    required this.soloud,
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
    _positionTimer?.cancel();

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
      _playerStateSubscription = audioHandler.playerStateSubscription;
      _playerStateSubscription?.onData((playerState) {
        if (playerState == PlayerState.completed) {
          stopSong();
        }

        maybeEmit(
          state.copyWith(
            status: SongStatus.updated,
            playerState: playerState,
          ),
        );
      });

      /// audio player subscriptions for position
      _positionSubscription = audioHandler.positionSubscription;
      _positionSubscription?.onData((position) {
        maybeEmit(
          state.copyWith(
            position: position,
            status: SongStatus.updated,
          ),
        );
      });

      /// audio player subscriptions for duration
      _durationSubscription = audioHandler.durationSubscription;
      _durationSubscription?.onData((duration) {
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

      final waveformData = await _getWaveformData(path);

      // Initialize audio player with the file but keep it paused
      await audioHandler.playSong(state.song);
      await audioHandler.pause();

      // check if tutorial is completed
      final isTutorialCompleted = localConfigRepository.hasCompletedTutorial;

      // Get initial position and duration
      final initialPosition = await audioPlayer.getCurrentPosition();
      final initialDuration = await audioPlayer.getDuration();

      emit(
        state.copyWith(
          data: waveformData,
          status: SongStatus.loadSuccess,
          song: state.song,
          isTutorialCompleted: isTutorialCompleted,
          playerState: PlayerState.paused,
          position: initialPosition,
          duration: initialDuration,
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
    log('togglePlaySong state.playerState: ${state.playerState}');

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

    _positionTimer?.cancel();

    await audioHandler.stop();
  }

  Future<void> pauseSong() async {
    log('PAUSE song at ${state.position?.toFormattedString()}');
    _positionTimer?.cancel();

    await audioHandler.pause();
  }

  Future<void> seekSong(Duration position) async {
    log('SEEK song to $position');

    // seek to end position: this is a test!!!
    /* final endPosition = state.song.duration;
    try {
      await audioHandler.seek(endPosition);
    } catch (ex) {
      log('lol wtf');
    }

    emit(
      state.copyWith(
        status: SongStatus.updated,
        position: endPosition,
      ),
    );

    return; */

    if (position == state.position || position > state.song.duration) return;

    var positionToSeek = position;

    try {
      // Ensure position is within valid range
      if (positionToSeek < Duration.zero) {
        positionToSeek = Duration.zero;
      } else if (positionToSeek > state.song.duration) {
        positionToSeek = state.song.duration;
      }

      log('handler SEEK to $positionToSeek');
      // Seek to position
      await audioHandler.seek(positionToSeek);

      // Update state immediately after successful seek
      emit(
        state.copyWith(
          status: SongStatus.updated,
          position: positionToSeek,
        ),
      );
    } catch (e, stackTrace) {
      unawaited(crashReportingRepository.reportError(e, stackTrace));
      log('seek error: $e');
      // Try to recover by stopping and restarting playback
      /* final wasPlaying = state.playerState == PlayerState.playing;

      await audioHandler.stop();
      await audioHandler.playSong(state.song);
      if (!wasPlaying) {
        await audioHandler.pause();
      }
      // Try seek operation again
      await audioHandler.seek(position); */

      // Update state after recovery
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
    final currentPosition = await audioHandler.audioPlayer.getCurrentPosition();
    if (currentPosition == null) return;

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

    await updateLoop(activeLoop.copyWith(end: endPosition));
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
      await audioHandler.pause();
      await audioHandler.seek(loop.start!);
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

      // Try to reset audio player
      try {
        await audioHandler.stop();
        await audioHandler.playSong(state.song);
        await audioHandler.pause();
        await audioHandler.seek(loop.start!);
      } catch (e2) {
        // Ignore errors during cleanup
        log('Failed to recover from seek error: $e2', name: 'SongCubit');
      }
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

    // Use audio service for background playback with loop
    audioHandler.customAction('enableLoop', {'loop': loop});

    if (state.playerState != PlayerState.playing) {
      await audioHandler.play();

      if (state.position == null) return;

      // check if loop end is reached
      // if reached, start over
      if (loop.end != null && state.position! >= loop.end!) {
        await audioHandler.seek(loop.start!);
      }
    } else {
      await audioHandler.pause();
    }
  }

  void pauseLoop(Loop loop) {
    if (state.activeLoop == null) return;

    _positionTimer?.cancel();

    audioHandler.pause();
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
      // stop the song
      await pauseSong();
      // Disable loop mode in audio handler
      await audioHandler.customAction('disableLoop');
    }
  }

  Future<void> back(int seconds) async {
    final position = state.position;

    // only seek if the position is greater than the duration
    if (position != null && position > Duration(seconds: seconds)) {
      await audioHandler.seek(position - Duration(seconds: seconds));
    }
  }

  Future<void> forward(int seconds) async {
    log('forward: $seconds');
    final position = state.position;

    // only seek if the position is less than the duration
    if (position != null && position < state.song.duration - Duration(seconds: seconds)) {
      final newPosition = position + Duration(seconds: seconds);
      await audioHandler.seek(newPosition);
    }

    emit(state.copyWith(status: SongStatus.updated));
  }

  // Add new method
  Future<void> updateSpeed(double newSpeed) async {
    await audioHandler.setSpeed(newSpeed);

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
}
