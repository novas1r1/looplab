// ignore_for_file: avoid_redundant_argument_values

import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/cubit_extension.dart';
import 'package:repeatlab/core/utils/musical_key.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/repositories/crash_reporting_repository.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
import 'package:repeatlab/data/repositories/song_repository.dart';
import 'package:repeatlab/data/services/audio_service_provider.dart';
import 'package:repeatlab/data/services/media_player_handler.dart';
import 'package:repeatlab/data/services/repeatlab_audioplayers_service_handler.dart';

// part 'song_cubit.mapper.dart';
part 'song_cubit.mapper.dart';
part 'song_state.dart';

class SongCubit extends Cubit<SongState> {
  final Song song;

  final SongRepository songRepository;
  final LocalConfigRepository localConfigRepository;
  final CrashReportingRepository crashReportingRepository;

  static const double _minPlaybackSpeed = 0.5;
  static const double _maxPlaybackSpeed = 2.0;

  /// Highest BPM the speed controls support. Values above this (e.g. from the
  /// free-form BPM field) must be capped: otherwise the min/max bound
  /// calculation would pass an inverted range to `clamp`, throwing
  /// ArgumentError. See FLUTTER-B8.
  static const int _maxSupportedBpm = 400;

  /// Active media handler. Concretely a [RepeatlabAudioplayersServiceHandler]
  /// for audio songs (set in [initSong]) or a [VideoPlayerHandler] for video
  /// songs (set in `VideoSongCubit.initVideo`). All cubit/widget code goes
  /// through the [MediaPlayerHandler] interface.
  ///
  /// Nullable backing field: the cubit can be closed before init assigns the
  /// handler (user pops the page while `AudioService.init` is still awaiting),
  /// so [close] must be able to tell whether a handler exists at all.
  MediaPlayerHandler? _audioHandler;
  MediaPlayerHandler get audioHandler => _audioHandler!;
  StreamSubscription<List<Song>>? _songSubscription;

  Stream<PlayerState>? playerStateStream;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  Stream<Duration>? positionStream;
  StreamSubscription<Duration>? _positionSubscription;

  Stream<Duration>? durationStream;
  StreamSubscription<Duration>? _durationSubscription;

  StreamController<List<Loop>>? loopsStreamController;
  StreamSubscription<List<Loop>>? _loopsSubscription;

  /// Subscription for navigation events from the audio handler (skip prev/next buttons)
  StreamSubscription<LoopNavigationEvent>? _navigationSubscription;

  Duration? positionToSeek;

  Future<Duration> get position async => await audioHandler.position;

  SongCubit({
    required this.song,
    required this.songRepository,
    required this.localConfigRepository,
    required this.crashReportingRepository,
  }) : super(SongState(song: song)) {
    loopsStreamController = StreamController<List<Loop>>.broadcast();
    // clear the stream
    loopsStreamController?.stream.drain();
    _loopsSubscription = loopsStreamController?.stream.listen((loops) {
      emit(state.copyWith(song: state.song.copyWith(loops: loops)));
    });
  }

  @override
  Future<void> close() async {
    // The handler may not exist yet if the page was popped mid-init.
    final handler = _audioHandler;

    if (handler != null && state.playerState == PlayerState.playing) {
      await stopSong();
    }

    await _songSubscription?.cancel();
    await _loopsSubscription?.cancel();
    await _navigationSubscription?.cancel();
    // For audio songs the handler is an app-lifetime singleton with broadcast
    // streams — without cancelling, this page's listeners keep firing after
    // close (emit-after-close StateError, stray stopSong on the next song).
    await _playerStateSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _durationSubscription?.cancel();

    // Clean up audio service if available
    await handler?.stop();

    return super.close();
  }

  /// Handle navigation events from the audio handler (notification/Bluetooth controls)
  /// These events come from external sources, so we call the direct methods
  /// to avoid recursion (skip methods call audio handler which emits events again)
  void _handleNavigationEvent(LoopNavigationEvent event) {
    dev.log('Navigation event received: $event');
    switch (event) {
      case LoopNavigationEvent.restartCurrentLoop:
        // Audio handler already handled the restart via _restartCurrentPlayback()
        break;
      case LoopNavigationEvent.previousLoop:
        previousLoop(); // Direct call to avoid recursion
      case LoopNavigationEvent.nextLoop:
        nextLoop(); // Direct call to avoid recursion
    }
  }

  /// Skip to previous loop or restart current playback.
  /// Called from skip previous button (UI and notification).
  /// Uses audio handler's double-tap detection for consistent behavior.
  Future<void> skipToPreviousOrRestart() async {
    dev.log('skipToPreviousOrRestart');
    try {
      // Use audio handler's skipToPrevious which has double-tap detection
      // Single tap: restarts current loop/song
      // Double tap: goes to previous loop (via navigation event)
      await audioHandler.skipToPrevious();
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to skip to previous: $ex',
        ),
      );
    }
  }

  /// Skip to the previous loop in the list.
  /// Called on double-tap of skip previous button.
  Future<void> skipToPreviousLoop() async {
    dev.log('skipToPreviousLoop');
    if (state.song.loops.isEmpty) return;

    previousLoop();
  }

  /// Skip to the next loop in the list.
  /// Called from skip next button (UI and notification).
  Future<void> skipToNextLoop() async {
    dev.log('skipToNextLoop');
    try {
      // Use audio handler's skipToNext for consistent behavior
      await audioHandler.skipToNext();
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to skip to next: $ex',
        ),
      );
    }
  }

  /// Toggle full song repeat mode
  Future<void> toggleFullSongRepeat() async {
    final newValue = !state.isFullSongRepeatEnabled;

    try {
      await audioHandler.customAction('setFullSongRepeat', {
        'enabled': newValue,
      });
      await localConfigRepository.setFullSongRepeatEnabled(isEnabled: newValue);

      emit(
        state.copyWith(
          status: SongStatus.updated,
          isFullSongRepeatEnabled: newValue,
          error: null,
        ),
      );
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to toggle full song repeat: $ex',
        ),
      );
    }
  }

  /// Toggle auto-play when selecting loops or navigating between them
  Future<void> toggleAutoPlay() async {
    final newValue = !state.isAutoPlayEnabled;

    try {
      await localConfigRepository.setAutoPlayOnLoopSelect(isEnabled: newValue);

      emit(
        state.copyWith(
          status: SongStatus.updated,
          isAutoPlayEnabled: newValue,
          error: null,
        ),
      );
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to toggle auto-play: $ex',
        ),
      );
    }
  }

  Future<void> initSong(AudioPlayer audioPlayer) async {
    try {
      final handler = await AudioServiceProvider.init(audioPlayer);
      await initWithHandler(handler);
    } catch (ex, stack) {
      // Without this catch an AudioService.init failure is an unhandled
      // exception and no state is emitted — the page spins forever.
      unawaited(crashReportingRepository.reportError(ex, stack));
      maybeEmit(
        state.copyWith(
          status: SongStatus.loadError,
          error: 'Failed to initialize audio service: $ex',
        ),
      );
    }
  }

  /// Shared init body used by both audio (via [initSong]) and video (via
  /// `VideoSongCubit.initVideo`). The caller is responsible for constructing
  /// the right [MediaPlayerHandler] implementation.
  ///
  /// Subclasses (e.g. `VideoSongCubit`) call this from their own init method.
  Future<void> initWithHandler(MediaPlayerHandler handler) async {
    emit(state.copyWith(status: SongStatus.loading));

    try {
      // Cancel any existing subscriptions before reinitializing
      await _playerStateSubscription?.cancel();
      await _positionSubscription?.cancel();
      await _durationSubscription?.cancel();

      // Assign the media handler.
      _audioHandler = handler;

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

      // Initialize audio player with the file but keep it paused.
      // autoStart: false loads the source without starting playback, so the
      // user doesn't hear a brief blip when opening a song.
      // Note: playSong automatically resets speed to 1.0 and pitch to 0 for
      // each new song.
      await audioHandler.playSong(state.song, autoStart: false);

      // Restore the persisted per-song pitch (unlike speed, pitch survives
      // song reopen). If the platform rejects it, stay at 0.
      var appliedPitch = 0;
      final persistedPitch = state.song.pitchSemitones.clamp(
        minPitchSemitones,
        maxPitchSemitones,
      );
      if (persistedPitch != 0 && isPitchControlSupported) {
        if (await audioHandler.setPitchSemitones(persistedPitch)) {
          appliedPitch = persistedPitch;
        }
      }

      // check if tutorial is completed
      final isTutorialCompleted = localConfigRepository.hasCompletedTutorial;

      // load auto-play setting
      final isAutoPlayEnabled = localConfigRepository.autoPlayOnLoopSelect;

      // load full song repeat setting
      final isFullSongRepeatEnabled =
          localConfigRepository.fullSongRepeatEnabled;

      // we need to disable loop mode here because the audio handler is not initialized yet
      await audioHandler.customAction('disableLoop');

      // Apply full song repeat setting to audio handler
      await audioHandler.customAction('setFullSongRepeat', {
        'enabled': isFullSongRepeatEnabled,
      });

      // Sync loops with audio handler for navigation
      await audioHandler.customAction('setLoops', {'loops': state.song.loops});

      // Listen to navigation events from notification/Bluetooth controls
      _navigationSubscription = audioHandler.navigationEvents.listen(
        _handleNavigationEvent,
      );

      // Initialize speed control state - always reset to 1.0 on song open.
      // Cap a persisted BPM to the supported range; older songs may have stored
      // an out-of-range value that would make the bound calculation throw.
      final rawBpm = state.song.bpm;
      final songBpm = (rawBpm != null && rawBpm > _maxSupportedBpm)
          ? _maxSupportedBpm
          : rawBpm;
      int? initialMinBpm;
      int? initialMaxBpm;
      if (songBpm != null && songBpm > 0) {
        initialMinBpm = (songBpm * 0.5).round().clamp(1, songBpm);
        initialMaxBpm = (songBpm * 2.0).round().clamp(
          songBpm,
          _maxSupportedBpm,
        );
      }

      emit(
        state.copyWith(
          status: SongStatus.loadSuccess,
          song: state.song,
          isTutorialCompleted: isTutorialCompleted,
          isAutoPlayEnabled: isAutoPlayEnabled,
          isFullSongRepeatEnabled: isFullSongRepeatEnabled,
          playerState: PlayerState.paused,
          // Speed control state - reset to 1.0 on song open
          speed: 1.0,
          tempoMode: TempoMode.multiplier,
          originalBpm: songBpm,
          currentBpm: songBpm, // Start at original BPM (speed 1.0)
          minBpm: initialMinBpm,
          maxBpm: initialMaxBpm,
          // Pitch is restored from the song, unlike speed; the mode resets
          pitchSemitones: appliedPitch,
          pitchMode: PitchMode.semitones,
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
    dev.log('togglePlaySong state.playerState was: ${state.playerState}');

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
          // This resets speed to 1.0 and pitch to 0, so sync UI state
          await audioHandler.playSong(state.song);
          _syncSpeedStateAfterSongReload();
          await _reapplyPitchAfterSongReload();
        case null:
          // Initialize the audio handler if it's null
          // This resets speed to 1.0 and pitch to 0, so sync UI state
          await audioHandler.playSong(state.song);
          _syncSpeedStateAfterSongReload();
          await _reapplyPitchAfterSongReload();
      }
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(
        state.copyWith(
          status: SongStatus.error,
          error:
              'Failed to play audio file. The file format might not be supported: $ex',
        ),
      );
    }
  }

  /// Syncs the UI speed state after the audio handler resets speed to 1.0
  /// This happens when playSong is called to reinitialize from stopped/completed state
  void _syncSpeedStateAfterSongReload() {
    dev.log('Syncing speed state after song reload', name: 'SongCubit');
    emit(
      state.copyWith(
        speed: 1.0,
        currentBpm: state.originalBpm, // Reset to original BPM if set
      ),
    );
  }

  /// Reapplies the current pitch after the audio handler reset it to 0 in
  /// playSong (unlike speed, pitch should survive a song reload). Reverts the
  /// UI state to 0 if the platform rejects the change.
  Future<void> _reapplyPitchAfterSongReload() async {
    if (state.pitchSemitones == 0 || !isPitchControlSupported) return;

    final success = await audioHandler.setPitchSemitones(state.pitchSemitones);
    if (!success) {
      dev.log(
        'Failed to reapply pitch after song reload, reverting to 0',
        name: 'SongCubit',
      );
      emit(state.copyWith(pitchSemitones: 0));
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
    } catch (ex) {
      // disabled crash reporting because its happening too often
      // unawaited(crashReportingRepository.reportError(ex, stack));
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
    // dev.log('setLoopStart to ${state.position}');

    final activeLoop = state.activeLoop;
    if (activeLoop == null) return;

    // Get current position directly from audio player
    final currentPosition = await position;

    dev.log('setLoopStart to $currentPosition');

    await updateLoop(activeLoop.copyWith(start: currentPosition));
  }

  /// Sets the end of a loop
  /// The end can only be placed after the start
  /// When the audio player is playing and looping already and a new end is set,
  /// the loop will be updated and the audio player will continue playing and
  /// as soon as the new end is reached, the loop will start over
  Future<void> setLoopEnd() async {
    dev.log('setLoopEnd: ${state.activeLoop}');

    final activeLoop = state.activeLoop;
    if (activeLoop == null) return;

    try {
      // Get current position directly from audio player
      var endPosition = await position;

      // Ensure end position is not greater than song duration
      if (endPosition > state.song.duration) {
        endPosition = state.song.duration;
      }

      dev.log('setLoopEnd: got current position $endPosition');

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
    dev.log('UNSELECT LOOP: ${state.activeLoop}');
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
    dev.log('SELECT LOOP: $loop');
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

      // Auto-play the loop if enabled
      if (state.isAutoPlayEnabled) {
        await audioHandler.play();
      }
    } on TimeoutException catch (ex) {
      emit(
        state.copyWith(
          status: SongStatus.error,
          error:
              'Failed to select loop because start position could not be seeked: $ex',
          activeLoop: null,
          isLoopModeEnabled: false,
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
        } else if (updatedLoop.start != null &&
            currentPosition < updatedLoop.start!) {
          await audioHandler.seek(updatedLoop.start!);
        }
      } else {
        await audioHandler.pause();
      }
    } on TimeoutException catch (ex) {
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to toggle play loop: $ex',
        ),
      );
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
      final currentLoopIndex = state.song.loops.indexWhere(
        (loop) => loop.id == currentLoop.id,
      );
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
      final currentLoopIndex = state.song.loops.indexWhere(
        (loop) => loop.id == currentLoop.id,
      );
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
    dev.log('ADDING LOOP: ${state.activeLoop}', name: 'SongCubit');

    final startPosition = await position;

    try {
      // Loop ids must be unique per song: update/delete match by id, so a
      // duplicate id would corrupt other loops. `loops.length` is not unique
      // once a loop has been deleted — use max(id) + 1 instead.
      final nextId = state.song.loops.isEmpty
          ? 0
          : state.song.loops.map((l) => l.id).reduce((a, b) => a > b ? a : b) +
                1;

      // create a new loop
      final loop = Loop(
        id: nextId,
        name: 'Loop ${nextId + 1}',
        songId: state.song.id,
        // for each new loop assign a color based on LoopColor.values
        // for the first loop, first color, for the second loop, second color, etc.
        // if the number of loops is greater than the number of colors, start again from the first color
        color: LoopColor.values[nextId % LoopColor.values.length],
        start: startPosition,
      );

      final updatedSong = await songRepository.addLoopToSong(
        song: state.song,
        loop: loop,
      );

      loopsStreamController?.add([...state.song.loops, loop]);

      // Sync loops with audio handler for navigation
      await audioHandler.customAction('setLoops', {'loops': updatedSong.loops});

      emit(
        state.copyWith(
          status: SongStatus.loopAdded,
          song: updatedSong,
          activeLoop: loop,
          isLoopModeEnabled: true,
          error: null,
        ),
      );

      // Activation analytics: a loop was actually created (vs. just tapping
      // "add loop"). `loop_count` is the total loops on the song afterwards.
      AppAnalytics.trackEvent(
        AppAnalytics.loopCreated,
        data: {'loop_count': updatedSong.loops.length},
      );
      await _trackFirstLoopIfNeeded();
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

  /// Fires the `first_loop_created` activation event exactly once per install.
  Future<void> _trackFirstLoopIfNeeded() async {
    if (localConfigRepository.firstLoopTracked) return;
    AppAnalytics.trackEvent(AppAnalytics.firstLoopCreated);
    await localConfigRepository.markFirstLoopTracked();
  }

  Future<void> updateLoop(Loop updatedLoop) async {
    dev.log('updateLoop: $updatedLoop');
    emit(state.copyWith(status: SongStatus.updating));

    try {
      final updatedSong = await songRepository.updateLoopForSong(
        song: state.song,
        loop: updatedLoop,
      );

      loopsStreamController?.add(updatedSong.loops);

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
    dev.log('deleteLoop: $loop');
    emit(state.copyWith(status: SongStatus.updating));

    try {
      final updatedSong = await songRepository.deleteLoopForSong(
        song: state.song,
        loop: loop,
      );

      loopsStreamController?.add(updatedSong.loops);

      // Sync loops with audio handler for navigation
      await audioHandler.customAction('setLoops', {'loops': updatedSong.loops});

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
      loopsStreamController?.close();
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

  Future<void> updateSongDetails({
    required String title,
    required String artist,
    required int? bpm,
    required String? musicalKey,
  }) async {
    final bpmChanged = bpm != state.song.bpm;

    emit(state.copyWith(status: SongStatus.updating));

    try {
      // Build the updated song. For BPM and musical key we must construct a
      // new Song directly because dart_mappable's copyWith cannot distinguish
      // null (clear) from not-provided when the field is nullable.
      final updatedSong = Song(
        id: state.song.id,
        title: title,
        artist: artist,
        fileName: state.song.fileName,
        duration: state.song.duration,
        bpm: bpm,
        currentBpm: state.song.currentBpm,
        pitchSemitones: state.song.pitchSemitones,
        musicalKey: musicalKey,
        loops: state.song.loops,
        loopSort: state.song.loopSort,
        sortOrder: state.song.sortOrder,
        mediaType: state.song.mediaType,
        videoSizeMode: state.song.videoSizeMode,
      );
      await songRepository.updateSong(updatedSong);

      emit(
        state.copyWith(
          status: SongStatus.updated,
          song: updatedSong,
          error: null,
        ),
      );

      // Update BPM-related speed state if BPM changed
      if (bpmChanged) {
        await setOriginalBpm(bpm);
      }
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to update song details: $ex',
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
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to toggle loop mode: $ex',
        ),
      );
    }
  }

  Future<void> back(int seconds) async {
    dev.log('back: $seconds');
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
    dev.log('forward: $seconds');
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

  // ==================== SPEED CONTROL METHODS ====================

  /// Switch between multiplier mode (0.5x-2.0x) and BPM mode
  void setTempoMode(TempoMode mode) {
    dev.log('setTempoMode: $mode', name: 'SongCubit');
    emit(state.copyWith(tempoMode: mode));
  }

  /// Update speed using a multiplier value (0.5 to 2.0).
  /// If originalBpm is set, also updates currentBpm accordingly.
  /// Returns true if speed was applied successfully, false otherwise.
  Future<bool> setSpeedByMultiplier(double multiplier) async {
    dev.log('setSpeedByMultiplier: $multiplier', name: 'SongCubit');

    try {
      final normalizedSpeed = multiplier.clamp(
        _minPlaybackSpeed,
        _maxPlaybackSpeed,
      );
      // Round to 1 decimal place
      final roundedSpeed =
          double.tryParse(normalizedSpeed.toStringAsFixed(1)) ?? 1.0;

      // Apply speed to audio handler
      final success = await audioHandler.setSpeed(roundedSpeed);

      if (!success) {
        dev.log(
          'Speed change failed, reverting UI to actual speed',
          name: 'SongCubit',
        );
        // Get the actual speed from audio handler
        final actualSpeed = audioHandler.currentPlaybackSpeed;
        int? actualBpm;
        if (state.originalBpm != null) {
          actualBpm = (state.originalBpm! * actualSpeed).round();
        }
        emit(
          state.copyWith(
            status: SongStatus.speedChangeFailed,
            speed: actualSpeed,
            currentBpm: actualBpm,
            error: 'Speed change failed. Please try again.',
          ),
        );
        return false;
      }

      // Calculate currentBpm if originalBpm is set
      int? newCurrentBpm;
      if (state.originalBpm != null) {
        newCurrentBpm = (state.originalBpm! * roundedSpeed).round();
      }

      emit(
        state.copyWith(
          status: SongStatus.updated,
          speed: roundedSpeed,
          currentBpm: newCurrentBpm,
          error: null,
        ),
      );
      return true;
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      dev.log('Failed to set speed by multiplier: $ex', name: 'SongCubit');
      // Revert to actual speed on error
      final actualSpeed = audioHandler.currentPlaybackSpeed;
      int? actualBpm;
      if (state.originalBpm != null) {
        actualBpm = (state.originalBpm! * actualSpeed).round();
      }
      emit(
        state.copyWith(
          status: SongStatus.speedChangeFailed,
          speed: actualSpeed,
          currentBpm: actualBpm,
          error: 'Speed change failed. Please try again.',
        ),
      );
      return false;
    }
  }

  /// Update speed using a BPM value.
  /// Requires originalBpm to be set. Calculates speed as currentBpm/originalBpm.
  /// Returns true if speed was applied successfully, false otherwise.
  Future<bool> setSpeedByBpm(int bpm) async {
    dev.log('setSpeedByBpm: $bpm', name: 'SongCubit');

    if (state.originalBpm == null || state.originalBpm! <= 0) {
      dev.log(
        'Cannot set speed by BPM: originalBpm not set',
        name: 'SongCubit',
      );
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Original BPM must be set first',
        ),
      );
      return false;
    }

    try {
      // Calculate speed from BPM ratio
      final speed = bpm / state.originalBpm!;
      final normalizedSpeed = speed.clamp(_minPlaybackSpeed, _maxPlaybackSpeed);
      final roundedSpeed =
          double.tryParse(normalizedSpeed.toStringAsFixed(2)) ?? 1.0;

      // Apply speed to audio handler
      final success = await audioHandler.setSpeed(roundedSpeed);

      if (!success) {
        dev.log(
          'Speed change failed, reverting UI to actual speed',
          name: 'SongCubit',
        );
        final actualSpeed = audioHandler.currentPlaybackSpeed;
        final actualBpm = (state.originalBpm! * actualSpeed).round();
        emit(
          state.copyWith(
            status: SongStatus.speedChangeFailed,
            speed: actualSpeed,
            currentBpm: actualBpm,
            error: 'Speed change failed. Please try again.',
          ),
        );
        return false;
      }

      emit(
        state.copyWith(
          status: SongStatus.updated,
          speed: roundedSpeed,
          currentBpm: bpm,
          error: null,
        ),
      );
      return true;
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      dev.log('Failed to set speed by BPM: $ex', name: 'SongCubit');
      final actualSpeed = audioHandler.currentPlaybackSpeed;
      final actualBpm = (state.originalBpm! * actualSpeed).round();
      emit(
        state.copyWith(
          status: SongStatus.speedChangeFailed,
          speed: actualSpeed,
          currentBpm: actualBpm,
          error: 'Speed change failed. Please try again.',
        ),
      );
      return false;
    }
  }

  /// Set or clear the original BPM for the song.
  /// When set, calculates min/max BPM bounds and sets currentBpm to originalBpm.
  /// When cleared (null), clears all BPM-related state.
  Future<void> setOriginalBpm(int? bpm) async {
    dev.log('setOriginalBpm: $bpm', name: 'SongCubit');

    // Cap to the supported range. The free-form BPM field can yield values far
    // above what the speed controls support; without capping, the min/max bound
    // calculation below would pass an inverted range to clamp and throw
    // (FLUTTER-B8).
    final effectiveBpm = (bpm != null && bpm > _maxSupportedBpm)
        ? _maxSupportedBpm
        : bpm;

    try {
      // Persist to song model
      final updatedSong = state.song.copyWith(bpm: effectiveBpm);
      await songRepository.updateSong(updatedSong);

      if (effectiveBpm != null && effectiveBpm > 0) {
        // Calculate BPM bounds (0.5x to 2.0x of original)
        final minBpm = (effectiveBpm * 0.5).round().clamp(1, effectiveBpm);
        final maxBpm = (effectiveBpm * 2.0).round().clamp(
          effectiveBpm,
          _maxSupportedBpm,
        );

        emit(
          state.copyWith(
            status: SongStatus.updated,
            song: updatedSong,
            originalBpm: effectiveBpm,
            currentBpm: effectiveBpm,
            minBpm: minBpm,
            maxBpm: maxBpm,
            speed: 1.0, // Reset speed to 1.0 when setting original BPM
            error: null,
          ),
        );

        // Reset audio handler speed to 1.0
        await audioHandler.setSpeed(1.0);
      } else {
        // Clear all BPM-related state
        emit(
          state.copyWith(
            status: SongStatus.updated,
            song: updatedSong,
            originalBpm: null,
            currentBpm: null,
            minBpm: null,
            maxBpm: null,
            error: null,
          ),
        );
      }
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      dev.log('Failed to set original BPM: $ex', name: 'SongCubit');
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to set original BPM: $ex',
        ),
      );
    }
  }

  /// Reset speed to 1.0 (original tempo).
  /// If originalBpm is set, also resets currentBpm to originalBpm.
  /// Returns true if speed was reset successfully, false otherwise.
  Future<bool> resetSpeed() async {
    dev.log('resetSpeed', name: 'SongCubit');

    try {
      final success = await audioHandler.setSpeed(1.0);

      if (!success) {
        dev.log('Speed reset failed', name: 'SongCubit');
        final actualSpeed = audioHandler.currentPlaybackSpeed;
        int? actualBpm;
        if (state.originalBpm != null) {
          actualBpm = (state.originalBpm! * actualSpeed).round();
        }
        emit(
          state.copyWith(
            status: SongStatus.speedChangeFailed,
            speed: actualSpeed,
            currentBpm: actualBpm,
            error: 'Speed reset failed. Please try again.',
          ),
        );
        return false;
      }

      emit(
        state.copyWith(
          status: SongStatus.updated,
          speed: 1.0,
          currentBpm:
              state.originalBpm, // Reset to original if set, null otherwise
          error: null,
        ),
      );
      return true;
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      dev.log('Failed to reset speed: $ex', name: 'SongCubit');
      final actualSpeed = audioHandler.currentPlaybackSpeed;
      int? actualBpm;
      if (state.originalBpm != null) {
        actualBpm = (state.originalBpm! * actualSpeed).round();
      }
      emit(
        state.copyWith(
          status: SongStatus.speedChangeFailed,
          speed: actualSpeed,
          currentBpm: actualBpm,
          error: 'Speed reset failed. Please try again.',
        ),
      );
      return false;
    }
  }

  // ==================== END SPEED CONTROL METHODS ====================

  Future<void> updateLoopOrder(List<Loop> newLoops) async {
    try {
      final updatedSong = state.song.copyWith(loops: newLoops);
      await songRepository.updateSong(updatedSong);

      loopsStreamController?.add(updatedSong.loops);

      // Sync loops with audio handler for navigation
      await audioHandler.customAction('setLoops', {'loops': updatedSong.loops});

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

  Future<void> setVideoSizeMode(VideoSizeMode mode) async {
    if (state.song.videoSizeMode == mode) return;
    final updatedSong = state.song.copyWith(videoSizeMode: mode);
    emit(state.copyWith(song: updatedSong, status: SongStatus.updated));
    try {
      await songRepository.updateSong(updatedSong);
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
    }
  }

  // ==================== PITCH CONTROL METHODS ====================

  static const int minPitchSemitones = -12;
  static const int maxPitchSemitones = 12;

  /// Whether pitch shifting works for the current song on this platform:
  /// video → all platforms (media_kit/libmpv); audio → Android only
  /// (Signalsmith processor in the audioplayers fork). The pitch card hides
  /// itself when unsupported.
  bool get isPitchControlSupported =>
      state.song.mediaType == MediaType.video || Platform.isAndroid;

  /// Update the pitch shift in semitones (-12 to +12) and persist it on the
  /// song. Returns true if the pitch was applied successfully.
  Future<bool> setPitchSemitones(int semitones) async {
    dev.log('setPitchSemitones: $semitones', name: 'SongCubit');

    try {
      final target = semitones.clamp(minPitchSemitones, maxPitchSemitones);

      final success = await audioHandler.setPitchSemitones(target);

      if (!success) {
        dev.log(
          'Pitch change failed, reverting UI to actual pitch',
          name: 'SongCubit',
        );
        emit(
          state.copyWith(
            status: SongStatus.pitchChangeFailed,
            pitchSemitones: audioHandler.currentPitchSemitones,
            error: 'Pitch change failed. Please try again.',
          ),
        );
        return false;
      }

      // Persist the pitch per song. A persistence failure must not revert
      // the already-applied audio change — report it and keep the UI state.
      var updatedSong = state.song;
      try {
        updatedSong = state.song.copyWith(pitchSemitones: target);
        await songRepository.updateSong(updatedSong);
      } catch (ex, stack) {
        unawaited(crashReportingRepository.reportError(ex, stack));
        updatedSong = state.song;
      }

      emit(
        state.copyWith(
          status: SongStatus.updated,
          song: updatedSong,
          pitchSemitones: target,
          error: null,
        ),
      );
      return true;
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      dev.log('Failed to set pitch: $ex', name: 'SongCubit');
      emit(
        state.copyWith(
          status: SongStatus.pitchChangeFailed,
          pitchSemitones: audioHandler.currentPitchSemitones,
          error: 'Pitch change failed. Please try again.',
        ),
      );
      return false;
    }
  }

  /// Reset pitch to the original (0 semitones)
  Future<bool> resetPitch() {
    dev.log('resetPitch', name: 'SongCubit');
    return setPitchSemitones(0);
  }

  /// Switch between semitone mode and key mode (mirrors [setTempoMode])
  void setPitchMode(PitchMode mode) {
    dev.log('setPitchMode: $mode', name: 'SongCubit');
    emit(state.copyWith(pitchMode: mode));
  }

  /// Set or clear the song's original musical key and persist it. Resets the
  /// pitch to 0, mirroring how [setOriginalBpm] resets speed: changing the
  /// reference makes the previous shift meaningless.
  Future<void> setOriginalKey(String? key) async {
    dev.log('setOriginalKey: $key', name: 'SongCubit');

    final canonical = key == null ? null : MusicalKey.canonicalize(key);

    try {
      // Build the updated song directly (not copyWith) so a null key actually
      // clears the field — same pattern as updateSongDetails.
      final updatedSong = Song(
        id: state.song.id,
        title: state.song.title,
        artist: state.song.artist,
        fileName: state.song.fileName,
        duration: state.song.duration,
        bpm: state.song.bpm,
        currentBpm: state.song.currentBpm,
        pitchSemitones: 0,
        musicalKey: canonical,
        loops: state.song.loops,
        loopSort: state.song.loopSort,
        sortOrder: state.song.sortOrder,
        mediaType: state.song.mediaType,
        videoSizeMode: state.song.videoSizeMode,
      );
      await songRepository.updateSong(updatedSong);

      await audioHandler.setPitchSemitones(0);

      emit(
        state.copyWith(
          status: SongStatus.updated,
          song: updatedSong,
          pitchSemitones: 0,
          error: null,
        ),
      );
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      dev.log('Failed to set original key: $ex', name: 'SongCubit');
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to set original key: $ex',
        ),
      );
    }
  }

  /// Set the pitch by choosing the key the song should sound in. Picks the
  /// shorter transposition direction (Am → Cm is +3, not −9).
  /// Requires the original key to be set.
  Future<bool> setPitchByTargetKey(String targetKey) async {
    dev.log('setPitchByTargetKey: $targetKey', name: 'SongCubit');

    final originalKey = state.song.musicalKey;
    if (originalKey == null) return false;

    final offset = MusicalKey.signedOffset(originalKey, targetKey);
    if (offset == null) {
      dev.log(
        'Cannot transpose from $originalKey to $targetKey',
        name: 'SongCubit',
      );
      return false;
    }

    return setPitchSemitones(offset);
  }
}
