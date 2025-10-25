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

    // Always report to Sentry in release mode, and optionally in debug mode
    if (Sentry.isEnabled) {
      try {
        if (properties != null) {
          // Add properties as extra data to the exception
          await Sentry.captureException(
            error,
            stackTrace: stackTrace,
            hint: Hint.withMap(properties),
          );
        } else {
          await Sentry.captureException(
            error,
            stackTrace: stackTrace,
          );
        }
      } catch (sentryError) {
        // If Sentry itself fails, log to console
        log('Failed to report error to Sentry: $sentryError');
      }
    }

    return null;
  }

  Future<void> logInfos(String message) async {
    if (Sentry.isEnabled && !kDebugMode) {
      try {
        await Sentry.captureMessage(message);
      } catch (sentryError) {
        log('Failed to log info to Sentry: $sentryError');
      }
    }
  }

  Future<void> logWarning(
    String message, {
    Map<String, dynamic>? context,
  }) async {
    if (Sentry.isEnabled) {
      try {
        await Sentry.captureMessage(
          message,
          level: SentryLevel.warning,
          hint: context != null ? Hint.withMap(context) : null,
        );
      } catch (sentryError) {
        log('Failed to log warning to Sentry: $sentryError');
      }
    }
  }
}
