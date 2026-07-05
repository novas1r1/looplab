import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/repositories/backup/backup_exceptions.dart';
import 'package:repeatlab/data/repositories/backup/backup_manifest.dart';

/// Serializer for the `.rlbackup` format.
///
/// Two encode paths:
/// * [encode] builds the archive fully in memory — used by unit tests and
///   small round-trips.
/// * [encodeToFile] streams audio entries from disk via [ZipFileEncoder] —
///   used in production so video-sized libraries don't OOM.
///
/// Decode is in-memory only; see `docs/known_issues.md` for the matching
/// import-side limitation.
///
/// Layout:
///   manifest.json   — schema version, app version, exported timestamp,
///                     per-file sizes (and, in legacy 1.7.x–2.0.1 exports,
///                     SHA-256 hashes — no longer written or verified).
///   songs.json      — dart_mappable JSON list of Song (loops embedded)
///   audio/`name`    — raw audio bytes, one per song, keyed by [Song.fileName]
class BackupSerializer {
  static const String manifestFileName = 'manifest.json';
  static const String songsFileName = 'songs.json';
  static const String audioDirectory = 'audio';

  const BackupSerializer();

  /// Encodes [songs] and their [audioFiles] (keyed by `Song.fileName`) into a
  /// zip byte buffer. Audio files referenced by songs but missing from the map
  /// are skipped silently — the caller (repository) is responsible for the
  /// consistency check, since it owns the filesystem.
  Uint8List encode({
    required List<Song> songs,
    required Map<String, Uint8List> audioFiles,
    required String appVersion,
    DateTime? exportedAt,
  }) {
    final manifest = BackupManifest(
      schemaVersion: BackupManifest.currentSchemaVersion,
      appVersion: appVersion,
      exportedAt: (exportedAt ?? DateTime.now().toUtc()).toIso8601String(),
      songCount: songs.length,
      audioFiles: {
        for (final entry in audioFiles.entries)
          entry.key: BackupFileInfo(size: entry.value.length),
      },
    );

    final archive = Archive();

    final manifestBytes = utf8.encode(jsonEncode(manifest.toMap()));
    archive.addFile(
      ArchiveFile(manifestFileName, manifestBytes.length, manifestBytes),
    );

    final songsBytes = utf8.encode(
      jsonEncode(songs.map((s) => s.toMap()).toList()),
    );
    archive.addFile(
      ArchiveFile(songsFileName, songsBytes.length, songsBytes),
    );

    for (final entry in audioFiles.entries) {
      archive.addFile(
        ArchiveFile(
          '$audioDirectory/${entry.key}',
          entry.value.length,
          entry.value,
        ),
      );
    }

    final encoded = ZipEncoder().encode(archive);
    return Uint8List.fromList(encoded);
  }

  /// Streaming variant of [encode]. Writes the archive directly to [outPath],
  /// reading audio entries from disk one at a time via [ZipFileEncoder]. Peak
  /// memory is roughly one libarchive buffer (~64 KB) per file, not the size
  /// of the whole library. Use this for the production export path; the
  /// in-memory [encode] is kept for unit tests and small round-trips.
  ///
  /// [audioFilePaths] maps `Song.fileName` → absolute path on disk. Caller is
  /// responsible for filtering out songs whose audio file is missing.
  Future<void> encodeToFile({
    required List<Song> songs,
    required Map<String, String> audioFilePaths,
    required String outPath,
    required String appVersion,
    DateTime? exportedAt,
  }) async {
    final manifest = BackupManifest(
      schemaVersion: BackupManifest.currentSchemaVersion,
      appVersion: appVersion,
      exportedAt: (exportedAt ?? DateTime.now().toUtc()).toIso8601String(),
      songCount: songs.length,
      audioFiles: {
        for (final entry in audioFilePaths.entries)
          entry.key: BackupFileInfo(size: File(entry.value).lengthSync()),
      },
    );

    final encoder = ZipFileEncoder()..create(outPath);
    try {
      final manifestBytes = utf8.encode(jsonEncode(manifest.toMap()));
      encoder.addArchiveFile(
        ArchiveFile(manifestFileName, manifestBytes.length, manifestBytes),
      );

      final songsBytes = utf8.encode(
        jsonEncode(songs.map((s) => s.toMap()).toList()),
      );
      encoder.addArchiveFile(
        ArchiveFile(songsFileName, songsBytes.length, songsBytes),
      );

      for (final entry in audioFilePaths.entries) {
        await encoder.addFile(
          File(entry.value),
          '$audioDirectory/${entry.key}',
        );
      }
    } finally {
      await encoder.close();
    }
  }

  /// Reads the manifest without decoding audio payloads — cheap, used by the
  /// dry-run confirmation dialog. In-memory entry point; the streaming peek
  /// path drives [readManifestFromArchive] over an [InputFileStream] directly.
  BackupManifest peekManifest(Uint8List bytes) {
    final archive = _safeDecode(bytes);
    return readManifestFromArchive(archive);
  }

  /// Full decode: validates schema version, parses songs, materializes every
  /// audio file. Used by tests and small-library round-trips. Production
  /// import drives [decodeHeaderFromArchive] + per-entry streaming instead.
  BackupPayload decode(Uint8List bytes) {
    final archive = _safeDecode(bytes);
    final (manifest: manifest, songs: songs) = decodeHeaderFromArchive(archive);

    // Zip CRC32 (validated by ZipDecoder) covers accidental corruption.
    // We don't recompute SHA-256 even when older 1.7.x–2.0.1 exports include
    // it on the manifest — see BackupManifest.currentSchemaVersion docs.
    final audioFiles = <String, Uint8List>{};
    for (final entry in manifest.audioFiles.entries) {
      final archiveFile = archive.findFile('$audioDirectory/${entry.key}');
      if (archiveFile == null) {
        throw BackupFormatException(
          'audio file "${entry.key}" listed in manifest is missing',
        );
      }
      audioFiles[entry.key] = Uint8List.fromList(
        archiveFile.content as List<int>,
      );
    }

    return BackupPayload(
      manifest: manifest,
      songs: songs,
      audioFiles: audioFiles,
    );
  }

  /// Parses the manifest and songs.json from an already-opened [archive] and
  /// validates the schema version. Does NOT materialize audio entries — the
  /// caller is expected to iterate them separately, streaming each to disk
  /// when the archive was opened over an [InputFileStream]. Used by the
  /// production import path so video-sized libraries don't OOM.
  ({BackupManifest manifest, List<Song> songs}) decodeHeaderFromArchive(
    Archive archive,
  ) {
    final manifest = readManifestFromArchive(archive);

    if (manifest.schemaVersion > BackupManifest.currentSchemaVersion) {
      throw BackupSchemaVersionException(
        backupVersion: manifest.schemaVersion,
        supportedVersion: BackupManifest.currentSchemaVersion,
      );
    }

    final songsFile = archive.findFile(songsFileName);
    if (songsFile == null) {
      throw const BackupFormatException('songs.json missing');
    }
    final songsRaw = jsonDecode(utf8.decode(songsFile.content as List<int>));
    if (songsRaw is! List) {
      throw const BackupFormatException('songs.json is not a list');
    }
    final songs = songsRaw
        .map((e) => SongMapper.fromMap(e as Map<String, dynamic>))
        .toList();

    return (manifest: manifest, songs: songs);
  }

  Archive _safeDecode(Uint8List bytes) {
    try {
      return ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      throw BackupFormatException('archive is not a valid zip: $e');
    }
  }

  /// Reads only the manifest from an already-opened [archive]. Public because
  /// the streaming import path opens its own [Archive] over an
  /// [InputFileStream] and needs to read the manifest without going through
  /// the in-memory [peekManifest] / [decode] entry points.
  BackupManifest readManifestFromArchive(Archive archive) {
    final manifestFile = archive.findFile(manifestFileName);
    if (manifestFile == null) {
      throw const BackupFormatException('manifest.json missing');
    }
    try {
      final raw = jsonDecode(utf8.decode(manifestFile.content as List<int>));
      return BackupManifestMapper.fromMap(raw as Map<String, dynamic>);
    } on BackupFormatException {
      rethrow;
    } catch (e) {
      throw BackupFormatException('manifest.json is malformed: $e');
    }
  }
}

class BackupPayload {
  final BackupManifest manifest;
  final List<Song> songs;
  final Map<String, Uint8List> audioFiles;

  const BackupPayload({
    required this.manifest,
    required this.songs,
    required this.audioFiles,
  });
}
