import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Consent lifecycle for analytics. Before the user decides (onboarding not
/// finished), events are buffered in memory only — nothing is persisted or
/// transmitted. On grant the buffer is flushed to PostHog; on denial it is
/// discarded.
enum _ConsentState { undecided, granted, denied }

class _BufferedEvent {
  final String event;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  _BufferedEvent(this.event, this.data) : timestamp = DateTime.now().toUtc();
}

abstract final class AppAnalytics {
  const AppAnalytics._();

  /// Pre-consent events are held in memory only (GDPR: no processing before
  /// consent — buffered data never leaves the device and dies with the
  /// process). Bounded so a stuck onboarding can't grow it unchecked.
  static const int _maxBufferedEvents = 50;
  static final List<_BufferedEvent> _buffer = [];
  static _ConsentState _consentState = _ConsentState.undecided;

  /// Unit tests run in debug mode without a native PostHog implementation:
  /// [bypassDebugGuardForTesting] disables the kDebugMode early-return and
  /// [captureOverrideForTesting] replaces the PostHog capture call.
  @visibleForTesting
  static bool bypassDebugGuardForTesting = false;

  @visibleForTesting
  static Future<void> Function(
    String eventName,
    Map<String, Object>? properties,
  )?
  captureOverrideForTesting;

  @visibleForTesting
  static void resetForTesting() {
    _consentState = _ConsentState.undecided;
    _buffer.clear();
    bypassDebugGuardForTesting = false;
    captureOverrideForTesting = null;
  }

  /// Restores the consent state on app start.
  ///
  /// [consentDecided] is whether the user has already made a consent choice
  /// (onboarding finished) — if not, events are buffered until
  /// [onConsentDecision] runs. Buffering only ever happens during the first
  /// onboarding; on later runs the stored decision applies immediately.
  static void init({required bool consented, required bool consentDecided}) {
    _consentState = consented
        ? _ConsentState.granted
        : (consentDecided ? _ConsentState.denied : _ConsentState.undecided);
  }

  /// Applies the user's consent choice. Call after PostHog itself has been
  /// enabled/disabled so flushed events aren't dropped by the SDK's opt-out.
  ///
  /// Grant: flushes all buffered pre-consent events (in order, tagged with
  /// their original timestamp). Denial: discards the buffer.
  static void onConsentDecision({required bool granted}) {
    if (granted) {
      _consentState = _ConsentState.granted;
      for (final buffered in _buffer) {
        _capture(buffered.event, {
          ...?buffered.data,
          'original_timestamp': buffered.timestamp.toIso8601String(),
        });
      }
      _buffer.clear();
    } else {
      _consentState = _ConsentState.denied;
      _buffer.clear();
    }
  }

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
  static const clickPitchModeSemitones = 'click_pitch_mode_semitones';
  static const clickPitchModeKey = 'click_pitch_mode_key';
  static const clickSetOriginalKey = 'click_set_original_key';
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
  static const clickControlsTabSpeed = 'click_controls_tab_speed';
  static const clickControlsTabPitch = 'click_controls_tab_pitch';
  static const clickControlsTabMetronome = 'click_controls_tab_metronome';
  static const clickMetronomeToggle = 'click_metronome_toggle';
  static const clickMetronomeNudge = 'click_metronome_nudge';
  static const clickMetronomeTimeSignature = 'click_metronome_time_signature';
  static const clickMetronomeSubdivision = 'click_metronome_subdivision';
  static const clickMetronomeTapBeat = 'click_metronome_tap_beat';
  static const clickMetronomeHalfBeat = 'click_metronome_half_beat';
  static const metronomeAnchorSet = 'metronome_anchor_set';
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
    if (kDebugMode && !bypassDebugGuardForTesting) return;

    switch (_consentState) {
      case _ConsentState.undecided:
        // No consent decision yet (mid-onboarding): hold in memory so the
        // pre-consent funnel steps survive until the user opts in.
        if (_buffer.length < _maxBufferedEvents) {
          _buffer.add(_BufferedEvent(event, data));
        }
      case _ConsentState.denied:
        // The SDK is opted out and would drop this anyway; skip the call.
        return;
      case _ConsentState.granted:
        _capture(event, data);
    }
  }

  static void _capture(String event, Map<String, dynamic>? data) {
    // Run inside a guarded zone so any sync OR async failure inside the
    // analytics SDK can never bubble up into the user-facing call site.
    runZonedGuarded(
      () {
        final future =
            captureOverrideForTesting?.call(event, _toProperties(data)) ??
            Posthog().capture(
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
