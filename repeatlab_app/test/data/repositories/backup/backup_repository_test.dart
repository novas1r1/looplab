import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/repositories/backup/backup_exceptions.dart';
import 'package:repeatlab/data/repositories/backup/backup_manifest.dart';
import 'package:repeatlab/data/repositories/backup/backup_repository.dart';
import 'package:repeatlab/data/repositories/backup/backup_serializer.dart';
import 'package:repeatlab/data/repositories/song_repository.dart';
import 'package:sembast/sembast_memory.dart';

import '../../../helpers/mock_data.dart';
import '../../../helpers/mock_services.dart';

var _testDbCounter = 0;

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform({required this.applicationDocumentsPath});

  final String applicationDocumentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async =>
      applicationDocumentsPath;
}

void main() {
  late Database db;
  late SongRepository songRepository;
  late BackupRepository backupRepository;
  late Directory docsDir;
  late Directory tempDir;
  late Directory rootTmp;
  late PathProviderPlatform originalPathProvider;

  final packageInfo = PackageInfo(
    appName: 'repeatlab',
    packageName: 'repeatlab',
    version: '1.6.11',
    buildNumber: '78',
  );

  final store = StoreRef<String, Map<String, dynamic>>('songs');

  setUp(() async {
    _testDbCounter++;
    db = await databaseFactoryMemory.openDatabase(
      'backup_test_$_testDbCounter.db',
    );
    songRepository = SongRepository(db: db, soLoud: MockSoLoud());

    rootTmp = await Directory.systemTemp.createTemp('rlbackup_test_');
    docsDir = await Directory(p.join(rootTmp.path, 'docs')).create();
    tempDir = await Directory(p.join(rootTmp.path, 'tmp')).create();

    // SongRepository resolves file paths via Song.path (path_provider), which
    // is independent of BackupRepository's injected getDocumentsDirectory —
    // point it at the same docsDir so clearDb's file deletion (exercised via
    // songRepository, the repository under test here) operates on the files
    // BackupRepository actually wrote.
    originalPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProviderPlatform(
      applicationDocumentsPath: docsDir.path,
    );

    backupRepository = BackupRepository(
      db: db,
      songRepository: songRepository,
      packageInfo: packageInfo,
      getDocumentsDirectory: () async => docsDir,
      getTemporaryDirectory: () async => tempDir,
    );
  });

  tearDown(() async {
    songRepository.dispose();
    await db.close();
    PathProviderPlatform.instance = originalPathProvider;
    if (await rootTmp.exists()) {
      await rootTmp.delete(recursive: true);
    }
  });

  Future<void> seedSong(Song song, Uint8List audioBytes) async {
    await store.record(song.id).put(db, song.toMap());
    await File(
      p.join(docsDir.path, song.fileName),
    ).writeAsBytes(audioBytes, flush: true);
  }

  Uint8List bytes(String seed) => Uint8List.fromList(
    List.generate(32, (i) => (seed.codeUnits[i % seed.length] + i) & 0xff),
  );

  group('BackupRepository.exportToFile', () {
    test(
      'writes a roundtrippable .rlbackup file containing all songs',
      () async {
        await seedSong(MockData.songShort, bytes('short'));
        await seedSong(MockData.songMedium, bytes('medium'));

        final file = await backupRepository.exportToFile(
          now: DateTime(2026, 4, 19, 12),
        );

        expect(await file.exists(), isTrue);
        expect(p.basename(file.path), '2026-04-19_repeatlab_export.rlbackup');
        expect(p.dirname(file.path), tempDir.path);

        final payload = const BackupSerializer().decode(
          await file.readAsBytes(),
        );
        expect(payload.manifest.songCount, 2);
        expect(payload.manifest.appVersion, '1.6.11');
        expect(
          payload.songs.map((s) => s.id),
          containsAll([
            MockData.songShort.id,
            MockData.songMedium.id,
          ]),
        );
        expect(payload.audioFiles[MockData.songShort.fileName], bytes('short'));
      },
    );

    test('skips songs whose audio file is missing from disk', () async {
      await seedSong(MockData.songShort, bytes('short'));
      // songMedium has a DB record but no file on disk.
      await store
          .record(MockData.songMedium.id)
          .put(db, MockData.songMedium.toMap());

      final file = await backupRepository.exportToFile();
      final payload = const BackupSerializer().decode(await file.readAsBytes());

      // Both songs recorded in manifest songCount (they exist in DB), but only
      // one audio payload was packaged.
      expect(payload.songs, hasLength(2));
      expect(payload.audioFiles.keys, [MockData.songShort.fileName]);
    });

    test('handles empty library', () async {
      final file = await backupRepository.exportToFile();
      final payload = const BackupSerializer().decode(await file.readAsBytes());
      expect(payload.songs, isEmpty);
      expect(payload.audioFiles, isEmpty);
    });

    test('skips audio songs when includeAudioSongs is false', () async {
      await seedSong(MockData.songShort, bytes('short'));
      final video = MockData.songShort.copyWith(
        id: 'video-1',
        title: 'Sample Video',
        fileName: 'clip.mp4',
        mediaType: MediaType.video,
      );
      await seedSong(video, bytes('video'));

      final file = await backupRepository.exportToFile(
        options: const BackupExportOptions(includeAudioSongs: false),
      );
      final payload = const BackupSerializer().decode(await file.readAsBytes());

      expect(payload.songs.map((s) => s.id), ['video-1']);
      expect(payload.audioFiles.keys, ['clip.mp4']);
    });

    test('skips video songs when includeVideoSongs is false', () async {
      await seedSong(MockData.songShort, bytes('short'));
      final video = MockData.songShort.copyWith(
        id: 'video-1',
        title: 'Sample Video',
        fileName: 'clip.mp4',
        mediaType: MediaType.video,
      );
      await seedSong(video, bytes('video'));

      final file = await backupRepository.exportToFile(
        options: const BackupExportOptions(includeVideoSongs: false),
      );
      final payload = const BackupSerializer().decode(await file.readAsBytes());

      expect(payload.songs.map((s) => s.id), [MockData.songShort.id]);
      expect(payload.audioFiles.keys, [MockData.songShort.fileName]);
    });

    test(
      'strips loops and per-song settings when includeLoopsAndSettings is false',
      () async {
        final richSong = MockData.songMedium.copyWith(
          loops: [MockData.loopVerse, MockData.loopChorus],
          loopSort: LoopSort.startTime,
          sortOrder: 42,
          videoSizeMode: VideoSizeMode.large,
          bpm: 99,
          currentBpm: 110,
        );
        await seedSong(richSong, bytes('rich'));

        final file = await backupRepository.exportToFile(
          options: const BackupExportOptions(includeLoopsAndSettings: false),
        );
        final payload = const BackupSerializer().decode(
          await file.readAsBytes(),
        );
        final exported = payload.songs.single;

        // Intrinsic record preserved.
        expect(exported.id, richSong.id);
        expect(exported.title, richSong.title);
        expect(exported.artist, richSong.artist);
        expect(exported.fileName, richSong.fileName);
        expect(exported.duration, richSong.duration);
        expect(exported.mediaType, richSong.mediaType);

        // Loops + tweakable settings reset to defaults.
        expect(exported.loops, isEmpty);
        expect(exported.bpm, isNull);
        expect(exported.currentBpm, isNull);
        expect(exported.loopSort, LoopSort.none);
        expect(exported.sortOrder, 0);
        expect(exported.videoSizeMode, VideoSizeMode.medium);
      },
    );
  });

  group('BackupRepository.peekImport', () {
    test(
      'returns manifest without writing anything to the documents dir',
      () async {
        await seedSong(MockData.songShort, bytes('short'));
        final exported = await backupRepository.exportToFile();

        // Fresh repo so we can import into a clean state.
        final freshDb = await databaseFactoryMemory.openDatabase(
          'peek_fresh.db',
        );
        final freshSongRepo = SongRepository(db: freshDb, soLoud: MockSoLoud());
        final freshDocs = await Directory(
          p.join(rootTmp.path, 'fresh_docs'),
        ).create();
        final fresh = BackupRepository(
          db: freshDb,
          songRepository: freshSongRepo,
          packageInfo: packageInfo,
          getDocumentsDirectory: () async => freshDocs,
          getTemporaryDirectory: () async => tempDir,
        );

        final manifest = await fresh.peekImport(exported);
        expect(manifest.songCount, 1);
        expect(manifest.schemaVersion, BackupManifest.currentSchemaVersion);
        expect(await freshDocs.list().isEmpty, isTrue);

        freshSongRepo.dispose();
        await freshDb.close();
      },
    );
  });

  group('BackupRepository.importFromFile', () {
    Future<File> exportWith(List<(Song, Uint8List)> seeds) async {
      // Build an export from a separate sandbox DB so the "importing" DB
      // starts empty.
      final sourceDb = await databaseFactoryMemory.openDatabase(
        'source_${seeds.hashCode}.db',
      );
      final sourceSongRepo = SongRepository(db: sourceDb, soLoud: MockSoLoud());
      final sourceDocs = await Directory(
        p.join(rootTmp.path, 'source_${seeds.hashCode}_docs'),
      ).create();

      for (final (song, audio) in seeds) {
        await StoreRef<String, Map<String, dynamic>>(
          'songs',
        ).record(song.id).put(sourceDb, song.toMap());
        await File(
          p.join(sourceDocs.path, song.fileName),
        ).writeAsBytes(audio, flush: true);
      }

      final source = BackupRepository(
        db: sourceDb,
        songRepository: sourceSongRepo,
        packageInfo: packageInfo,
        getDocumentsDirectory: () async => sourceDocs,
        getTemporaryDirectory: () async => tempDir,
      );

      final file = await source.exportToFile();
      sourceSongRepo.dispose();
      await sourceDb.close();
      return file;
    }

    test('merge imports new songs into an empty library', () async {
      final exported = await exportWith([
        (MockData.songShort, bytes('short')),
        (MockData.songMedium, bytes('medium')),
      ]);

      final summary = await backupRepository.importFromFile(
        exported,
        mode: BackupImportMode.merge,
      );

      expect(summary.songsImported, 2);
      expect(summary.songsSkipped, 0);
      expect(summary.filesRenamed, 0);
      expect(summary.replacedExistingLibrary, isFalse);

      final songs = await songRepository.getAllSongs();
      expect(songs, hasLength(2));
      expect(
        await File(
          p.join(docsDir.path, MockData.songShort.fileName),
        ).readAsBytes(),
        bytes('short'),
      );
    });

    test('merge skips songs whose id already exists', () async {
      // Existing library already has songShort.
      await seedSong(MockData.songShort, bytes('short'));

      final exported = await exportWith([
        (MockData.songShort, bytes('short')),
        (MockData.songMedium, bytes('medium')),
      ]);

      final summary = await backupRepository.importFromFile(
        exported,
        mode: BackupImportMode.merge,
      );

      expect(summary.songsImported, 1);
      expect(summary.songsSkipped, 1);
      expect(summary.filesRenamed, 0);

      final songs = await songRepository.getAllSongs();
      expect(
        songs.map((s) => s.id),
        containsAll([
          MockData.songShort.id,
          MockData.songMedium.id,
        ]),
      );
    });

    test(
      'merge renames audio when a different file with the same name exists',
      () async {
        // Song with different id but identical filename already on disk with
        // different content.
        final conflictingSong = MockData.songShort.copyWith(
          id: 'pre-existing',
          title: 'Pre-existing song',
        );
        await seedSong(conflictingSong, bytes('pre-existing-content'));

        final exported = await exportWith([
          (MockData.songShort, bytes('incoming-content')),
        ]);

        final summary = await backupRepository.importFromFile(
          exported,
          mode: BackupImportMode.merge,
        );

        expect(summary.songsImported, 1);
        expect(summary.filesRenamed, 1);

        final songs = await songRepository.getAllSongs();
        final imported = songs.firstWhere((s) => s.id == MockData.songShort.id);
        expect(imported.fileName, isNot(MockData.songShort.fileName));
        expect(imported.fileName, contains('imported-'));
        // Original file untouched.
        expect(
          await File(
            p.join(docsDir.path, MockData.songShort.fileName),
          ).readAsBytes(),
          bytes('pre-existing-content'),
        );
        // Renamed file has the incoming content.
        expect(
          await File(p.join(docsDir.path, imported.fileName)).readAsBytes(),
          bytes('incoming-content'),
        );
      },
    );

    test(
      'merge reuses existing audio file when the content hashes match',
      () async {
        // Same filename AND same content already on disk under a different
        // song id. No rename needed.
        final other = MockData.songMedium.copyWith(
          id: 'other-song',
          fileName: MockData.songShort.fileName,
        );
        await seedSong(other, bytes('shared-content'));

        final exported = await exportWith([
          (MockData.songShort, bytes('shared-content')),
        ]);

        final summary = await backupRepository.importFromFile(
          exported,
          mode: BackupImportMode.merge,
        );

        expect(summary.songsImported, 1);
        expect(summary.filesRenamed, 0);
        final songs = await songRepository.getAllSongs();
        final imported = songs.firstWhere((s) => s.id == MockData.songShort.id);
        expect(imported.fileName, MockData.songShort.fileName);
      },
    );

    test(
      'replace preserves the existing library when the backup is corrupt',
      () async {
        await seedSong(MockData.songLong, bytes('precious'));

        final corrupt = File(p.join(rootTmp.path, 'corrupt.rlbackup'));
        await corrupt.writeAsBytes(List.generate(64, (i) => i), flush: true);

        await expectLater(
          backupRepository.importFromFile(
            corrupt,
            mode: BackupImportMode.replace,
          ),
          throwsA(isA<BackupFormatException>()),
        );

        // The failed import must not have wiped the library.
        final songs = await songRepository.getAllSongs();
        expect(songs.map((s) => s.id), [MockData.songLong.id]);
        expect(
          await File(p.join(docsDir.path, MockData.songLong.fileName)).exists(),
          isTrue,
        );
      },
    );

    test(
      'replace imports songs whose ids already exist in the library',
      () async {
        // The same song exists locally (older loops) and in the backup —
        // replace must import the backup's version, not skip it as a duplicate.
        await seedSong(MockData.songShort, bytes('old-content'));

        final exported = await exportWith([
          (
            MockData.songShort.copyWith(title: 'From backup'),
            bytes('old-content'),
          ),
        ]);

        final summary = await backupRepository.importFromFile(
          exported,
          mode: BackupImportMode.replace,
        );

        expect(summary.songsImported, 1);
        expect(summary.songsSkipped, 0);
        final songs = await songRepository.getAllSongs();
        expect(songs.single.title, 'From backup');
      },
    );

    test(
      'replace does not delete a file reused via hash-dedup for the new song',
      () async {
        // Identical content means the isolate reuses the existing file rather
        // than writing a new one, so the incoming song ends up with the same
        // fileName as the old song being cleared. clearDb's file deletion
        // must not delete a file the new song still needs.
        await seedSong(MockData.songShort, bytes('same-content'));

        final exported = await exportWith([
          (
            MockData.songShort.copyWith(title: 'From backup'),
            bytes('same-content'),
          ),
        ]);

        await backupRepository.importFromFile(
          exported,
          mode: BackupImportMode.replace,
        );

        final songs = await songRepository.getAllSongs();
        expect(songs.single.fileName, MockData.songShort.fileName);
        expect(
          await File(
            p.join(docsDir.path, MockData.songShort.fileName),
          ).exists(),
          isTrue,
        );
      },
    );

    test('skips songs whose fileName would escape the documents dir', () async {
      // Craft a malicious backup directly via the serializer: the song's
      // fileName tries to traverse out of the docs dir (zip-slip).
      const evilName = '../evil.mp3';
      final evilSong = MockData.songShort.copyWith(fileName: evilName);
      final payload = const BackupSerializer().encode(
        songs: [evilSong],
        audioFiles: {evilName: bytes('evil')},
        appVersion: '1.6.11',
      );
      final malicious = File(p.join(rootTmp.path, 'malicious.rlbackup'));
      await malicious.writeAsBytes(payload, flush: true);

      final summary = await backupRepository.importFromFile(
        malicious,
        mode: BackupImportMode.merge,
      );

      expect(summary.songsImported, 0);
      expect(summary.songsSkipped, 1);
      // Nothing escaped the docs dir (docsDir is rootTmp/docs, so ../evil.mp3
      // would land directly in rootTmp).
      expect(await File(p.join(rootTmp.path, 'evil.mp3')).exists(), isFalse);
      expect(await songRepository.getAllSongs(), isEmpty);
    });

    test('replace wipes the existing DB before importing', () async {
      await seedSong(MockData.songLong, bytes('to-be-wiped'));

      final exported = await exportWith([
        (MockData.songShort, bytes('short')),
      ]);

      final summary = await backupRepository.importFromFile(
        exported,
        mode: BackupImportMode.replace,
      );

      expect(summary.replacedExistingLibrary, isTrue);
      expect(summary.songsImported, 1);

      final songs = await songRepository.getAllSongs();
      expect(songs, hasLength(1));
      expect(songs.single.id, MockData.songShort.id);
    });

    test(
      "replace deletes the replaced song's orphaned file from disk",
      () async {
        await seedSong(MockData.songLong, bytes('to-be-wiped'));

        final exported = await exportWith([
          (MockData.songShort, bytes('short')),
        ]);

        await backupRepository.importFromFile(
          exported,
          mode: BackupImportMode.replace,
        );

        expect(
          await File(
            p.join(docsDir.path, MockData.songLong.fileName),
          ).exists(),
          isFalse,
        );
        expect(
          await File(
            p.join(docsDir.path, MockData.songShort.fileName),
          ).exists(),
          isTrue,
        );
      },
    );
  });
}
