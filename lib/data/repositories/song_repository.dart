import 'dart:io';

import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:looplab/models/song.dart';
import 'package:sembast/sembast.dart';
import 'package:uuid/uuid.dart';

class SongRepository {
  final Database db;
  final SoLoud soLoud;

  final _store = StoreRef<String, Map<String, dynamic>>('songs');

  SongRepository({
    required this.db,
    required this.soLoud,
  });

  Future<List<Song>> getAllSongs() async {
    final records = await _store.find(db);

    return records.map((e) => SongMapper.fromMap(e.value)).toList();
  }

  Future<void> addSongFile(File file) async {
    final source = await soLoud.loadFile(file.path);
    final duration = soLoud.getLength(source);

    // Don't forget to dispose the source when you're done with it
    await soLoud.disposeSource(source);

    final song = Song(
      id: const Uuid().v4(),
      title: file.path.split('/').last,
      artist: '',
      path: file.path,
      duration: duration,
    );

    await _store.add(db, song.toMap());
  }

  Future<void> updateSong(Song song) async {
    await _store.update(db, song.toMap());
  }

  Future<void> deleteSong(Song song) async {
    await _store.delete(db, finder: Finder(filter: Filter.byKey(song.id)));
  }

  Future<void> clearDb() async {
    await _store.delete(db);
  }
}
