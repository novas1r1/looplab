import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
import 'package:repeatlab/features/onboarding/view/onboarding_page.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';

import '../../helpers/mock_cubits.dart';
import '../../helpers/mock_repositories.dart';
import '../../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLocalConfigRepository localConfig;
  late MockPremiumSubscriptionCubit premiumCubit;
  final captured = <({String event, Map<String, Object>? properties})>[];

  setUp(() {
    localConfig = MockLocalConfigRepository();
    premiumCubit = MockPremiumSubscriptionCubit();

    AppAnalytics.resetForTesting();
    captured.clear();
    AppAnalytics.bypassDebugGuardForTesting = true;
    // Force the granted state so trackEvent captures synchronously instead of
    // buffering (the page fires view/started events from initState).
    AppAnalytics.init(consented: true, consentDecided: true);
    AppAnalytics.captureOverrideForTesting = (event, properties) async {
      captured.add((event: event, properties: properties));
    };
  });

  tearDown(AppAnalytics.resetForTesting);

  Widget buildSubject() => MultiRepositoryProvider(
    providers: [
      RepositoryProvider<LocalConfigRepository>.value(value: localConfig),
    ],
    child: BlocProvider<PremiumSubscriptionCubit>.value(
      value: premiumCubit,
      child: const OnboardingPage(),
    ),
  );

  // A phone-portrait surface so the consent slide lays out like the design and
  // every control is on-screen and hit-testable (the default 800x600 puts the
  // consent cards partly behind the bottom bar).
  Future<void> pumpOnboarding(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpApp(buildSubject());
    await tester.pumpAndSettle();
  }

  Future<void> gotoConsentViaSkip(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('onboarding.skip')));
    await tester.pumpAndSettle();
  }

  // Toggle a consent card by tapping its checkbox area (top-left), avoiding the
  // Privacy Policy / Terms links embedded in the data-protection card's text.
  Future<void> tapCard(WidgetTester tester, Key cardKey) async {
    final rect = tester.getRect(find.byKey(cardKey));
    await tester.tapAt(rect.topLeft + const Offset(30, 30));
    await tester.pumpAndSettle();
  }

  // The check glyph scoped to a specific consent card, so it never collides
  // with the primary button's own icon.
  Finder checkInCard(Key cardKey) => find.descendant(
    of: find.byKey(cardKey),
    matching: find.byIcon(Icons.check),
  );

  group('OnboardingPage', () {
    testWidgets('starts on the first info slide with Skip visible', (
      tester,
    ) async {
      await pumpOnboarding(tester);

      expect(find.byKey(const Key('onboarding.skip')), findsOneWidget);
      // Consent-only controls are not built until the consent slide is reached.
      expect(find.byKey(const Key('onboarding.privacy')), findsNothing);
    });

    testWidgets('Skip jumps straight to the consent slide and hides Skip', (
      tester,
    ) async {
      await pumpOnboarding(tester);

      await gotoConsentViaSkip(tester);

      expect(find.byKey(const Key('onboarding.privacy')), findsOneWidget);
      expect(find.byKey(const Key('onboarding.analytics')), findsOneWidget);
      // The consent slide has no Skip.
      expect(find.byKey(const Key('onboarding.skip')), findsNothing);
    });

    testWidgets('Get Started is disabled until data protection is accepted', (
      tester,
    ) async {
      await pumpOnboarding(tester);
      await gotoConsentViaSkip(tester);

      FilledButton getStarted() => tester.widget<FilledButton>(
        find.byKey(const Key('onboarding.next')),
      );

      // Required consent not given yet -> button disabled.
      expect(getStarted().onPressed, isNull);

      await tapCard(tester, const Key('onboarding.privacy'));

      expect(getStarted().onPressed, isNotNull);
    });

    testWidgets('analytics is opt-in (unchecked) and toggles independently', (
      tester,
    ) async {
      await pumpOnboarding(tester);
      await gotoConsentViaSkip(tester);

      // GDPR opt-in: neither box is pre-checked.
      expect(checkInCard(const Key('onboarding.analytics')), findsNothing);
      expect(checkInCard(const Key('onboarding.privacy')), findsNothing);

      await tapCard(tester, const Key('onboarding.analytics'));
      expect(checkInCard(const Key('onboarding.analytics')), findsOneWidget);
      // Analytics and data protection toggle independently.
      expect(checkInCard(const Key('onboarding.privacy')), findsNothing);

      await tapCard(tester, const Key('onboarding.privacy'));
      expect(checkInCard(const Key('onboarding.analytics')), findsOneWidget);
      expect(checkInCard(const Key('onboarding.privacy')), findsOneWidget);
    });

    testWidgets('tapping Skip emits onboarding_skipped with from_page', (
      tester,
    ) async {
      await pumpOnboarding(tester);
      await gotoConsentViaSkip(tester);

      final skipEvents = captured.where(
        (e) => e.event == AppAnalytics.onboardingSkipped,
      );
      expect(skipEvents, hasLength(1));
      expect(skipEvents.single.properties?['from_page'], 0);
    });

    testWidgets('paging Next through the info slides reaches consent', (
      tester,
    ) async {
      await pumpOnboarding(tester);

      // Four info slides -> four advances land on the consent slide.
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byKey(const Key('onboarding.next')));
        await tester.pumpAndSettle();
      }

      expect(find.byKey(const Key('onboarding.privacy')), findsOneWidget);
      expect(find.byKey(const Key('onboarding.skip')), findsNothing);
    });
  });
}
