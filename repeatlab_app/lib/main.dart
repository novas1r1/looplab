import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:repeatlab/app/app.dart';
import 'package:repeatlab/bootstrap.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:userorient_flutter/userorient_flutter.dart';

Future<void> main() async {
  SentryWidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  final dir = await getApplicationDocumentsDirectory();
// make sure it exists
  await dir.create(recursive: true);
// build the database path
  final dbPath = join(dir.path, 'repeatlab.db');
// open the database
  final db = await databaseFactoryIo.openDatabase(dbPath);

  MapperContainer.globals.use(const DurationMapper());

  final soloud = SoLoud.instance;
  await soloud.init(sampleRate: 48000);

  final packageInfo = await PackageInfo.fromPlatform();
  final sharedPreferences = await SharedPreferences.getInstance();

  // get current device language
  // final deviceLanguage = Platform.localeName.split('_')[0];
  UserOrient.configure(
    apiKey: '691f5ff6-2fa2-444f-b440-734f7cb12c1d',
    languageCode: 'en',
  );

  bootstrap(
    () => SentryWidget(
      child: App(
        db: db,
        packageInfo: packageInfo,
        sharedPreferences: sharedPreferences,
        // audioPlayer: audioPlayer,
      ),
    ),
  );
}
