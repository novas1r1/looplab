import 'dart:async';
import 'dart:developer';
import 'dart:io';

// import 'package:audiotags/audiotags.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';
import 'package:flutter_soloud/flutter_soloud.dart' hide AudioMetadata;
import 'package:media_kit/media_kit.dart';
import 'package:path/path.dart' as p;
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
    } on SoLoudFileLoadFailedException {
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

    final song = Song(
      id: const Uuid().v4(),
      title: metadata?.title ?? fileName,
      artist: metadata?.artist ?? 'Unknown Artist',
      fileName: fileName,
      duration: duration,
    );

    // Shift existing songs down so the new song appears at the top
    await incrementExistingSortOrders();
    await _store.add(db, song.toMap());
    await getAllSongs();
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

    final duration = await _probeVideoDuration(file);
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
  }

  /// Probe video duration by briefly opening the file with media_kit. Returns
  /// `null` if duration can't be determined within a small timeout. Adds
  /// ~100–500 ms one-time at import; acceptable for a non-hot path.
  Future<Duration?> _probeVideoDuration(File file) async {
    final probe = Player();
    try {
      await probe.open(Media(file.path), play: false);
      // Wait for libmpv to report a non-zero duration. Bail after 5s to avoid
      // hanging on truly broken files.
      final duration = await probe.stream.duration
          .firstWhere((d) => d > Duration.zero)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => Duration.zero,
          );
      return duration > Duration.zero ? duration : null;
    } on Exception catch (ex) {
      log('Failed to probe video duration: $ex', name: 'AddVideoFile');
      return null;
    } finally {
      await probe.dispose();
    }
  }

  /// Converts any audio file to 16-bit PCM WAV using FFmpeg.
  /// Returns the converted [File] on success, or `null` if cancelled.
  /// Throws on conversion failure.
  Future<File?> _convertToWav(File file) async {
    final ext = file.path.toLowerCase().split('.').last;

    // Build the output path by replacing the original extension with .wav
    final outputPath = '${file.path.substring(0, file.path.length - ext.length)}wav';

    // FFmpeg command to convert the audio. "-y" overwrites existing files,
    // "-vn" drops any (unlikely) video track, and we encode the audio stream
    // using 16-bit PCM which is supported by SoLoud.
    final ffmpegCommand = '-y -i "${file.path}" -vn -c:a pcm_s16le "$outputPath"';

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
    await getAllSongs();
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
    final updatedLoops = song.loops.map((e) => e.id == loop.id ? loop : e).toList();
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

/// Thrown when a user picks a video file whose format cannot be loaded.
class UnsupportedVideoFormatException implements Exception {
  final String format;

  const UnsupportedVideoFormatException(this.format);

  @override
  String toString() =>
      'The video format ".$format" is not supported. '
      'Supported formats: ${SongRepository.supportedVideoFormatsLabel}.';
}
