// ignore_for_file: avoid_redundant_argument_values

import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/beat_grid.dart';
import 'package:repeatlab/core/utils/cubit_extension.dart';
import 'package:repeatlab/core/utils/musical_key.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/repositories/crash_reporting_repository.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
import 'package:repeatlab/data/repositories/song_repository.dart';
import 'package:repeatlab/data/services/audio_service_provider.dart';
import 'package:repeatlab/data/services/media_player_handler.dart';
import 'package:repeatlab/data/services/metronome_track_service.dart';
import 'package:repeatlab/data/services/repeatlab_audioplayers_service_handler.dart';
import 'package:repeatlab/data/services/song_metronome.dart';

// part 'song_cubit.mapper.dart';
part 'song_cubit.mapper.dart';
part 'song_state.dart';

class SongCubit extends Cubit<SongState> {
  final Song song;

  final SongRepository songRepository;
  final LocalConfigRepository localConfigRepository;
  final CrashReportingRepository crashReportingRepository;

  /// Native metronome wrapper. Injected in tests; lazily initialized on first
  /// use, so unsupported platforms never touch the plugin. Only used for
  /// video songs — audio songs use the in-pipeline click track instead.
  final SongMetronome _metronome;

  /// Owns the legacy baked-mix cache directory — only used to purge cached
  /// mixes when a song is deleted. Injected in tests so no path_provider
  /// plugin is touched.
  final MetronomeTrackService _trackService;

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

  /// Position discontinuities from the handler (user seeks AND native loop
  /// wraps, which never reach the cubit any other way) — the metronome
  /// realigns its click grid from this.
  StreamSubscription<Duration>? _seekEventsSubscription;

  /// Debounces grid restarts so seek bursts / slider sweeps coalesce into
  /// one audible re-phase.
  Timer? _gridRealignTimer;

  /// Tap-to-align capture: buffered tap positions (song-time ms) and the
  /// settle timer that commits them into the beat anchor.
  final List<int> _tapPositionsMs = [];
  Timer? _tapSettleTimer;

  /// Serializes metronome start/stop against each other. An aligned start
  /// awaits the player position mid-flight; without ordering, a stop
  /// (pause/completed) issued during that await could be overtaken by the
  /// stale start — leaving the click running over silence.
  Future<void> _metronomeCommandQueue = Future<void>.value();

  /// Bumped on every stop/dispose; an in-flight aligned start aborts when
  /// its captured generation is stale.
  int _metronomeGeneration = 0;

  /// Coalesces native click-config resends so a burst of settings changes
  /// (nudge taps, volume slider) sends once, not per tap.
  Timer? _clickTrackRefreshTimer;

  Duration? positionToSeek;

  Future<Duration> get position async => await audioHandler.position;

  SongCubit({
    required this.song,
    required this.songRepository,
    required this.localConfigRepository,
    required this.crashReportingRepository,
    SongMetronome? metronome,
    MetronomeTrackService? trackService,
  }) : _metronome = metronome ?? SongMetronome(),
       _trackService = trackService ?? MetronomeTrackService(),
       super(SongState(song: song)) {
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
    await _seekEventsSubscription?.cancel();
    _gridRealignTimer?.cancel();
    _tapSettleTimer?.cancel();
    _clickTrackRefreshTimer?.cancel();

    // The audio handler is an app-lifetime singleton — silence the native
    // click processor so it cannot outlive this song page.
    if (handler != null &&
        _usesNativeClickPipeline &&
        state.isMetronomeEnabled) {
      unawaited(_disableNativeClickTrack());
    }

    // Clean up audio service if available
    await handler?.stop();

    // Serialized behind any in-flight metronome command; the generation
    // bump aborts a pending aligned start so it cannot resurrect the
    // engine after dispose.
    _metronomeGeneration++;
    await _enqueueMetronomeCommand(_metronome.dispose);

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
      await _seekEventsSubscription?.cancel();

      // Assign the media handler.
      _audioHandler = handler;

      // Initialize subscriptions before any other operations
      playerStateStream = audioHandler.playerStateStream;
      _playerStateSubscription = playerStateStream?.listen((playerState) {
        if (playerState == PlayerState.completed) {
          stopSong();
        }

        // Single choke point that sees play/pause/stop/completed for both
        // audio and video (incl. notification/Bluetooth controls) — the
        // metronome follows playback from here. Only react to actual
        // transitions so duplicate stream events don't restart the phase.
        final previousPlayerState = state.playerState;

        maybeEmit(
          state.copyWith(
            status: SongStatus.updated,
            playerState: playerState,
            error: null,
          ),
        );

        if (playerState != previousPlayerState) {
          unawaited(_syncMetronomeToPlayback(playerState));
        }
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

      // Realign the metronome on every position discontinuity the handler
      // performs — including native loop wraps the cubit never initiates.
      _seekEventsSubscription = audioHandler.seekEvents.listen((_) {
        unawaited(_realignMetronome(MetronomeRealignReason.loopJumped));
      });

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
          // Metronome always starts off; volume/subdivision are global prefs
          isMetronomeEnabled: false,
          metronomeVolume: localConfigRepository.metronomeVolume,
          metronomeSubdivision: _readMetronomeSubdivisionPref(),
          metronomeTapCount: 0,
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
          _reapplyClickTrackAfterSongReload();
        case null:
          // Initialize the audio handler if it's null
          // This resets speed to 1.0 and pitch to 0, so sync UI state
          await audioHandler.playSong(state.song);
          _syncSpeedStateAfterSongReload();
          await _reapplyPitchAfterSongReload();
          _reapplyClickTrackAfterSongReload();
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
    unawaited(_realignMetronome(MetronomeRealignReason.tempoChanged));
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
      unawaited(_realignMetronome(MetronomeRealignReason.seeked));
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

    // Push the new bounds to the handler immediately (mirrors setLoopEnd) so a
    // subsequent play resumes from the new start rather than the stale one.
    if (state.isLoopModeEnabled) {
      audioHandler.customAction('enableLoop', {
        'loop': activeLoop.copyWith(start: currentPosition),
      });
    }

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

      unawaited(_realignMetronome(MetronomeRealignReason.seeked));

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

        unawaited(_realignMetronome(MetronomeRealignReason.seeked));
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
      // Cached click mixes for a deleted song are dead weight.
      unawaited(
        _trackService.clearForSong(state.song.id).catchError((Object _) {}),
      );
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
        metronomeOffsetMs: state.song.metronomeOffsetMs,
        metronomeBeatAnchorMs: state.song.metronomeBeatAnchorMs,
        metronomeBeatsPerBar: state.song.metronomeBeatsPerBar,
        metronomeBeatUnit: state.song.metronomeBeatUnit,
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
      unawaited(_realignMetronome(MetronomeRealignReason.seeked));
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
      unawaited(_realignMetronome(MetronomeRealignReason.seeked));
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
      unawaited(_realignMetronome(MetronomeRealignReason.tempoChanged));
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
      unawaited(_realignMetronome(MetronomeRealignReason.tempoChanged));
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

        unawaited(_realignMetronome(MetronomeRealignReason.tempoChanged));
        // A new original BPM changes the baked beat grid entirely.
        _scheduleClickTrackRefresh();
      } else {
        // Clear all BPM-related state. Without a BPM the metronome has no
        // tempo to click at — force it off.
        emit(
          state.copyWith(
            status: SongStatus.updated,
            song: updatedSong,
            originalBpm: null,
            currentBpm: null,
            minBpm: null,
            maxBpm: null,
            isMetronomeEnabled: false,
            error: null,
          ),
        );
        await _stopMetronome();
        if (_usesNativeClickPipeline) {
          _clickTrackRefreshTimer?.cancel();
          await _disableNativeClickTrack();
        }
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
      unawaited(_realignMetronome(MetronomeRealignReason.tempoChanged));
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

  // ==================== METRONOME METHODS ====================

  /// Test hook: platform support is compile-time (`Platform.isX`), which
  /// would make every metronome method a no-op in host unit tests.
  @visibleForTesting
  bool? isMetronomeSupportedOverride;

  /// Whether the metronome works on this platform. The native click
  /// pipeline and `precise_metronome` ship iOS + Android implementations
  /// only; the metronome tab hides itself elsewhere (mirrors
  /// [isPitchControlSupported]).
  bool get isMetronomeSupported =>
      isMetronomeSupportedOverride ?? (Platform.isAndroid || Platform.isIOS);

  /// Audio songs use a click track locked to the media timeline (instead of
  /// the live free-running metronome, which video songs keep because their
  /// file cannot be processed). See
  /// docs/plans/2026-07-23-metronome-track-design.md.
  bool get _usesClickTrack => state.song.mediaType == MediaType.audio;

  /// Test hook: forces native click-pipeline support, which is
  /// platform-dependent (`Platform.isAndroid || Platform.isIOS`) in
  /// production.
  @visibleForTesting
  bool? isNativeClickTrackSupportedOverride;

  /// Audio songs get the *native in-pipeline* click — synthesized in the
  /// audioplayers fork's playback pipeline (Android: ExoPlayer
  /// ClickTrackAudioProcessor, iOS/macOS: MTAudioProcessingTap) — with
  /// instant toggle/volume, no mixing, no source swap.
  bool get _usesNativeClickPipeline =>
      _usesClickTrack &&
      (isNativeClickTrackSupportedOverride ??
          (Platform.isAndroid || Platform.isIOS));

  /// Toggle the metronome on/off. Requires a BPM (the metronome panel shows
  /// a "set BPM first" prompt otherwise).
  ///
  /// Audio songs: configures/clears the native in-pipeline click (instant).
  /// Video songs: starts/stops the live click.
  Future<void> toggleMetronome() async {
    if (!isMetronomeSupported) return;

    final enable = !state.isMetronomeEnabled;
    if (enable && (state.currentBpm == null || state.currentBpm! <= 0)) {
      return;
    }

    emit(
      state.copyWith(
        status: SongStatus.updated,
        isMetronomeEnabled: enable,
        error: null,
      ),
    );

    try {
      if (_usesNativeClickPipeline) {
        if (enable) {
          await _applyNativeClickTrack();
        } else {
          _clickTrackRefreshTimer?.cancel();
          await _disableNativeClickTrack();
        }
        return;
      }

      // Audio songs always use the native pipeline on supported platforms;
      // only video songs fall through to the live metronome.
      if (_usesClickTrack) return;

      if (enable && state.playerState == PlayerState.playing) {
        await _realignMetronome(MetronomeRealignReason.playStarted);
      } else if (!enable) {
        await _stopMetronome();
      }
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(
        state.copyWith(
          status: SongStatus.error,
          isMetronomeEnabled: false,
          error: 'Failed to toggle metronome: $ex',
        ),
      );
    }
  }

  /// Live volume change while dragging. Pass [persist] true (e.g. from the
  /// slider's onChangeEnd) to write the global preference.
  Future<void> setMetronomeVolume(double volume, {bool persist = false}) async {
    if (!isMetronomeSupported) return;

    final clamped = volume.clamp(0.0, 1.0);
    emit(state.copyWith(metronomeVolume: clamped));

    try {
      if (!_usesClickTrack) {
        await _metronome.setVolume(clamped);
      } else if (_usesNativeClickPipeline) {
        // Native clicks change volume live while dragging (coalesced).
        _scheduleClickTrackRefresh();
      }
      if (persist) {
        await localConfigRepository.setMetronomeVolume(clamped);
        _scheduleClickTrackRefresh();
      }
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
    }
  }

  /// Set the song's time signature (persisted per song). Restarts the click
  /// phase while running so the accent lands on the next downbeat cleanly.
  Future<void> setMetronomeTimeSignature(int beatsPerBar, int beatUnit) async {
    if (!isMetronomeSupported) return;

    try {
      final updatedSong = state.song.copyWith(
        metronomeBeatsPerBar: beatsPerBar,
        metronomeBeatUnit: beatUnit,
      );
      await songRepository.updateSong(updatedSong);
      emit(
        state.copyWith(
          status: SongStatus.updated,
          song: updatedSong,
          error: null,
        ),
      );

      if (_usesClickTrack) {
        _scheduleClickTrackRefresh();
      } else if (_metronome.isRunning) {
        await _realignMetronome(MetronomeRealignReason.playStarted);
      }
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to set time signature: $ex',
        ),
      );
    }
  }

  /// Set the subdivision (global preference), applied live.
  Future<void> setMetronomeSubdivision(MetronomeSubdivision subdivision) async {
    if (!isMetronomeSupported) return;

    emit(state.copyWith(metronomeSubdivision: subdivision));

    try {
      await localConfigRepository.setMetronomeSubdivision(subdivision.name);
      if (_usesClickTrack) {
        _scheduleClickTrackRefresh();
      } else {
        await _metronome.setSubdivision(subdivision.pulsesPerBeat);
      }
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
    }
  }

  /// Nudge the click grid by [deltaMs] (negative = earlier), accumulated
  /// into the song's persisted offset so the alignment survives reopening
  /// the song. Live path: applied to the running click. Click-track path:
  /// the grid shift is baked into a (debounced) re-mix.
  Future<void> nudgeMetronome(int deltaMs) async {
    if (!isMetronomeSupported) return;

    try {
      final updatedSong = state.song.copyWith(
        metronomeOffsetMs: state.song.metronomeOffsetMs + deltaMs,
      );
      await songRepository.updateSong(updatedSong);
      emit(
        state.copyWith(
          status: SongStatus.updated,
          song: updatedSong,
          error: null,
        ),
      );

      if (_usesClickTrack) {
        _scheduleClickTrackRefresh();
      } else {
        await _metronome.nudge(Duration(milliseconds: deltaMs));
      }
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to nudge metronome: $ex',
        ),
      );
    }
  }

  /// Shift the click grid by half a beat — the quickest fix when the click
  /// lands exactly on the off-beats. With an anchor the half beat is folded
  /// into the anchor (song-time); without one it goes into the wall-clock
  /// offset like a regular nudge. Applied live while running either way.
  Future<void> flipMetronomeHalfBeat() async {
    if (!isMetronomeSupported) return;

    final bpm = state.currentBpm;
    if (bpm == null || bpm <= 0) return;

    final anchor = state.song.metronomeBeatAnchorMs;
    final originalBpm = state.originalBpm;
    final halfBeatWallMs = (60000 / bpm / 2).round();

    if (anchor == null || originalBpm == null || originalBpm <= 0) {
      await nudgeMetronome(halfBeatWallMs);
      return;
    }

    try {
      final halfBeatSongMs = (BeatGrid.beatPeriodMs(originalBpm) / 2).round();
      final updatedSong = state.song.copyWith(
        metronomeBeatAnchorMs: anchor + halfBeatSongMs,
      );
      await songRepository.updateSong(updatedSong);
      emit(
        state.copyWith(
          status: SongStatus.updated,
          song: updatedSong,
          error: null,
        ),
      );

      if (_usesClickTrack) {
        _scheduleClickTrackRefresh();
      } else {
        await _metronome.nudge(Duration(milliseconds: halfBeatWallMs));
      }
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to shift metronome: $ex',
        ),
      );
    }
  }

  /// Test hook: attaches a mocked handler (position + seekEvents) without
  /// going through [initWithHandler], which needs real files and plugins.
  @visibleForTesting
  void debugSetAudioHandler(MediaPlayerHandler handler) {
    _audioHandler = handler;
    _seekEventsSubscription = handler.seekEvents.listen((_) {
      unawaited(_realignMetronome(MetronomeRealignReason.loopJumped));
    });
  }

  /// Test hook: the tap capture normally commits ~1.8 beats after the last
  /// tap, which is too slow for unit tests.
  @visibleForTesting
  int? tapSettleMsOverride;

  /// Test hook shortening the seek/tempo grid-realign debounces.
  @visibleForTesting
  int? realignDebounceMsOverride;

  /// Record one tap of the tap-to-align capture. The user taps along with
  /// the song's beats while it plays; once the taps stop (settle timer) the
  /// circular-mean phase of the tap positions is persisted as the song's
  /// beat anchor — from then on the click grid follows the song across
  /// pause, seeks and loop wraps.
  Future<void> tapMetronomeBeat() async {
    if (!isMetronomeSupported) return;

    final originalBpm = state.originalBpm;
    if (originalBpm == null || originalBpm <= 0) return;
    if (state.playerState != PlayerState.playing) return;

    try {
      final positionMs = (await audioHandler.position).inMilliseconds;
      _tapPositionsMs.add(positionMs);
      emit(
        state.copyWith(
          status: SongStatus.updated,
          metronomeTapCount: _tapPositionsMs.length,
          error: null,
        ),
      );

      // Commit once the user stops tapping. The window must exceed one
      // wall-clock beat (they tap every beat while capturing), with a floor
      // for fast tempos.
      final beatWallMs =
          BeatGrid.beatPeriodMs(originalBpm) /
          (state.speed > 0 ? state.speed : 1.0);
      final settleMs =
          tapSettleMsOverride ?? math.max(1200, (beatWallMs * 1.8).round());
      _tapSettleTimer?.cancel();
      _tapSettleTimer = Timer(Duration(milliseconds: settleMs), () {
        unawaited(_commitTapAnchor());
      });
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
    }
  }

  /// Persists the captured taps as the beat anchor and realigns the click
  /// while running. A fresh anchor resets the wall-clock trim — the taps
  /// are the new alignment truth.
  Future<void> _commitTapAnchor() async {
    if (isClosed) return;

    final taps = List<int>.of(_tapPositionsMs);
    _tapPositionsMs.clear();

    final originalBpm = state.originalBpm;
    if (taps.isEmpty || originalBpm == null || originalBpm <= 0) {
      maybeEmit(state.copyWith(metronomeTapCount: 0));
      return;
    }

    try {
      final anchor = BeatGrid.circularMeanPhaseMs(
        taps,
        BeatGrid.beatPeriodMs(originalBpm),
      );
      final updatedSong = state.song.copyWith(
        metronomeBeatAnchorMs: anchor,
        metronomeOffsetMs: 0,
      );
      await songRepository.updateSong(updatedSong);
      emit(
        state.copyWith(
          status: SongStatus.updated,
          song: updatedSong,
          metronomeTapCount: 0,
          error: null,
        ),
      );

      AppAnalytics.trackEvent(
        AppAnalytics.metronomeAnchorSet,
        data: {'tap_count': taps.length},
      );

      if (_usesClickTrack) {
        _scheduleClickTrackRefresh();
      } else if (state.isMetronomeEnabled &&
          state.playerState == PlayerState.playing) {
        await _startMetronomeAligned();
      }
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      maybeEmit(state.copyWith(metronomeTapCount: 0));
    }
  }

  /// Reset the alignment completely: beat anchor, wall-clock trim and any
  /// in-progress tap capture. Restarts the click from "now" when running.
  Future<void> resetMetronomeOffset() async {
    if (!isMetronomeSupported) return;

    _tapSettleTimer?.cancel();
    _tapPositionsMs.clear();

    final song = state.song;
    if (song.metronomeBeatAnchorMs == null &&
        song.metronomeOffsetMs == 0 &&
        state.metronomeTapCount == 0) {
      return;
    }

    try {
      // Direct construction: dart_mappable's copyWith cannot clear a
      // nullable field (same pattern as updateSongDetails).
      final updatedSong = Song(
        id: song.id,
        title: song.title,
        artist: song.artist,
        fileName: song.fileName,
        duration: song.duration,
        bpm: song.bpm,
        currentBpm: song.currentBpm,
        pitchSemitones: song.pitchSemitones,
        musicalKey: song.musicalKey,
        loops: song.loops,
        loopSort: song.loopSort,
        sortOrder: song.sortOrder,
        mediaType: song.mediaType,
        videoSizeMode: song.videoSizeMode,
        metronomeOffsetMs: 0,
        metronomeBeatAnchorMs: null,
        metronomeBeatsPerBar: song.metronomeBeatsPerBar,
        metronomeBeatUnit: song.metronomeBeatUnit,
      );
      await songRepository.updateSong(updatedSong);
      emit(
        state.copyWith(
          status: SongStatus.updated,
          song: updatedSong,
          metronomeTapCount: 0,
          error: null,
        ),
      );

      if (_usesClickTrack) {
        _scheduleClickTrackRefresh();
      } else if (_metronome.isRunning) {
        await _startMetronomeAligned();
      }
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      emit(
        state.copyWith(
          status: SongStatus.error,
          error: 'Failed to reset metronome alignment: $ex',
        ),
      );
    }
  }

  /// Follows playback state — the metronome only clicks while the song
  /// plays (no standalone mode in v1). Click-track mode needs none of this:
  /// the clicks live inside the audio stream and pause/resume with it.
  Future<void> _syncMetronomeToPlayback(PlayerState playerState) async {
    if (!isMetronomeSupported || !state.isMetronomeEnabled) return;
    if (_usesClickTrack) return;

    try {
      if (playerState == PlayerState.playing) {
        await _realignMetronome(MetronomeRealignReason.playStarted);
      } else {
        await _stopMetronome();
      }
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
    }
  }

  /// The native engine anchors its first click ~50 ms after the start call
  /// (look-ahead scheduling); subtract that from computed grid delays so
  /// clicks don't land systematically late. Residual device latency is
  /// absorbed by the user's wall-clock trim.
  static const int _metronomeStartAnchorMs = 50;

  /// Debounce for seek/loop-wrap grid restarts (coalesces scrub bursts and
  /// the wrap + bounds-check double seek).
  static const int _seekRealignDebounceMs = 150;

  /// Settle time before the grid restarts after a tempo change — a restart
  /// per slider tick would stutter, so the sweep runs on the live
  /// phase-preserving setTempo and realigns once afterwards.
  static const int _tempoRealignSettleMs = 400;

  /// Single code path for (re)aligning the live click grid to playback
  /// (video songs only). Click-track mode is immune to seeks/loops/tempo by
  /// construction, so all realign reasons are no-ops there.
  Future<void> _realignMetronome(MetronomeRealignReason reason) async {
    if (!isMetronomeSupported || !state.isMetronomeEnabled) return;
    if (_usesClickTrack) return;

    final bpm = state.currentBpm;
    if (bpm == null || bpm <= 0) return;

    try {
      switch (reason) {
        case MetronomeRealignReason.playStarted:
          await _startMetronomeAligned();
        case MetronomeRealignReason.tempoChanged:
          // Phase-preserving on the native side — safe from a slider sweep.
          // With an anchor, the grid additionally restarts once the tempo
          // settles (the preserved phase drifts off the song's grid).
          await _metronome.setTempo(bpm);
          _scheduleGridRealign(_tempoRealignSettleMs);
        case MetronomeRealignReason.seeked:
        case MetronomeRealignReason.loopJumped:
          // Without an anchor the click free-runs across position jumps
          // ("nudge now, grid later"); with one it restarts on the new
          // position, debounced so bursts re-phase only once.
          _scheduleGridRealign(_seekRealignDebounceMs);
      }
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
    }
  }

  /// Schedules a debounced grid restart. No-op without a beat anchor —
  /// free-run alignment must not be destroyed by restarts.
  void _scheduleGridRealign(int debounceMs) {
    if (state.song.metronomeBeatAnchorMs == null) return;

    _gridRealignTimer?.cancel();
    _gridRealignTimer = Timer(
      Duration(milliseconds: realignDebounceMsOverride ?? debounceMs),
      () {
        if (isClosed ||
            !state.isMetronomeEnabled ||
            state.playerState != PlayerState.playing) {
          return;
        }
        unawaited(() async {
          try {
            await _startMetronomeAligned();
          } catch (ex, stack) {
            unawaited(crashReportingRepository.reportError(ex, stack));
          }
        }());
      },
    );
  }

  /// Appends [command] to the serial metronome queue. A failed command is
  /// surfaced to its caller but never blocks later commands.
  Future<void> _enqueueMetronomeCommand(Future<void> Function() command) {
    final next = _metronomeCommandQueue.then((_) => command());
    _metronomeCommandQueue = next.then<void>(
      (_) {},
      onError: (Object _) {},
    );
    return next;
  }

  /// Stops the click. Always routed through the command queue and always
  /// invalidates any in-flight aligned start — a stop must win every race
  /// against a start, or the click keeps running over paused music.
  Future<void> _stopMetronome() {
    _metronomeGeneration++;
    _gridRealignTimer?.cancel();
    return _enqueueMetronomeCommand(_metronome.stop);
  }

  /// Whether an aligned start captured at [generation] must abort: the
  /// cubit closed, a stop was issued after it was scheduled, or playback
  /// is no longer running. Checked when the queued command runs AND again
  /// after awaiting the player position.
  bool _isStaleAlignedStart(int generation) =>
      isClosed ||
      generation != _metronomeGeneration ||
      !state.isMetronomeEnabled ||
      state.playerState != PlayerState.playing;

  /// Starts (or restarts) the click. With a beat anchor the first click is
  /// scheduled onto the song's beat grid based on the *fresh* player
  /// position (never the throttled position stream); without one it keeps
  /// the v1 free-run behavior of offsetting from "now".
  /// Time signature actually sent to the click engines, as
  /// (beatsPerBar, beatUnit).
  ///
  /// Without a beat anchor the grid's "beat 1" is arbitrary — the grid counts
  /// from the file start (or from "now" on the live path), so an accented
  /// downbeat would land on a musically random beat, which is worse than no
  /// accent at all. Until tap-to-align sets an anchor the metronome renders a
  /// uniform 1-beat click; the song's stored signature only takes effect once
  /// beat 1 is actually known. The UI mirrors this by hiding the
  /// time-signature control until the song is synced.
  (int, int) get _effectiveTimeSignature =>
      state.song.metronomeBeatAnchorMs == null
      ? (1, 4)
      : (state.song.metronomeBeatsPerBar, state.song.metronomeBeatUnit);

  Future<void> _startMetronomeAligned() {
    final generation = _metronomeGeneration;

    return _enqueueMetronomeCommand(() async {
      if (_isStaleAlignedStart(generation)) return;

      final bpm = state.currentBpm;
      if (bpm == null || bpm <= 0) return;

      final anchor = state.song.metronomeBeatAnchorMs;
      final originalBpm = state.originalBpm;

      var offsetMs = state.song.metronomeOffsetMs;
      if (anchor != null && originalBpm != null && originalBpm > 0) {
        final positionMs = (await audioHandler.position).inMilliseconds;
        // The position read is a platform-channel round trip — a pause may
        // have stopped the metronome in the meantime.
        if (_isStaleAlignedStart(generation)) return;

        final speed = state.speed > 0 ? state.speed : 1.0;
        final songMsToBeat = BeatGrid.songMsToNextBeat(
          positionMs: positionMs,
          anchorMs: anchor,
          periodMs: BeatGrid.beatPeriodMs(originalBpm),
        );
        // Wall-clock delay until that beat, plus the user's trim, minus the
        // engine's fixed start anchor. startAligned normalizes the result
        // into one beat period, so negative values roll to the next beat.
        offsetMs =
            (songMsToBeat / speed).round() +
            state.song.metronomeOffsetMs -
            _metronomeStartAnchorMs;
      }

      final (beatsPerBar, beatUnit) = _effectiveTimeSignature;
      await _metronome.startAligned(
        bpm: bpm,
        offsetMs: offsetMs,
        beatsPerBar: beatsPerBar,
        beatUnit: beatUnit,
        pulsesPerBeat: state.metronomeSubdivision.pulsesPerBeat,
        volume: state.metronomeVolume,
      );
    });
  }

  // ==================== CLICK TRACK (audio songs) ====================

  /// Coalesce window for native click-config resends (no mixing involved —
  /// this only limits method-channel chatter from slider drags).
  static const int _nativeClickRefreshDebounceMs = 50;

  /// Test hook shortening the click-track refresh debounce.
  @visibleForTesting
  int? clickTrackDebounceMsOverride;

  /// Schedules a coalesced config resend after a grid/volume change.
  /// No-op unless the metronome is enabled in click-track mode.
  void _scheduleClickTrackRefresh() {
    if (!isMetronomeSupported ||
        !_usesNativeClickPipeline ||
        !state.isMetronomeEnabled) {
      return;
    }

    final debounceMs =
        clickTrackDebounceMsOverride ?? _nativeClickRefreshDebounceMs;
    _clickTrackRefreshTimer?.cancel();
    _clickTrackRefreshTimer = Timer(
      Duration(milliseconds: debounceMs),
      () {
        if (isClosed || !state.isMetronomeEnabled) return;
        unawaited(_applyNativeClickTrack());
      },
    );
  }

  /// Sends the full grid config to the native in-pipeline click processor.
  /// Instant: no mixing, no source swap — the processor picks the new
  /// config up within one audio buffer.
  Future<void> _applyNativeClickTrack() async {
    final originalBpm = state.originalBpm;
    if (originalBpm == null || originalBpm <= 0) return;

    try {
      await audioHandler.setNativeClickTrack(
        enabled: state.isMetronomeEnabled,
        bpm: originalBpm,
        anchorMs: state.song.metronomeBeatAnchorMs,
        offsetMs: state.song.metronomeOffsetMs,
        beatsPerBar: _effectiveTimeSignature.$1,
        pulsesPerBeat: state.metronomeSubdivision.pulsesPerBeat,
        volume: state.metronomeVolume,
      );
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
      maybeEmit(
        state.copyWith(
          status: SongStatus.error,
          isMetronomeEnabled: false,
          error: 'Failed to configure metronome: $ex',
        ),
      );
    }
  }

  /// Silences the native click processor (config cleared on the platform
  /// side). Failures are reported but never surface — disabling must not
  /// error the UI.
  Future<void> _disableNativeClickTrack() async {
    try {
      await audioHandler.setNativeClickTrack(enabled: false);
    } catch (ex, stack) {
      unawaited(crashReportingRepository.reportError(ex, stack));
    }
  }

  /// `playSong` drops the click state (the handler clears the processor's
  /// grid so a new song never inherits the old one) — re-send the config if
  /// the metronome is on.
  void _reapplyClickTrackAfterSongReload() {
    if (_usesNativeClickPipeline && state.isMetronomeEnabled) {
      unawaited(_applyNativeClickTrack());
    }
  }

  MetronomeSubdivision _readMetronomeSubdivisionPref() {
    final name = localConfigRepository.metronomeSubdivision;
    return MetronomeSubdivision.values.firstWhere(
      (value) => value.name == name,
      orElse: () => MetronomeSubdivision.none,
    );
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
        metronomeOffsetMs: state.song.metronomeOffsetMs,
        metronomeBeatAnchorMs: state.song.metronomeBeatAnchorMs,
        metronomeBeatsPerBar: state.song.metronomeBeatsPerBar,
        metronomeBeatUnit: state.song.metronomeBeatUnit,
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
