import 'dart:async';
import 'dart:developer';
import 'dart:io';

// import 'package:audiotags/audiotags.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter_soloud/flutter_soloud.dart' hide AudioMetadata;
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
    final records = await _store.find(db);
    final songs = records.map((e) => SongMapper.fromMap(e.value)).toList();
    _songController.add(songs);

    return songs;
  }

  Future<void> addSongFile(File file) async {
    File fileToUse = file;
    // store under file name because ios changes the folder name on every update
    String fileName = fileToUse.path.split('/').last;

    // check if the file is an m4a file and if so, convert it to mp3
    // soloud does not support m4a files
    try {
      if (file.path.toLowerCase().endsWith('.m4a')) {
        final convertedFile = await convertM4aToMp3(file);
        if (convertedFile != null) {
          fileToUse = convertedFile;
          fileName = fileToUse.path.split('/').last;
        }
      }
    } on Exception catch (ex) {
      log('Error converting m4a to mp3: $ex', name: 'AddSongFile');
      rethrow;
    }

    final source = await soLoud.loadFile(fileToUse.path);
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

    await _store.add(db, song.toMap());
    await getAllSongs();
  }

  Future<File?> convertM4aToMp3(File file) async {
    // Only proceed if the source file has an .m4a extension. Otherwise, skip.
    if (!file.path.toLowerCase().endsWith('.m4a')) {
      log('Provided file is not an .m4a file – skipping conversion.', name: 'ConvertM4aToMp3');
      return null;
    }

    // Build the output path by simply replacing the extension with .mp3
    final outputPath = file.path.replaceAll(RegExp(r'\.m4a', caseSensitive: false), '.mp3');

    // FFmpeg command to convert the audio. "-y" overwrites existing files,
    // "-vn" drops any (unlikely) video track, and we encode the audio stream
    // with libmp3lame using a reasonable constant quality setting.
    //
    // Note: libmp3lame is bundled with ffmpeg_kit_flutter_new (GPL build).
    final ffmpegCommand = '-y -i "${file.path}" -vn -codec:a libmp3lame -qscale:a 2 "$outputPath"';

    log('Starting m4a→mp3 conversion using FFmpeg: $ffmpegCommand', name: 'ConvertM4aToMp3');

    // Execute conversion.
    final session = await FFmpegKit.execute(ffmpegCommand);

    final returnCode = await session.getReturnCode();

    if (ReturnCode.isSuccess(returnCode)) {
      log('FFmpeg conversion succeeded: $outputPath', name: 'ConvertM4aToMp3');
      // Optionally delete the original .m4a file to avoid wasting space.
      await file.delete();
      return File(outputPath);
    } else if (ReturnCode.isCancel(returnCode)) {
      log('FFmpeg conversion was cancelled by the user.', name: 'ConvertM4aToMp3');
    } else {
      // Something went wrong – gather diagnostics.
      final failStackTrace = await session.getFailStackTrace();
      final sessionLog = await session.getOutput();
      log(
        'FFmpeg conversion failed with code: $returnCode\n$failStackTrace',
        name: 'ConvertM4aToMp3',
      );
      log('FFmpeg log output:\n$sessionLog', name: 'ConvertM4aToMp3');
      throw Exception(
        'Failed to convert m4a to mp3. FFmpeg return code: $returnCode',
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
