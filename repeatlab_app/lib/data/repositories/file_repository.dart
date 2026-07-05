import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:repeatlab/app/view/repository_wrapper.dart';
import 'package:repeatlab/data/repositories/song_repository.dart';

class FileRepository {
  final FilePickerWrapper filePicker;

  const FileRepository({required this.filePicker});

  /// Pick one or more audio files and copy each into the app documents
  /// directory. Returns an empty list when the user cancels the picker.
  Future<List<File>> pickAudioFiles() async {
    FilePickerResult? result;

    if (Platform.isIOS) {
      // this allows to pick any file type from every location, also iCloud
      // result = await filePicker.pickFiles();

      result = await filePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'mp3',
          'm4a',
          'aac',
          'wav',
          'flac',
          'ogg',
          'wma',
          'opus',
          'aiff',
        ],
        allowMultiple: true,
      );
      // this only shows files in mediathek
      // result = await filePicker.pickFiles(
      //   type: FileType.audio,
      // );
    } else {
      try {
        // TODO: Fix this once [log] ERROR: PlatformException(invalid_format_type, Can't handle the provided file type., null, null)
        // is solved
        // filepicking for FileType.audio is not working. It displays all files in the system.
        result = await filePicker.pickFiles(
          type: FileType.audio,
          allowMultiple: true,
        );

        /* result = await filePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['mp3', 'm4a', 'aac', 'wav', 'flac', 'mpg', 'ogg'],
        ); */
      } on PlatformException catch (e) {
        log('Error picking file: $e');
        rethrow;
      }
    }

    return _copyPickedFiles(result);
  }

  /// Pick one or more video files and copy each into the app documents
  /// directory. Returns an empty list when the user cancels the picker.
  ///
  /// Mirrors [pickAudioFiles] for video formats supported by media_kit
  /// (libmpv), see [SongRepository.videoPickerExtensions].
  ///
  /// iOS must use `FileType.custom` with explicit extensions: `FileType.video`
  /// would open the Photos library picker instead of the Files browser.
  /// Android must use `FileType.video`: with `FileType.custom`, files whose
  /// document provider reports an unexpected MIME type would be greyed out.
  Future<List<File>> pickVideoFiles() async {
    FilePickerResult? result;

    if (Platform.isIOS) {
      result = await filePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: SongRepository.videoPickerExtensionsIos,
        allowMultiple: true,
      );
    } else {
      try {
        result = await filePicker.pickFiles(
          type: FileType.video,
          allowMultiple: true,
        );
      } on PlatformException catch (e) {
        log('Error picking video file: $e');
        rethrow;
      }
    }

    return _copyPickedFiles(result);
  }

  /// Move every picked file into the app documents directory, preserving the
  /// original file name where possible. When a file with the same name is
  /// already in the documents directory (an earlier import, possibly with
  /// different content and loops pointing into it), the incoming file is
  /// renamed to `<stem> (n).<ext>` instead of overwriting it. Files without
  /// a resolvable path are skipped.
  ///
  /// The picker already materializes a throwaway copy in the app cache, so a
  /// rename is enough — it is near-instant and avoids duplicating multi-hundred
  /// MB videos. Falls back to a full copy when the source sits on another
  /// volume (e.g. iOS security-scoped paths outside the cache dir).
  Future<List<File>> _copyPickedFiles(FilePickerResult? result) async {
    if (result == null || result.files.isEmpty) {
      return [];
    }

    final appDir = await getApplicationDocumentsDirectory();
    final copiedFiles = <File>[];

    for (final pickedFile in result.files) {
      final rawPath = pickedFile.path;
      if (rawPath == null || rawPath.isEmpty) {
        continue;
      }

      final sourceFile = File(_normalizePickedPath(rawPath));
      final fileName = _resolveFileName(pickedFile.name, sourceFile.path);
      final destinationPath = await _uniqueDestinationPath(appDir, fileName);
      final newFile = File(destinationPath);
      try {
        await sourceFile.rename(newFile.path);
      } on FileSystemException {
        await sourceFile.copy(newFile.path);
      }

      copiedFiles.add(newFile);
    }

    return copiedFiles;
  }
}

/// Returns a path in [dir] for [fileName] that doesn't collide with an
/// existing file: the name itself if free, otherwise `<stem> (n).<ext>` with
/// the smallest free `n`.
Future<String> _uniqueDestinationPath(Directory dir, String fileName) async {
  final direct = p.join(dir.path, fileName);
  if (!await File(direct).exists()) {
    return direct;
  }

  final stem = p.basenameWithoutExtension(fileName);
  final ext = p.extension(fileName);
  var counter = 1;
  while (true) {
    final candidate = p.join(dir.path, '$stem ($counter)$ext');
    if (!await File(candidate).exists()) {
      return candidate;
    }
    counter++;
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
