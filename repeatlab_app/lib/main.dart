import 'dart:developer';

import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:repeatlab/app_bloc_observer.dart';
import 'package:repeatlab/bootstrap.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:userorient_flutter/userorient_flutter.dart';

Future<void> main() async {
  SentryWidgetsFlutterBinding.ensureInitialized();

  // Initialize Sentry before anything else to catch early crashes
  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://2ca5460258f78d3ad8694f64123da2e1@o4508596905050112.ingest.de.sentry.io/4508596929167440';
      options.tracesSampleRate = 1.0;
      options.sendDefaultPii = false;
      options.attachScreenshot = true;
      options.environment = kDebugMode ? 'dev' : 'prod';

      // Enable native crash reporting
      options.enableAutoSessionTracking = true;
      options.attachStacktrace = true;

      // Set debug mode for better error reporting in debug builds
      options.debug = kDebugMode;
    },
  );

  // Wrap the entire app initialization in a try-catch to catch any startup errors
  try {
    await _initializeApp();
  } catch (error, stackTrace) {
    // Report any startup errors to Sentry
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      hint: Hint.withMap({'location': 'app_initialization'}),
    );
    rethrow;
  }
}

Future<void> _initializeApp() async {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Build the app and all of its core dependencies (DB, audio/video engines,
  // package info, preferences). Shared with E2E tests, see [bootstrap].
  final app = await bootstrap();

  // get current device language
  // final deviceLanguage = Platform.localeName.split('_')[0];
  try {
    UserOrient.configure(
      apiKey: '691f5ff6-2fa2-444f-b440-734f7cb12c1d',
    );
  } catch (error, stackTrace) {
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      hint: Hint.withMap({'location': 'userorient_configure'}),
    );
    // Don't rethrow for UserOrient as it's not critical
  }

  final config = ClarityConfig(
    projectId: "s94ipqi1r5",
    logLevel: LogLevel.None,
  );

  final isAnalyticsEnabled = app.localConfigRepository.acceptedAnalytics;

  if (isAnalyticsEnabled && !kDebugMode) {
    Clarity.resume();
  } else {
    Clarity.pause();
  }

  // Initialize PostHog manually (native AUTO_INIT is disabled) so nothing is
  // captured before the user has consented. `optOut` mirrors the Clarity gating
  // above: data is only collected in release builds with analytics consent.
  // Consent changes at runtime flip this via Posthog().enable()/disable() in
  // LocalConfigRepository.setAnalyticsEnabled.
  try {
    await Posthog().setup(
      PostHogConfig('phc_Bq9ELUiqpUjZM8QvSBR5HXbDbPVzjD2tNdLwy5FkxP4n')
        ..host = 'https://eu.i.posthog.com'
        ..debug = kDebugMode
        ..captureApplicationLifecycleEvents = true
        ..personProfiles = PostHogPersonProfiles.identifiedOnly
        ..optOut = !(isAnalyticsEnabled && !kDebugMode),
    );
  } catch (error, stackTrace) {
    await Sentry.captureException(
      error,
      stackTrace: stackTrace,
      hint: Hint.withMap({'location': 'posthog_setup'}),
    );
    // Don't rethrow; analytics is not critical to app startup.
  }

  // Restore the consent state for the pre-consent event buffer. Until the
  // user decides (onboarding not finished), AppAnalytics holds events in
  // memory; they are flushed on opt-in and discarded on opt-out — see
  // AppAnalytics.onConsentDecision, called from setAnalyticsEnabled.
  AppAnalytics.init(
    consented: isAnalyticsEnabled,
    consentDecided: app.localConfigRepository.introShown,
  );

  // needed if we use just_audio_background
  /* await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  ); */

  // debugRepaintRainbowEnabled = true;

  // Enhanced error handling for Flutter framework errors
  FlutterError.onError = (details) {
    log(details.exceptionAsString(), stackTrace: details.stack);

    // Report to Sentry
    Sentry.captureException(
      details.exception,
      stackTrace: details.stack,
      hint: Hint.withMap({
        'location': 'flutter_error',
        'library': details.library ?? 'unknown',
        'context': details.context?.toString() ?? 'unknown',
      }),
    );
  };

  // Handle unhandled asynchronous errors
  PlatformDispatcher.instance.onError = (error, stack) {
    log('Unhandled platform error: $error', stackTrace: stack);

    // Report to Sentry
    Sentry.captureException(
      error,
      stackTrace: stack,
      hint: Hint.withMap({'location': 'platform_dispatcher_error'}),
    );

    return true; // Prevent the error from being re-thrown
  };

  Bloc.observer = const AppBlocObserver();

  // Run the app wrapped in SentryWidget
  runApp(
    SentryWidget(
      child: ClarityWidget(
        app: /* DevicePreview(
          builder: (context) =>  */
            app,
        // ),
        clarityConfig: config,
      ),
    ),
  );
}
