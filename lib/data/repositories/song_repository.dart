import 'package:looplab/models/song.dart';
import 'package:sembast/sembast.dart';

class SongRepository {
  SongRepository({required this.db});
  final Database db;

  final _store = StoreRef<String, Map<String, dynamic>>('songs');

  Future<void> addSong(Song song) async {
    await _store.add(db, song.toMap());
  }

  Future<List<Song>> loadSongs() async {
    final records = await _store.find(db);
    return records.map((e) => Song.fromMap(e.value)).toList();
  }
}
