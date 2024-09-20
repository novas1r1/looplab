import 'dart:io';

import 'package:file_picker/file_picker.dart';

class FileRepository {
  final FilePicker filePicker;

  const FileRepository({required this.filePicker});

  Future<File?> pickSingleAudioFile() async {
    final result = await filePicker.pickFiles(
        // type: FileType.audio,
        );

    return result != null ? File(result.files.single.path!) : null;
  }

  Future<List<File>> pickMultipleAudioFiles() async {
    final result = await filePicker.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    return result != null
        ? result.paths.map((path) => File(path!)).toList()
        : [];
  }
}
