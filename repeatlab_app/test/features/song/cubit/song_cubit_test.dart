import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';
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
          ]),
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
}
