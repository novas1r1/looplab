import 'dart:io';

import 'package:file_picker/file_picker.dart';

class FileRepository {
  FileRepository({required this.filePicker});
  final FilePicker filePicker;

  Future<File?> pickSingleAudioFile() async {
    final result = await filePicker.pickFiles(
        // type: FileType.audio,
        );

    if (result != null) {
      final file = File(result.files.single.path!);
      return file;
    }
    return null;
  }

  Future<List<File>> pickMultipleAudioFiles() async {
    final result = await filePicker.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    if (result != null) {
      final files = result.paths.map((path) => File(path!)).toList();
      return files;
    }

    return [];
  }
}
