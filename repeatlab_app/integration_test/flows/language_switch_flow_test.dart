import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../helpers/e2e_app.dart';
import '../helpers/reset_app_state.dart';

void main() {
  registerE2ESetUp();

  patrolTest('language switch: English <-> German re-localizes', ($) async {
    await resetAppState(); // pinned to 'en'
    await pumpRepeatLab($);

    // Open the drawer; the Settings entry reads "Settings" in English.
    await $(const Key('home.drawer')).tap();
    expect($('Settings'), findsWidgets);

    // Switch to German via the language picker.
    await $(const Key('drawer.language')).tap();
    await $('Deutsch').tap();
    await $.pumpAndSettle();

    // The drawer re-localizes: "Settings" → "Einstellungen".
    expect($('Einstellungen'), findsWidgets);

    // Switch back to English.
    await $(const Key('drawer.language')).tap();
    await $('English').tap();
    await $.pumpAndSettle();
    expect($('Settings'), findsWidgets);
  });
}
