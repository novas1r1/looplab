import 'dart:io';
import 'dart:typed_data';

// ignore: depend_on_referenced_packages
import 'package:cross_file/cross_file.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:repeatlab/app/view/repository_wrapper.dart';
import 'package:repeatlab/data/repositories/purchases_repository.dart';

/// A concrete [PlatformFile] backed by a local [File], for feeding canned
/// picks into the app (the plugin's own implementations are platform-side).
base class LocalPlatformFile extends PlatformFile {
  final File file;

  LocalPlatformFile(this.file);

  @override
  String get name => p.basename(file.path);

  @override
  Uri get uri => Uri.file(file.path);

  @override
  String? get path => file.path;

  @override
  XFile get xFile => XFile(file.path, name: name);

  @override
  Future<int> length() => file.length();

  @override
  Future<Uint8List> readAsBytes() => file.readAsBytes();

  @override
  Stream<Uint8List> readAsByteStream() =>
      file.openRead().map(Uint8List.fromList);
}

/// A [FilePickerWrapper] that returns a canned file instead of opening the
/// native picker, making media-import flows deterministic. [saveFile] returns a
/// temp path so export flows don't open the native save dialog either.
class FakeFilePickerWrapper extends FilePickerWrapper {
  /// Files returned by the next [pickFiles] call (a multi-select result when
  /// there is more than one). Set per flow (audio / video). Empty → the pick
  /// is treated as cancelled.
  List<File> filesToReturn;

  FakeFilePickerWrapper({File? fileToReturn, List<File>? filesToReturn})
    : filesToReturn = [
        ...?filesToReturn,
        if (fileToReturn != null) fileToReturn,
      ];

  @override
  Future<List<PlatformFile>> pickFiles({
    required FileType type,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
  }) async {
    return [for (final file in filesToReturn) LocalPlatformFile(file)];
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

/// A [PurchasesRepository] that configures the REAL RevenueCat SDK (so the
/// native paywall can be presented) but reports the user as non-Pro to the
/// app, whatever the device's sandbox account says. Used by the paywall flow:
/// every premium gate then routes to `presentPaywall`, and the RevenueCat
/// paywall sheet actually opens on the device.
///
/// Note that `presentPaywallIfNeeded('Pro')` still asks RevenueCat itself, so
/// the device's (anonymous) RevenueCat user must not hold the Pro entitlement
/// - otherwise the sheet is skipped and the flow fails with a clear message.
class NonProRealPurchasesRepository extends PurchasesRepository {
  const NonProRealPurchasesRepository();

  @override
  Future<bool> get hasWeeklySubscription async => false;

  @override
  Future<bool> get hasYearlySubscription async => false;

  @override
  Future<bool> get hasLifetimePurchase async => false;
}
