import 'package:flutter_test/flutter_test.dart';
import 'package:repeatlab/data/models/recording_layer.dart';

void main() {
  group('RecordingLayer', () {
    test('creates instance with required fields', () {
      final layer = RecordingLayer(
        id: 'layer-1',
        songId: 'song-1',
        filePath: '/path/to/recording.wav',
        startPosition: const Duration(seconds: 30),
        duration: const Duration(seconds: 15),
        createdAt: DateTime(2026, 2, 26),
      );

      expect(layer.id, 'layer-1');
      expect(layer.songId, 'song-1');
      expect(layer.filePath, '/path/to/recording.wav');
      expect(layer.startPosition, const Duration(seconds: 30));
      expect(layer.duration, const Duration(seconds: 15));
      expect(layer.volume, 1.0);
      expect(layer.isMuted, false);
      expect(layer.label, isNull);
    });

    test('serializes to and from map', () {
      final layer = RecordingLayer(
        id: 'layer-1',
        songId: 'song-1',
        filePath: '/path/to/recording.wav',
        startPosition: const Duration(seconds: 30),
        duration: const Duration(seconds: 15),
        createdAt: DateTime(2026, 2, 26),
        volume: 0.8,
        isMuted: true,
        label: 'Guitar take 1',
      );

      final map = layer.toMap();
      final restored = RecordingLayerMapper.fromMap(map);

      expect(restored.id, layer.id);
      expect(restored.songId, layer.songId);
      expect(restored.filePath, layer.filePath);
      expect(restored.startPosition, layer.startPosition);
      expect(restored.duration, layer.duration);
      expect(restored.volume, layer.volume);
      expect(restored.isMuted, layer.isMuted);
      expect(restored.label, layer.label);
      expect(restored.createdAt, layer.createdAt);
    });

    test('copyWith creates modified copy', () {
      final layer = RecordingLayer(
        id: 'layer-1',
        songId: 'song-1',
        filePath: '/path/to/recording.wav',
        startPosition: const Duration(seconds: 30),
        duration: const Duration(seconds: 15),
        createdAt: DateTime(2026, 2, 26),
      );

      final muted = layer.copyWith(isMuted: true, volume: 0.5);

      expect(muted.isMuted, true);
      expect(muted.volume, 0.5);
      expect(muted.id, layer.id);
    });
  });
}
