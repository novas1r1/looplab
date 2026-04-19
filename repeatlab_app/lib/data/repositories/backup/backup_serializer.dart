import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/repositories/backup/backup_exceptions.dart';
import 'package:repeatlab/data/repositories/backup/backup_manifest.dart';

/// Pure, in-memory serializer for the `.rlbackup` format.
///
/// Layout:
///   manifest.json   — schema version, app version, exported timestamp, file hashes
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
          entry.key: BackupFileInfo(
            sha256: sha256.convert(entry.value).toString(),
            size: entry.value.length,
          ),
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

  /// Reads the manifest without decoding audio payloads — cheap, used by the
  /// dry-run confirmation dialog.
  BackupManifest peekManifest(Uint8List bytes) {
    final archive = _safeDecode(bytes);
    return _readManifest(archive);
  }

  /// Full decode: validates schema version, parses songs, verifies every audio
  /// file's hash against the manifest. Throws on any inconsistency.
  BackupPayload decode(Uint8List bytes) {
    final archive = _safeDecode(bytes);
    final manifest = _readManifest(archive);

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

    final audioFiles = <String, Uint8List>{};
    for (final entry in manifest.audioFiles.entries) {
      final archiveFile = archive.findFile('$audioDirectory/${entry.key}');
      if (archiveFile == null) {
        throw BackupFormatException(
          'audio file "${entry.key}" listed in manifest is missing',
        );
      }
      final content = Uint8List.fromList(archiveFile.content as List<int>);
      final actualHash = sha256.convert(content).toString();
      if (actualHash != entry.value.sha256) {
        throw BackupHashMismatchException(entry.key);
      }
      audioFiles[entry.key] = content;
    }

    return BackupPayload(
      manifest: manifest,
      songs: songs,
      audioFiles: audioFiles,
    );
  }

  Archive _safeDecode(Uint8List bytes) {
    try {
      return ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      throw BackupFormatException('archive is not a valid zip: $e');
    }
  }

  BackupManifest _readManifest(Archive archive) {
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
