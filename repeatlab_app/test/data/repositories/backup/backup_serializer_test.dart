import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repeatlab/data/models/loop.dart';
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
        expect(info.sha256, hasLength(64));
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
        'throws BackupHashMismatchException when audio content is tampered',
        () {
          final audio = {
            MockData.songShort.fileName: audioBytesFor('original'),
          };
          final bytes = serializer.encode(
            songs: [MockData.songShort],
            audioFiles: audio,
            appVersion: '1.6.11',
          );

          // Swap the audio payload inside the zip, keep the manifest intact.
          final archive = ZipDecoder().decodeBytes(bytes);
          final tampered = Archive();
          for (final file in archive.files) {
            if (file.name ==
                '${BackupSerializer.audioDirectory}/${MockData.songShort.fileName}') {
              final replacement = audioBytesFor('tampered');
              tampered.addFile(
                ArchiveFile(file.name, replacement.length, replacement),
              );
            } else {
              tampered.addFile(file);
            }
          }
          final tamperedBytes =
              Uint8List.fromList(ZipEncoder().encode(tampered));

          expect(
            () => serializer.decode(tamperedBytes),
            throwsA(
              isA<BackupHashMismatchException>().having(
                (e) => e.fileName,
                'fileName',
                MockData.songShort.fileName,
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
          final strippedBytes =
              Uint8List.fromList(ZipEncoder().encode(stripped));

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
      test('returns manifest without verifying audio hashes', () {
        // Produce a zip whose audio content is broken, but whose manifest is
        // valid. peekManifest should not care.
        final bytes = serializer.encode(
          songs: [MockData.songShort],
          audioFiles: {MockData.songShort.fileName: audioBytesFor('v1')},
          appVersion: '1.6.11',
        );

        final archive = ZipDecoder().decodeBytes(bytes);
        final tampered = Archive();
        for (final file in archive.files) {
          if (file.name.startsWith('${BackupSerializer.audioDirectory}/')) {
            final replacement = audioBytesFor('different');
            tampered.addFile(
              ArchiveFile(file.name, replacement.length, replacement),
            );
          } else {
            tampered.addFile(file);
          }
        }
        final tamperedBytes =
            Uint8List.fromList(ZipEncoder().encode(tampered));

        final manifest = serializer.peekManifest(tamperedBytes);
        expect(manifest.songCount, 1);
        // decode() would throw BackupHashMismatchException here — peek doesn't.
        expect(
          () => serializer.decode(tamperedBytes),
          throwsA(isA<BackupHashMismatchException>()),
        );
      });
    });
  });
}
