import 'dart:async';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:repeatlab/app_bloc_observer.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> bootstrap(FutureOr<Widget> Function() builder) async {
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
    },
    appRunner: () async => runApp(await builder()),
  );
}
