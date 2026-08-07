import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:media_kit/media_kit.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:repeatlab/app/app.dart';
import 'package:repeatlab/app/view/repository_wrapper.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
import 'package:repeatlab/data/repositories/purchases_repository.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Builds the [App] widget along with its core dependencies (database, audio /
/// video engines, package info, preferences).
///
/// This is the single shared construction path for both production ([main]) and
/// E2E tests. Every parameter defaults to the real implementation, so production
/// behaviour is unchanged; tests inject fakes for the seams that would otherwise
/// hit native UI or remote services:
///
/// - [database] — an open Sembast database (tests pass an isolated handle).
/// - [filePicker] — the file-picker wrapper (tests fake media imports / saves).
/// - [purchases] — the RevenueCat repository (tests fake the Pro entitlement).
/// - [sharedPreferences] — the preferences store (tests pass a reset store).
///
/// Sentry / Clarity / UserOrient initialisation and `runApp` deliberately stay
/// in [main]; this function never initialises them, so test runs stay offline
/// and side-effect free. The granular `Sentry.captureException` calls below are
/// safe no-ops when Sentry has not been initialised (i.e. under tests).
Future<App> bootstrap({
  Database? database,
  FilePickerWrapper? filePicker,
  PurchasesRepository? purchases,
  SharedPreferences? sharedPreferences,
}) async {
  // Initialize database with error handling
  Database db;
  try {
    if (database != null) {
      db = database;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      // make sure it exists
      await dir.create(recursive: true);
      // build the database path
      final dbPath = join(dir.path, 'repeatlab.db');
      // open the database
      db = await databaseFactoryIo.openDatabase(dbPath);
    }
  } catch (error, stackTrace) {
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      hint: Hint.withMap({'location': 'database_initialization'}),
    );
    rethrow;
  }

  MapperContainer.globals.use(const DurationMapper());

  // SoLoud is only a decoder in this app (waveforms decode engine-free via
  // readSamplesFromMem; the import probe initializes the engine on demand in
  // SongRepository.addSongFile). Deliberately NOT initialized here: a running
  // engine keeps an output audio stream open app-wide, and miniaudio's
  // device-update callback crashed on audio route changes (Bluetooth
  // connect/disconnect, unplugging headphones) — Sentry FLUTTER-2Y (Android,
  // 330 events) and FLUTTER-FY (iOS). A startup init failure also used to
  // kill app boot entirely (FLUTTER-HZ).
  final soloud = SoLoud.instance;

  // Initialize media_kit (libmpv-based video playback). Idempotent and cheap;
  // safe to call even if no video songs exist yet.
  try {
    MediaKit.ensureInitialized();
  } catch (error, stackTrace) {
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      hint: Hint.withMap({'location': 'media_kit_initialization'}),
    );
    // Don't rethrow: audio still works without media_kit.
  }

  // Initialize other services with error handling
  PackageInfo packageInfo;
  SharedPreferences prefs;
  LocalConfigRepository localConfigRepository;

  try {
    packageInfo = await PackageInfo.fromPlatform();
    prefs = sharedPreferences ?? await SharedPreferences.getInstance();
    localConfigRepository = LocalConfigRepository(
      sharedPreferences: prefs,
    );
  } catch (error, stackTrace) {
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      hint: Hint.withMap({'location': 'package_info_shared_preferences'}),
    );
    rethrow;
  }

  return App(
    db: db,
    soloud: soloud,
    packageInfo: packageInfo,
    localConfigRepository: localConfigRepository,
    filePicker: filePicker ?? const FilePickerWrapper(),
    purchases: purchases ?? const PurchasesRepository(),
  );
}
