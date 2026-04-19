import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:repeatlab/data/repositories/backup/backup_manifest.dart';
import 'package:repeatlab/data/repositories/backup/backup_serializer.dart';
import 'package:repeatlab/data/repositories/song_repository.dart';
import 'package:sembast/sembast.dart';
import 'package:uuid/uuid.dart';

enum BackupImportMode { merge, replace }

class BackupImportSummary {
  /// New songs written to the DB.
  final int songsImported;

  /// Songs skipped because a song with the same id already existed.
  final int songsSkipped;

  /// Songs whose audio file was renamed to avoid clobbering a different
  /// existing file with the same name.
  final int filesRenamed;

  /// True if the existing library was wiped before importing
  /// ([BackupImportMode.replace]).
  final bool replacedExistingLibrary;

  const BackupImportSummary({
    required this.songsImported,
    required this.songsSkipped,
    required this.filesRenamed,
    required this.replacedExistingLibrary,
  });
}

class BackupRepository {
  static const String fileExtension = 'rlbackup';
  static const String _storeName = 'songs';

  final Database db;
  final SongRepository songRepository;
  final PackageInfo packageInfo;
  final BackupSerializer serializer;

  // Injectable for tests.
  final Future<Directory> Function() _getDocumentsDirectory;
  final Future<Directory> Function() _getTemporaryDirectory;

  final _store = StoreRef<String, Map<String, dynamic>>(_storeName);

  BackupRepository({
    required this.db,
    required this.songRepository,
    required this.packageInfo,
    this.serializer = const BackupSerializer(),
    Future<Directory> Function()? getDocumentsDirectory,
    Future<Directory> Function()? getTemporaryDirectory,
  }) : _getDocumentsDirectory =
           getDocumentsDirectory ?? path_provider.getApplicationDocumentsDirectory,
       _getTemporaryDirectory =
           getTemporaryDirectory ?? path_provider.getTemporaryDirectory;

  /// Collects every song and its audio file, packages them into a
  /// `.rlbackup` archive in the temp directory, and returns the file.
  /// Caller is responsible for sharing/moving the file.
  Future<File> exportToFile({DateTime? now}) async {
    final songs = await songRepository.getAllSongs();
    final docsDir = await _getDocumentsDirectory();

    final audioFiles = <String, Uint8List>{};
    for (final song in songs) {
      final audioFile = File(p.join(docsDir.path, song.fileName));
      if (!await audioFile.exists()) {
        log(
          'BackupRepository.exportToFile: audio file missing for '
          'song "${song.title}" (${song.fileName}); skipping',
        );
        continue;
      }
      audioFiles[song.fileName] = await audioFile.readAsBytes();
    }

    final bytes = serializer.encode(
      songs: songs,
      audioFiles: audioFiles,
      appVersion: packageInfo.version,
      exportedAt: now,
    );

    final tempDir = await _getTemporaryDirectory();
    final fileName = _buildExportFileName(now ?? DateTime.now());
    final outFile = File(p.join(tempDir.path, fileName));
    await outFile.writeAsBytes(bytes, flush: true);

    return outFile;
  }

  /// Reads just the manifest from a backup file — cheap, used to render the
  /// confirmation dialog ("12 songs, 230 MB — merge or replace?").
  Future<BackupManifest> peekImport(File file) async {
    final bytes = await file.readAsBytes();
    return serializer.peekManifest(bytes);
  }

  /// Imports a backup into the local DB and documents directory.
  ///
  /// Merge behavior: songs whose `id` already exists in the DB are skipped.
  /// Replace behavior: the existing songs store is cleared first, then the
  /// backup is merged into the empty DB.
  ///
  /// Filename collisions (same name, different content) trigger a rename of
  /// the incoming file to `<stem>-imported-<shortuuid>.<ext>`.
  Future<BackupImportSummary> importFromFile(
    File file, {
    required BackupImportMode mode,
  }) async {
    final bytes = await file.readAsBytes();
    final payload = serializer.decode(bytes);

    final docsDir = await _getDocumentsDirectory();
    await docsDir.create(recursive: true);

    var replaced = false;
    if (mode == BackupImportMode.replace) {
      await songRepository.clearDb();
      replaced = true;
    }

    final existingRecords = await _store.find(db);
    final existingIds = existingRecords
        .map((r) => r.value['id'] as String)
        .toSet();

    var imported = 0;
    var skipped = 0;
    var renamed = 0;

    for (final song in payload.songs) {
      if (existingIds.contains(song.id)) {
        skipped++;
        continue;
      }

      final incomingBytes = payload.audioFiles[song.fileName];
      if (incomingBytes == null) {
        // Manifest integrity is enforced in decode(); defensive skip.
        log(
          'BackupRepository.importFromFile: audio missing in payload for '
          'song "${song.title}" (${song.fileName}); skipping',
        );
        skipped++;
        continue;
      }

      final resolvedFileName = await _writeAudioResolvingCollisions(
        docsDir: docsDir,
        desiredFileName: song.fileName,
        incomingBytes: incomingBytes,
      );

      final songToPersist = resolvedFileName == song.fileName
          ? song
          : song.copyWith(fileName: resolvedFileName);

      if (resolvedFileName != song.fileName) {
        renamed++;
      }

      await _store.record(songToPersist.id).put(db, songToPersist.toMap());
      existingIds.add(songToPersist.id);
      imported++;
    }

    await songRepository.getAllSongs();

    return BackupImportSummary(
      songsImported: imported,
      songsSkipped: skipped,
      filesRenamed: renamed,
      replacedExistingLibrary: replaced,
    );
  }

  Future<String> _writeAudioResolvingCollisions({
    required Directory docsDir,
    required String desiredFileName,
    required Uint8List incomingBytes,
  }) async {
    final target = File(p.join(docsDir.path, desiredFileName));

    if (!await target.exists()) {
      await target.writeAsBytes(incomingBytes, flush: true);
      return desiredFileName;
    }

    final existingBytes = await target.readAsBytes();
    final existingHash = sha256.convert(existingBytes);
    final incomingHash = sha256.convert(incomingBytes);

    if (existingHash == incomingHash) {
      // Same file already on disk — reuse it, don't rewrite.
      return desiredFileName;
    }

    // Genuine collision: rename.
    final ext = p.extension(desiredFileName);
    final stem = p.basenameWithoutExtension(desiredFileName);
    final suffix = const Uuid().v4().substring(0, 8);
    final renamed = '$stem-imported-$suffix$ext';
    await File(p.join(docsDir.path, renamed))
        .writeAsBytes(incomingBytes, flush: true);
    return renamed;
  }

  String _buildExportFileName(DateTime exportedAt) {
    final local = exportedAt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return 'repeatlab-backup-$y-$m-$d.$fileExtension';
  }
}
