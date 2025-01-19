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
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  bootstrap(
    () => App(
      db: db,
      soloud: soloud,
      packageInfo: packageInfo,
      sharedPreferences: sharedPreferences,
    ),
  );
}
