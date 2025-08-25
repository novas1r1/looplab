import 'dart:io';

import 'package:file_picker/file_picker.dart';
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

    // copy file to app directory
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = result.files.single.path!.split('/').last;
    final file = File(result.files.single.path!);
    final newFile = File('${appDir.path}/$fileName');
    await file.copy(newFile.path);

    return newFile;
  }

  Future<List<File>> pickMultipleAudioFiles() async {
    final result = await filePicker.pickFiles(
      type: FileType.audio,
      allowMultiple: true,
    );

    return result != null ? result.paths.map((path) => File(path!)).toList() : [];
  }
}
