// ignore_for_file: avoid_implementing_value_types
import 'dart:io';
import 'dart:ui';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:repeatlab/data/repositories/backup/backup_exceptions.dart';
import 'package:repeatlab/data/repositories/backup/backup_manifest.dart';
import 'package:repeatlab/data/repositories/backup/backup_repository.dart';
import 'package:repeatlab/features/backup/cubit/backup_cubit.dart';
import 'package:share_plus/share_plus.dart';

import '../../../helpers/mock_repositories.dart';

void main() {
  late MockBackupRepository mockBackup;
  late MockCrashReportingRepository mockCrash;
  late Directory sandbox;

  setUp(() async {
    mockBackup = MockBackupRepository();
    mockCrash = MockCrashReportingRepository();
    when(
      () => mockCrash.reportError(any(), any()),
    ).thenAnswer((_) async => null);
    sandbox = await Directory.systemTemp.createTemp('backup_cubit_test_');
  });

  tearDown(() async {
    if (await sandbox.exists()) {
      await sandbox.delete(recursive: true);
    }
  });

  setUpAll(() {
    registerFallbackValue(StackTrace.empty);
    registerFallbackValue(File('/dev/null'));
    registerFallbackValue(BackupImportMode.merge);
  });

  BackupCubit buildCubit({
    Future<ShareResultStatus> Function(File, {Rect? sharePositionOrigin})?
    shareFile,
    Future<File?> Function()? pickBackupFile,
  }) {
    return BackupCubit(
      backupRepository: mockBackup,
      crashReportingRepository: mockCrash,
      shareFile:
          shareFile ??
          (_, {Rect? sharePositionOrigin}) async => ShareResultStatus.success,
      pickBackupFile: pickBackupFile ?? () async => null,
    );
  }

  BackupManifest manifest({int songCount = 3}) => BackupManifest(
    schemaVersion: BackupManifest.currentSchemaVersion,
    appVersion: '1.6.11',
    exportedAt: '2026-04-19T12:00:00.000Z',
    songCount: songCount,
    audioFiles: const {},
  );

  Future<File> sandboxFile(String name, [List<int>? bytes]) async {
    final f = File(p.join(sandbox.path, name));
    await f.writeAsBytes(bytes ?? [1, 2, 3], flush: true);
    return f;
  }

  group('exportAndShare', () {
    blocTest<BackupCubit, BackupState>(
      'emits exporting → exportSuccess when export + share succeed',
      setUp: () async {
        final file = await sandboxFile('out.rlbackup');
        when(() => mockBackup.exportToFile()).thenAnswer((_) async => file);
      },
      build: buildCubit,
      act: (cubit) => cubit.exportAndShare(),
      expect: () => [
        isA<BackupState>().having(
          (s) => s.status,
          'status',
          BackupStatus.exporting,
        ),
        isA<BackupState>().having(
          (s) => s.status,
          'status',
          BackupStatus.exportSuccess,
        ),
      ],
    );

    blocTest<BackupCubit, BackupState>(
      'emits failure and reports the error when export throws',
      setUp: () {
        when(() => mockBackup.exportToFile()).thenThrow(Exception('disk full'));
      },
      build: buildCubit,
      act: (cubit) => cubit.exportAndShare(),
      expect: () => [
        isA<BackupState>().having(
          (s) => s.status,
          'status',
          BackupStatus.exporting,
        ),
        isA<BackupState>()
            .having((s) => s.status, 'status', BackupStatus.failure)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              contains('disk full'),
            ),
      ],
      verify: (_) {
        verify(() => mockCrash.reportError(any(), any())).called(1);
      },
    );

    blocTest<BackupCubit, BackupState>(
      'still emits exportSuccess if the share sheet throws (file is valid)',
      setUp: () async {
        final file = await sandboxFile('out.rlbackup');
        when(() => mockBackup.exportToFile()).thenAnswer((_) async => file);
      },
      build: () => buildCubit(
        shareFile: (_, {Rect? sharePositionOrigin}) async =>
            throw Exception('share boom'),
      ),
      act: (cubit) => cubit.exportAndShare(),
      expect: () => [
        isA<BackupState>().having(
          (s) => s.status,
          'status',
          BackupStatus.exporting,
        ),
        isA<BackupState>().having(
          (s) => s.status,
          'status',
          BackupStatus.exportSuccess,
        ),
      ],
      verify: (_) {
        verify(() => mockCrash.reportError(any(), any())).called(1);
      },
    );
  });

  group('pickBackupForImport', () {
    test(
      'returns null without emitting failure when user cancels pick',
      () async {
        final cubit = buildCubit(pickBackupFile: () async => null);
        final result = await cubit.pickBackupForImport();
        expect(result, isNull);
        expect(cubit.state.status, BackupStatus.idle);
      },
    );

    test('returns candidate when manifest parses', () async {
      final file = await sandboxFile('in.rlbackup');
      when(
        () => mockBackup.peekImport(any()),
      ).thenAnswer((_) async => manifest(songCount: 7));

      final cubit = buildCubit(pickBackupFile: () async => file);
      final result = await cubit.pickBackupForImport();

      expect(result, isNotNull);
      expect(result!.manifest.songCount, 7);
      expect(result.file.path, file.path);
      expect(cubit.state.status, BackupStatus.idle);
    });

    test('emits failure on schema version mismatch', () async {
      final file = await sandboxFile('in.rlbackup');
      when(() => mockBackup.peekImport(any())).thenThrow(
        const BackupSchemaVersionException(
          backupVersion: 99,
          supportedVersion: 1,
        ),
      );

      final cubit = buildCubit(pickBackupFile: () async => file);
      final result = await cubit.pickBackupForImport();

      expect(result, isNull);
      expect(cubit.state.status, BackupStatus.failure);
      expect(cubit.state.errorMessage, contains('v99'));
    });

    test('emits failure on malformed backup', () async {
      final file = await sandboxFile('in.rlbackup');
      when(
        () => mockBackup.peekImport(any()),
      ).thenThrow(const BackupFormatException('not a zip'));

      final cubit = buildCubit(pickBackupFile: () async => file);
      final result = await cubit.pickBackupForImport();

      expect(result, isNull);
      expect(cubit.state.status, BackupStatus.failure);
      expect(cubit.state.errorMessage, contains('not a zip'));
    });
  });

  group('confirmImport', () {
    blocTest<BackupCubit, BackupState>(
      'emits importing → importSuccess with summary',
      setUp: () {
        when(
          () => mockBackup.importFromFile(
            any(),
            mode: any(named: 'mode'),
          ),
        ).thenAnswer(
          (_) async => const BackupImportSummary(
            songsImported: 4,
            songsSkipped: 1,
            filesRenamed: 0,
            replacedExistingLibrary: false,
          ),
        );
      },
      build: buildCubit,
      act: (cubit) async {
        final file = await sandboxFile('in.rlbackup');
        await cubit.confirmImport(file: file, mode: BackupImportMode.merge);
      },
      expect: () => [
        isA<BackupState>().having(
          (s) => s.status,
          'status',
          BackupStatus.importing,
        ),
        isA<BackupState>()
            .having((s) => s.status, 'status', BackupStatus.importSuccess)
            .having(
              (s) => s.lastImportSummary?.songsImported,
              'imported',
              4,
            ),
      ],
    );

    blocTest<BackupCubit, BackupState>(
      'emits failure when importFromFile throws',
      setUp: () {
        when(
          () => mockBackup.importFromFile(
            any(),
            mode: any(named: 'mode'),
          ),
        ).thenThrow(const BackupFormatException('song.mp3 corrupted'));
      },
      build: buildCubit,
      act: (cubit) async {
        final file = await sandboxFile('in.rlbackup');
        await cubit.confirmImport(file: file, mode: BackupImportMode.replace);
      },
      expect: () => [
        isA<BackupState>().having(
          (s) => s.status,
          'status',
          BackupStatus.importing,
        ),
        isA<BackupState>()
            .having((s) => s.status, 'status', BackupStatus.failure)
            .having(
              (s) => s.errorMessage,
              'errorMessage',
              contains('song.mp3'),
            ),
      ],
      verify: (_) {
        verify(() => mockCrash.reportError(any(), any())).called(1);
      },
    );
  });
}
