import 'package:sentry_flutter/sentry_flutter.dart';

class CrashReportingRepository {
  const CrashReportingRepository();

  Future<void> reportError(Object error, StackTrace stackTrace) async {
    if (Sentry.isEnabled) {
      await Sentry.captureException(error, stackTrace: stackTrace);
    }
  }

  Future<void> logInfos(String message) async {
    if (Sentry.isEnabled) {
      await Sentry.captureMessage(message);
    }
  }
}
