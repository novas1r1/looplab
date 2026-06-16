import 'dart:developer';

import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
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
  static const kAutoPlayOnLoopSelect = 'auto_play_on_loop_select';
  static const kFullSongRepeatEnabled = 'full_song_repeat_enabled';
  static const kLanguageCode = 'language_code';

  final SharedPreferences sharedPreferences;

  const LocalConfigRepository({required this.sharedPreferences});

  bool get introShown => sharedPreferences.getBool(kIntroShown) ?? false;

  Future<void> setIntroShown({required bool wasShown}) =>
      sharedPreferences.setBool(kIntroShown, wasShown);

  bool get hasCompletedTutorial =>
      sharedPreferences.getBool(kHasCompletedTutorial) ?? false;

  bool get acceptedDataprotection =>
      sharedPreferences.getBool(kAcceptedDataprotection) ?? false;

  bool get acceptedAnalytics =>
      sharedPreferences.getBool(kAnalyticsEnabled) ?? false;

  bool get hasRatedApp => sharedPreferences.getBool(kHasRatedApp) ?? false;

  Future<void> setCrashloggingEnabled({required bool isEnabled}) =>
      sharedPreferences.setBool(kCrashlyticsEnabled, isEnabled);

  Future<void> setAnalyticsEnabled({required bool isEnabled}) async {
    await sharedPreferences.setBool(kAnalyticsEnabled, isEnabled);

    if (isEnabled && !kDebugMode) {
      log('Resuming Clarity & PostHog');
      Clarity.resume();
      await Posthog().enable();
    } else {
      log('Pausing Clarity & PostHog');
      Clarity.pause();
      await Posthog().disable();
    }
  }

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

  /// Auto-play when selecting loops or navigating between them
  bool get autoPlayOnLoopSelect =>
      sharedPreferences.getBool(kAutoPlayOnLoopSelect) ?? true;

  Future<void> setAutoPlayOnLoopSelect({required bool isEnabled}) =>
      sharedPreferences.setBool(kAutoPlayOnLoopSelect, isEnabled);

  /// Full song repeat - loops the entire song when playback completes
  bool get fullSongRepeatEnabled =>
      sharedPreferences.getBool(kFullSongRepeatEnabled) ?? false;

  Future<void> setFullSongRepeatEnabled({required bool isEnabled}) =>
      sharedPreferences.setBool(kFullSongRepeatEnabled, isEnabled);

  /// Selected app language code (e.g. 'en', 'de'). `null` means follow system.
  String? get languageCode => sharedPreferences.getString(kLanguageCode);

  Future<void> setLanguageCode(String? code) async {
    if (code == null) {
      await sharedPreferences.remove(kLanguageCode);
    } else {
      await sharedPreferences.setString(kLanguageCode, code);
    }
  }
}
