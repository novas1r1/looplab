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

    // Walk the four info slides through to the consent slide.
    await $(const Key('onboarding.next')).tap();
    await $(const Key('onboarding.next')).tap();
    await $(const Key('onboarding.next')).tap();
    await $(const Key('onboarding.next')).tap();

    // Accept data protection on the consent slide, then finish.
    await $(const Key('onboarding.privacy')).tap();
    await $(const Key('onboarding.next')).tap();
    await $.pumpAndSettle();

    // Landed on home.
    expect($(const Key('home.fab')), findsOneWidget);
  });
}
