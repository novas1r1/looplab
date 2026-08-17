import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:repeatlab/data/services/metronome_track_service.dart';

void main() {
  late Directory tempDir;

  MetronomeTrackService buildService() {
    return MetronomeTrackService(
      cacheDirProvider: () async => tempDir,
    );
  }

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('metronome_mixes_test');
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  File seedMix(String songId, String fileName) {
    final file = File(p.join(tempDir.path, songId, fileName))
      ..createSync(recursive: true)
      ..writeAsStringSync('fake-m4a');
    return file;
  }

  group('MetronomeTrackService', () {
    test('clearAll deletes the whole legacy cache root', () async {
      final service = buildService();
      seedMix('song-1', 'a.m4a');
      seedMix('song-2', 'b.m4a');

      await service.clearAll();

      expect(tempDir.existsSync(), isFalse);
    });

    test('clearAll is quiet when the cache root does not exist', () async {
      final service = buildService();
      tempDir.deleteSync(recursive: true);

      await expectLater(service.clearAll(), completes);
    });

    test("clearForSong removes only that song's cached mixes", () async {
      final service = buildService();
      seedMix('song-1', 'a.m4a');
      final other = seedMix('song-2', 'b.m4a');

      await service.clearForSong('song-1');

      expect(
        Directory(p.join(tempDir.path, 'song-1')).existsSync(),
        isFalse,
      );
      expect(other.existsSync(), isTrue);
    });

    test('clearForSong is quiet when the song has no cached mixes', () async {
      final service = buildService();

      await expectLater(service.clearForSong('missing-song'), completes);
    });
  });
}
