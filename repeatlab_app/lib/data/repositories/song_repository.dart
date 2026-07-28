import 'dart:async';
import 'dart:developer';
import 'dart:io';

// import 'package:audiotags/audiotags.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';
import 'package:flutter_soloud/flutter_soloud.dart'
    hide AudioMetadata, Mp3Metadata;
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;
import 'package:repeatlab/core/utils/musical_key.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:sembast/sembast.dart';
import 'package:uuid/uuid.dart';

class SongRepository {
  final Database db;
  final SoLoud soLoud;

  final _store = StoreRef<String, Map<String, dynamic>>('songs');

  final _songController = StreamController<List<Song>>.broadcast();

  SongRepository({
    required this.db,
    required this.soLoud,
  });

  Stream<List<Song>> get songs => _songController.stream;

  Future<List<Song>> getAllSongs() async {
    final records = await _store.find(
      db,
      finder: Finder(sortOrders: [SortOrder('sortOrder')]),
    );
    final songs = records.map((e) => SongMapper.fromMap(e.value)).toList();
    _songController.add(songs);

    return songs;
  }

  Future<void> incrementExistingSortOrders() async {
    final records = await _store.find(db);
    for (final record in records) {
      final song = SongMapper.fromMap(record.value);
      await record.ref.update(
        db,
        song.copyWith(sortOrder: song.sortOrder + 1).toMap(),
      );
    }
  }

  Future<void> reorderSongs(List<Song> songs) async {
    for (final song in songs) {
      await _store.update(
        db,
        song.toMap(),
        finder: Finder(filter: Filter.equals('id', song.id)),
      );
    }
    await getAllSongs();
  }

  /// File extensions natively supported by SoLoud (via miniaudio).
  static const _soloudSupportedExtensions = {'.mp3', '.wav', '.ogg', '.flac'};

  /// Human-readable list of supported formats shown in error messages.
  static const supportedFormatsLabel = 'MP3, WAV, OGG, FLAC, M4A, AAC';

  /// File extensions imported as videos (played via media_kit / libmpv).
  /// Superset across platforms — videos restored from a backup may use any
  /// of these, regardless of what the local picker offers.
  static const _videoSupportedExtensions = {
    '.mp4',
    '.mov',
    '.m4v',
    '.mkv',
    '.webm',
    '.avi',
  };

  /// Video formats users can pick on each platform. Currently identical,
  /// but kept separate because the pickers filter differently: Android
  /// filters via MIME types, iOS via UTIs. mkv/webm have no system UTI on
  /// iOS and only resolve because they are declared under
  /// UTImportedTypeDeclarations in ios/Runner/Info.plist — keep that
  /// declaration in sync with [videoPickerExtensionsIos].
  static const videoPickerExtensionsAndroid = [
    'mp4',
    'mov',
    'm4v',
    'mkv',
    'webm',
    'avi',
  ];
  static const videoPickerExtensionsIos = [
    'mp4',
    'mov',
    'm4v',
    'mkv',
    'webm',
    'avi',
  ];

  /// Video formats pickable on the current platform.
  static List<String> get videoPickerExtensions =>
      Platform.isIOS ? videoPickerExtensionsIos : videoPickerExtensionsAndroid;

  /// Human-readable list of supported video formats shown in error messages
  /// and pick dialogs; derived from the platform's picker extensions.
  static String get supportedVideoFormatsLabel =>
      videoPickerExtensions.map((e) => e.toUpperCase()).join(', ');

  Future<void> addSongFile(File file) async {
    File fileToUse = file;
    // store under file name because ios changes the folder name on every update
    String fileName = p.basename(fileToUse.path);

    // Convert any file format not natively supported by SoLoud to WAV.
    // SoLoud supports: mp3, wav, ogg, flac. Everything else (m4a, aac, …)
    // must be converted via FFmpeg first.
    final extension = fileName.toLowerCase().split('.').last;
    if (!_soloudSupportedExtensions.contains('.$extension')) {
      try {
        final convertedFile = await _convertToWav(file);
        if (convertedFile != null) {
          fileToUse = convertedFile;
          fileName = p.basename(fileToUse.path);
        } else {
          throw UnsupportedAudioFormatException(extension);
        }
      } on UnsupportedAudioFormatException {
        rethrow;
      } on Exception catch (ex) {
        log('Error converting .$extension to wav: $ex', name: 'AddSongFile');
        throw UnsupportedAudioFormatException(extension);
      }
    }

    AudioSource source;
    try {
      source = await soLoud.loadFile(fileToUse.path);
    } on SoLoudFileLoadFailedException catch (ex) {
      // SoLoud failed to load the file. For natively-supported formats
      // (mp3/wav/ogg/flac) this is NOT a format problem — it's a genuine
      // load failure (missing/stale path, truncated or malformed file, …).
      // Reporting it as "unsupported format" produced the misleading Sentry
      // issue FLUTTER-D7 (".mp3 is not supported"). Surface an honest error
      // with enough context to diagnose the real cause.
      final exists = await fileToUse.exists();
      final sizeBytes = exists ? await fileToUse.length() : 0;
      log(
        'SoLoud failed to load "$fileName" '
        '(ext=.$extension, exists=$exists, size=$sizeBytes): $ex',
        name: 'AddSongFile',
      );
      if (_soloudSupportedExtensions.contains('.$extension')) {
        throw AudioFileLoadException(
          fileName: fileName,
          extension: extension,
          exists: exists,
          sizeBytes: sizeBytes,
          cause: ex.toString(),
        );
      }
      throw UnsupportedAudioFormatException(extension);
    }

    final duration = soLoud.getLength(source);

    // Don't forget to dispose the source when you're done with it
    await soLoud.disposeSource(source);

    // Get metadata from the file
    // final metadata = await AudioTags.read(file.path);
    AudioMetadata? metadata;

    try {
      metadata = readMetadata(fileToUse);
    } on NoMetadataParserException catch (ex) {
      // https://github.com/ClementBeal/audio_metadata_reader/issues/50
      log('No metadata available: $ex');
    }

    // BPM/key tags are read from the ORIGINAL file: formats converted to WAV
    // (m4a, aac, …) lose their tags in conversion, and the unified
    // readMetadata model drops TBPM/TKEY entirely.
    final tags = _readBpmAndKeyTags(file);

    final song = Song(
      id: const Uuid().v4(),
      title: metadata?.title ?? fileName,
      artist: metadata?.artist ?? 'Unknown Artist',
      fileName: fileName,
      duration: duration,
      bpm: tags.bpm,
      musicalKey: tags.musicalKey,
    );

    // Shift existing songs down so the new song appears at the top
    await incrementExistingSortOrders();
    await _store.add(db, song.toMap());
    await getAllSongs();
  }

  /// Best-effort read of BPM (TBPM) and musical key (TKEY) tags. Only MP3
  /// (ID3v2) carries these in a form audio_metadata_reader exposes; other
  /// formats simply return nulls. Never throws — tag data is optional.
  ({int? bpm, String? musicalKey}) _readBpmAndKeyTags(File file) {
    try {
      final tags = readAllMetadata(file, getImage: false);
      if (tags is Mp3Metadata) {
        return (
          bpm: MusicalKey.parseTagBpm(tags.bpm),
          musicalKey: MusicalKey.normalizeTagKey(tags.initialKey),
        );
      }
    } on Exception catch (ex) {
      log('BPM/key tag read failed: $ex');
    }
    return (bpm: null, musicalKey: null);
  }

  /// Import a video file. The file is kept as-is (no transcoding, no audio
  /// extraction); duration is probed via a short-lived media_kit [Player].
  /// File metadata (title/artist) is attempted via [readMetadata] which can
  /// handle moov-atom tags in mp4/mov; falls back to filename / 'Unknown'.
  Future<void> addVideoFile(File file) async {
    final fileName = p.basename(file.path);
    final extension = fileName.toLowerCase().split('.').last;

    if (!_videoSupportedExtensions.contains('.$extension')) {
      throw UnsupportedVideoFormatException(extension);
    }

    final sizeBytes = await file.exists() ? await file.length() : -1;
    final stopwatch = Stopwatch()..start();
    log(
      'addVideoFile start: "$fileName" ($sizeBytes bytes)',
      name: 'ImportTiming',
    );

    final duration = await _probeVideoDuration(file);
    log(
      'Duration probe finished ($duration) '
      'after ${stopwatch.elapsedMilliseconds} ms',
      name: 'ImportTiming',
    );
    if (duration == null || duration <= Duration.zero) {
      throw UnsupportedVideoFormatException(extension);
    }

    // Best-effort metadata; many mp4/mov files carry moov-atom tags.
    AudioMetadata? metadata;
    try {
      metadata = readMetadata(file);
    } on NoMetadataParserException catch (ex) {
      log('No metadata available for video: $ex');
    } on Exception catch (ex) {
      log('Metadata read failed for video: $ex');
    }
    log(
      'Metadata read finished after ${stopwatch.elapsedMilliseconds} ms',
      name: 'ImportTiming',
    );

    final song = Song(
      id: const Uuid().v4(),
      title: metadata?.title ?? fileName,
      artist: metadata?.artist ?? 'Unknown Artist',
      fileName: fileName,
      duration: duration,
      mediaType: MediaType.video,
    );

    // Shift existing songs down so the new song appears at the top
    await incrementExistingSortOrders();
    await _store.add(db, song.toMap());
    await getAllSongs();
    log(
      'addVideoFile finished after ${stopwatch.elapsedMilliseconds} ms',
      name: 'ImportTiming',
    );
  }

  /// Probe video duration by briefly opening the file with media_kit. Returns
  /// `null` if duration can't be determined within a small timeout. Adds
  /// ~100–500 ms one-time at import; acceptable for a non-hot path.
  Future<Duration?> _probeVideoDuration(File file) async {
    final probe = Player();
    final stopwatch = Stopwatch()..start();
    try {
      log('Probe open start: ${file.path}', name: 'ImportTiming');
      // open() itself can hang on files libmpv struggles with — cap it so a
      // broken file fails the import instead of freezing it forever.
      await probe
          .open(Media(file.path), play: false)
          .timeout(const Duration(seconds: 15));
      log(
        'Probe open done after ${stopwatch.elapsedMilliseconds} ms',
        name: 'ImportTiming',
      );
      // Wait for libmpv to report a non-zero duration. Bail after 5s to avoid
      // hanging on truly broken files.
      final duration = await probe.stream.duration
          .firstWhere((d) => d > Duration.zero)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => Duration.zero,
          );
      return duration > Duration.zero ? duration : null;
    } on TimeoutException {
      log(
        'Probe open timed out after ${stopwatch.elapsedMilliseconds} ms — '
        'treating file as unreadable',
        name: 'ImportTiming',
      );
      return null;
    } on Exception catch (ex) {
      log('Failed to probe video duration: $ex', name: 'AddVideoFile');
      return null;
    } finally {
      // Not awaited: if open() hung, dispose() can hang on the same lock and
      // would freeze the import again.
      unawaited(
        probe.dispose().timeout(const Duration(seconds: 5)).catchError((
          Object ex,
        ) {
          log('Probe dispose failed: $ex', name: 'ImportTiming');
        }),
      );
    }
  }

  /// Converts any audio file to 16-bit PCM WAV using FFmpeg.
  /// Returns the converted [File] on success, or `null` if cancelled.
  /// Throws on conversion failure.
  Future<File?> _convertToWav(File file) async {
    final ext = file.path.toLowerCase().split('.').last;

    // Build the output path by replacing the original extension with .wav.
    // If that name is already taken (a previously imported song — its loops
    // point into that audio), pick `<stem> (n).wav` instead of overwriting.
    var outputPath =
        '${file.path.substring(0, file.path.length - ext.length)}wav';
    if (await File(outputPath).exists()) {
      final dir = p.dirname(outputPath);
      final stem = p.basenameWithoutExtension(outputPath);
      var counter = 1;
      while (await File(p.join(dir, '$stem ($counter).wav')).exists()) {
        counter++;
      }
      outputPath = p.join(dir, '$stem ($counter).wav');
    }

    // FFmpeg command to convert the audio. "-y" overwrites existing files,
    // "-vn" drops any (unlikely) video track, and we encode the audio stream
    // using 16-bit PCM which is supported by SoLoud.
    final ffmpegCommand =
        '-y -i "${file.path}" -vn -c:a pcm_s16le "$outputPath"';

    log(
      'Starting $ext→wav conversion using FFmpeg: $ffmpegCommand',
      name: 'ConvertToWav',
    );

    // Execute conversion.
    final session = await FFmpegKit.execute(ffmpegCommand);

    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      log('FFmpeg conversion succeeded: $outputPath', name: 'ConvertToWav');
      // Delete the original file to avoid wasting space.
      await file.delete();
      return File(outputPath);
    } else if (ReturnCode.isCancel(returnCode)) {
      log('FFmpeg conversion was cancelled.', name: 'ConvertToWav');
    } else {
      // Something went wrong – gather diagnostics.
      final failStackTrace = await session.getFailStackTrace();
      final sessionLog = await session.getOutput();
      log(
        'FFmpeg conversion failed with code: $returnCode\n$failStackTrace',
        name: 'ConvertToWav',
      );
      log('FFmpeg log output:\n$sessionLog', name: 'ConvertToWav');
      throw Exception(
        'Failed to convert $ext to wav. FFmpeg return code: $returnCode',
      );
    }
    return null;
  }

  Future<void> updateSong(Song song) async {
    await _store.update(
      db,
      song.toMap(),
      finder: Finder(filter: Filter.equals('id', song.id)),
    );
    await getAllSongs();
  }

  Future<void> deleteSong(Song song) async {
    await _store.delete(
      db,
      finder: Finder(filter: Filter.equals('id', song.id)),
    );

    // Other songs can legitimately share a fileName (e.g. a backup restore
    // that dedupes identical content onto one file for two songs), so only
    // delete the file if no remaining song still points at it.
    final remainingSongs = await getAllSongs();
    final stillReferenced = remainingSongs.any(
      (remaining) => remaining.fileName == song.fileName,
    );
    if (!stillReferenced) {
      await _deleteMediaFile(song);
    }
  }

  /// Deletes [song]'s media file from the app documents directory, if
  /// present. Best-effort: a filesystem error is logged and swallowed rather
  /// than thrown, since the caller's DB state is already consistent by the
  /// time this runs.
  Future<void> _deleteMediaFile(Song song) async {
    try {
      final file = File(await song.path);
      if (await file.exists()) {
        await file.delete();
      }
    } on Exception catch (ex) {
      log(
        'Failed to delete media file "${song.fileName}": $ex',
        name: 'DeleteSong',
      );
    }
  }

  Future<Song> addLoopToSong({
    required Song song,
    required Loop loop,
  }) async {
    log('ADDING LOOP: ${loop.toMap()}');

    final updatedSong = song.copyWith(loops: [...song.loops, loop]);

    await _store.update(
      db,
      updatedSong.toMap(),
      finder: Finder(filter: Filter.equals('id', song.id)),
    );
    await getAllSongs();

    return updatedSong;
  }

  Future<Song> updateLoopForSong({
    required Song song,
    required Loop loop,
  }) async {
    log('UPDATING LOOP: ${loop.toMap()}');

    // update the loop in the song
    final updatedLoops = song.loops
        .map((e) => e.id == loop.id ? loop : e)
        .toList();
    final updatedSong = song.copyWith(loops: updatedLoops);

    await _store.update(
      db,
      updatedSong.toMap(),
      finder: Finder(filter: Filter.equals('id', song.id)),
    );
    await getAllSongs();

    return updatedSong;
  }

  Future<Song> deleteLoopForSong({
    required Song song,
    required Loop loop,
  }) async {
    log('DELETING LOOP: ${loop.toMap()}');

    final updatedLoops = song.loops.where((e) => e.id != loop.id).toList();
    final updatedSong = song.copyWith(loops: updatedLoops);

    await _store.update(
      db,
      updatedSong.toMap(),
      finder: Finder(filter: Filter.equals('id', song.id)),
    );
    await getAllSongs();

    return updatedSong;
  }

  Future<void> clearDb() async {
    await _store.delete(db);
  }

  void dispose() {
    _songController.close();
  }
}

/// Thrown when a user picks an audio file whose format cannot be loaded.
class UnsupportedAudioFormatException implements Exception {
  final String format;

  const UnsupportedAudioFormatException(this.format);

  @override
  String toString() =>
      'The audio format ".$format" is not supported. '
      'Supported formats: ${SongRepository.supportedFormatsLabel}.';
}

/// Thrown when a file whose format IS supported (mp3/wav/ogg/flac) still
/// fails to load in SoLoud. Distinct from [UnsupportedAudioFormatException]
/// so we don't tell users a supported format is unsupported. Carries enough
/// context (path existence, size, underlying error) to diagnose the cause
/// from crash reports.
class AudioFileLoadException implements Exception {
  final String fileName;
  final String extension;
  final bool exists;
  final int sizeBytes;
  final String cause;

  const AudioFileLoadException({
    required this.fileName,
    required this.extension,
    required this.exists,
    required this.sizeBytes,
    required this.cause,
  });

  @override
  String toString() =>
      'Failed to load audio file "$fileName" '
      '(ext=.$extension, exists=$exists, size=$sizeBytes bytes). '
      'Underlying error: $cause';
}

/// Thrown when a user picks a video file whose format cannot be loaded.
class UnsupportedVideoFormatException implements Exception {
  final String format;

  const UnsupportedVideoFormatException(this.format);

  @override
  String toString() =>
      'The video format ".$format" is not supported. '
      'Supported formats: ${SongRepository.supportedVideoFormatsLabel}.';
}
