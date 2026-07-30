import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/repositories/backup/backup_exceptions.dart';
import 'package:repeatlab/data/repositories/backup/backup_manifest.dart';
import 'package:repeatlab/data/repositories/backup/backup_serializer.dart';

import '../../../helpers/mock_data.dart';

void main() {
  const serializer = BackupSerializer();

  Uint8List audioBytesFor(String seed) =>
      Uint8List.fromList(utf8.encode('fake-audio:$seed'));

  group('BackupSerializer', () {
    group('encode', () {
      test('produces a readable zip with manifest, songs, and audio', () {
        final songs = [MockData.songShort, MockData.songMedium];
        final audio = {
          MockData.songShort.fileName: audioBytesFor('short'),
          MockData.songMedium.fileName: audioBytesFor('medium'),
        };

        final bytes = serializer.encode(
          songs: songs,
          audioFiles: audio,
          appVersion: '1.6.11',
          exportedAt: DateTime.utc(2026, 4, 19, 12),
        );

        final archive = ZipDecoder().decodeBytes(bytes);
        expect(archive.findFile(BackupSerializer.manifestFileName), isNotNull);
        expect(archive.findFile(BackupSerializer.songsFileName), isNotNull);
        expect(
          archive.findFile(
            '${BackupSerializer.audioDirectory}/${MockData.songShort.fileName}',
          ),
          isNotNull,
        );
      });

      test('manifest records schema version, app version, and song count', () {
        final bytes = serializer.encode(
          songs: [MockData.songShort],
          audioFiles: {MockData.songShort.fileName: audioBytesFor('short')},
          appVersion: '1.6.11',
          exportedAt: DateTime.utc(2026, 4, 19, 12),
        );

        final manifest = serializer.peekManifest(bytes);
        expect(manifest.schemaVersion, BackupManifest.currentSchemaVersion);
        expect(manifest.appVersion, '1.6.11');
        expect(manifest.exportedAt, '2026-04-19T12:00:00.000Z');
        expect(manifest.songCount, 1);
        expect(manifest.audioFiles.keys, [MockData.songShort.fileName]);
        final info = manifest.audioFiles[MockData.songShort.fileName]!;
        expect(info.size, audioBytesFor('short').length);
        // 2.0.2+ exports no longer include sha256; old backups in the wild
        // still do and continue to parse via the optional field.
        expect(info.sha256, isNull);
      });

      test('handles empty library', () {
        final bytes = serializer.encode(
          songs: [],
          audioFiles: {},
          appVersion: '1.6.11',
        );

        final payload = serializer.decode(bytes);
        expect(payload.songs, isEmpty);
        expect(payload.audioFiles, isEmpty);
        expect(payload.manifest.songCount, 0);
      });
    });

    group('decode', () {
      test('roundtrips songs and audio bytes identically', () {
        final song = MockData.songMedium.copyWith(
          loops: [MockData.loopVerse, MockData.loopChorus],
        );
        final audio = {song.fileName: audioBytesFor('medium')};

        final bytes = serializer.encode(
          songs: [song],
          audioFiles: audio,
          appVersion: '1.6.11',
        );
        final payload = serializer.decode(bytes);

        expect(payload.songs, hasLength(1));
        final decoded = payload.songs.single;
        expect(decoded.id, song.id);
        expect(decoded.title, song.title);
        expect(decoded.artist, song.artist);
        expect(decoded.duration, song.duration);
        expect(decoded.bpm, song.bpm);
        expect(decoded.loops, hasLength(2));
        expect(decoded.loops.first.name, 'Verse 1');
        expect(decoded.loops.first.color, LoopColor.green);
        expect(
          payload.audioFiles[song.fileName],
          equals(audio[song.fileName]),
        );
      });

      test('roundtrips pitch, fine tune and musical key', () {
        final song = MockData.songMedium.copyWith(
          pitchSemitones: -4,
          fineTuneCents: -25,
          musicalKey: 'F#m',
        );

        final bytes = serializer.encode(
          songs: [song],
          audioFiles: {song.fileName: audioBytesFor('medium')},
          appVersion: '2.0.4',
        );
        final decoded = serializer.decode(bytes).songs.single;

        expect(decoded.pitchSemitones, -4);
        expect(decoded.fineTuneCents, -25);
        expect(decoded.musicalKey, 'F#m');
      });

      test('roundtrips metronome offset and time signature', () {
        final song = MockData.songMedium.copyWith(
          metronomeOffsetMs: -75,
          metronomeBeatAnchorMs: 1234,
          metronomeBeatsPerBar: 6,
          metronomeBeatUnit: 8,
        );

        final bytes = serializer.encode(
          songs: [song],
          audioFiles: {song.fileName: audioBytesFor('medium')},
          appVersion: '2.2.0',
        );
        final decoded = serializer.decode(bytes).songs.single;

        expect(decoded.metronomeOffsetMs, -75);
        expect(decoded.metronomeBeatAnchorMs, 1234);
        expect(decoded.metronomeBeatsPerBar, 6);
        expect(decoded.metronomeBeatUnit, 8);
      });

      test(
        'imports backups from versions without metronome fields (defaults)',
        () {
          final legacyMap = MockData.songMedium.toMap()
            ..remove('metronomeOffsetMs')
            ..remove('metronomeBeatAnchorMs')
            ..remove('metronomeBeatsPerBar')
            ..remove('metronomeBeatUnit');

          expect(SongMapper.fromMap(legacyMap).metronomeOffsetMs, 0);
          expect(SongMapper.fromMap(legacyMap).metronomeBeatAnchorMs, isNull);
          expect(SongMapper.fromMap(legacyMap).metronomeBeatsPerBar, 4);
          expect(SongMapper.fromMap(legacyMap).metronomeBeatUnit, 4);
        },
      );

      test(
        'imports backups from versions without pitch/key fields (defaults)',
        () {
          // Simulate a songs.json entry written by an app version that
          // predates pitchSemitones/fineTuneCents/musicalKey.
          final legacyMap = MockData.songMedium.toMap()
            ..remove('pitchSemitones')
            ..remove('fineTuneCents')
            ..remove('musicalKey');

          final bytes = serializer.encode(
            songs: [MockData.songMedium],
            audioFiles: {
              MockData.songMedium.fileName: audioBytesFor('medium'),
            },
            appVersion: '2.0.3',
          );

          // Rebuild the archive with the legacy songs.json payload.
          final archive = ZipDecoder().decodeBytes(bytes);
          final rebuilt = Archive();
          for (final file in archive.files) {
            if (file.name == BackupSerializer.songsFileName) {
              final legacyBytes = utf8.encode(jsonEncode([legacyMap]));
              rebuilt.addFile(
                ArchiveFile(file.name, legacyBytes.length, legacyBytes),
              );
            } else {
              rebuilt.addFile(file);
            }
          }
          final legacyZip = Uint8List.fromList(ZipEncoder().encode(rebuilt));

          final decoded = serializer.decode(legacyZip).songs.single;
          expect(decoded.pitchSemitones, 0);
          expect(decoded.fineTuneCents, 0);
          expect(decoded.musicalKey, isNull);
        },
      );

      test('ignores unknown fields from future app versions', () {
        // Simulate a songs.json entry written by a NEWER app version that
        // has fields this version doesn't know about.
        final futureMap = MockData.songMedium.toMap()
          ..['someFutureField'] = 'whatever'
          ..['anotherOne'] = 42;

        final bytes = serializer.encode(
          songs: [MockData.songMedium],
          audioFiles: {MockData.songMedium.fileName: audioBytesFor('medium')},
          appVersion: '9.9.9',
        );

        final archive = ZipDecoder().decodeBytes(bytes);
        final rebuilt = Archive();
        for (final file in archive.files) {
          if (file.name == BackupSerializer.songsFileName) {
            final futureBytes = utf8.encode(jsonEncode([futureMap]));
            rebuilt.addFile(
              ArchiveFile(file.name, futureBytes.length, futureBytes),
            );
          } else {
            rebuilt.addFile(file);
          }
        }
        final futureZip = Uint8List.fromList(ZipEncoder().encode(rebuilt));

        final decoded = serializer.decode(futureZip).songs.single;
        expect(decoded.id, MockData.songMedium.id);
        expect(decoded.title, MockData.songMedium.title);
      });

      test('throws BackupFormatException for non-zip bytes', () {
        final garbage = Uint8List.fromList([1, 2, 3, 4, 5]);
        expect(
          () => serializer.decode(garbage),
          throwsA(isA<BackupFormatException>()),
        );
      });

      test('throws BackupFormatException when manifest is missing', () {
        final archive = Archive()
          ..addFile(
            ArchiveFile(
              BackupSerializer.songsFileName,
              2,
              utf8.encode('[]'),
            ),
          );
        final bytes = Uint8List.fromList(ZipEncoder().encode(archive));

        expect(
          () => serializer.decode(bytes),
          throwsA(
            isA<BackupFormatException>().having(
              (e) => e.message,
              'message',
              contains('manifest.json missing'),
            ),
          ),
        );
      });

      test('throws BackupFormatException when songs.json is missing', () {
        final manifest = BackupManifest(
          schemaVersion: BackupManifest.currentSchemaVersion,
          appVersion: '1.6.11',
          exportedAt: DateTime.utc(2026, 4, 19).toIso8601String(),
          songCount: 0,
          audioFiles: const {},
        );
        final archive = Archive();
        final manifestBytes = utf8.encode(jsonEncode(manifest.toMap()));
        archive.addFile(
          ArchiveFile(
            BackupSerializer.manifestFileName,
            manifestBytes.length,
            manifestBytes,
          ),
        );
        final bytes = Uint8List.fromList(ZipEncoder().encode(archive));

        expect(
          () => serializer.decode(bytes),
          throwsA(
            isA<BackupFormatException>().having(
              (e) => e.message,
              'message',
              contains('songs.json missing'),
            ),
          ),
        );
      });

      test(
        'throws BackupSchemaVersionException when backup is newer than app',
        () {
          final manifest = BackupManifest(
            schemaVersion: BackupManifest.currentSchemaVersion + 1,
            appVersion: '99.0.0',
            exportedAt: DateTime.utc(2026, 4, 19).toIso8601String(),
            songCount: 0,
            audioFiles: const {},
          );
          final archive = Archive();
          final manifestBytes = utf8.encode(jsonEncode(manifest.toMap()));
          archive.addFile(
            ArchiveFile(
              BackupSerializer.manifestFileName,
              manifestBytes.length,
              manifestBytes,
            ),
          );
          final songsBytes = utf8.encode('[]');
          archive.addFile(
            ArchiveFile(
              BackupSerializer.songsFileName,
              songsBytes.length,
              songsBytes,
            ),
          );
          final bytes = Uint8List.fromList(ZipEncoder().encode(archive));

          expect(
            () => serializer.decode(bytes),
            throwsA(
              isA<BackupSchemaVersionException>()
                  .having(
                    (e) => e.backupVersion,
                    'backupVersion',
                    BackupManifest.currentSchemaVersion + 1,
                  )
                  .having(
                    (e) => e.supportedVersion,
                    'supportedVersion',
                    BackupManifest.currentSchemaVersion,
                  ),
            ),
          );
        },
      );

      test(
        'throws BackupFormatException when manifest lists audio not in archive',
        () {
          // Encode normally, then delete the audio entry from the archive.
          final audio = {
            MockData.songShort.fileName: audioBytesFor('gone'),
          };
          final bytes = serializer.encode(
            songs: [MockData.songShort],
            audioFiles: audio,
            appVersion: '1.6.11',
          );

          final archive = ZipDecoder().decodeBytes(bytes);
          final stripped = Archive();
          for (final file in archive.files) {
            if (!file.name.startsWith('${BackupSerializer.audioDirectory}/')) {
              stripped.addFile(file);
            }
          }
          final strippedBytes = Uint8List.fromList(
            ZipEncoder().encode(stripped),
          );

          expect(
            () => serializer.decode(strippedBytes),
            throwsA(
              isA<BackupFormatException>().having(
                (e) => e.message,
                'message',
                contains(MockData.songShort.fileName),
              ),
            ),
          );
        },
      );
    });

    group('peekManifest', () {
      test('returns manifest without touching audio entries', () {
        // peekManifest is meant to be cheap — used by the import confirmation
        // dialog before the user commits. It should read only the manifest
        // entry, not iterate over audio payloads.
        final bytes = serializer.encode(
          songs: [MockData.songShort],
          audioFiles: {MockData.songShort.fileName: audioBytesFor('v1')},
          appVersion: '1.6.11',
        );

        // Strip the audio entry from the archive — peek should still succeed.
        final archive = ZipDecoder().decodeBytes(bytes);
        final stripped = Archive();
        for (final file in archive.files) {
          if (!file.name.startsWith('${BackupSerializer.audioDirectory}/')) {
            stripped.addFile(file);
          }
        }
        final strippedBytes = Uint8List.fromList(ZipEncoder().encode(stripped));

        final manifest = serializer.peekManifest(strippedBytes);
        expect(manifest.songCount, 1);
        expect(manifest.audioFiles.keys, [MockData.songShort.fileName]);
        // decode() still throws because the manifest references a file that
        // isn't in the archive — that check remains.
        expect(
          () => serializer.decode(strippedBytes),
          throwsA(isA<BackupFormatException>()),
        );
      });
    });
  });
}
