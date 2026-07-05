import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

abstract final class AppAnalytics {
  const AppAnalytics._();
  // screens
  static const viewHome = 'view_home';
  static const viewSong = 'view_song';
  static const viewFeedback = 'view_feedback';
  static const viewRateApp = 'view_rate_app';
  static const viewDataProtection = 'view_data_protection';
  static const viewTermsOfService = 'view_terms_of_service';
  static const viewLegalNotices = 'view_legal_notices';
  static const viewLicenses = 'view_licenses';
  static const viewPremiumScreen = 'view_premium_screen';
  static const viewChangelogDialog = 'view_changelog_dialog';
  static const viewTapBpmDialog = 'view_tap_bpm_dialog';
  static const viewEditOriginalBpmDialog = 'view_edit_original_bpm_dialog';
  static const viewEditLoopDialog = 'view_edit_loop_dialog';
  static const viewExportLoopDialog = 'view_export_loop_dialog';
  static const viewOnboarding = 'view_onboarding';
  // events home screen
  static const clickAddSong = 'click_add_song';
  static const clickClearDb = 'click_clear_db';
  static const clickDeleteSong = 'click_delete_song';
  static const clickReportBug = 'click_report_bug';
  static const clickRateApp = 'click_rate_app';
  static const clickFeedback = 'click_feedback';
  static const clickVoteForFeatures = 'click_vote_for_features';
  static const clickHelp = 'click_help';
  static const clickOpenSong = 'click_open_song';
  static const clickSkipTutorial = 'click_skip_tutorial';
  // events song screen
  static const clickDeleteLoop = 'click_delete_loop';
  static const clickAddLoop = 'click_add_loop';
  static const clickForward10Seconds = 'click_forward_10_sec';
  static const clickBack10Seconds = 'click_back_10_sec';
  static const clickSkipPrevious = 'click_skip_previous';
  static const clickSkipNext = 'click_skip_next';
  static const clickEditLoop = 'click_edit_loop';
  static const clickPlayLoop = 'click_play_loop';
  static const clickStopLoop = 'click_stop_loop';
  static const clickPlaySong = 'click_play_song';
  static const clickPauseSong = 'click_pause_song';
  static const clickSetLoopStart = 'click_set_loop_start';
  static const clickSetLoopEnd = 'click_set_loop_end';
  static const clickUpdateSpeed = 'click_update_speed';
  static const clickUpdatePitch = 'click_update_pitch';
  static const clickUpdateBpm = 'click_update_bpm';
  static const clickSetOriginalBpm = 'click_set_original_bpm';
  static const clickShowTutorial = 'click_show_tutorial';
  static const clickZoomIn = 'click_zoom_in';
  static const clickZoomOut = 'click_zoom_out';
  static const clickRestore = 'click_restore';
  static const clickTerms = 'click_terms';
  static const clickPrivacy = 'click_privacy';
  static const clickDeleteAllData = 'click_delete_all_data';
  static const clickUseTappedBpm = 'click_use_tapped_bpm';
  static const clickTempoModeMultiplier = 'click_tempo_mode_multiplier';
  static const clickTempoModeBpm = 'click_tempo_mode_bpm';
  static const clickToggleFullSongRepeat = 'click_toggle_full_song_repeat';
  static const clickToggleAutoPlay = 'click_toggle_auto_play';
  static const clickEditSong = 'click_edit_song';
  static const clickToggleLoopMode = 'click_toggle_loop_mode';
  static const clickReorderLoops = 'click_reorder_loops';
  static const reorderSongs = 'reorder_songs';
  static const clickUpdateLoop = 'click_update_loop';

  // export
  static const clickExportLoop = 'click_export_loop';
  static const exportLoopSuccess = 'export_loop_success';
  static const exportLoopError = 'export_loop_error';
  static const exportLoopCanceled = 'export_loop_canceled';

  // song add lifecycle
  static const songAddSuccess = 'song_add_success';
  static const songAddError = 'song_add_error';
  static const songAddUnsupportedFormat = 'song_add_unsupported_format';

  // paywall

  /// Unified paywall-view funnel event, carrying a `trigger` property so a
  /// single funnel step covers every paywall entry point. Fired via
  /// [trackPaywallViewed].
  static const paywallViewed = 'paywall_viewed';

  // backup & restore
  static const clickBackupExport = 'click_backup_export';
  static const backupExportSuccess = 'backup_export_success';
  static const backupExportFailure = 'backup_export_failure';
  static const backupExportShareCanceled = 'backup_export_share_canceled';
  static const clickBackupImport = 'click_backup_import';
  static const backupImportPicked = 'backup_import_picked';
  static const backupImportCanceled = 'backup_import_canceled';
  static const backupImportSuccess = 'backup_import_success';
  static const backupImportFailure = 'backup_import_failure';

  // subscription
  static const clickCancelSubscriptionAndroid =
      'click_cancel_subscription_android';
  static const clickCancelSubscriptionIos = 'click_cancel_subscription_ios';
  static const restoreSubscriptionSuccess = 'restore_subscription_success';
  static const restoreSubscriptionFailure = 'restore_subscription_failure';

  // language
  static const clickChangeLanguage = 'click_change_language';
  static const changeLanguage = 'change_language';

  // onboarding
  static const onboardingStarted = 'onboarding_started';
  static const onboardingCompleted = 'onboarding_completed';
  static const onboardingAnalyticsAccepted = 'onboarding_analytics_accepted';
  static const onboardingAnalyticsDeclined = 'onboarding_analytics_declined';

  // activation milestones
  static const loopCreated = 'loop_created';
  static const firstSongAdded = 'first_song_added';
  static const firstLoopCreated = 'first_loop_created';

  // monetization
  static const purchaseSuccess = 'purchase_success';
  static const paywallDismissed = 'paywall_dismissed';

  static void trackEvent(
    String event, {
    Map<String, dynamic>? data,
  }) {
    log('ANALYTICS: $event, data: $data');
    if (kDebugMode) return;

    // Run inside a guarded zone so any sync OR async failure inside the
    // analytics SDK can never bubble up into the user-facing call site.
    runZonedGuarded(
      () {
        final future = Posthog().capture(
          eventName: event,
          properties: _toProperties(data),
        );
        unawaited(
          future.catchError(
            (Object error, StackTrace stack) {
              log('Error tracking event "$event": $error');
            },
          ),
        );
      },
      (error, stack) {
        log('Error tracking event "$event": $error');
      },
    );
  }

  /// Registers `is_premium` as a super property so every captured event is
  /// segmentable by subscription state without identifying the user.
  static void setPremium({required bool isPremium}) {
    if (kDebugMode) return;

    runZonedGuarded(
      () {
        unawaited(
          Posthog().register('is_premium', isPremium).catchError(
            (Object error, StackTrace stack) {
              log('Error registering is_premium: $error');
            },
          ),
        );
      },
      (error, stack) {
        log('Error registering is_premium: $error');
      },
    );
  }

  /// Fires the unified [paywallViewed] funnel event with a `trigger` property
  /// (e.g. `drawer`, `onboarding`, `backup`, `song_loops`, `song_speed`,
  /// `premium_screen`), so a single funnel step covers every paywall entry
  /// point.
  static void trackPaywallViewed({required String trigger}) {
    trackEvent(paywallViewed, data: {'trigger': trigger});
  }

  /// PostHog's `capture` expects `Map<String, Object>` (non-null values), but
  /// call sites pass `Map<String, dynamic>`. Convert, dropping null values.
  static Map<String, Object>? _toProperties(Map<String, dynamic>? data) {
    if (data == null) return null;
    return {
      for (final entry in data.entries)
        if (entry.value != null) entry.key: entry.value as Object,
    };
  }
}
