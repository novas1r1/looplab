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

    // Accept data protection on the consent slide, then finish. Tap the
    // card's check indicator (top-left, inside the 16px padding) rather than
    // its centre — the centre lands on the "privacy policy" link span, which
    // pushes the policy page instead of toggling the card.
    final privacyCard = $(const Key('onboarding.privacy'));
    await privacyCard.waitUntilVisible();
    final cardRect = $.tester.getRect(privacyCard);
    await $.tester.tapAt(cardRect.topLeft + const Offset(28, 28));
    await $.pumpAndSettle();
    await $(const Key('onboarding.next')).tap();
    await $.pumpAndSettle();

    // Landed on home.
    expect($(const Key('home.fab')), findsOneWidget);
  });
}
