import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class CrashReportingRepository {
  const CrashReportingRepository();

  Future<void> reportError(Object error, StackTrace stackTrace) async {
    log('ERROR: $error');
    if (Sentry.isEnabled && !kDebugMode) {
      await Sentry.captureException(error, stackTrace: stackTrace);
    }
  }

  Future<void> logInfos(String message) async {
    if (Sentry.isEnabled && !kDebugMode) {
      await Sentry.captureMessage(message);
    }
  }
}
