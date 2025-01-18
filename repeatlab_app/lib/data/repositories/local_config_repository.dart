import 'package:shared_preferences/shared_preferences.dart';

class LocalConfigRepository {
  static const kIntroShown = 'intro_shown';
  static const kCrashlyticsEnabled = 'crashlytics_enabled';
  static const kAnalyticsEnabled = 'analytics_enabled';
  static const kAcceptedDataprotection = 'accepted_dataprotection';

  /// build version of the app when the changelog was last shown
  static const kChangelogVersionShown = 'changelog_version_shown';
  static const kRateAppDialogShown = 'rate_app_dialog_shown';
  static const kHasRatedApp = 'has_rated_app';
  static const kHasRatedAppTime = 'has_rated_app_time';
  static const kHasCompletedTutorial = 'has_completed_tutorial';

  final SharedPreferences sharedPreferences;

  const LocalConfigRepository({required this.sharedPreferences});

  bool get introShown => sharedPreferences.getBool(kIntroShown) ?? false;

  Future<void> setIntroShown({required bool wasShown}) =>
      sharedPreferences.setBool(kIntroShown, wasShown);

  bool get hasCompletedTutorial =>
      sharedPreferences.getBool(kHasCompletedTutorial) ?? false;

  bool get acceptedDataprotection =>
      sharedPreferences.getBool(kAcceptedDataprotection) ?? false;

  bool get acceptedCrashlogging =>
      sharedPreferences.getBool(kCrashlyticsEnabled) ?? false;

  bool get acceptedAnalytics =>
      sharedPreferences.getBool(kAnalyticsEnabled) ?? false;

  bool get hasRatedApp => sharedPreferences.getBool(kHasRatedApp) ?? false;

  Future<void> setCrashloggingEnabled({required bool isEnabled}) =>
      sharedPreferences.setBool(kCrashlyticsEnabled, isEnabled);

  Future<void> setAnalyticsEnabled({required bool isEnabled}) =>
      sharedPreferences.setBool(kAnalyticsEnabled, isEnabled);

  Future<void> setHasCompletedTutorial({required bool hasCompleted}) =>
      sharedPreferences.setBool(kHasCompletedTutorial, hasCompleted);

  Future<bool> clear() => sharedPreferences.clear();

  Future<void> setChangelogShown(int version) =>
      sharedPreferences.setInt(kChangelogVersionShown, version);

  int get lastChangelogVersionShown =>
      sharedPreferences.getInt(kChangelogVersionShown) ?? 1;

  bool get rateAppDialogShown =>
      sharedPreferences.getBool(kRateAppDialogShown) ?? false;

  Future<void> setHasRatedApp(bool value) async {
    await sharedPreferences.setBool(kHasRatedApp, value);
    await sharedPreferences.setString(
      kHasRatedAppTime,
      DateTime.now().toIso8601String(),
    );
  }
}
