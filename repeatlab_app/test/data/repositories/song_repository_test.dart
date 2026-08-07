import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/repositories/backup_activity_guard.dart';
import 'package:repeatlab/data/repositories/song_repository.dart';
import 'package:sembast/sembast_memory.dart';

import '../../helpers/mock_data.dart';
import '../../helpers/mock_services.dart';

var _testDbCounter = 0;

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform({
    required this.applicationDocumentsPath,
    this.throwOnResolve,
  });

  final String applicationDocumentsPath;

  /// When set, [getApplicationDocumentsPath] throws this instead of
  /// resolving — used to simulate a filesystem/platform-channel failure.
  final Object? throwOnResolve;

  @override
  Future<String?> getApplicationDocumentsPath() async {
    final error = throwOnResolve;
    if (error != null) throw error;
    return applicationDocumentsPath;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Database db;
  late MockSoLoud mockSoLoud;
  late SongRepository songRepository;
  late Directory appDir;
  late PathProviderPlatform originalPathProvider;

  setUpAll(() {
    registerFallbackValue(MockData.songShort);
    registerFallbackValue(MockData.loopVerse);
  });

  setUp(() async {
    // Use unique database name for each test to ensure isolation
    _testDbCounter++;
    db = await databaseFactoryMemory.openDatabase('test_$_testDbCounter.db');
    mockSoLoud = MockSoLoud();
    songRepository = SongRepository(db: db, soLoud: mockSoLoud);

    appDir = await Directory.systemTemp.createTemp('song_repo_app_dir');
    originalPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProviderPlatform(
      applicationDocumentsPath: appDir.path,
    );
  });

  tearDown(() async {
    songRepository.dispose();
    await db.close();
    PathProviderPlatform.instance = originalPathProvider;
    BackupActivityGuard.reset();
    if (await appDir.exists()) {
      await appDir.delete(recursive: true);
    }
  });

  group('SongRepository', () {
    group('getAllSongs', () {
      test('returns empty list when database is empty', () async {
        final songs = await songRepository.getAllSongs();
        expect(songs, isEmpty);
      });

      test('returns all songs from database', () async {
        // Manually insert songs into the database
        final store = StoreRef<String, Map<String, dynamic>>('songs');
        await store.add(db, MockData.songShort.toMap());
        await store.add(db, MockData.songMedium.toMap());

        final songs = await songRepository.getAllSongs();
        expect(songs, hasLength(2));
      });

      test('emits songs on stream after getAllSongs', () async {
        final store = StoreRef<String, Map<String, dynamic>>('songs');
        await store.add(db, MockData.songShort.toMap());

        // Listen to the stream before calling getAllSongs
        final songsFuture = songRepository.songs.first;
        await songRepository.getAllSongs();

        final songs = await songsFuture;
        expect(songs, hasLength(1));
        expect(songs.first.id, MockData.songShort.id);
      });
    });

    group('updateSong', () {
      test('updates song in database', () async {
        // First add a song
        final store = StoreRef<String, Map<String, dynamic>>('songs');
        await store.add(db, MockData.songShort.toMap());

        // Update the song
        final updatedSong = MockData.songShort.copyWith(title: 'Updated Title');
        await songRepository.updateSong(updatedSong);

        // Verify the update
        final songs = await songRepository.getAllSongs();
        expect(songs.first.title, 'Updated Title');
      });

      test('emits updated songs on stream', () async {
        final store = StoreRef<String, Map<String, dynamic>>('songs');
        await store.add(db, MockData.songShort.toMap());

        final updatedSong = MockData.songShort.copyWith(title: 'New Title');

        // Collect stream events
        final streamResults = <List<Song>>[];
        final subscription = songRepository.songs.listen(streamResults.add);

        await songRepository.updateSong(updatedSong);
        await Future<void>.delayed(Duration.zero);

        await subscription.cancel();

        expect(streamResults.last.first.title, 'New Title');
      });
    });

    group('deleteSong', () {
      test('removes song from database', () async {
        final store = StoreRef<String, Map<String, dynamic>>('songs');
        await store.add(db, MockData.songShort.toMap());
        await store.add(db, MockData.songMedium.toMap());

        // Verify both songs exist
        var songs = await songRepository.getAllSongs();
        expect(songs, hasLength(2));

        // Delete one song
        await songRepository.deleteSong(MockData.songShort);

        // Verify only one song remains
        songs = await songRepository.getAllSongs();
        expect(songs, hasLength(1));
        expect(songs.first.id, MockData.songMedium.id);
      });

      test('deletes the underlying media file when unreferenced', () async {
        final file = File(p.join(appDir.path, MockData.songShort.fileName));
        await file.writeAsString('audio bytes');

        final store = StoreRef<String, Map<String, dynamic>>('songs');
        await store.add(db, MockData.songShort.toMap());

        await songRepository.deleteSong(MockData.songShort);

        expect(await file.exists(), isFalse);
      });

      test(
        'keeps the media file when another remaining song shares its fileName',
        () async {
          final file = File(p.join(appDir.path, MockData.songShort.fileName));
          await file.writeAsString('audio bytes');

          final sharedSong = MockData.songShort.copyWith(id: 'shared-song-id');
          final store = StoreRef<String, Map<String, dynamic>>('songs');
          await store.add(db, MockData.songShort.toMap());
          await store.add(db, sharedSong.toMap());

          await songRepository.deleteSong(MockData.songShort);

          expect(await file.exists(), isTrue);
        },
      );

      test(
        'removes the DB record even if the file is missing on disk',
        () async {
          final store = StoreRef<String, Map<String, dynamic>>('songs');
          await store.add(db, MockData.songShort.toMap());

          await songRepository.deleteSong(MockData.songShort);

          final songs = await songRepository.getAllSongs();
          expect(songs, isEmpty);
        },
      );

      test(
        'removes the DB record even if resolving the file path throws',
        () async {
          PathProviderPlatform.instance = _FakePathProviderPlatform(
            applicationDocumentsPath: appDir.path,
            throwOnResolve: Exception('platform channel unavailable'),
          );

          final store = StoreRef<String, Map<String, dynamic>>('songs');
          await store.add(db, MockData.songShort.toMap());

          await songRepository.deleteSong(MockData.songShort);

          final songs = await songRepository.getAllSongs();
          expect(songs, isEmpty);
        },
      );

      test(
        'keeps the media file but still removes the DB record while a '
        'backup transfer is in flight',
        () async {
          final file = File(p.join(appDir.path, MockData.songShort.fileName));
          await file.writeAsString('audio bytes');

          final store = StoreRef<String, Map<String, dynamic>>('songs');
          await store.add(db, MockData.songShort.toMap());

          await BackupActivityGuard.run(
            () => songRepository.deleteSong(MockData.songShort),
          );

          expect(await file.exists(), isTrue);
          final songs = await songRepository.getAllSongs();
          expect(songs, isEmpty);
        },
      );
    });

    group('addLoopToSong', () {
      test('adds loop to song and returns updated song', () async {
        final store = StoreRef<String, Map<String, dynamic>>('songs');
        await store.add(db, MockData.songMedium.toMap());

        final loop = Loop(
          id: 1,
          name: 'Test Loop',
          songId: MockData.songMedium.id,
          color: LoopColor.green,
          start: const Duration(seconds: 10),
          end: const Duration(seconds: 30),
        );

        final updatedSong = await songRepository.addLoopToSong(
          song: MockData.songMedium,
          loop: loop,
        );

        expect(updatedSong.loops, hasLength(1));
        expect(updatedSong.loops.first.name, 'Test Loop');
      });

      test('preserves existing loops when adding new loop', () async {
        final songWithLoop = MockData.songMedium.copyWith(
          loops: [MockData.loopVerse],
        );
        final store = StoreRef<String, Map<String, dynamic>>('songs');
        await store.add(db, songWithLoop.toMap());

        final newLoop = Loop(
          id: 2,
          name: 'New Loop',
          songId: MockData.songMedium.id,
          color: LoopColor.orange,
          start: const Duration(minutes: 2),
          end: const Duration(minutes: 3),
        );

        final updatedSong = await songRepository.addLoopToSong(
          song: songWithLoop,
          loop: newLoop,
        );

        expect(updatedSong.loops, hasLength(2));
      });
    });

    group('updateLoopForSong', () {
      test('updates existing loop in song', () async {
        final songWithLoop = MockData.songMedium.copyWith(
          loops: [MockData.loopVerse],
        );
        final store = StoreRef<String, Map<String, dynamic>>('songs');
        await store.add(db, songWithLoop.toMap());

        final updatedLoop = MockData.loopVerse.copyWith(
          name: 'Updated Verse',
          end: const Duration(minutes: 2),
        );

        final updatedSong = await songRepository.updateLoopForSong(
          song: songWithLoop,
          loop: updatedLoop,
        );

        expect(updatedSong.loops.first.name, 'Updated Verse');
        expect(updatedSong.loops.first.end, const Duration(minutes: 2));
      });

      test('does not modify other loops when updating one', () async {
        final songWithLoops = MockData.songMedium.copyWith(
          loops: [MockData.loopVerse, MockData.loopChorus],
        );
        final store = StoreRef<String, Map<String, dynamic>>('songs');
        await store.add(db, songWithLoops.toMap());

        final updatedVerse = MockData.loopVerse.copyWith(name: 'Updated Verse');

        final updatedSong = await songRepository.updateLoopForSong(
          song: songWithLoops,
          loop: updatedVerse,
        );

        expect(updatedSong.loops, hasLength(2));
        expect(updatedSong.loops[0].name, 'Updated Verse');
        expect(updatedSong.loops[1].name, MockData.loopChorus.name);
      });
    });

    group('deleteLoopForSong', () {
      test('removes loop from song', () async {
        final songWithLoops = MockData.songMedium.copyWith(
          loops: [MockData.loopVerse, MockData.loopChorus],
        );
        final store = StoreRef<String, Map<String, dynamic>>('songs');
        await store.add(db, songWithLoops.toMap());

        final updatedSong = await songRepository.deleteLoopForSong(
          song: songWithLoops,
          loop: MockData.loopVerse,
        );

        expect(updatedSong.loops, hasLength(1));
        expect(updatedSong.loops.first.id, MockData.loopChorus.id);
      });

      test('returns song with empty loops when last loop is deleted', () async {
        final songWithLoop = MockData.songMedium.copyWith(
          loops: [MockData.loopVerse],
        );
        final store = StoreRef<String, Map<String, dynamic>>('songs');
        await store.add(db, songWithLoop.toMap());

        final updatedSong = await songRepository.deleteLoopForSong(
          song: songWithLoop,
          loop: MockData.loopVerse,
        );

        expect(updatedSong.loops, isEmpty);
      });
    });

    group('song ordering', () {
      test('getAllSongs returns songs sorted by sortOrder ascending', () async {
        final store = StoreRef<String, Map<String, dynamic>>('songs');
        await store.add(db, MockData.songShort.copyWith(sortOrder: 2).toMap());
        await store.add(db, MockData.songMedium.copyWith(sortOrder: 0).toMap());
        await store.add(db, MockData.songLong.copyWith(sortOrder: 1).toMap());

        final songs = await songRepository.getAllSongs();
        expect(songs[0].id, MockData.songMedium.id);
        expect(songs[1].id, MockData.songLong.id);
        expect(songs[2].id, MockData.songShort.id);
      });

      test(
        'new songs are inserted with sortOrder 0 and existing songs shift down',
        () async {
          final store = StoreRef<String, Map<String, dynamic>>('songs');
          await store.add(
            db,
            MockData.songShort.copyWith(sortOrder: 0).toMap(),
          );
          await store.add(
            db,
            MockData.songMedium.copyWith(sortOrder: 1).toMap(),
          );

          // Simulate adding a new song by calling the internal insert logic
          await songRepository.incrementExistingSortOrders();

          final songs = await songRepository.getAllSongs();
          // Existing songs should have shifted: 0->1, 1->2
          expect(songs[0].sortOrder, 1);
          expect(songs[1].sortOrder, 2);
        },
      );

      test('reorderSongs updates sortOrder for all songs', () async {
        final store = StoreRef<String, Map<String, dynamic>>('songs');
        await store.add(db, MockData.songShort.copyWith(sortOrder: 0).toMap());
        await store.add(db, MockData.songMedium.copyWith(sortOrder: 1).toMap());
        await store.add(db, MockData.songLong.copyWith(sortOrder: 2).toMap());

        // Reorder: move song at index 2 to index 0
        final reordered = [
          MockData.songLong.copyWith(sortOrder: 0),
          MockData.songShort.copyWith(sortOrder: 1),
          MockData.songMedium.copyWith(sortOrder: 2),
        ];
        await songRepository.reorderSongs(reordered);

        final songs = await songRepository.getAllSongs();
        expect(songs[0].id, MockData.songLong.id);
        expect(songs[1].id, MockData.songShort.id);
        expect(songs[2].id, MockData.songMedium.id);
      });
    });

    group('clearDb', () {
      test('removes all songs from database', () async {
        final store = StoreRef<String, Map<String, dynamic>>('songs');
        await store.add(db, MockData.songShort.toMap());
        await store.add(db, MockData.songMedium.toMap());
        await store.add(db, MockData.songLong.toMap());

        var songs = await songRepository.getAllSongs();
        expect(songs, hasLength(3));

        await songRepository.clearDb();

        songs = await songRepository.getAllSongs();
        expect(songs, isEmpty);
      });

      test("deletes every song's media file", () async {
        final shortFile = File(
          p.join(appDir.path, MockData.songShort.fileName),
        );
        final mediumFile = File(
          p.join(appDir.path, MockData.songMedium.fileName),
        );
        await shortFile.writeAsString('audio bytes');
        await mediumFile.writeAsString('audio bytes');

        final store = StoreRef<String, Map<String, dynamic>>('songs');
        await store.add(db, MockData.songShort.toMap());
        await store.add(db, MockData.songMedium.toMap());

        await songRepository.clearDb();

        expect(await shortFile.exists(), isFalse);
        expect(await mediumFile.exists(), isFalse);
      });

      test('keeps files named in keepFileNames', () async {
        final shortFile = File(
          p.join(appDir.path, MockData.songShort.fileName),
        );
        final mediumFile = File(
          p.join(appDir.path, MockData.songMedium.fileName),
        );
        await shortFile.writeAsString('audio bytes');
        await mediumFile.writeAsString('audio bytes');

        final store = StoreRef<String, Map<String, dynamic>>('songs');
        await store.add(db, MockData.songShort.toMap());
        await store.add(db, MockData.songMedium.toMap());

        await songRepository.clearDb(
          keepFileNames: {MockData.songShort.fileName},
        );

        expect(await shortFile.exists(), isTrue);
        expect(await mediumFile.exists(), isFalse);
      });

      test("does not throw when a song's file is missing on disk", () async {
        final store = StoreRef<String, Map<String, dynamic>>('songs');
        await store.add(db, MockData.songShort.toMap());

        await songRepository.clearDb();

        final songs = await songRepository.getAllSongs();
        expect(songs, isEmpty);
      });

      test(
        'keeps files but still clears the DB while a backup transfer is '
        'in flight',
        () async {
          final file = File(p.join(appDir.path, MockData.songShort.fileName));
          await file.writeAsString('audio bytes');

          final store = StoreRef<String, Map<String, dynamic>>('songs');
          await store.add(db, MockData.songShort.toMap());

          await BackupActivityGuard.run(() => songRepository.clearDb());

          expect(await file.exists(), isTrue);
          final songs = await songRepository.getAllSongs();
          expect(songs, isEmpty);
        },
      );

      test(
        'deletes files even while a backup transfer is in flight when '
        'respectBackupGuard is false',
        () async {
          final file = File(p.join(appDir.path, MockData.songShort.fileName));
          await file.writeAsString('audio bytes');

          final store = StoreRef<String, Map<String, dynamic>>('songs');
          await store.add(db, MockData.songShort.toMap());

          await BackupActivityGuard.run(
            () => songRepository.clearDb(respectBackupGuard: false),
          );

          expect(await file.exists(), isFalse);
        },
      );
    });

    group('sweepOrphanedFiles', () {
      test('deletes a media file no song references', () async {
        final orphan = File(p.join(appDir.path, 'orphaned.mp3'));
        await orphan.writeAsString('audio bytes');

        await songRepository.sweepOrphanedFiles();

        expect(await orphan.exists(), isFalse);
      });

      test(
        'keeps an orphaned file while a backup transfer is in flight',
        () async {
          final orphan = File(p.join(appDir.path, 'orphaned.mp3'));
          await orphan.writeAsString('audio bytes');

          await BackupActivityGuard.run(
            () => songRepository.sweepOrphanedFiles(),
          );

          expect(await orphan.exists(), isTrue);
        },
      );

      test('keeps a media file still referenced by a song', () async {
        final referenced = File(
          p.join(appDir.path, MockData.songShort.fileName),
        );
        await referenced.writeAsString('audio bytes');

        final store = StoreRef<String, Map<String, dynamic>>('songs');
        await store.add(db, MockData.songShort.toMap());

        await songRepository.sweepOrphanedFiles();

        expect(await referenced.exists(), isTrue);
      });

      test('leaves non-media files untouched', () async {
        final dbFile = File(p.join(appDir.path, 'repeatlab.db'));
        await dbFile.writeAsString('not a media file');

        await songRepository.sweepOrphanedFiles();

        expect(await dbFile.exists(), isTrue);
      });

      test('does nothing when the documents directory is missing', () async {
        await appDir.delete(recursive: true);

        await expectLater(songRepository.sweepOrphanedFiles(), completes);
      });

      test('does not throw when resolving the directory fails', () async {
        PathProviderPlatform.instance = _FakePathProviderPlatform(
          applicationDocumentsPath: appDir.path,
          throwOnResolve: Exception('platform channel unavailable'),
        );

        await expectLater(songRepository.sweepOrphanedFiles(), completes);
      });
    });

    group('stream behavior', () {
      test(
        'songs stream is broadcast and can have multiple listeners',
        () async {
          final store = StoreRef<String, Map<String, dynamic>>('songs');
          await store.add(db, MockData.songShort.toMap());

          final results1 = <List<Song>>[];
          final results2 = <List<Song>>[];

          final sub1 = songRepository.songs.listen(results1.add);
          final sub2 = songRepository.songs.listen(results2.add);

          await songRepository.getAllSongs();
          await Future<void>.delayed(Duration.zero);

          await sub1.cancel();
          await sub2.cancel();

          expect(results1, isNotEmpty);
          expect(results2, isNotEmpty);
          // Compare by id since Song's hashCode involves async path getter
          expect(results1.last.first.id, results2.last.first.id);
        },
      );
    });

    group('addSongFile SoLoud engine lifecycle', () {
      // The engine must only live for the duration of the import probe: a
      // permanently running engine keeps an output audio stream open, and
      // miniaudio's device-update callback crashed the app on audio route
      // changes (FLUTTER-2Y/FLUTTER-FY).

      late File wavFile;
      late _MockAudioSource mockSource;

      setUp(() async {
        wavFile = File(p.join(appDir.path, 'probe.wav'));
        await wavFile.writeAsBytes(_minimalWavBytes());

        mockSource = _MockAudioSource();
        when(() => mockSoLoud.isInitialized).thenReturn(false);
        when(() => mockSoLoud.init()).thenAnswer((_) async {});
        when(() => mockSoLoud.deinit()).thenReturn(null);
        when(
          () => mockSoLoud.loadFile(any()),
        ).thenAnswer((_) async => mockSource);
        when(
          () => mockSoLoud.getLength(mockSource),
        ).thenReturn(const Duration(seconds: 2));
        when(
          () => mockSoLoud.disposeSource(mockSource),
        ).thenAnswer((_) async {});
      });

      test('initializes the engine for the probe and shuts it down after',
          () async {
        await songRepository.addSongFile(wavFile);

        verifyInOrder([
          () => mockSoLoud.init(),
          () => mockSoLoud.loadFile(wavFile.path),
          () => mockSoLoud.disposeSource(mockSource),
          () => mockSoLoud.deinit(),
        ]);

        final songs = await songRepository.getAllSongs();
        expect(songs.single.duration, const Duration(seconds: 2));
      });

      test('shuts the engine down even when the load fails', () async {
        when(() => mockSoLoud.loadFile(any()))
            .thenThrow(const SoLoudFileLoadFailedException());

        await expectLater(
          songRepository.addSongFile(wavFile),
          throwsA(isA<AudioFileLoadException>()),
        );

        verify(() => mockSoLoud.deinit()).called(1);
      });

      test('leaves an engine running that it did not start', () async {
        when(() => mockSoLoud.isInitialized).thenReturn(true);

        await songRepository.addSongFile(wavFile);

        verifyNever(() => mockSoLoud.init());
        verifyNever(() => mockSoLoud.deinit());
      });
    });
  });
}

class _MockAudioSource extends Mock implements AudioSource {}

/// A canonical 44-byte PCM WAV header plus four bytes of silence — the
/// smallest file the metadata readers in [SongRepository.addSongFile] parse
/// without error.
List<int> _minimalWavBytes() {
  const sampleRate = 44100;
  const bitsPerSample = 16;
  const channels = 1;
  const dataSize = 4;
  const byteRate = sampleRate * channels * bitsPerSample ~/ 8;
  const blockAlign = channels * bitsPerSample ~/ 8;

  final bytes = BytesBuilder()
    ..add('RIFF'.codeUnits)
    ..add(_uint32le(36 + dataSize))
    ..add('WAVE'.codeUnits)
    ..add('fmt '.codeUnits)
    ..add(_uint32le(16))
    ..add(_uint16le(1)) // PCM
    ..add(_uint16le(channels))
    ..add(_uint32le(sampleRate))
    ..add(_uint32le(byteRate))
    ..add(_uint16le(blockAlign))
    ..add(_uint16le(bitsPerSample))
    ..add('data'.codeUnits)
    ..add(_uint32le(dataSize))
    ..add(List.filled(dataSize, 0));
  return bytes.toBytes();
}

List<int> _uint32le(int value) => [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ];

List<int> _uint16le(int value) => [value & 0xFF, (value >> 8) & 0xFF];
