import 'package:flutter_test/flutter_test.dart';
import 'package:repeatlab/data/repositories/recording_repository.dart';
import 'package:sembast/sembast_memory.dart';

import '../../helpers/mock_data.dart';

void main() {
  late Database db;
  late RecordingRepository repository;

  setUp(() async {
    db = await databaseFactoryMemory.openDatabase('test.db');
    repository = RecordingRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  group('RecordingRepository', () {
    test('returns empty list when no layers exist for song', () async {
      final layers = await repository.getLayersForSong('nonexistent');
      expect(layers, isEmpty);
    });

    test('adds and retrieves a recording layer', () async {
      await repository.addLayer(MockData.recordingLayer1);

      final layers = await repository.getLayersForSong('song-medium');
      expect(layers, hasLength(1));
      expect(layers.first.id, 'recording-1');
      expect(layers.first.songId, 'song-medium');
    });

    test('updates a recording layer', () async {
      await repository.addLayer(MockData.recordingLayer1);

      final updated = MockData.recordingLayer1.copyWith(
        volume: 0.5,
        isMuted: true,
      );
      await repository.updateLayer(updated);

      final layers = await repository.getLayersForSong('song-medium');
      expect(layers.first.volume, 0.5);
      expect(layers.first.isMuted, true);
    });

    test('deletes a recording layer', () async {
      await repository.addLayer(MockData.recordingLayer1);
      await repository.addLayer(MockData.recordingLayer2);

      await repository.deleteLayer(MockData.recordingLayer1);

      final layers = await repository.getLayersForSong('song-medium');
      expect(layers, hasLength(1));
      expect(layers.first.id, 'recording-2');
    });

    test('deletes all layers for a song', () async {
      await repository.addLayer(MockData.recordingLayer1);
      await repository.addLayer(MockData.recordingLayer2);

      await repository.deleteAllLayersForSong('song-medium');

      final layers = await repository.getLayersForSong('song-medium');
      expect(layers, isEmpty);
    });

    test('counts layers for a song', () async {
      await repository.addLayer(MockData.recordingLayer1);
      await repository.addLayer(MockData.recordingLayer2);

      final count = await repository.getLayerCountForSong('song-medium');
      expect(count, 2);
    });
  });
}
