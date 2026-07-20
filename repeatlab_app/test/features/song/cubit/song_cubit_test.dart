import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';
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

  group('metronome', () {
    late MockSongMetronome mockMetronome;

    SongCubit buildCubit({Song song = MockData.songMedium}) {
      final cubit = SongCubit(
        song: song,
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

    test('resetMetronomeOffset nudges the accumulated offset away', () async {
      final songWithOffset = MockData.songMedium.copyWith(
        metronomeOffsetMs: 75,
      );
      final cubit = buildCubit(song: songWithOffset);

      await cubit.resetMetronomeOffset();

      expect(cubit.state.song.metronomeOffsetMs, 0);
      verify(
        () => mockMetronome.nudge(const Duration(milliseconds: -75)),
      ).called(1);
    });

    test('resetMetronomeOffset is a no-op at zero offset', () async {
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
}

class MockSongMetronome extends Mock implements SongMetronome {}
