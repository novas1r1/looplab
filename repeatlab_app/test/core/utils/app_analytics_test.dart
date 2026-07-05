import 'package:flutter_test/flutter_test.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';

void main() {
  final captured = <({String event, Map<String, Object>? properties})>[];

  setUp(() {
    AppAnalytics.resetForTesting();
    captured.clear();
    AppAnalytics.bypassDebugGuardForTesting = true;
    AppAnalytics.captureOverrideForTesting = (event, properties) async {
      captured.add((event: event, properties: properties));
    };
  });

  tearDown(AppAnalytics.resetForTesting);

  group('AppAnalytics pre-consent buffer', () {
    test('does not capture while consent is undecided', () {
      AppAnalytics.init(consented: false, consentDecided: false);

      AppAnalytics.trackEvent('onboarding_started');

      expect(captured, isEmpty);
    });

    test('flushes buffered events in order on consent grant', () {
      AppAnalytics.init(consented: false, consentDecided: false);

      AppAnalytics.trackEvent('view_onboarding');
      AppAnalytics.trackEvent('onboarding_started');

      AppAnalytics.onConsentDecision(granted: true);

      expect(captured, hasLength(2));
      expect(captured[0].event, 'view_onboarding');
      expect(captured[1].event, 'onboarding_started');
    });

    test('flushed events carry their original timestamp', () {
      AppAnalytics.init(consented: false, consentDecided: false);

      AppAnalytics.trackEvent('onboarding_started', data: {'slide': 1});
      AppAnalytics.onConsentDecision(granted: true);

      final properties = captured.single.properties;
      expect(properties?['slide'], 1);
      expect(properties?['original_timestamp'], isA<String>());
      expect(
        DateTime.parse(properties!['original_timestamp']! as String),
        isNotNull,
      );
    });

    test('discards buffered events on consent denial', () {
      AppAnalytics.init(consented: false, consentDecided: false);

      AppAnalytics.trackEvent('onboarding_started');
      AppAnalytics.onConsentDecision(granted: false);

      expect(captured, isEmpty);

      // A later opt-in (e.g. via settings) must not resurrect them.
      AppAnalytics.onConsentDecision(granted: true);
      expect(captured, isEmpty);
    });

    test('drops events after denial instead of buffering them', () {
      AppAnalytics.init(consented: false, consentDecided: false);
      AppAnalytics.onConsentDecision(granted: false);

      AppAnalytics.trackEvent('view_home');
      AppAnalytics.onConsentDecision(granted: true);

      expect(captured, isEmpty);
    });

    test('captures directly once consent is granted', () {
      AppAnalytics.init(consented: false, consentDecided: false);
      AppAnalytics.onConsentDecision(granted: true);

      AppAnalytics.trackEvent('onboarding_completed', data: {'foo': 'bar'});

      expect(captured.single.event, 'onboarding_completed');
      expect(captured.single.properties, {'foo': 'bar'});
      // Direct captures are not flushed buffer entries — no synthetic
      // timestamp is attached.
      expect(
        captured.single.properties,
        isNot(contains('original_timestamp')),
      );
    });

    test('bounds the buffer at 50 events', () {
      AppAnalytics.init(consented: false, consentDecided: false);

      for (var i = 0; i < 60; i++) {
        AppAnalytics.trackEvent('event_$i');
      }
      AppAnalytics.onConsentDecision(granted: true);

      expect(captured, hasLength(50));
      expect(captured.first.event, 'event_0');
      expect(captured.last.event, 'event_49');
    });
  });

  group('AppAnalytics.init', () {
    test('stored grant captures immediately without buffering', () {
      AppAnalytics.init(consented: true, consentDecided: true);

      AppAnalytics.trackEvent('view_home');

      expect(captured.single.event, 'view_home');
    });

    test('stored denial drops events', () {
      AppAnalytics.init(consented: false, consentDecided: true);

      AppAnalytics.trackEvent('view_home');
      // Even a later grant flushes nothing captured while denied.
      AppAnalytics.onConsentDecision(granted: true);

      expect(captured, isEmpty);
    });
  });
}
