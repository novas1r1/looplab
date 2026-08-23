import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:repeatlab/app_bloc_observer.dart';
import 'package:repeatlab/bootstrap.dart';

/// Driver-enabled entrypoint used for interactive development, not for CI.
///
/// It is the production app — same [bootstrap] call as `main()`, same real
/// dependencies (Sembast, SoLoud, media_kit, preferences) — with the Flutter
/// Driver extension registered so tooling can drive the running instance over
/// the VM service: tap, scroll, enter text, read the widget tree.
///
/// Deliberately absent, exactly as in the E2E harness: Sentry, Clarity,
/// PostHog and UserOrient. Development sessions must not report crashes,
/// record sessions, or emit analytics. `SystemChrome` and the bloc observer
/// stay, since they only affect what the app looks like and logs locally.
///
/// Run it with `make run-driver`, then attach.
Future<void> main() async {
  enableFlutterDriverExtension();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  Bloc.observer = const AppBlocObserver();

  runApp(await bootstrap());
}
