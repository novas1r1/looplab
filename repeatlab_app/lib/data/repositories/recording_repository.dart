import 'dart:developer';
import 'dart:io';

import 'package:repeatlab/data/models/recording_layer.dart';
import 'package:sembast/sembast.dart';

class RecordingRepository {
  final Database db;

  final _store = StoreRef<String, Map<String, dynamic>>('recording_layers');

  RecordingRepository({required this.db});

  Future<List<RecordingLayer>> getLayersForSong(String songId) async {
    final records = await _store.find(
      db,
      finder: Finder(filter: Filter.equals('songId', songId)),
    );
    return records
        .map((r) => RecordingLayerMapper.fromMap(r.value))
        .toList();
  }

  Future<void> addLayer(RecordingLayer layer) async {
    await _store.add(db, layer.toMap());
  }

  Future<void> updateLayer(RecordingLayer layer) async {
    await _store.update(
      db,
      layer.toMap(),
      finder: Finder(filter: Filter.equals('id', layer.id)),
    );
  }

  Future<void> deleteLayer(RecordingLayer layer) async {
    await _store.delete(
      db,
      finder: Finder(filter: Filter.equals('id', layer.id)),
    );

    // Delete the audio file from disk
    try {
      final file = File(layer.filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (ex) {
      log('Failed to delete recording file: $ex', name: 'RecordingRepository');
    }
  }

  Future<void> deleteAllLayersForSong(String songId) async {
    final layers = await getLayersForSong(songId);

    // Delete all audio files
    for (final layer in layers) {
      try {
        final file = File(layer.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (ex) {
        log('Failed to delete recording file: $ex',
            name: 'RecordingRepository');
      }
    }

    // Delete the song's recording directory
    try {
      if (layers.isNotEmpty) {
        final dir = Directory(layers.first.filePath).parent;
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      }
    } catch (_) {
      // Directory may not exist or layers may be empty
    }

    await _store.delete(
      db,
      finder: Finder(filter: Filter.equals('songId', songId)),
    );
  }

  Future<int> getLayerCountForSong(String songId) async {
    final records = await _store.find(
      db,
      finder: Finder(filter: Filter.equals('songId', songId)),
    );
    return records.length;
  }
}
