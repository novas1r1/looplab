import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class CrashReportingRepository {
  const CrashReportingRepository();

  Future<SentryId?> reportError(
    Object error,
    StackTrace stackTrace, {
    Map<String, dynamic>? properties,
  }) async {
    log('ERROR: $error');
    if (Sentry.isEnabled) {
      if (properties != null) {
        await Sentry.captureMessage(properties.toString());
      } else {
        await Sentry.captureException(error, stackTrace: stackTrace);
      }
    }

    return null;
  }

  Future<void> logInfos(String message) async {
    if (Sentry.isEnabled && !kDebugMode) {
      await Sentry.captureMessage(message);
    }
  }
}
