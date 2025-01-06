import 'package:wiredash/wiredash.dart';

abstract final class AppAnalytics {
  const AppAnalytics._();
  // screens
  static const viewHome = 'view_home';
  static const viewSong = 'view_song';

  // events home screen
  static const clickAddSong = 'click_add_song';
  static const clickClearDb = 'click_clear_db';
  static const clickDeleteSong = 'click_delete_song';
  static const clickReportBug = 'click_report_bug';
  static const clickRateApp = 'click_rate_app';
  static const clickFeedback = 'click_feedback';
  static const clickHelp = 'click_help';

  // events song screen
  static const clickDeleteLoop = 'click_delete_loop';
  static const clickAddLoop = 'click_add_loop';
  static const clickForward10Seconds = 'click_forward_10_sec';
  static const clickBack10Seconds = 'click_back_10_sec';
  static const clickEditLoop = 'click_edit_loop';
  static const clickPlayLoop = 'click_play_loop';
  static const clickStopLoop = 'click_stop_loop';

  static Future<void> trackEvent(
    String event, {
    Map<String, dynamic>? data,
  }) async {
    await Wiredash.trackEvent(event, data: data);
  }
}
