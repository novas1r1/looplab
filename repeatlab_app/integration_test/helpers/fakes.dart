import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:repeatlab/app/view/repository_wrapper.dart';
import 'package:repeatlab/data/repositories/purchases_repository.dart';

/// A [FilePickerWrapper] that returns a canned file instead of opening the
/// native picker, making media-import flows deterministic. [saveFile] returns a
/// temp path so export flows don't open the native save dialog either.
class FakeFilePickerWrapper extends FilePickerWrapper {
  /// File returned by the next [pickFiles] call. Set per flow (audio / video).
  File? fileToReturn;

  FakeFilePickerWrapper({this.fileToReturn});

  @override
  Future<FilePickerResult?> pickFiles({
    required FileType type,
    List<String>? allowedExtensions,
    bool allowMultiple = false,
    Function(FilePickerStatus)? onFileLoading,
  }) async {
    final file = fileToReturn;
    if (file == null) return null;
    return FilePickerResult([
      PlatformFile(
        name: p.basename(file.path),
        size: await file.length(),
        path: file.path,
      ),
    ]);
  }

  @override
  Future<String?> saveFile({
    required String fileName,
    required Uint8List bytes,
    required FileType type,
    List<String>? allowedExtensions,
  }) async {
    final dir = await getTemporaryDirectory();
    final out = File(p.join(dir.path, fileName));
    await out.writeAsBytes(bytes, flush: true);
    return out.path;
  }
}

/// A [PurchasesRepository] that never touches RevenueCat. [isPro] controls
/// whether premium-gated features (multiple loops, backup, speed) are unlocked.
class FakePurchasesRepository extends PurchasesRepository {
  final bool isPro;

  const FakePurchasesRepository({this.isPro = true});

  @override
  Future<void> setup() async {
    // No-op — never configure the real SDK in tests.
  }

  @override
  Future<bool> get hasWeeklySubscription async => false;

  @override
  Future<bool> get hasYearlySubscription async => false;

  @override
  Future<bool> get hasLifetimePurchase async => isPro;

  @override
  Future<List<Offering>> get offers async => [];
}
