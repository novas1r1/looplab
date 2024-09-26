import 'package:looplab/models/loop.dart';
import 'package:sembast/sembast.dart';

class LoopRepository {
  final Database db;

  final _store = StoreRef<String, Map<String, dynamic>>('loops');

  LoopRepository({required this.db});

  Future<List<Loop>> getAllLoops() async {
    final records = await _store.find(db);

    return records.map((e) => LoopMapper.fromMap(e.value)).toList();
  }

  Future<Loop> addLoop(Loop loop) async {
    final key = await _store.add(db, loop.toMap());

    return loop.copyWith(id: key);
  }

  Future<void> updateLoop(Loop loop) async {
    await _store.update(db, loop.toMap());
  }

  Future<void> deleteLoop(Loop loop) async {
    await _store.delete(db, finder: Finder(filter: Filter.byKey(loop.id)));
  }

  Future<List<Loop>> getLoopsBySongId(String songId) async {
    final finder = Finder(filter: Filter.equals('songId', songId));
    final records = await _store.find(db, finder: finder);

    return records.map((e) => LoopMapper.fromMap(e.value)).toList();
  }
}
