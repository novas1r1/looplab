import 'dart:async';
import 'dart:developer';
import 'dart:io';

// import 'package:audiotags/audiotags.dart';
import 'package:just_audio/just_audio.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:sembast/sembast.dart';
import 'package:uuid/uuid.dart';

class SongRepository {
  final Database db;

  final _store = StoreRef<String, Map<String, dynamic>>('songs');

  final _songController = StreamController<List<Song>>.broadcast();

  SongRepository({
    required this.db,
  });

  Stream<List<Song>> get songs => _songController.stream;

  Future<List<Song>> getAllSongs() async {
    final records = await _store.find(db);
    final songs = records.map((e) => SongMapper.fromMap(e.value)).toList();
    _songController.add(songs);

    return songs;
  }

  Future<void> addSongFile(File file) async {
    // final source = await soLoud.loadFile(file.path);
    // final duration = soLoud.getLength(source);

    // Don't forget to dispose the source when you're done with it
    // await soLoud.disposeSource(source);

    // get duration from the file using just_audio
    final duration = await AudioPlayer().setAudioSource(AudioSource.file(file.path));

    // store under file name because ios changes the folder name on every update
    final fileName = file.path.split('/').last;

    // Get metadata from the file
    // final metadata = await AudioTags.read(file.path);

    final song = Song(
      id: const Uuid().v4(),
      // title: metadata?.title ?? fileName,
      title: fileName,
      // artist: metadata?.trackArtist ?? 'Unknown Artist',
      artist: 'Unknown Artist',
      fileName: fileName,
      duration: duration ?? Duration.zero,
    );

    await _store.add(db, song.toMap());
    await getAllSongs();
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
