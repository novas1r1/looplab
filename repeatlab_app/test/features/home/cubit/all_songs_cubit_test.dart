import 'dart:async';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/repositories/file_repository.dart';
import 'package:repeatlab/data/repositories/song_repository.dart';
import 'package:repeatlab/features/home/cubit/all_songs_cubit.dart';

import '../../../helpers/mock_data.dart';
import '../../../helpers/mock_repositories.dart';

class MockFile extends Mock implements File {}

void main() {
  late MockSongRepository mockSongRepository;
  late MockFileRepository mockFileRepository;
  late MockCrashReportingRepository mockCrashReportingRepository;
  late MockLocalConfigRepository mockLocalConfigRepository;
  late StreamController<List<Song>> songsStreamController;

  setUpAll(() {
    registerFallbackValue(MockData.songShort);
    registerFallbackValue(StackTrace.empty);
    registerFallbackValue(<Song>[]);
    registerFallbackValue(MockFile());
  });

  setUp(() {
    mockSongRepository = MockSongRepository();
    mockFileRepository = MockFileRepository();
    mockCrashReportingRepository = MockCrashReportingRepository();
    mockLocalConfigRepository = MockLocalConfigRepository();
    songsStreamController = StreamController<List<Song>>.broadcast();

    // first_song_added already tracked, so the success paths don't try to
    // mark the milestone (analytics is a no-op in debug tests regardless).
    when(
      () => mockLocalConfigRepository.firstSongTracked,
    ).thenReturn(true);

    when(() => mockSongRepository.songs).thenAnswer(
      (_) => songsStreamController.stream,
    );
    when(
      () => mockCrashReportingRepository.reportError(any(), any()),
    ).thenAnswer((_) async => null);
    when(
      () => mockCrashReportingRepository.reportError(
        any(),
        any(),
        properties: any(named: 'properties'),
      ),
    ).thenAnswer((_) async => null);
  });

  tearDown(() async {
    await songsStreamController.close();
  });

  AllSongsCubit buildCubit() => AllSongsCubit(
    songRepository: mockSongRepository,
    fileRepository: mockFileRepository,
    crashReportingRepository: mockCrashReportingRepository,
    localConfigRepository: mockLocalConfigRepository,
  );

  group('AllSongsCubit', () {
    test('initial state is correct', () {
      final cubit = buildCubit();
      expect(cubit.state.status, AllSongsStatus.initial);
      expect(cubit.state.songs, isEmpty);
      expect(cubit.state.errorMessage, isNull);
      cubit.close();
    });

    group('loadSongs', () {
      blocTest<AllSongsCubit, AllSongsState>(
        'emits [loading, loaded] with songs when getAllSongs succeeds',
        build: () {
          when(() => mockSongRepository.getAllSongs()).thenAnswer(
            (_) async => MockData.testSongs,
          );
          return buildCubit();
        },
        act: (cubit) => cubit.loadSongs(),
        expect: () => [
          isA<AllSongsState>().having(
            (s) => s.status,
            'status',
            AllSongsStatus.loading,
          ),
          isA<AllSongsState>()
              .having((s) => s.status, 'status', AllSongsStatus.loaded)
              .having((s) => s.songs, 'songs', MockData.testSongs),
        ],
        verify: (_) {
          verify(() => mockSongRepository.getAllSongs()).called(1);
        },
      );

      blocTest<AllSongsCubit, AllSongsState>(
        'emits [loading, loaded] with empty list when no songs exist',
        build: () {
          when(() => mockSongRepository.getAllSongs()).thenAnswer(
            (_) async => [],
          );
          return buildCubit();
        },
        act: (cubit) => cubit.loadSongs(),
        expect: () => [
          isA<AllSongsState>().having(
            (s) => s.status,
            'status',
            AllSongsStatus.loading,
          ),
          isA<AllSongsState>()
              .having((s) => s.status, 'status', AllSongsStatus.loaded)
              .having((s) => s.songs, 'songs', isEmpty),
        ],
      );

      blocTest<AllSongsCubit, AllSongsState>(
        'emits [loading, error] when getAllSongs throws',
        build: () {
          when(() => mockSongRepository.getAllSongs()).thenThrow(
            Exception('Database error'),
          );
          return buildCubit();
        },
        act: (cubit) => cubit.loadSongs(),
        expect: () => [
          isA<AllSongsState>().having(
            (s) => s.status,
            'status',
            AllSongsStatus.loading,
          ),
          isA<AllSongsState>()
              .having((s) => s.status, 'status', AllSongsStatus.error)
              .having(
                (s) => s.errorMessage,
                'errorMessage',
                contains('Database error'),
              ),
        ],
        verify: (_) {
          verify(
            () => mockCrashReportingRepository.reportError(any(), any()),
          ).called(1);
        },
      );
    });

    group('addSong', () {
      blocTest<AllSongsCubit, AllSongsState>(
        'emits [importing, initial] when user cancels file picker',
        build: () {
          when(() => mockFileRepository.pickAudioFiles()).thenAnswer(
            (_) async => [],
          );
          return buildCubit();
        },
        act: (cubit) => cubit.addSong(),
        expect: () => [
          isA<AllSongsState>().having(
            (s) => s.status,
            'status',
            AllSongsStatus.importing,
          ),
          isA<AllSongsState>().having(
            (s) => s.status,
            'status',
            AllSongsStatus.initial,
          ),
        ],
      );

      blocTest<AllSongsCubit, AllSongsState>(
        'emits [importing, progress, loaded] when file is picked and added successfully',
        build: () {
          final mockFile = MockFile();
          when(() => mockFile.path).thenReturn('/path/to/song.mp3');
          when(() => mockFileRepository.pickAudioFiles()).thenAnswer(
            (_) async => [mockFile],
          );
          when(() => mockSongRepository.addSongFile(mockFile)).thenAnswer(
            (_) async {},
          );
          when(() => mockSongRepository.getAllSongs()).thenAnswer(
            (_) async => [MockData.songShort],
          );
          return buildCubit();
        },
        act: (cubit) => cubit.addSong(),
        expect: () => [
          isA<AllSongsState>().having(
            (s) => s.status,
            'status',
            AllSongsStatus.importing,
          ),
          isA<AllSongsState>()
              .having((s) => s.status, 'status', AllSongsStatus.importing)
              .having((s) => s.importCurrent, 'importCurrent', 1)
              .having((s) => s.importTotal, 'importTotal', 1),
          isA<AllSongsState>()
              .having((s) => s.status, 'status', AllSongsStatus.loaded)
              .having((s) => s.importTotal, 'importTotal', isNull)
              .having(
                (s) => s.songs,
                'songs',
                [MockData.songShort],
              ),
        ],
      );

      blocTest<AllSongsCubit, AllSongsState>(
        'adds every file when multiple files are picked',
        build: () {
          final firstFile = MockFile();
          when(() => firstFile.path).thenReturn('/path/to/one.mp3');
          final secondFile = MockFile();
          when(() => secondFile.path).thenReturn('/path/to/two.mp3');
          when(() => mockFileRepository.pickAudioFiles()).thenAnswer(
            (_) async => [firstFile, secondFile],
          );
          when(() => mockSongRepository.addSongFile(any())).thenAnswer(
            (_) async {},
          );
          when(() => mockSongRepository.getAllSongs()).thenAnswer(
            (_) async => [MockData.songShort, MockData.songMedium],
          );
          return buildCubit();
        },
        act: (cubit) => cubit.addSong(),
        expect: () => [
          isA<AllSongsState>().having(
            (s) => s.status,
            'status',
            AllSongsStatus.importing,
          ),
          isA<AllSongsState>()
              .having((s) => s.importCurrent, 'importCurrent', 1)
              .having((s) => s.importTotal, 'importTotal', 2),
          isA<AllSongsState>()
              .having((s) => s.importCurrent, 'importCurrent', 2)
              .having((s) => s.importTotal, 'importTotal', 2),
          isA<AllSongsState>()
              .having((s) => s.status, 'status', AllSongsStatus.loaded)
              .having(
                (s) => s.songs,
                'songs',
                [MockData.songShort, MockData.songMedium],
              ),
        ],
        verify: (_) {
          verify(() => mockSongRepository.addSongFile(any())).called(2);
        },
      );

      blocTest<AllSongsCubit, AllSongsState>(
        'imports the good files and surfaces the error when one file fails',
        build: () {
          final goodFile = MockFile();
          when(() => goodFile.path).thenReturn('/path/to/good.mp3');
          final badFile = MockFile();
          when(() => badFile.path).thenReturn('/path/to/bad.xyz');
          when(() => mockFileRepository.pickAudioFiles()).thenAnswer(
            (_) async => [goodFile, badFile],
          );
          when(() => mockSongRepository.addSongFile(goodFile)).thenAnswer(
            (_) async {},
          );
          when(() => mockSongRepository.addSongFile(badFile)).thenThrow(
            const UnsupportedAudioFormatException('xyz'),
          );
          when(() => mockSongRepository.getAllSongs()).thenAnswer(
            (_) async => [MockData.songShort],
          );
          return buildCubit();
        },
        act: (cubit) => cubit.addSong(),
        expect: () => [
          isA<AllSongsState>().having(
            (s) => s.status,
            'status',
            AllSongsStatus.importing,
          ),
          isA<AllSongsState>()
              .having((s) => s.importCurrent, 'importCurrent', 1)
              .having((s) => s.importTotal, 'importTotal', 2),
          isA<AllSongsState>()
              .having((s) => s.importCurrent, 'importCurrent', 2)
              .having((s) => s.importTotal, 'importTotal', 2),
          isA<AllSongsState>()
              .having((s) => s.status, 'status', AllSongsStatus.errorAudioFormat)
              .having((s) => s.songs, 'songs', [MockData.songShort])
              .having((s) => s.errorMessage, 'errorMessage', 'xyz'),
        ],
        verify: (_) {
          verify(
            () => mockCrashReportingRepository.reportError(
              any(),
              any(),
              properties: any(named: 'properties'),
            ),
          ).called(1);
        },
      );

      blocTest<AllSongsCubit, AllSongsState>(
        'emits [importing, error] when addSongFile throws',
        build: () {
          final mockFile = MockFile();
          when(() => mockFile.path).thenReturn('/path/to/song.mp3');
          when(() => mockFileRepository.pickAudioFiles()).thenAnswer(
            (_) async => [mockFile],
          );
          when(() => mockSongRepository.addSongFile(mockFile)).thenThrow(
            Exception('Failed to add song'),
          );
          when(() => mockSongRepository.getAllSongs()).thenAnswer(
            (_) async => [],
          );
          return buildCubit();
        },
        act: (cubit) => cubit.addSong(),
        expect: () => [
          isA<AllSongsState>().having(
            (s) => s.status,
            'status',
            AllSongsStatus.importing,
          ),
          isA<AllSongsState>()
              .having((s) => s.importCurrent, 'importCurrent', 1)
              .having((s) => s.importTotal, 'importTotal', 1),
          isA<AllSongsState>()
              .having((s) => s.status, 'status', AllSongsStatus.error)
              .having(
                (s) => s.errorMessage,
                'errorMessage',
                contains('Failed to add song'),
              ),
        ],
        verify: (_) {
          verify(
            () => mockCrashReportingRepository.reportError(
              any(),
              any(),
              properties: any(named: 'properties'),
            ),
          ).called(1);
        },
      );
    });

    group('pick already in progress', () {
      blocTest<AllSongsCubit, AllSongsState>(
        'emits [importing, errorImportInProgress] without a crash report '
        'when a previous audio pick is still running',
        build: () {
          when(() => mockFileRepository.pickAudioFiles()).thenThrow(
            const PickAlreadyInProgressException(),
          );
          return buildCubit();
        },
        act: (cubit) => cubit.addSong(),
        expect: () => [
          isA<AllSongsState>().having(
            (s) => s.status,
            'status',
            AllSongsStatus.importing,
          ),
          isA<AllSongsState>().having(
            (s) => s.status,
            'status',
            AllSongsStatus.errorImportInProgress,
          ),
        ],
        verify: (_) {
          verifyNever(
            () => mockCrashReportingRepository.reportError(any(), any()),
          );
        },
      );

      blocTest<AllSongsCubit, AllSongsState>(
        'emits [importing, errorImportInProgress] without a crash report '
        'when a previous video pick is still running',
        build: () {
          when(() => mockFileRepository.pickVideoFiles()).thenThrow(
            const PickAlreadyInProgressException(),
          );
          return buildCubit();
        },
        act: (cubit) => cubit.addVideo(),
        expect: () => [
          isA<AllSongsState>().having(
            (s) => s.status,
            'status',
            AllSongsStatus.importing,
          ),
          isA<AllSongsState>().having(
            (s) => s.status,
            'status',
            AllSongsStatus.errorImportInProgress,
          ),
        ],
        verify: (_) {
          verifyNever(
            () => mockCrashReportingRepository.reportError(any(), any()),
          );
        },
      );
    });

    group('stale error message', () {
      blocTest<AllSongsCubit, AllSongsState>(
        'clears the previous errorMessage when a new import starts',
        seed: () => const AllSongsState(
          status: AllSongsStatus.errorAudioFormat,
          errorMessage: 'xyz',
        ),
        build: () {
          when(() => mockFileRepository.pickAudioFiles()).thenAnswer(
            (_) async => [],
          );
          return buildCubit();
        },
        act: (cubit) => cubit.addSong(),
        expect: () => [
          isA<AllSongsState>()
              .having((s) => s.status, 'status', AllSongsStatus.importing)
              .having((s) => s.errorMessage, 'errorMessage', isNull),
          isA<AllSongsState>().having(
            (s) => s.status,
            'status',
            AllSongsStatus.initial,
          ),
        ],
      );
    });

    group('deleteSong', () {
      blocTest<AllSongsCubit, AllSongsState>(
        'calls songRepository.deleteSong when deleteSong is called',
        build: () {
          when(
            () => mockSongRepository.deleteSong(MockData.songShort),
          ).thenAnswer((_) async {});
          return buildCubit();
        },
        act: (cubit) => cubit.deleteSong(MockData.songShort),
        verify: (_) {
          verify(
            () => mockSongRepository.deleteSong(MockData.songShort),
          ).called(1);
        },
      );

      blocTest<AllSongsCubit, AllSongsState>(
        'emits error state when deleteSong throws',
        build: () {
          when(
            () => mockSongRepository.deleteSong(MockData.songShort),
          ).thenThrow(Exception('Delete failed'));
          return buildCubit();
        },
        act: (cubit) => cubit.deleteSong(MockData.songShort),
        expect: () => [
          isA<AllSongsState>()
              .having((s) => s.status, 'status', AllSongsStatus.error)
              .having(
                (s) => s.errorMessage,
                'errorMessage',
                contains('Delete failed'),
              ),
        ],
        verify: (_) {
          verify(
            () => mockCrashReportingRepository.reportError(any(), any()),
          ).called(1);
        },
      );
    });

    group('clearDb', () {
      blocTest<AllSongsCubit, AllSongsState>(
        'returns true and reloads songs when clearDb succeeds',
        build: () {
          when(() => mockSongRepository.clearDb()).thenAnswer((_) async {});
          when(() => mockSongRepository.getAllSongs()).thenAnswer(
            (_) async => [],
          );
          return buildCubit();
        },
        act: (cubit) async {
          final result = await cubit.clearDb();
          expect(result, isTrue);
        },
        verify: (_) {
          verify(() => mockSongRepository.clearDb()).called(1);
          verify(() => mockSongRepository.getAllSongs()).called(1);
        },
      );

      blocTest<AllSongsCubit, AllSongsState>(
        'returns false and reports error when clearDb throws',
        build: () {
          when(
            () => mockSongRepository.clearDb(),
          ).thenThrow(Exception('Clear failed'));
          return buildCubit();
        },
        act: (cubit) async {
          final result = await cubit.clearDb();
          expect(result, isFalse);
        },
        verify: (_) {
          verify(
            () => mockCrashReportingRepository.reportError(any(), any()),
          ).called(1);
        },
      );
    });

    group('reorderSongs', () {
      blocTest<AllSongsCubit, AllSongsState>(
        'optimistically reorders songs and persists via repository',
        seed: () => const AllSongsState(
          status: AllSongsStatus.loaded,
          songs: [MockData.songShort, MockData.songMedium, MockData.songLong],
        ),
        build: () {
          when(
            () => mockSongRepository.reorderSongs(any()),
          ).thenAnswer((_) async {});
          return buildCubit();
        },
        act: (cubit) => cubit.reorderSongs(2, 0),
        expect: () => [
          isA<AllSongsState>().having(
            (s) => s.songs.map((s) => s.id).toList(),
            'song ids',
            [
              MockData.songLong.id,
              MockData.songShort.id,
              MockData.songMedium.id,
            ],
          ),
        ],
        verify: (_) {
          verify(() => mockSongRepository.reorderSongs(any())).called(1);
        },
      );

      blocTest<AllSongsCubit, AllSongsState>(
        'emits error state when reorderSongs throws',
        seed: () => const AllSongsState(
          status: AllSongsStatus.loaded,
          songs: [MockData.songShort, MockData.songMedium],
        ),
        build: () {
          when(() => mockSongRepository.reorderSongs(any())).thenThrow(
            Exception('Reorder failed'),
          );
          return buildCubit();
        },
        act: (cubit) => cubit.reorderSongs(1, 0),
        expect: () => [
          // Optimistic reorder
          isA<AllSongsState>().having(
            (s) => s.songs.map((s) => s.id).toList(),
            'song ids',
            [MockData.songMedium.id, MockData.songShort.id],
          ),
          // Error state after persistence fails
          isA<AllSongsState>().having(
            (s) => s.status,
            'status',
            AllSongsStatus.error,
          ),
        ],
        verify: (_) {
          verify(
            () => mockCrashReportingRepository.reportError(any(), any()),
          ).called(1);
        },
      );
    });

    group('stream subscription', () {
      test('updates state when songs stream emits new data', () async {
        when(() => mockSongRepository.getAllSongs()).thenAnswer(
          (_) async => [],
        );

        final cubit = buildCubit();

        // Initially empty
        expect(cubit.state.songs, isEmpty);

        // Emit new songs via stream
        songsStreamController.add(MockData.testSongs);
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state.songs, MockData.testSongs);

        await cubit.close();
      });
    });
  });
}
