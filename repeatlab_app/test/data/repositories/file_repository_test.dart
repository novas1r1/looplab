import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:repeatlab/app/view/repository_wrapper.dart';
import 'package:repeatlab/data/repositories/file_repository.dart';

class _MockFilePicker extends Mock implements FilePickerWrapper {}

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform({
    required this.applicationDocumentsPath,
    String? temporaryPath,
  }) : _temporaryPath = temporaryPath ?? Directory.systemTemp.path;

  final String applicationDocumentsPath;
  final String _temporaryPath;

  @override
  Future<String?> getApplicationDocumentsPath() async =>
      applicationDocumentsPath;

  @override
  Future<String?> getTemporaryPath() async => _temporaryPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FileType.any);
  });

  late _MockFilePicker filePicker;
  late Directory tempAppDir;
  late PathProviderPlatform originalPathProvider;

  setUp(() async {
    filePicker = _MockFilePicker();
    tempAppDir = await Directory.systemTemp.createTemp('file_repo_app_dir');
    originalPathProvider = PathProviderPlatform.instance;
    PathProviderPlatform.instance = _FakePathProviderPlatform(
      applicationDocumentsPath: tempAppDir.path,
    );
  });

  tearDown(() async {
    PathProviderPlatform.instance = originalPathProvider;
    await tempAppDir.delete(recursive: true);
  });

  test(
    'pickAudioFiles copies file when path contains percent-encoded whitespace',
    () async {
      final sourceDir = await Directory.systemTemp.createTemp(
        'file_repo_source_whitespace',
      );
      final sourceFile = File(p.join(sourceDir.path, 'Butterfly by night.mp3'));
      await sourceFile.writeAsString('content');

      final encodedPath = sourceFile.path.replaceAll(' ', '%20');

      when(
        () => filePicker.pickFiles(
          type: any(named: 'type'),
          allowedExtensions: any(named: 'allowedExtensions'),
          allowMultiple: any(named: 'allowMultiple'),
          onFileLoading: any(named: 'onFileLoading'),
        ),
      ).thenAnswer(
        (_) async => FilePickerResult([
          PlatformFile(
            name: 'Butterfly by night.mp3',
            path: encodedPath,
            size: await sourceFile.length(),
          ),
        ]),
      );

      final repository = FileRepository(filePicker: filePicker);

      final copiedFiles = await repository.pickAudioFiles();

      expect(copiedFiles, hasLength(1));
      final copiedFile = copiedFiles.single;
      expect(p.basename(copiedFile.path), 'Butterfly by night.mp3');
      expect(await copiedFile.exists(), isTrue);
      expect(await copiedFile.readAsString(), 'content');

      await sourceDir.delete(recursive: true);
    },
  );

  test(
    'pickAudioFiles copies file when percent character is percent-encoded',
    () async {
      final sourceDir = await Directory.systemTemp.createTemp(
        'file_repo_source_percent',
      );
      const originalName = 'Butterfly%by%night.mp3';
      final sourceFile = File(p.join(sourceDir.path, originalName));
      await sourceFile.writeAsString('content-%');

      final encodedPath = sourceFile.path.replaceAll('%', '%25');

      when(
        () => filePicker.pickFiles(
          type: any(named: 'type'),
          allowedExtensions: any(named: 'allowedExtensions'),
          allowMultiple: any(named: 'allowMultiple'),
          onFileLoading: any(named: 'onFileLoading'),
        ),
      ).thenAnswer(
        (_) async => FilePickerResult([
          PlatformFile(
            name: originalName,
            path: encodedPath,
            size: await sourceFile.length(),
          ),
        ]),
      );

      final repository = FileRepository(filePicker: filePicker);

      final copiedFiles = await repository.pickAudioFiles();

      expect(copiedFiles, hasLength(1));
      final copiedFile = copiedFiles.single;
      expect(p.basename(copiedFile.path), originalName);
      expect(await copiedFile.exists(), isTrue);
      expect(await copiedFile.readAsString(), 'content-%');

      await sourceDir.delete(recursive: true);
    },
  );

  test(
    'pickAudioFiles copies every file when multiple files are picked',
    () async {
      final sourceDir = await Directory.systemTemp.createTemp(
        'file_repo_multiple',
      );
      final first = File(p.join(sourceDir.path, 'One more night.mp3'));
      await first.writeAsString('first');
      final second = File(p.join(sourceDir.path, 'Butterfly%by%night.mp3'));
      await second.writeAsString('second');

      final encodedPaths = [
        first.path.replaceAll(' ', '%20'),
        second.path.replaceAll('%', '%25'),
      ];

      when(
        () => filePicker.pickFiles(
          type: any(named: 'type'),
          allowedExtensions: any(named: 'allowedExtensions'),
          allowMultiple: any(named: 'allowMultiple'),
          onFileLoading: any(named: 'onFileLoading'),
        ),
      ).thenAnswer(
        (_) async => FilePickerResult([
          PlatformFile(
            name: 'One more night.mp3',
            path: encodedPaths[0],
            size: await first.length(),
          ),
          PlatformFile(
            name: 'Butterfly%by%night.mp3',
            path: encodedPaths[1],
            size: await second.length(),
          ),
        ]),
      );

      final repository = FileRepository(filePicker: filePicker);

      final files = await repository.pickAudioFiles();

      expect(files, hasLength(2));
      expect(p.basename(files[0].path), 'One more night.mp3');
      expect(await files[0].readAsString(), 'first');
      expect(p.basename(files[1].path), 'Butterfly%by%night.mp3');
      expect(await files[1].readAsString(), 'second');

      await sourceDir.delete(recursive: true);
    },
  );

  test(
    'pickAudioFiles renames the copy when a file with the same name already exists',
    () async {
      // A previously imported song's audio already lives in the app dir.
      final existing = File(p.join(tempAppDir.path, 'track01.mp3'));
      await existing.writeAsString('existing song audio');

      final sourceDir = await Directory.systemTemp.createTemp(
        'file_repo_collision',
      );
      final sourceFile = File(p.join(sourceDir.path, 'track01.mp3'));
      await sourceFile.writeAsString('different incoming audio');

      when(
        () => filePicker.pickFiles(
          type: any(named: 'type'),
          allowedExtensions: any(named: 'allowedExtensions'),
          allowMultiple: any(named: 'allowMultiple'),
          onFileLoading: any(named: 'onFileLoading'),
        ),
      ).thenAnswer(
        (_) async => FilePickerResult([
          PlatformFile(
            name: 'track01.mp3',
            path: sourceFile.path,
            size: await sourceFile.length(),
          ),
        ]),
      );

      final repository = FileRepository(filePicker: filePicker);

      final copiedFiles = await repository.pickAudioFiles();

      expect(copiedFiles, hasLength(1));
      expect(p.basename(copiedFiles.single.path), 'track01 (1).mp3');
      expect(
        await copiedFiles.single.readAsString(),
        'different incoming audio',
      );
      // The pre-existing file was not overwritten.
      expect(await existing.readAsString(), 'existing song audio');

      await sourceDir.delete(recursive: true);
    },
  );

  test('pickAudioFiles returns empty list when user cancels', () async {
    when(
      () => filePicker.pickFiles(
        type: any(named: 'type'),
        allowedExtensions: any(named: 'allowedExtensions'),
        allowMultiple: any(named: 'allowMultiple'),
        onFileLoading: any(named: 'onFileLoading'),
      ),
    ).thenAnswer((_) async => null);

    final repository = FileRepository(filePicker: filePicker);

    expect(await repository.pickAudioFiles(), isEmpty);
  });

  test(
    'pick throws PickAlreadyInProgressException while a previous pick is '
    'still running, and allows picking again afterwards',
    () async {
      // First pick hangs until we complete it manually — simulates the
      // platform still downloading a large cloud file (e.g. from OneDrive).
      final firstPickCompleter = Completer<FilePickerResult?>();
      when(
        () => filePicker.pickFiles(
          type: any(named: 'type'),
          allowedExtensions: any(named: 'allowedExtensions'),
          allowMultiple: any(named: 'allowMultiple'),
          onFileLoading: any(named: 'onFileLoading'),
        ),
      ).thenAnswer((_) => firstPickCompleter.future);

      final repository = FileRepository(filePicker: filePicker);

      final firstPick = repository.pickAudioFiles();

      await expectLater(
        repository.pickVideoFiles(),
        throwsA(isA<PickAlreadyInProgressException>()),
      );
      await expectLater(
        repository.pickAudioFiles(),
        throwsA(isA<PickAlreadyInProgressException>()),
      );

      // The original pick finishes (user cancelled) and unblocks new picks.
      firstPickCompleter.complete(null);
      expect(await firstPick, isEmpty);

      when(
        () => filePicker.pickFiles(
          type: any(named: 'type'),
          allowedExtensions: any(named: 'allowedExtensions'),
          allowMultiple: any(named: 'allowMultiple'),
          onFileLoading: any(named: 'onFileLoading'),
        ),
      ).thenAnswer((_) async => null);
      expect(await repository.pickAudioFiles(), isEmpty);
    },
  );

  test(
    "pick maps the plugin's 'already_active' error to "
    'PickAlreadyInProgressException',
    () async {
      when(
        () => filePicker.pickFiles(
          type: any(named: 'type'),
          allowedExtensions: any(named: 'allowedExtensions'),
          allowMultiple: any(named: 'allowMultiple'),
          onFileLoading: any(named: 'onFileLoading'),
        ),
      ).thenThrow(
        PlatformException(
          code: 'already_active',
          message: 'File picker is already active',
        ),
      );

      final repository = FileRepository(filePicker: filePicker);

      await expectLater(
        repository.pickVideoFiles(),
        throwsA(isA<PickAlreadyInProgressException>()),
      );
    },
  );
}
