import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/services/media_player_handler.dart';
import 'package:repeatlab/data/services/metronome_track_service.dart';
import 'package:repeatlab/data/services/song_metronome.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';

import '../../../helpers/mock_data.dart';
import '../../../helpers/mock_repositories.dart';

/// Tests for SongCubit state management.
///
/// Note: SongCubit has tight coupling with AudioServiceProvider and
/// RepeatlabAudioplayersServiceHandler which makes it challenging to test
/// in isolation. These tests focus on state management aspects that can
/// be tested without initializing the audio handler.
///
/// Full integration tests with audio would require additional setup
/// and potentially running on a real device.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSongRepository mockSongRepository;
  late MockLocalConfigRepository mockLocalConfigRepository;
  late MockCrashReportingRepository mockCrashReportingRepository;
  late StreamController<List<Song>> songsStreamController;

  setUpAll(() {
    registerFallbackValue(MockData.songShort);
    registerFallbackValue(MockData.loopVerse);
    registerFallbackValue(StackTrace.empty);
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    mockSongRepository = MockSongRepository();
    mockLocalConfigRepository = MockLocalConfigRepository();
    mockCrashReportingRepository = MockCrashReportingRepository();
    songsStreamController = StreamController<List<Song>>.broadcast();

    // Setup default mock behaviors
    when(() => mockSongRepository.songs).thenAnswer(
      (_) => songsStreamController.stream,
    );
    when(
      () => mockCrashReportingRepository.reportError(any(), any()),
    ).thenAnswer((_) async => null);
    when(() => mockLocalConfigRepository.hasCompletedTutorial).thenReturn(true);
  });

  tearDown(() async {
    await songsStreamController.close();
  });

  group('SongCubit', () {
    group('initial state', () {
      test('has correct initial values', () {
        // Create cubit without closing it to avoid audioHandler access
        final cubit = SongCubit(
          song: MockData.songMedium,
          songRepository: mockSongRepository,
          localConfigRepository: mockLocalConfigRepository,
          crashReportingRepository: mockCrashReportingRepository,
        );

        expect(cubit.state.status, SongStatus.loading);
        expect(cubit.state.song, MockData.songMedium);
        expect(cubit.state.activeLoop, isNull);
        expect(cubit.state.isLoopModeEnabled, isFalse);
        expect(cubit.state.speed, 1.0);
        expect(cubit.state.playerState, isNull);
        expect(cubit.state.error, isNull);
        expect(cubit.state.isTutorialCompleted, isFalse);

        // Don't close the cubit as it will try to access audioHandler
      });
    });

    group('SongState', () {
      test('copyWith preserves unchanged values', () {
        const state = SongState(
          song: MockData.songMedium,
          status: SongStatus.loadSuccess,
          speed: 1.5,
          activeLoop: MockData.loopVerse,
          isLoopModeEnabled: true,
          isTutorialCompleted: true,
          playerState: PlayerState.playing,
          error: 'test error',
        );

        final newState = state.copyWith(speed: 2.0);

        expect(newState.song, MockData.songMedium);
        expect(newState.status, SongStatus.loadSuccess);
        expect(newState.speed, 2.0);
        expect(newState.activeLoop, MockData.loopVerse);
        expect(newState.isLoopModeEnabled, isTrue);
        expect(newState.isTutorialCompleted, isTrue);
        expect(newState.playerState, PlayerState.playing);
        expect(newState.error, 'test error');
      });

      test('copyWith updates specified values', () {
        const state = SongState(
          song: MockData.songMedium,
        );

        final newState = state.copyWith(
          status: SongStatus.loadSuccess,
          activeLoop: MockData.loopVerse,
          isLoopModeEnabled: true,
        );

        expect(newState.status, SongStatus.loadSuccess);
        expect(newState.activeLoop, MockData.loopVerse);
        expect(newState.isLoopModeEnabled, isTrue);
      });
    });

    group('SongStatus enum', () {
      test('has all expected values', () {
        expect(
          SongStatus.values,
          containsAll([
            SongStatus.loading,
            SongStatus.loadSuccess,
            SongStatus.loadError,
            SongStatus.error,
            SongStatus.loopAdded,
            SongStatus.loopDeleted,
            SongStatus.loopModeToggled,
            SongStatus.updated,
            SongStatus.updating,
            SongStatus.songDeleted,
            SongStatus.speedChangeFailed,
            SongStatus.pitchChangeFailed,
          ]),
        );
      });
    });

    group('pitch state', () {
      test('defaults to 0 semitones', () {
        const state = SongState(song: MockData.songMedium);
        expect(state.pitchSemitones, 0);
        expect(MockData.songMedium.pitchSemitones, 0);
      });

      test('copyWith updates pitchSemitones on state and song', () {
        const state = SongState(song: MockData.songMedium);

        final newState = state.copyWith(
          pitchSemitones: 5,
          song: state.song.copyWith(pitchSemitones: 5),
        );

        expect(newState.pitchSemitones, 5);
        expect(newState.song.pitchSemitones, 5);
        // Unchanged values are preserved
        expect(newState.speed, state.speed);
      });

      test('song decoded from a map without pitchSemitones defaults to 0', () {
        final map = MockData.songMedium.toMap()..remove('pitchSemitones');
        final decoded = SongMapper.fromMap(map);
        expect(decoded.pitchSemitones, 0);
      });
    });

    group('fine tune state', () {
      test('defaults to 0 cents', () {
        const state = SongState(song: MockData.songMedium);
        expect(state.fineTuneCents, 0);
        expect(MockData.songMedium.fineTuneCents, 0);
      });

      test('copyWith updates fineTuneCents on state and song', () {
        const state = SongState(song: MockData.songMedium);

        final newState = state.copyWith(
          fineTuneCents: 18,
          song: state.song.copyWith(fineTuneCents: 18),
        );

        expect(newState.fineTuneCents, 18);
        expect(newState.song.fineTuneCents, 18);
        // The semitone axis is independent
        expect(newState.pitchSemitones, 0);
      });

      test('song decoded from a map without fineTuneCents defaults to 0', () {
        final map = MockData.songMedium.toMap()..remove('fineTuneCents');
        final decoded = SongMapper.fromMap(map);
        expect(decoded.fineTuneCents, 0);
      });

      test('totalPitchCents combines both axes', () {
        const state = SongState(song: MockData.songMedium);

        expect(state.totalPitchCents, 0);
        expect(
          state.copyWith(pitchSemitones: 3, fineTuneCents: 18).totalPitchCents,
          318,
        );
        expect(
          state
              .copyWith(pitchSemitones: -3, fineTuneCents: -25)
              .totalPitchCents,
          -325,
        );
        // A cents-only offset must produce a non-zero total, otherwise the
        // reapply guards would treat the song as untransposed.
        expect(state.copyWith(fineTuneCents: 20).totalPitchCents, 20);
        // Mixed signs: 1 semitone up, 30 cents down.
        expect(
          state.copyWith(pitchSemitones: 1, fineTuneCents: -30).totalPitchCents,
          70,
        );
      });
    });
  });

  group('SongState edge cases', () {
    test('state with null song (after deletion) is valid', () {
      // After deletion, the song might be conceptually null
      // This tests the state representation for edge cases
      const state = SongState(
        song: MockData.songMedium,
        status: SongStatus.songDeleted,
      );

      expect(state.status, SongStatus.songDeleted);
    });

    test('state with loops', () {
      final songWithLoops = MockData.songMedium.copyWith(
        loops: MockData.testLoops,
      );

      final state = SongState(
        song: songWithLoops,
        status: SongStatus.loadSuccess,
      );

      expect(state.song.loops, hasLength(4));
      expect(state.song.loops, MockData.testLoops);
    });

    test('state with active loop selected', () {
      final songWithLoops = MockData.songMedium.copyWith(
        loops: MockData.testLoops,
      );

      final state = SongState(
        song: songWithLoops,
        status: SongStatus.loadSuccess,
        activeLoop: MockData.loopVerse,
        isLoopModeEnabled: true,
      );

      expect(state.activeLoop, MockData.loopVerse);
      expect(state.isLoopModeEnabled, isTrue);
    });

    test('state with error message', () {
      const state = SongState(
        song: MockData.songMedium,
        status: SongStatus.error,
        error: 'Failed to load audio file',
      );

      expect(state.status, SongStatus.error);
      expect(state.error, 'Failed to load audio file');
    });

    test('state with custom speed', () {
      const state = SongState(
        song: MockData.songMedium,
        status: SongStatus.loadSuccess,
        speed: 1.5,
      );

      expect(state.speed, 1.5);
    });

    test('state with tutorial not completed', () {
      const state = SongState(
        song: MockData.songMedium,
        status: SongStatus.loadSuccess,
      );

      expect(state.isTutorialCompleted, isFalse);
    });

    test('state with different player states', () {
      for (final playerState in PlayerState.values) {
        final state = SongState(
          song: MockData.songMedium,
          status: SongStatus.loadSuccess,
          playerState: playerState,
        );

        expect(state.playerState, playerState);
      }
    });
  });

  group('Loop model integration', () {
    test('loop with start and end positions', () {
      const loop = Loop(
        id: 1,
        name: 'Test Loop',
        songId: 'song-1',
        color: LoopColor.green,
        start: Duration(seconds: 10),
        end: Duration(seconds: 30),
      );

      expect(loop.start, const Duration(seconds: 10));
      expect(loop.end, const Duration(seconds: 30));
    });

    test('loop with null end (open-ended loop)', () {
      const loop = Loop(
        id: 1,
        name: 'Open Loop',
        songId: 'song-1',
        color: LoopColor.orange,
        start: Duration(seconds: 10),
      );

      expect(loop.start, const Duration(seconds: 10));
      expect(loop.end, isNull);
    });

    test('loop colors are distinct', () {
      final colors = LoopColor.values.map((c) => c.color).toSet();
      expect(colors.length, LoopColor.values.length);
    });
  });

  group('Song model with loops', () {
    test('song copyWith updates loops correctly', () {
      const newLoops = [MockData.loopVerse, MockData.loopChorus];
      final updatedSong = MockData.songMedium.copyWith(loops: newLoops);

      expect(updatedSong.loops, hasLength(2));
      expect(updatedSong.loops, newLoops);
      expect(updatedSong.id, MockData.songMedium.id);
      expect(updatedSong.title, MockData.songMedium.title);
    });

    test('song copyWith updates BPM correctly', () {
      final updatedSong = MockData.songNoBpm.copyWith(bpm: 120);

      expect(updatedSong.bpm, 120);
    });

    test('song copyWith updates currentBpm correctly', () {
      final updatedSong = MockData.songMedium.copyWith(currentBpm: 100);

      expect(updatedSong.currentBpm, 100);
    });
  });

  group('Repository mocking verification', () {
    test('song repository stream emits updates', () async {
      final songs = await songsStreamController.stream.first.timeout(
        const Duration(milliseconds: 100),
        onTimeout: () {
          songsStreamController.add([MockData.songShort]);
          return [MockData.songShort];
        },
      );

      // Just verify stream infrastructure works
      expect(songs, isA<List<Song>>());
    });

    test('crash reporting repository accepts error reports', () async {
      await mockCrashReportingRepository.reportError(
        Exception('test'),
        StackTrace.current,
      );

      verify(
        () => mockCrashReportingRepository.reportError(any(), any()),
      ).called(1);
    });
  });

  group('pitch and fine tune (video songs)', () {
    late MockMediaPlayerHandler mockHandler;

    // Video songs report isPitchControlSupported on every platform, so these
    // tests run on the Windows/CI host without needing Android or iOS.
    SongCubit buildCubit({int pitchSemitones = 0, int fineTuneCents = 0}) {
      final cubit = SongCubit(
        song: MockData.songMedium.copyWith(
          mediaType: MediaType.video,
          pitchSemitones: pitchSemitones,
          fineTuneCents: fineTuneCents,
        ),
        songRepository: mockSongRepository,
        localConfigRepository: mockLocalConfigRepository,
        crashReportingRepository: mockCrashReportingRepository,
      )..debugSetAudioHandler(mockHandler);
      return cubit;
    }

    setUp(() {
      mockHandler = MockMediaPlayerHandler();

      when(() => mockHandler.seekEvents).thenAnswer(
        (_) => const Stream<Duration>.empty(),
      );
      when(
        () => mockHandler.setPitchCents(any()),
      ).thenAnswer((_) async => true);
      when(
        () => mockHandler.playSong(any(), autoStart: any(named: 'autoStart')),
      ).thenAnswer((_) async {});
      when(() => mockHandler.currentPitchCents).thenReturn(0);
      when(
        () => mockSongRepository.updateSong(any()),
      ).thenAnswer((_) async {});
    });

    test('setFineTuneCents applies and persists the cents offset', () async {
      final cubit = buildCubit();

      expect(await cubit.setFineTuneCents(18), isTrue);

      verify(() => mockHandler.setPitchCents(18)).called(1);
      expect(cubit.state.fineTuneCents, 18);
      expect(cubit.state.song.fineTuneCents, 18);
      // The semitone axis is untouched
      expect(cubit.state.pitchSemitones, 0);
    });

    test('setFineTuneCents clamps to the +/-50 cent range', () async {
      final cubit = buildCubit();

      await cubit.setFineTuneCents(200);
      expect(cubit.state.fineTuneCents, 50);

      await cubit.setFineTuneCents(-200);
      expect(cubit.state.fineTuneCents, -50);
    });

    test('setFineTuneCents combines with an existing transposition', () async {
      final cubit = buildCubit();

      await cubit.setPitchSemitones(3);
      await cubit.setFineTuneCents(18);

      // 3 semitones + 18 cents reaches the handler as one total.
      verify(() => mockHandler.setPitchCents(318)).called(1);
      expect(cubit.state.pitchSemitones, 3);
      expect(cubit.state.fineTuneCents, 18);
    });

    test('setPitchSemitones preserves the fine tune', () async {
      final cubit = buildCubit();

      await cubit.setFineTuneCents(-25);
      await cubit.setPitchSemitones(-2);

      verify(() => mockHandler.setPitchCents(-225)).called(1);
      expect(cubit.state.fineTuneCents, -25);
    });

    test('resetPitch zeroes both axes', () async {
      final cubit = buildCubit();

      await cubit.setPitchSemitones(4);
      await cubit.setFineTuneCents(30);

      expect(await cubit.resetPitch(), isTrue);

      verify(() => mockHandler.setPitchCents(0)).called(1);
      expect(cubit.state.pitchSemitones, 0);
      expect(cubit.state.fineTuneCents, 0);
      expect(cubit.state.song.fineTuneCents, 0);
    });

    test(
      'a failed pitch change reverts to the previous semitones and cents',
      () async {
        final cubit = buildCubit();

        await cubit.setPitchSemitones(3);
        await cubit.setFineTuneCents(18);

        when(
          () => mockHandler.setPitchCents(any()),
        ).thenAnswer((_) async => false);

        expect(await cubit.setPitchSemitones(7), isFalse);

        // Reverted to the captured pre-call values, not derived by splitting
        // the handler's combined total.
        expect(cubit.state.status, SongStatus.pitchChangeFailed);
        expect(cubit.state.pitchSemitones, 3);
        expect(cubit.state.fineTuneCents, 18);
      },
    );

    test('setOriginalKey zeroes the transposition but keeps the fine tune', () async {
      final cubit = buildCubit(pitchSemitones: 5, fineTuneCents: 18);

      await cubit.setOriginalKey('Am');

      // Fine tune compensates for the recording, not the reference key.
      verify(() => mockHandler.setPitchCents(18)).called(1);
      expect(cubit.state.song.pitchSemitones, 0);
      expect(cubit.state.song.fineTuneCents, 18);
      expect(cubit.state.song.musicalKey, 'Am');

      final persisted = verify(
        () => mockSongRepository.updateSong(captureAny()),
      ).captured.last as Song;
      expect(persisted.pitchSemitones, 0);
      expect(persisted.fineTuneCents, 18);
    });

    test(
      'a cents-only offset is reapplied after a song reload',
      () async {
        final cubit = buildCubit();

        // No transposition at all — only fine tune. The old guard tested
        // pitchSemitones alone and would have skipped the reapply entirely,
        // silently dropping the tuning on every stop/play cycle.
        await cubit.setFineTuneCents(20);
        expect(cubit.state.pitchSemitones, 0);
        clearInteractions(mockHandler);

        when(() => mockHandler.seekEvents).thenAnswer(
          (_) => const Stream<Duration>.empty(),
        );
        when(
          () => mockHandler.setPitchCents(any()),
        ).thenAnswer((_) async => true);
        when(
          () => mockHandler.playSong(any(), autoStart: any(named: 'autoStart')),
        ).thenAnswer((_) async {});

        // playerState is null, so this takes the reinitialize branch that
        // resets pitch in the handler and then reapplies it.
        await cubit.togglePlaySong();

        verify(() => mockHandler.setPitchCents(20)).called(1);
        expect(cubit.state.fineTuneCents, 20);
      },
    );
  });

  group('metronome (live path, video songs)', () {
    late MockSongMetronome mockMetronome;

    // The live native metronome only serves video songs since the native
    // in-pipeline click took over audio songs — these tests pin the video
    // path.
    SongCubit buildCubit({Song song = MockData.songMedium}) {
      final cubit = SongCubit(
        song: song.copyWith(mediaType: MediaType.video),
        songRepository: mockSongRepository,
        localConfigRepository: mockLocalConfigRepository,
        crashReportingRepository: mockCrashReportingRepository,
        metronome: mockMetronome,
      )..isMetronomeSupportedOverride = true;
      return cubit;
    }

    setUp(() {
      mockMetronome = MockSongMetronome();

      when(() => mockMetronome.isRunning).thenReturn(false);
      when(
        () => mockMetronome.startAligned(
          bpm: any(named: 'bpm'),
          offsetMs: any(named: 'offsetMs'),
          beatsPerBar: any(named: 'beatsPerBar'),
          beatUnit: any(named: 'beatUnit'),
          pulsesPerBeat: any(named: 'pulsesPerBeat'),
          volume: any(named: 'volume'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockMetronome.stop()).thenAnswer((_) async {});
      when(() => mockMetronome.setTempo(any())).thenAnswer((_) async {});
      when(() => mockMetronome.setVolume(any())).thenAnswer((_) async {});
      when(
        () => mockMetronome.setTimeSignature(any(), any()),
      ).thenAnswer((_) async {});
      when(() => mockMetronome.setSubdivision(any())).thenAnswer((_) async {});
      when(() => mockMetronome.nudge(any())).thenAnswer((_) async {});
      when(() => mockMetronome.dispose()).thenAnswer((_) async {});

      when(
        () => mockSongRepository.updateSong(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockLocalConfigRepository.setMetronomeVolume(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockLocalConfigRepository.setMetronomeSubdivision(any()),
      ).thenAnswer((_) async {});
    });

    test('toggle is refused while no BPM is set', () async {
      final cubit = buildCubit();

      await cubit.toggleMetronome();

      expect(cubit.state.isMetronomeEnabled, isFalse);
      verifyZeroInteractions(mockMetronome);
    });

    test('everything no-ops on unsupported platforms', () async {
      final cubit = buildCubit()..isMetronomeSupportedOverride = false;

      await cubit.toggleMetronome();
      await cubit.setMetronomeVolume(0.8);
      await cubit.setMetronomeSubdivision(MetronomeSubdivision.triplets);
      await cubit.nudgeMetronome(25);

      expect(cubit.state.isMetronomeEnabled, isFalse);
      verifyZeroInteractions(mockMetronome);
    });

    test('toggle enables with BPM but does not start while paused', () async {
      final cubit = buildCubit();
      await cubit.setOriginalBpm(120);

      await cubit.toggleMetronome();

      expect(cubit.state.isMetronomeEnabled, isTrue);
      verifyNever(
        () => mockMetronome.startAligned(
          bpm: any(named: 'bpm'),
          offsetMs: any(named: 'offsetMs'),
          beatsPerBar: any(named: 'beatsPerBar'),
          beatUnit: any(named: 'beatUnit'),
          pulsesPerBeat: any(named: 'pulsesPerBeat'),
          volume: any(named: 'volume'),
        ),
      );
    });

    test('toggle off stops the metronome', () async {
      final cubit = buildCubit();
      await cubit.setOriginalBpm(120);
      await cubit.toggleMetronome();

      await cubit.toggleMetronome();

      expect(cubit.state.isMetronomeEnabled, isFalse);
      verify(() => mockMetronome.stop()).called(1);
    });

    test('clearing the BPM force-disables the metronome', () async {
      final cubit = buildCubit();
      await cubit.setOriginalBpm(120);
      await cubit.toggleMetronome();
      expect(cubit.state.isMetronomeEnabled, isTrue);

      await cubit.setOriginalBpm(null);

      expect(cubit.state.isMetronomeEnabled, isFalse);
      expect(cubit.state.currentBpm, isNull);
      verify(() => mockMetronome.stop()).called(1);
    });

    test('volume changes apply live and persist only on request', () async {
      final cubit = buildCubit();

      await cubit.setMetronomeVolume(0.8);

      expect(cubit.state.metronomeVolume, 0.8);
      verify(() => mockMetronome.setVolume(0.8)).called(1);
      verifyNever(() => mockLocalConfigRepository.setMetronomeVolume(any()));

      await cubit.setMetronomeVolume(0.7, persist: true);

      verify(() => mockLocalConfigRepository.setMetronomeVolume(0.7)).called(1);
    });

    test('subdivision persists globally and applies live', () async {
      final cubit = buildCubit();

      await cubit.setMetronomeSubdivision(MetronomeSubdivision.triplets);

      expect(
        cubit.state.metronomeSubdivision,
        MetronomeSubdivision.triplets,
      );
      verify(
        () => mockLocalConfigRepository.setMetronomeSubdivision('triplets'),
      ).called(1);
      verify(() => mockMetronome.setSubdivision(3)).called(1);
    });

    test('time signature persists on the song', () async {
      final cubit = buildCubit();

      await cubit.setMetronomeTimeSignature(6, 8);

      expect(cubit.state.song.metronomeBeatsPerBar, 6);
      expect(cubit.state.song.metronomeBeatUnit, 8);
      final persisted =
          verify(() => mockSongRepository.updateSong(captureAny()))
              .captured
              .last as Song;
      expect(persisted.metronomeBeatsPerBar, 6);
      expect(persisted.metronomeBeatUnit, 8);
    });

    test('nudges accumulate into the persisted per-song offset', () async {
      final cubit = buildCubit();

      await cubit.nudgeMetronome(25);
      await cubit.nudgeMetronome(25);
      await cubit.nudgeMetronome(-25);

      expect(cubit.state.song.metronomeOffsetMs, 25);
      verify(
        () => mockMetronome.nudge(const Duration(milliseconds: 25)),
      ).called(2);
      verify(
        () => mockMetronome.nudge(const Duration(milliseconds: -25)),
      ).called(1);
      verify(() => mockSongRepository.updateSong(any())).called(3);
    });

    test('resetMetronomeOffset clears trim and anchor in one write', () async {
      final songWithAlignment = MockData.songMedium.copyWith(
        metronomeOffsetMs: 75,
        metronomeBeatAnchorMs: 130,
      );
      final cubit = buildCubit(song: songWithAlignment);

      await cubit.resetMetronomeOffset();

      expect(cubit.state.song.metronomeOffsetMs, 0);
      expect(cubit.state.song.metronomeBeatAnchorMs, isNull);
      final persisted =
          verify(() => mockSongRepository.updateSong(captureAny()))
              .captured
              .last as Song;
      expect(persisted.metronomeOffsetMs, 0);
      expect(persisted.metronomeBeatAnchorMs, isNull);
      verifyNever(() => mockMetronome.nudge(any()));
    });

    test('resetMetronomeOffset is a no-op with nothing to reset', () async {
      final cubit = buildCubit();

      await cubit.resetMetronomeOffset();

      verifyZeroInteractions(mockMetronome);
      verifyNever(() => mockSongRepository.updateSong(any()));
    });

    test('close disposes the native metronome', () async {
      final cubit = buildCubit();

      await cubit.close();

      verify(() => mockMetronome.dispose()).called(1);
    });
  });

  group('metronome beat-grid alignment (live path, video songs)', () {
    late MockSongMetronome mockMetronome;
    late MockMediaPlayerHandler mockHandler;
    late StreamController<Duration> seekEventsController;

    SongCubit buildCubit({Song song = MockData.songMedium}) {
      final cubit = SongCubit(
        song: song.copyWith(mediaType: MediaType.video),
        songRepository: mockSongRepository,
        localConfigRepository: mockLocalConfigRepository,
        crashReportingRepository: mockCrashReportingRepository,
        metronome: mockMetronome,
      )
        ..isMetronomeSupportedOverride = true
        ..tapSettleMsOverride = 1
        ..realignDebounceMsOverride = 1
        ..debugSetAudioHandler(mockHandler);
      return cubit;
    }

    /// Puts the cubit into "playing" — tap capture and grid restarts only
    /// run during playback.
    void markPlaying(SongCubit cubit) {
      cubit.emit(
        // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
        cubit.state.copyWith(playerState: PlayerState.playing),
      );
    }

    setUp(() {
      mockMetronome = MockSongMetronome();
      mockHandler = MockMediaPlayerHandler();
      seekEventsController = StreamController<Duration>.broadcast();

      when(() => mockMetronome.isRunning).thenReturn(false);
      when(
        () => mockMetronome.startAligned(
          bpm: any(named: 'bpm'),
          offsetMs: any(named: 'offsetMs'),
          beatsPerBar: any(named: 'beatsPerBar'),
          beatUnit: any(named: 'beatUnit'),
          pulsesPerBeat: any(named: 'pulsesPerBeat'),
          volume: any(named: 'volume'),
        ),
      ).thenAnswer((_) async {});
      when(() => mockMetronome.stop()).thenAnswer((_) async {});
      when(() => mockMetronome.setTempo(any())).thenAnswer((_) async {});
      when(() => mockMetronome.nudge(any())).thenAnswer((_) async {});
      when(() => mockMetronome.dispose()).thenAnswer((_) async {});

      when(
        () => mockHandler.seekEvents,
      ).thenAnswer((_) => seekEventsController.stream);
      when(() => mockHandler.setSpeed(any())).thenAnswer((_) async => true);

      when(
        () => mockSongRepository.updateSong(any()),
      ).thenAnswer((_) async {});
    });

    tearDown(() async {
      await seekEventsController.close();
    });

    test('taps commit a circular-mean beat anchor and reset the trim',
        () async {
      final songWithTrim = MockData.songMedium.copyWith(metronomeOffsetMs: 40);
      final cubit = buildCubit(song: songWithTrim);
      await cubit.setOriginalBpm(120); // beat period 500 ms
      markPlaying(cubit);

      // Taps on three consecutive beats at phase 100.
      final positions = [10100, 10600, 11100];
      var tapIndex = 0;
      when(() => mockHandler.position).thenAnswer(
        (_) async => Duration(milliseconds: positions[tapIndex++]),
      );

      await cubit.tapMetronomeBeat();
      expect(cubit.state.metronomeTapCount, 1);
      await cubit.tapMetronomeBeat();
      await cubit.tapMetronomeBeat();
      expect(cubit.state.metronomeTapCount, 3);

      // Let the 1 ms settle timer commit.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(cubit.state.metronomeTapCount, 0);
      expect(cubit.state.song.metronomeBeatAnchorMs, 100);
      expect(cubit.state.song.metronomeOffsetMs, 0);
    });

    test('taps are refused while paused or without a BPM', () async {
      final cubit = buildCubit();

      // No BPM yet.
      markPlaying(cubit);
      await cubit.tapMetronomeBeat();
      expect(cubit.state.metronomeTapCount, 0);

      // BPM set but paused.
      final paused = buildCubit();
      await paused.setOriginalBpm(120);
      await paused.tapMetronomeBeat();
      expect(paused.state.metronomeTapCount, 0);
    });

    test('seek events restart an anchored click on the beat grid', () async {
      final songWithAnchor = MockData.songMedium.copyWith(
        metronomeBeatAnchorMs: 100,
      );
      final cubit = buildCubit(song: songWithAnchor);
      await cubit.setOriginalBpm(120);
      await cubit.toggleMetronome();
      markPlaying(cubit);

      // Position 10300 → phase 200 of the [100 + n*500] grid → 300 ms to the
      // next beat; minus the 50 ms native start anchor = 250 ms delay.
      when(() => mockHandler.position).thenAnswer(
        (_) async => const Duration(milliseconds: 10300),
      );

      seekEventsController.add(const Duration(milliseconds: 10300));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verify(
        () => mockMetronome.startAligned(
          bpm: 120,
          offsetMs: 250,
          beatsPerBar: any(named: 'beatsPerBar'),
          beatUnit: any(named: 'beatUnit'),
          pulsesPerBeat: any(named: 'pulsesPerBeat'),
          volume: any(named: 'volume'),
        ),
      ).called(1);
    });

    test('an unanchored click starts with a uniform 1-beat signature',
        () async {
      // "Beat 1" is unknown until tap-to-align sets an anchor, so the accent
      // must not follow the song's stored time signature yet.
      final cubit = buildCubit(
        song: MockData.songMedium.copyWith(
          metronomeBeatsPerBar: 3,
          metronomeBeatUnit: 4,
        ),
      );
      await cubit.setOriginalBpm(120);
      markPlaying(cubit);

      await cubit.toggleMetronome();

      verify(
        () => mockMetronome.startAligned(
          bpm: 120,
          offsetMs: any(named: 'offsetMs'),
          beatsPerBar: 1,
          beatUnit: 4,
          pulsesPerBeat: any(named: 'pulsesPerBeat'),
          volume: any(named: 'volume'),
        ),
      ).called(1);
    });

    test('an anchored click starts with the song time signature', () async {
      final cubit = buildCubit(
        song: MockData.songMedium.copyWith(
          metronomeBeatAnchorMs: 100,
          metronomeBeatsPerBar: 3,
          metronomeBeatUnit: 4,
        ),
      );
      await cubit.setOriginalBpm(120);
      markPlaying(cubit);
      when(() => mockHandler.position).thenAnswer(
        (_) async => const Duration(milliseconds: 10300),
      );

      await cubit.toggleMetronome();

      verify(
        () => mockMetronome.startAligned(
          bpm: 120,
          offsetMs: any(named: 'offsetMs'),
          beatsPerBar: 3,
          beatUnit: 4,
          pulsesPerBeat: any(named: 'pulsesPerBeat'),
          volume: any(named: 'volume'),
        ),
      ).called(1);
    });

    test('seek events leave a free-running click alone (no anchor)', () async {
      final cubit = buildCubit();
      await cubit.setOriginalBpm(120);
      await cubit.toggleMetronome();
      markPlaying(cubit);

      seekEventsController.add(Duration.zero);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      verifyNever(
        () => mockMetronome.startAligned(
          bpm: any(named: 'bpm'),
          offsetMs: any(named: 'offsetMs'),
          beatsPerBar: any(named: 'beatsPerBar'),
          beatUnit: any(named: 'beatUnit'),
          pulsesPerBeat: any(named: 'pulsesPerBeat'),
          volume: any(named: 'volume'),
        ),
      );
    });

    test('a stop issued during an in-flight aligned start wins', () async {
      final songWithAnchor = MockData.songMedium.copyWith(
        metronomeBeatAnchorMs: 100,
      );
      final cubit = buildCubit(song: songWithAnchor);
      await cubit.setOriginalBpm(120);
      await cubit.toggleMetronome();
      markPlaying(cubit);

      // Aligned start blocks on the position read (platform channel in
      // production) so the pause can overtake it.
      final positionCompleter = Completer<Duration>();
      when(
        () => mockHandler.position,
      ).thenAnswer((_) => positionCompleter.future);

      seekEventsController.add(Duration.zero);
      // Let the 1 ms realign debounce fire; the start is now mid-flight.
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Metronome turned off while the start awaits the position. The stop
      // queues behind the start, so don't await before unblocking it.
      final stopFuture = cubit.toggleMetronome();
      positionCompleter.complete(const Duration(milliseconds: 10300));
      await stopFuture;

      verifyNever(
        () => mockMetronome.startAligned(
          bpm: any(named: 'bpm'),
          offsetMs: any(named: 'offsetMs'),
          beatsPerBar: any(named: 'beatsPerBar'),
          beatUnit: any(named: 'beatUnit'),
          pulsesPerBeat: any(named: 'pulsesPerBeat'),
          volume: any(named: 'volume'),
        ),
      );
      verify(() => mockMetronome.stop()).called(1);
    });

    test('half-beat flip without anchor folds into the offset', () async {
      final cubit = buildCubit();
      await cubit.setOriginalBpm(120);

      await cubit.flipMetronomeHalfBeat();

      expect(cubit.state.song.metronomeOffsetMs, 250);
      expect(cubit.state.song.metronomeBeatAnchorMs, isNull);
      verify(
        () => mockMetronome.nudge(const Duration(milliseconds: 250)),
      ).called(1);
    });

    test('half-beat flip with anchor shifts the anchor', () async {
      final songWithAnchor = MockData.songMedium.copyWith(
        metronomeBeatAnchorMs: 100,
      );
      final cubit = buildCubit(song: songWithAnchor);
      await cubit.setOriginalBpm(120);

      await cubit.flipMetronomeHalfBeat();

      expect(cubit.state.song.metronomeBeatAnchorMs, 350);
      expect(cubit.state.song.metronomeOffsetMs, 0);
      verify(
        () => mockMetronome.nudge(const Duration(milliseconds: 250)),
      ).called(1);
    });
  });
  group('metronome native click pipeline (audio songs)', () {
    late MockSongMetronome mockMetronome;
    late MockMetronomeTrackService mockTrackService;
    late MockMediaPlayerHandler mockHandler;
    late StreamController<Duration> seekEventsController;

    SongCubit buildCubit({Song song = MockData.songMedium}) {
      final cubit = SongCubit(
        song: song,
        songRepository: mockSongRepository,
        localConfigRepository: mockLocalConfigRepository,
        crashReportingRepository: mockCrashReportingRepository,
        metronome: mockMetronome,
        trackService: mockTrackService,
      )
        ..isMetronomeSupportedOverride = true
        ..isNativeClickTrackSupportedOverride = true
        ..clickTrackDebounceMsOverride = 1
        ..debugSetAudioHandler(mockHandler);
      return cubit;
    }

    // Configs sent to the handler, recorded by the stub in call order
    // (mocktail's flat captured list does not preserve named-arg order).
    late List<Map<String, Object?>> sentConfigs;

    void stubNativeClickTrack({Object? error}) {
      when(
        () => mockHandler.setNativeClickTrack(
          enabled: any(named: 'enabled'),
          bpm: any(named: 'bpm'),
          anchorMs: any(named: 'anchorMs'),
          offsetMs: any(named: 'offsetMs'),
          beatsPerBar: any(named: 'beatsPerBar'),
          pulsesPerBeat: any(named: 'pulsesPerBeat'),
          volume: any(named: 'volume'),
        ),
      ).thenAnswer((invocation) async {
        if (error != null) throw error;
        sentConfigs.add({
          'enabled': invocation.namedArguments[#enabled],
          'bpm': invocation.namedArguments[#bpm],
          'anchorMs': invocation.namedArguments[#anchorMs],
          'offsetMs': invocation.namedArguments[#offsetMs],
          'beatsPerBar': invocation.namedArguments[#beatsPerBar],
          'pulsesPerBeat': invocation.namedArguments[#pulsesPerBeat],
          'volume': invocation.namedArguments[#volume],
        });
      });
    }

    setUp(() {
      mockMetronome = MockSongMetronome();
      mockTrackService = MockMetronomeTrackService();
      mockHandler = MockMediaPlayerHandler();
      seekEventsController = StreamController<Duration>.broadcast();
      sentConfigs = [];

      when(() => mockMetronome.isRunning).thenReturn(false);
      when(() => mockMetronome.stop()).thenAnswer((_) async {});
      when(() => mockMetronome.dispose()).thenAnswer((_) async {});

      stubNativeClickTrack();
      when(
        () => mockHandler.seekEvents,
      ).thenAnswer((_) => seekEventsController.stream);
      when(() => mockHandler.setSpeed(any())).thenAnswer((_) async => true);

      when(
        () => mockSongRepository.updateSong(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockLocalConfigRepository.setMetronomeVolume(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockLocalConfigRepository.setMetronomeSubdivision(any()),
      ).thenAnswer((_) async {});
    });

    tearDown(() async {
      await seekEventsController.close();
    });

    test('enabling sends the full grid config, no mixing, no swap', () async {
      final cubit = buildCubit(
        song: MockData.songMedium.copyWith(
          metronomeBeatAnchorMs: 130,
          metronomeOffsetMs: 25,
        ),
      );
      await cubit.setOriginalBpm(120);
      await cubit.setSpeedByMultiplier(1.5);

      await cubit.toggleMetronome();

      expect(cubit.state.isMetronomeEnabled, isTrue);
      final config = sentConfigs.single;
      // Speed acts on the stream — the grid stays at the original BPM.
      expect(config['enabled'], isTrue);
      expect(config['bpm'], 120);
      expect(config['anchorMs'], 130);
      expect(config['offsetMs'], 25);
      expect(config['beatsPerBar'], 4);
      expect(config['pulsesPerBeat'], 1);
      expect(config['volume'], isA<double>());
    });

    test('without a beat anchor a uniform 1-beat grid is sent', () async {
      // "Beat 1" is unknown until tap-to-align sets an anchor, so the accent
      // must not follow the song's stored time signature yet.
      final cubit = buildCubit(
        song: MockData.songMedium.copyWith(
          metronomeBeatsPerBar: 3,
          metronomeBeatUnit: 4,
        ),
      );
      await cubit.setOriginalBpm(120);

      await cubit.toggleMetronome();

      final config = sentConfigs.single;
      expect(config['anchorMs'], isNull);
      expect(config['beatsPerBar'], 1);
    });

    test('disabling silences the native clicks', () async {
      final cubit = buildCubit();
      await cubit.setOriginalBpm(120);
      await cubit.toggleMetronome();

      await cubit.toggleMetronome();

      expect(cubit.state.isMetronomeEnabled, isFalse);
      expect(sentConfigs, hasLength(2));
      expect(sentConfigs.last['enabled'], isFalse);
    });

    test('a nudge while enabled resends the config with the new offset',
        () async {
      final cubit = buildCubit();
      await cubit.setOriginalBpm(120);
      await cubit.toggleMetronome();

      await cubit.nudgeMetronome(25);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(sentConfigs, hasLength(2));
      expect(sentConfigs.last['offsetMs'], 25);
      verifyNever(() => mockMetronome.nudge(any()));
    });

    test('volume changes apply live while dragging', () async {
      final cubit = buildCubit();
      await cubit.setOriginalBpm(120);
      await cubit.toggleMetronome();

      await cubit.setMetronomeVolume(0.8);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(sentConfigs, hasLength(2));
      expect(sentConfigs.last['volume'], 0.8);
      verifyNever(() => mockMetronome.setVolume(any()));
    });

    test('seek events do not resend the config', () async {
      final cubit = buildCubit(
        song: MockData.songMedium.copyWith(metronomeBeatAnchorMs: 100),
      );
      await cubit.setOriginalBpm(120);
      await cubit.toggleMetronome();

      seekEventsController.add(const Duration(milliseconds: 10300));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(sentConfigs, hasLength(1));
    });

    test('a failed native call turns the metronome back off', () async {
      stubNativeClickTrack(error: Exception('channel down'));
      final cubit = buildCubit();
      await cubit.setOriginalBpm(120);

      await cubit.toggleMetronome();

      expect(cubit.state.isMetronomeEnabled, isFalse);
      expect(cubit.state.status, SongStatus.error);
    });

    test('clearing the BPM disables the native clicks', () async {
      final cubit = buildCubit();
      await cubit.setOriginalBpm(120);
      await cubit.toggleMetronome();

      await cubit.setOriginalBpm(null);

      expect(cubit.state.isMetronomeEnabled, isFalse);
      expect(sentConfigs.last['enabled'], isFalse);
    });
  });
}

class MockSongMetronome extends Mock implements SongMetronome {}

class MockMediaPlayerHandler extends Mock implements MediaPlayerHandler {}

class MockMetronomeTrackService extends Mock implements MetronomeTrackService {}
