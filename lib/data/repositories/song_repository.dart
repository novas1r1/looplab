import 'package:looplab/models/song.dart';
import 'package:sembast/sembast.dart';

class SongRepository {
  final Database db;

  final _store = StoreRef<String, Map<String, dynamic>>('songs');

  SongRepository({required this.db});

  Future<List<Song>> getAllSongs() async {
    final records = await _store.find(db);

    return records.map((e) => SongMapper.fromMap(e.value)).toList();
  }

  Future<void> addSong(Song song) async {
    await _store.add(db, song.toMap());
  }

  Future<void> updateSong(Song song) async {
    await _store.update(db, song.toMap());
  }

  Future<void> deleteSong(Song song) async {
    await _store.delete(db, finder: Finder(filter: Filter.byKey(song.id)));
  }
}
