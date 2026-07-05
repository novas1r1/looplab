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

  FileRepository({required this.filePicker});

  /// True while a pick — including the platform-side copy of the picked
  /// files into the app cache — is still running. On Android, picking from a
  /// cloud document provider (OneDrive, Google Drive, …) downloads the whole
  /// file before the pick future resolves, which can take minutes for large
  /// videos. The platform plugin only supports one active pick, so new picks
  /// during that window must be rejected explicitly instead of surfacing as
  /// an opaque 'already_active' platform error.
  bool _pickInProgress = false;

  /// Pick one or more audio files and copy each into the app documents
  /// directory. Returns an empty list when the user cancels the picker.
  ///
  /// Throws [PickAlreadyInProgressException] when a previous pick (possibly
  /// still copying a large cloud file) has not finished yet.
  Future<List<File>> pickAudioFiles() {
    return _pickAndCopy(() async {
      if (Platform.isIOS) {
        // this allows to pick any file type from every location, also iCloud
        // result = await filePicker.pickFiles();

        return filePicker.pickFiles(
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
          onFileLoading: _logPickerStatus,
        );
        // this only shows files in mediathek
        // result = await filePicker.pickFiles(
        //   type: FileType.audio,
        // );
      }
      try {
        // TODO: Fix this once [log] ERROR: PlatformException(invalid_format_type, Can't handle the provided file type., null, null)
        // is solved
        // filepicking for FileType.audio is not working. It displays all files in the system.
        return await filePicker.pickFiles(
          type: FileType.audio,
          allowMultiple: true,
          onFileLoading: _logPickerStatus,
        );

        /* result = await filePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['mp3', 'm4a', 'aac', 'wav', 'flac', 'mpg', 'ogg'],
        ); */
      } on PlatformException catch (e) {
        log('Error picking file: $e');
        rethrow;
      }
    });
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
  ///
  /// Throws [PickAlreadyInProgressException] when a previous pick (possibly
  /// still copying a large cloud file) has not finished yet.
  Future<List<File>> pickVideoFiles() {
    return _pickAndCopy(() async {
      if (Platform.isIOS) {
        return filePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: SongRepository.videoPickerExtensionsIos,
          allowMultiple: true,
          onFileLoading: _logPickerStatus,
        );
      }
      try {
        return await filePicker.pickFiles(
          type: FileType.video,
          allowMultiple: true,
          onFileLoading: _logPickerStatus,
        );
      } on PlatformException catch (e) {
        log('Error picking video file: $e');
        rethrow;
      }
    });
  }

  /// Runs [pick] with a re-entrancy guard, then copies the result into the
  /// app documents directory. Rejects overlapping picks — both via the local
  /// [_pickInProgress] flag and by translating the plugin's 'already_active'
  /// error (a pick left pending on the platform side, e.g. after the user
  /// backed out while a cloud file was still downloading) — as
  /// [PickAlreadyInProgressException].
  Future<List<File>> _pickAndCopy(
    Future<FilePickerResult?> Function() pick,
  ) async {
    if (_pickInProgress) {
      throw const PickAlreadyInProgressException();
    }
    _pickInProgress = true;
    final stopwatch = Stopwatch()..start();
    try {
      log('Pick started', name: 'ImportTiming');
      final result = await pick();
      // On Android this duration includes the plugin copying every picked
      // file from its document provider (OneDrive, Drive, …) into the app
      // cache — usually the dominant cost for large cloud files.
      log(
        'Picker returned ${result?.files.length ?? 0} file(s) '
        'after ${stopwatch.elapsedMilliseconds} ms',
        name: 'ImportTiming',
      );
      final files = await _copyPickedFiles(result);
      log(
        'Pick + copy finished after ${stopwatch.elapsedMilliseconds} ms',
        name: 'ImportTiming',
      );
      return files;
    } on PlatformException catch (e) {
      if (e.code == 'already_active') {
        throw const PickAlreadyInProgressException();
      }
      rethrow;
    } finally {
      _pickInProgress = false;
    }
  }

  /// The plugin reports `picking` when it starts materializing the selected
  /// files (on Android: copying them from the document provider into the app
  /// cache) and `done` when finished. If logcat shows `picking` and never
  /// `done`, the freeze is inside the provider stream, not in our code.
  void _logPickerStatus(FilePickerStatus status) {
    log('File picker status: $status', name: 'ImportTiming');
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
      final stopwatch = Stopwatch()..start();
      try {
        await sourceFile.rename(newFile.path);
        log(
          'Renamed "$fileName" (${pickedFile.size} bytes) into app dir '
          'in ${stopwatch.elapsedMilliseconds} ms',
          name: 'ImportTiming',
        );
      } on FileSystemException catch (ex) {
        log(
          'Rename failed for "$fileName" ($ex), falling back to full copy',
          name: 'ImportTiming',
        );
        await sourceFile.copy(newFile.path);
        log(
          'Copied "$fileName" (${pickedFile.size} bytes) into app dir '
          'in ${stopwatch.elapsedMilliseconds} ms',
          name: 'ImportTiming',
        );
      }

      copiedFiles.add(newFile);
    }

    return copiedFiles;
  }
}

/// Thrown when a new file pick is requested while a previous pick is still
/// running — typically because the platform is still downloading/copying a
/// large file from a cloud provider (OneDrive, Google Drive, iCloud, …).
class PickAlreadyInProgressException implements Exception {
  const PickAlreadyInProgressException();

  @override
  String toString() => 'A file pick is already in progress.';
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
