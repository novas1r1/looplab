import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:wiredash/wiredash.dart';

abstract final class AppAnalytics {
  const AppAnalytics._();
  // screens
  static const viewHome = 'view_home';
  static const viewSong = 'view_song';
  static const viewPaywallFromDrawer = 'view_paywall_from_drawer';
  static const viewFeedback = 'view_feedback';
  static const viewRateApp = 'view_rate_app';
  static const viewDataProtection = 'view_data_protection';
  static const viewLegalNotices = 'view_legal_notices';
  static const viewLicenses = 'view_licenses';
  static const viewPremiumScreen = 'view_premium_screen';
  static const viewChangelogDialog = 'view_changelog_dialog';
  // events home screen
  static const clickAddSong = 'click_add_song';
  static const clickClearDb = 'click_clear_db';
  static const clickDeleteSong = 'click_delete_song';
  static const clickReportBug = 'click_report_bug';
  static const clickRateApp = 'click_rate_app';
  static const clickFeedback = 'click_feedback';
  static const clickHelp = 'click_help';
  static const clickOpenSong = 'click_open_song';
  static const clickSkipTutorial = 'click_skip_tutorial';
  // events song screen
  static const clickDeleteLoop = 'click_delete_loop';
  static const clickAddLoop = 'click_add_loop';
  static const clickForward10Seconds = 'click_forward_10_sec';
  static const clickBack10Seconds = 'click_back_10_sec';
  static const clickEditLoop = 'click_edit_loop';
  static const clickPlayLoop = 'click_play_loop';
  static const clickStopLoop = 'click_stop_loop';
  static const clickSetLoopStart = 'click_set_loop_start';
  static const clickSetLoopEnd = 'click_set_loop_end';
  static const clickUpdateSpeed = 'click_update_speed';
  static const clickShowTutorial = 'click_show_tutorial';
  static const clickZoomIn = 'click_zoom_in';
  static const clickZoomOut = 'click_zoom_out';
  static const clickRestore = 'click_restore';
  static const clickTerms = 'click_terms';
  static const clickPrivacy = 'click_privacy';

  static const showPaywallSongLoops = 'show_paywall_song_loops';
  static const showPaywallSongSpeed = 'show_paywall_song_speed';

  // subscription
  static const clickCancelSubscriptionAndroid = 'click_cancel_subscription_android';
  static const clickCancelSubscriptionIos = 'click_cancel_subscription_ios';

  static Future<void> trackEvent(
    String event, {
    Map<String, dynamic>? data,
  }) async {
    log('ANALYTICS: $event, data: $data');
    if (!kDebugMode) {
      await Wiredash.trackEvent(event, data: data);
    }
  }
}
