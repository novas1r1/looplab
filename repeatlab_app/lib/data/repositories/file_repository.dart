import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class FileRepository {
  final FilePicker filePicker;

  const FileRepository({required this.filePicker});

  Future<File?> pickSingleAudioFile() async {
    FilePickerResult? result;

    if (Platform.isIOS) {
      // this allows to pick any file type from every location, also iCloud
      // result = await filePicker.pickFiles();

      result = await filePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'aac', 'wav', 'flac', 'mpg', 'ogg'],
      );
      // this only shows files in mediathek
      // result = await filePicker.pickFiles(
      //   type: FileType.audio,
      // );
    } else {
      result = await filePicker.pickFiles(
        type: FileType.audio,
      );
    }

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final pickedFile = result.files.single;
    final rawPath = pickedFile.path;
    if (rawPath == null || rawPath.isEmpty) {
      return null;
    }

    final sourceFile = File(_normalizePickedPath(rawPath));

    // copy file to app directory
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = _resolveFileName(pickedFile.name, sourceFile.path);
    final destinationPath = p.join(appDir.path, fileName);
    final newFile = File(destinationPath);
    await sourceFile.copy(newFile.path);

    return newFile;
  }

  Future<List<File>> pickMultipleAudioFiles() async {
    final result = await filePicker.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    if (result == null) {
      return [];
    }

    return result.paths.whereType<String>().map(_normalizePickedPath).map(File.new).toList();
  }
}

String _resolveFileName(String providedName, String sourcePath) {
  final decodedName = _decodePercentEncodedSegment(providedName);
  if (decodedName.trim().isNotEmpty) {
    return decodedName;
  }

  return _decodePercentEncodedSegment(p.basename(sourcePath));
}

String _normalizePickedPath(String path) {
  if (path.startsWith('file://')) {
    try {
      return Uri.parse(path).toFilePath();
    } on FormatException {
      final withoutScheme = path.substring(7);
      return _decodePercentEncodedSegment(withoutScheme);
    }
  }

  return _decodePercentEncodedSegment(path);
}

String _decodePercentEncodedSegment(String value) {
  if (!value.contains('%')) {
    return value;
  }

  final hasEncodedPattern = RegExp('%[0-9A-Fa-f]{2}').hasMatch(value);

  if (!hasEncodedPattern) {
    return value;
  }

  try {
    return Uri.decodeFull(value);
  } on FormatException {
    return value;
  }
}
