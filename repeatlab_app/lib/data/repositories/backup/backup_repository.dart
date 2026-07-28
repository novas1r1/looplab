import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/repositories/backup/backup_exceptions.dart';
import 'package:repeatlab/data/repositories/backup/backup_manifest.dart';
import 'package:repeatlab/data/repositories/backup/backup_serializer.dart';
import 'package:repeatlab/data/repositories/backup_activity_guard.dart';
import 'package:repeatlab/data/repositories/song_repository.dart';
import 'package:sembast/sembast.dart';
import 'package:uuid/uuid.dart';

enum BackupImportMode { merge, replace }

/// Selects what an [BackupRepository.exportToFile] call should include.
/// Defaults are "everything on" — the picker in the export sheet opts out of
/// pieces the user doesn't want.
class BackupExportOptions {
  /// When false, audio songs ([MediaType.audio]) are excluded.
  final bool includeAudioSongs;

  /// When false, video songs ([MediaType.video]) are excluded.
  final bool includeVideoSongs;

  /// When false, each exported song is stripped of its loops + per-song
  /// settings (bpm, currentBpm, loopSort, sortOrder, videoSizeMode) — only
  /// the intrinsic record (id/title/artist/fileName/duration/mediaType) is
  /// kept. The user gets a clean import with default playback state.
  final bool includeLoopsAndSettings;

  const BackupExportOptions({
    this.includeAudioSongs = true,
    this.includeVideoSongs = true,
    this.includeLoopsAndSettings = true,
  });

  /// All flags on — the default behaviour and the value used by callers that
  /// pre-date the export picker.
  static const all = BackupExportOptions();

  /// True when at least one media-type flag is on. The export sheet's
  /// "Export" button is disabled when this is false, since an export with no
  /// audio AND no video would contain only an empty song list.
  bool get hasAnyMedia => includeAudioSongs || includeVideoSongs;
}

/// Strips loops and per-song settings, returning a song record that decodes
/// back into the same intrinsic media (id/title/artist/file/duration/type)
/// with the default values for everything else. Used by the export path when
/// the user unchecks "Loops & settings".
Song _stripLoopsAndSettings(Song s) => Song(
  id: s.id,
  title: s.title,
  artist: s.artist,
  fileName: s.fileName,
  duration: s.duration,
  mediaType: s.mediaType,
);

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
           getDocumentsDirectory ??
           path_provider.getApplicationDocumentsDirectory,
       _getTemporaryDirectory =
           getTemporaryDirectory ?? path_provider.getTemporaryDirectory;

  /// Collects every song and its audio file, packages them into a
  /// `.rlbackup` archive in the temp directory, and returns the file.
  /// Caller is responsible for sharing/moving the file.
  ///
  /// [options] gates which songs and which per-song fields are included; see
  /// [BackupExportOptions]. The default is the full library.
  ///
  /// Audio bytes are streamed from disk by [BackupSerializer.encodeToFile]
  /// rather than loaded into memory upfront, so video-sized libraries don't
  /// OOM during export.
  Future<File> exportToFile({
    BackupExportOptions options = BackupExportOptions.all,
    DateTime? now,
  }) {
    return BackupActivityGuard.run(() => _exportToFile(options, now));
  }

  Future<File> _exportToFile(BackupExportOptions options, DateTime? now) async {
    final allSongs = await songRepository.getAllSongs();
    final docsDir = await _getDocumentsDirectory();

    // Filter by media type, then strip per-song settings if the user opted
    // out of "Loops & settings".
    final filtered = allSongs.where(
      (s) => switch (s.mediaType) {
        MediaType.audio => options.includeAudioSongs,
        MediaType.video => options.includeVideoSongs,
      },
    );
    final songs = options.includeLoopsAndSettings
        ? filtered.toList()
        : filtered.map(_stripLoopsAndSettings).toList();

    // Collect paths (not bytes) for songs whose audio is on disk.
    final audioFilePaths = <String, String>{};
    for (final song in songs) {
      final audioPath = p.join(docsDir.path, song.fileName);
      if (!await File(audioPath).exists()) {
        log(
          'BackupRepository.exportToFile: audio file missing for '
          'song "${song.title}" (${song.fileName}); skipping',
        );
        continue;
      }
      audioFilePaths[song.fileName] = audioPath;
    }

    final tempDir = await _getTemporaryDirectory();
    final fileName = _buildExportFileName(now ?? DateTime.now());
    final outPath = p.join(tempDir.path, fileName);
    final songMaps = songs.map((s) => s.toMap()).toList();
    final appVersion = packageInfo.version;
    final exportedAt = now;

    // Stream the zip on a background isolate to keep the UI thread free.
    // ZipFileEncoder writes each entry to disk as it's added — peak memory is
    // ~one buffer per file, not the size of the whole library.
    await Isolate.run(() async {
      final restoredSongs = songMaps.map((m) => SongMapper.fromMap(m)).toList();
      await const BackupSerializer().encodeToFile(
        songs: restoredSongs,
        audioFilePaths: audioFilePaths,
        outPath: outPath,
        appVersion: appVersion,
        exportedAt: exportedAt,
      );
    });

    return File(outPath);
  }

  /// Reads just the manifest from a backup file — cheap, used to render the
  /// confirmation dialog ("12 songs, 230 MB — merge or replace?"). Streams
  /// the archive over [InputFileStream] so peeking a multi-GB backup doesn't
  /// load the whole file into memory just to read a few KB of metadata.
  Future<BackupManifest> peekImport(File file) async {
    final input = InputFileStream(file.path);
    try {
      final Archive archive;
      try {
        archive = ZipDecoder().decodeStream(input);
      } catch (e) {
        throw BackupFormatException('archive is not a valid zip: $e');
      }
      return serializer.readManifestFromArchive(archive);
    } finally {
      await input.close();
    }
  }

  /// Imports a backup into the local DB and documents directory.
  ///
  /// Merge behavior: songs whose `id` already exists in the DB are skipped.
  /// Replace behavior: the backup is decoded and its files written to disk
  /// first; only then is the existing songs store cleared and the backup
  /// persisted — a corrupt or failing backup never destroys the library.
  ///
  /// Filename collisions (same name, different content) trigger a rename of
  /// the incoming file to `<stem>-imported-<shortuuid>.<ext>`.
  ///
  /// Audio entries are streamed from the archive directly to disk via
  /// [InputFileStream] / [OutputFileStream], so peak memory during import is
  /// roughly one entry, not the size of the whole archive.
  Future<BackupImportSummary> importFromFile(
    File file, {
    required BackupImportMode mode,
  }) {
    return BackupActivityGuard.run(() => _importFromFile(file, mode: mode));
  }

  Future<BackupImportSummary> _importFromFile(
    File file, {
    required BackupImportMode mode,
  }) async {
    final docsDir = await _getDocumentsDirectory();
    await docsDir.create(recursive: true);

    final existingRecords = await _store.find(db);
    final existingIds = existingRecords
        .map((r) => r.value['id'] as String)
        .toSet();

    // Stream-decode in a background isolate. The isolate writes audio entries
    // straight to the docs dir and returns the song maps to persist; the DB
    // writes happen on the main isolate afterwards.
    //
    // In replace mode no ids are "existing" — the whole library is replaced,
    // so every song in the backup should be imported, none skipped.
    final archivePath = file.path;
    final docsPath = docsDir.path;
    final knownIds = mode == BackupImportMode.replace
        ? <String>[]
        : existingIds.toList();
    final result = await Isolate.run(
      () => _streamImportInIsolate(
        archivePath: archivePath,
        docsPath: docsPath,
        existingIds: knownIds,
      ),
    );

    // Only wipe the existing library once the archive has decoded and its
    // audio entries are safely on disk. Clearing before that point would
    // destroy the user's library when the backup turns out to be corrupt or
    // the import fails midway.
    var replaced = false;
    if (mode == BackupImportMode.replace) {
      // The incoming songs' files are already on disk at this point (see the
      // isolate call above) — protect their fileNames from clearDb's file
      // deletion, since a hash-dedup collision can point an old and a new
      // song at the same file.
      final keepFileNames = result.songMapsToPersist
          .map((songMap) => songMap['fileName'] as String)
          .toSet();
      // This clearDb call IS the guarded transfer (BackupActivityGuard is
      // already active from importFromFile), so it must not skip itself —
      // its file safety is already handled via keepFileNames above.
      await songRepository.clearDb(
        keepFileNames: keepFileNames,
        respectBackupGuard: false,
      );
      replaced = true;
      existingIds.clear();
    }

    for (final songMap in result.songMapsToPersist) {
      final id = songMap['id'] as String;
      await _store.record(id).put(db, songMap);
      existingIds.add(id);
    }

    await songRepository.getAllSongs();

    return BackupImportSummary(
      songsImported: result.songMapsToPersist.length,
      songsSkipped: result.skipped,
      filesRenamed: result.renamed,
      replacedExistingLibrary: replaced,
    );
  }

  String _buildExportFileName(DateTime exportedAt) {
    final local = exportedAt.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-${d}_repeatlab_export.$fileExtension';
  }
}

/// Result of the isolate-side streaming import — DB writes happen on the main
/// isolate afterwards using [songMapsToPersist].
class _StreamImportResult {
  final List<Map<String, dynamic>> songMapsToPersist;
  final int skipped;
  final int renamed;

  const _StreamImportResult({
    required this.songMapsToPersist,
    required this.skipped,
    required this.renamed,
  });
}

/// Top-level so it can run in [Isolate.run]. Opens the archive via
/// [InputFileStream], iterates songs in order, and writes each audio entry to
/// disk in the docs dir one at a time — no payload is held in memory across
/// iterations.
Future<_StreamImportResult> _streamImportInIsolate({
  required String archivePath,
  required String docsPath,
  required List<String> existingIds,
}) async {
  final input = InputFileStream(archivePath);
  try {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeStream(input);
    } catch (e) {
      throw BackupFormatException('archive is not a valid zip: $e');
    }

    final (manifest: _, songs: songs) = const BackupSerializer()
        .decodeHeaderFromArchive(archive);

    final knownIds = existingIds.toSet();
    final songMapsToPersist = <Map<String, dynamic>>[];
    var skipped = 0;
    var renamed = 0;

    for (final song in songs) {
      if (knownIds.contains(song.id)) {
        skipped++;
        continue;
      }

      // Zip-slip guard: fileName comes straight from the backup's songs.json
      // and is joined onto the docs dir below. A crafted backup with a name
      // like "../../evil" could otherwise write outside the sandbox.
      if (!_isSafeFileName(song.fileName)) {
        log(
          'BackupRepository: unsafe fileName in backup for '
          'song "${song.title}" ("${song.fileName}"); skipping',
        );
        skipped++;
        continue;
      }

      final entry = archive.findFile(
        '${BackupSerializer.audioDirectory}/${song.fileName}',
      );
      if (entry == null) {
        // Manifest-vs-archive consistency is checked by decodeHeader for the
        // header itself; missing audio entries are tolerated with a skip so a
        // partial backup can still import the songs it does have.
        log(
          'BackupRepository: audio missing in archive for '
          'song "${song.title}" (${song.fileName}); skipping',
        );
        skipped++;
        continue;
      }

      final resolved = await _streamEntryResolvingCollisions(
        entry: entry,
        docsPath: docsPath,
        desiredFileName: song.fileName,
      );

      if (resolved.renamed) renamed++;

      final songToPersist = resolved.fileName == song.fileName
          ? song
          : song.copyWith(fileName: resolved.fileName);

      songMapsToPersist.add(songToPersist.toMap());
      knownIds.add(songToPersist.id);
    }

    return _StreamImportResult(
      songMapsToPersist: songMapsToPersist,
      skipped: skipped,
      renamed: renamed,
    );
  } finally {
    await input.close();
  }
}

/// True when [fileName] is a plain file name that stays inside the directory
/// it is joined onto: non-empty, no path separators (either flavor — backups
/// may be crafted on any OS), and not a dot-segment.
bool _isSafeFileName(String fileName) {
  if (fileName.isEmpty) return false;
  if (fileName.contains('/') || fileName.contains('\\')) return false;
  if (fileName == '.' || fileName == '..') return false;
  return true;
}

/// Streams a single archive entry to a temp file in [docsPath], then resolves
/// any filename collision: if the target slot is free → rename temp into
/// place; if a file with identical size + SHA-256 is already there → discard
/// temp and reuse the existing file; otherwise rename the temp file to
/// `<stem>-imported-<shortuuid>.<ext>`.
///
/// Size check before hashing skips the expensive SHA-256 pass for the common
/// "different content" case (different size → definitely different content).
Future<({String fileName, bool renamed})> _streamEntryResolvingCollisions({
  required ArchiveFile entry,
  required String docsPath,
  required String desiredFileName,
}) async {
  // Unique temp name so concurrent or interrupted imports can't clobber each
  // other. Lives in docs dir so the final rename is same-filesystem (atomic).
  final tempSuffix = const Uuid().v4().substring(0, 8);
  final tempPath = p.join(docsPath, '$desiredFileName.$tempSuffix.import-tmp');

  final out = OutputFileStream(tempPath);
  try {
    entry.writeContent(out);
  } finally {
    await out.close();
  }

  final tempFile = File(tempPath);
  final target = File(p.join(docsPath, desiredFileName));

  if (!await target.exists()) {
    await tempFile.rename(target.path);
    return (fileName: desiredFileName, renamed: false);
  }

  final existingSize = await target.length();
  final tempSize = await tempFile.length();

  if (existingSize == tempSize) {
    final existingHash = await _streamHash(target);
    final tempHash = await _streamHash(tempFile);
    if (existingHash == tempHash) {
      // Same content already on disk — drop the temp copy.
      await tempFile.delete();
      return (fileName: desiredFileName, renamed: false);
    }
  }

  // Different content (different size or different hash). Rename to avoid
  // clobbering the existing file.
  final ext = p.extension(desiredFileName);
  final stem = p.basenameWithoutExtension(desiredFileName);
  final renamedSuffix = const Uuid().v4().substring(0, 8);
  final renamedFileName = '$stem-imported-$renamedSuffix$ext';
  await tempFile.rename(p.join(docsPath, renamedFileName));
  return (fileName: renamedFileName, renamed: true);
}

Future<Digest> _streamHash(File file) {
  return sha256.bind(file.openRead()).single;
}
