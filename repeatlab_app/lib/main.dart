import 'dart:developer';

import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:repeatlab/app/app.dart';
import 'package:repeatlab/app_bloc_observer.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
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
  await soloud.init();
  // SoLoud.instance.setVisualizationEnabled(true);

  final packageInfo = await PackageInfo.fromPlatform();
  final sharedPreferences = await SharedPreferences.getInstance();
  final localConfigRepository = LocalConfigRepository(
    sharedPreferences: sharedPreferences,
  );
  // get current device language
  // final deviceLanguage = Platform.localeName.split('_')[0];
  UserOrient.configure(
    apiKey: '691f5ff6-2fa2-444f-b440-734f7cb12c1d',
    languageCode: 'en',
  );

  final config = ClarityConfig(
    projectId: "s94ipqi1r5",
    logLevel: LogLevel.None,
  );

  final isAnalyticsEnabled = localConfigRepository.acceptedAnalytics;

  if (isAnalyticsEnabled && !kDebugMode) {
    Clarity.resume();
  } else {
    Clarity.pause();
  }

  // needed if we use just_audio_background
  /* await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  ); */

  // debugRepaintRainbowEnabled = true;

  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);
  };

  Bloc.observer = const AppBlocObserver();

  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://2ca5460258f78d3ad8694f64123da2e1@o4508596905050112.ingest.de.sentry.io/4508596929167440';
      options.tracesSampleRate = 1.0;
      options.profilesSampleRate = 1.0;
      options.sendDefaultPii = false;
      options.attachScreenshot = true;
      options.environment = kDebugMode ? 'dev' : 'prod';
    },
    appRunner: () => runApp(
      SentryWidget(
        child: ClarityWidget(
          app: App(
            db: db,
            soloud: soloud,
            packageInfo: packageInfo,
            localConfigRepository: localConfigRepository,
          ),
          clarityConfig: config,
        ),
      ),
    ),
  );
}
