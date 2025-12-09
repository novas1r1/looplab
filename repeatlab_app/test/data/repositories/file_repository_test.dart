import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:repeatlab/data/repositories/file_repository.dart';

class _MockFilePicker extends Mock implements FilePicker {}

class _FakePathProviderPlatform extends PathProviderPlatform {
  _FakePathProviderPlatform({
    required this.applicationDocumentsPath,
    String? temporaryPath,
  }) : _temporaryPath = temporaryPath ?? Directory.systemTemp.path;

  final String applicationDocumentsPath;
  final String _temporaryPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => applicationDocumentsPath;

  @override
  Future<String?> getTemporaryPath() async => _temporaryPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  test('pickSingleAudioFile copies file when path contains percent-encoded whitespace', () async {
    final sourceDir = await Directory.systemTemp.createTemp('file_repo_source_whitespace');
    final sourceFile = File(p.join(sourceDir.path, 'Butterfly by night.mp3'));
    await sourceFile.writeAsString('content');

    final encodedPath = sourceFile.path.replaceAll(' ', '%20');

    when(() => filePicker.pickFiles(type: FileType.audio)).thenAnswer(
      (_) async => FilePickerResult([
        PlatformFile(
          name: 'Butterfly by night.mp3',
          path: encodedPath,
          size: await sourceFile.length(),
        ),
      ]),
    );

    final repository = FileRepository(filePicker: filePicker);

    final copiedFile = await repository.pickSingleAudioFile();

    expect(copiedFile, isNotNull);
    expect(p.basename(copiedFile!.path), 'Butterfly by night.mp3');
    expect(await copiedFile.exists(), isTrue);
    expect(await copiedFile.readAsString(), 'content');

    await sourceDir.delete(recursive: true);
  });

  test('pickSingleAudioFile copies file when percent character is percent-encoded', () async {
    final sourceDir = await Directory.systemTemp.createTemp('file_repo_source_percent');
    const originalName = 'Butterfly%by%night.mp3';
    final sourceFile = File(p.join(sourceDir.path, originalName));
    await sourceFile.writeAsString('content-%');

    final encodedPath = sourceFile.path.replaceAll('%', '%25');

    when(() => filePicker.pickFiles(type: FileType.audio)).thenAnswer(
      (_) async => FilePickerResult([
        PlatformFile(
          name: originalName,
          path: encodedPath,
          size: await sourceFile.length(),
        ),
      ]),
    );

    final repository = FileRepository(filePicker: filePicker);

    final copiedFile = await repository.pickSingleAudioFile();

    expect(copiedFile, isNotNull);
    expect(p.basename(copiedFile!.path), originalName);
    expect(await copiedFile.exists(), isTrue);
    expect(await copiedFile.readAsString(), 'content-%');

    await sourceDir.delete(recursive: true);
  });

  test('pickMultipleAudioFiles normalizes provided paths', () async {
    final sourceDir = await Directory.systemTemp.createTemp('file_repo_multiple');
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
        type: FileType.audio,
        allowMultiple: true,
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

    final files = await repository.pickMultipleAudioFiles();

    expect(files, hasLength(2));
    expect(files[0].path, first.path);
    expect(files[1].path, second.path);

    await sourceDir.delete(recursive: true);
  });
}
