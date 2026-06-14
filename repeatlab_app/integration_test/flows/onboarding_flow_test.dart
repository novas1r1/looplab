import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../helpers/e2e_app.dart';
import '../helpers/reset_app_state.dart';

void main() {
  patrolTest('onboarding: first run walks to the home screen', ($) async {
    // The only flow that starts with onboarding NOT skipped.
    await resetAppState(skipOnboarding: false);
    // Pro (the default) so _finishOnboarding skips the native paywall.
    await pumpRepeatLab($);

    // Onboarding is shown.
    expect($(const Key('onboarding.next')), findsOneWidget);

    // Page 1 -> 2 -> 3.
    await $(const Key('onboarding.next')).tap();
    await $(const Key('onboarding.next')).tap();

    // Accept privacy on the last slide, then finish.
    await $(const Key('onboarding.privacy')).tap();
    await $(const Key('onboarding.next')).tap();
    await $.pumpAndSettle();

    // Landed on home.
    expect($(const Key('home.fab')), findsOneWidget);
  });
}
