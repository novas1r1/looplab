import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:repeatlab/data/services/metronome_track_service.dart';

void main() {
  late Directory tempDir;
  late List<String> ffmpegCommands;
  late bool ffmpegSucceeds;

  const config = ClickTrackConfig(
    durationMs: 2000,
    bpm: 120,
    anchorMs: null,
    offsetMs: 0,
    beatsPerBar: 4,
    beatUnit: 4,
    pulsesPerBeat: 1,
    volume: 0.5,
  );

  MetronomeTrackService buildService() {
    return MetronomeTrackService(
      cacheDirProvider: () async => tempDir,
      runFfmpeg: (command) async {
        ffmpegCommands.add(command);
        if (ffmpegSucceeds) {
          // The output path is the last quoted token of the command.
          final match =
              RegExp('"([^"]+)"\\s*\$').firstMatch(command)!.group(1)!;
          File(match).writeAsStringSync('fake-m4a');
        }
        return ffmpegSucceeds;
      },
    );
  }

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('metronome_mixes_test');
    ffmpegCommands = [];
    ffmpegSucceeds = true;
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  List<File> filesFor(String songId) {
    final dir = Directory(p.join(tempDir.path, songId));
    if (!dir.existsSync()) return [];
    return dir.listSync().whereType<File>().toList();
  }

  group('MetronomeTrackService', () {
    test('mixes on first request and serves from cache afterwards', () async {
      final service = buildService();

      final first = await service.ensureMixedTrack(
        songId: 'song-1',
        songPath: '/music/track.mp3',
        config: config,
      );
      final second = await service.ensureMixedTrack(
        songId: 'song-1',
        songPath: '/music/track.mp3',
        config: config,
      );

      expect(first, second);
      expect(File(first).existsSync(), isTrue);
      expect(ffmpegCommands, hasLength(1));
    });

    test('cleans up the temporary click WAV after mixing', () async {
      final service = buildService();

      await service.ensureMixedTrack(
        songId: 'song-1',
        songPath: '/music/track.mp3',
        config: config,
      );

      final leftovers = filesFor('song-1')
          .where((f) => f.path.endsWith('.wav'))
          .toList();
      expect(leftovers, isEmpty);
    });

    test('a changed config re-mixes and evicts the previous mix', () async {
      final service = buildService();

      final first = await service.ensureMixedTrack(
        songId: 'song-1',
        songPath: '/music/track.mp3',
        config: config,
      );
      const louder = ClickTrackConfig(
        durationMs: 2000,
        bpm: 120,
        anchorMs: null,
        offsetMs: 0,
        beatsPerBar: 4,
        beatUnit: 4,
        pulsesPerBeat: 1,
        volume: 0.9,
      );
      final second = await service.ensureMixedTrack(
        songId: 'song-1',
        songPath: '/music/track.mp3',
        config: louder,
      );

      expect(second, isNot(first));
      expect(ffmpegCommands, hasLength(2));
      // Only the latest mix survives.
      final mixes = filesFor('song-1');
      expect(mixes, hasLength(1));
      expect(mixes.single.path, second);
    });

    test('passes the click volume into the ffmpeg filter', () async {
      final service = buildService();

      await service.ensureMixedTrack(
        songId: 'song-1',
        songPath: '/music/track.mp3',
        config: config,
      );

      expect(ffmpegCommands.single, contains('volume=0.500'));
      expect(ffmpegCommands.single, contains('normalize=0'));
      expect(ffmpegCommands.single, contains('/music/track.mp3'));
    });

    test('throws on ffmpeg failure and leaves no cached file', () async {
      ffmpegSucceeds = false;
      final service = buildService();

      await expectLater(
        service.ensureMixedTrack(
          songId: 'song-1',
          songPath: '/music/track.mp3',
          config: config,
        ),
        throwsException,
      );

      expect(filesFor('song-1'), isEmpty);

      // A later attempt runs ffmpeg again instead of serving a broken hit.
      ffmpegSucceeds = true;
      await service.ensureMixedTrack(
        songId: 'song-1',
        songPath: '/music/track.mp3',
        config: config,
      );
      expect(ffmpegCommands, hasLength(2));
    });

    test('clearForSong removes all cached mixes for the song', () async {
      final service = buildService();
      await service.ensureMixedTrack(
        songId: 'song-1',
        songPath: '/music/track.mp3',
        config: config,
      );

      await service.clearForSong('song-1');

      expect(filesFor('song-1'), isEmpty);
    });

    test('cache keys differ per song file and grid settings', () {
      const shifted = ClickTrackConfig(
        durationMs: 2000,
        bpm: 120,
        anchorMs: 130,
        offsetMs: 0,
        beatsPerBar: 4,
        beatUnit: 4,
        pulsesPerBeat: 1,
        volume: 0.5,
      );
      expect(config.cacheKey('a.mp3'), config.cacheKey('a.mp3'));
      expect(config.cacheKey('a.mp3'), isNot(config.cacheKey('b.mp3')));
      expect(config.cacheKey('a.mp3'), isNot(shifted.cacheKey('a.mp3')));
    });
  });
}
