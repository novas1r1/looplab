import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // setAnalyticsEnabled toggles PostHog (Posthog().enable()/disable()), which
  // calls the native method channel. There is no native implementation in a
  // pure unit test, so stub the channel to a no-op to avoid MissingPluginException.
  const posthogChannel = MethodChannel('posthog_flutter');

  late MockSharedPreferences mockSharedPreferences;
  late LocalConfigRepository localConfigRepository;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(posthogChannel, (call) async => null);

    mockSharedPreferences = MockSharedPreferences();
    localConfigRepository = LocalConfigRepository(
      sharedPreferences: mockSharedPreferences,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(posthogChannel, null);
  });

  group('LocalConfigRepository', () {
    group('introShown', () {
      test('returns false when not set', () {
        when(
          () => mockSharedPreferences.getBool(LocalConfigRepository.kIntroShown),
        ).thenReturn(null);

        expect(localConfigRepository.introShown, isFalse);
      });

      test('returns true when set to true', () {
        when(
          () => mockSharedPreferences.getBool(LocalConfigRepository.kIntroShown),
        ).thenReturn(true);

        expect(localConfigRepository.introShown, isTrue);
      });

      test('returns false when set to false', () {
        when(
          () => mockSharedPreferences.getBool(LocalConfigRepository.kIntroShown),
        ).thenReturn(false);

        expect(localConfigRepository.introShown, isFalse);
      });
    });

    group('setIntroShown', () {
      test('saves value to shared preferences', () async {
        when(
          () => mockSharedPreferences.setBool(
            LocalConfigRepository.kIntroShown,
            true,
          ),
        ).thenAnswer((_) async => true);

        await localConfigRepository.setIntroShown(wasShown: true);

        verify(
          () => mockSharedPreferences.setBool(
            LocalConfigRepository.kIntroShown,
            true,
          ),
        ).called(1);
      });
    });

    group('hasCompletedTutorial', () {
      test('returns false when not set', () {
        when(
          () => mockSharedPreferences.getBool(
            LocalConfigRepository.kHasCompletedTutorial,
          ),
        ).thenReturn(null);

        expect(localConfigRepository.hasCompletedTutorial, isFalse);
      });

      test('returns true when set to true', () {
        when(
          () => mockSharedPreferences.getBool(
            LocalConfigRepository.kHasCompletedTutorial,
          ),
        ).thenReturn(true);

        expect(localConfigRepository.hasCompletedTutorial, isTrue);
      });
    });

    group('setHasCompletedTutorial', () {
      test('saves value to shared preferences', () async {
        when(
          () => mockSharedPreferences.setBool(
            LocalConfigRepository.kHasCompletedTutorial,
            true,
          ),
        ).thenAnswer((_) async => true);

        await localConfigRepository.setHasCompletedTutorial(hasCompleted: true);

        verify(
          () => mockSharedPreferences.setBool(
            LocalConfigRepository.kHasCompletedTutorial,
            true,
          ),
        ).called(1);
      });
    });

    group('acceptedDataprotection', () {
      test('returns false when not set', () {
        when(
          () => mockSharedPreferences.getBool(
            LocalConfigRepository.kAcceptedDataprotection,
          ),
        ).thenReturn(null);

        expect(localConfigRepository.acceptedDataprotection, isFalse);
      });

      test('returns true when set to true', () {
        when(
          () => mockSharedPreferences.getBool(
            LocalConfigRepository.kAcceptedDataprotection,
          ),
        ).thenReturn(true);

        expect(localConfigRepository.acceptedDataprotection, isTrue);
      });
    });

    group('acceptedAnalytics', () {
      test('returns false when not set', () {
        when(
          () => mockSharedPreferences.getBool(
            LocalConfigRepository.kAnalyticsEnabled,
          ),
        ).thenReturn(null);

        expect(localConfigRepository.acceptedAnalytics, isFalse);
      });

      test('returns true when set to true', () {
        when(
          () => mockSharedPreferences.getBool(
            LocalConfigRepository.kAnalyticsEnabled,
          ),
        ).thenReturn(true);

        expect(localConfigRepository.acceptedAnalytics, isTrue);
      });
    });

    group('hasRatedApp', () {
      test('returns false when not set', () {
        when(
          () => mockSharedPreferences.getBool(
            LocalConfigRepository.kHasRatedApp,
          ),
        ).thenReturn(null);

        expect(localConfigRepository.hasRatedApp, isFalse);
      });

      test('returns true when set to true', () {
        when(
          () => mockSharedPreferences.getBool(
            LocalConfigRepository.kHasRatedApp,
          ),
        ).thenReturn(true);

        expect(localConfigRepository.hasRatedApp, isTrue);
      });
    });

    group('setHasRatedApp', () {
      test('saves rating status and timestamp', () async {
        when(
          () => mockSharedPreferences.setBool(
            LocalConfigRepository.kHasRatedApp,
            true,
          ),
        ).thenAnswer((_) async => true);
        when(
          () => mockSharedPreferences.setString(
            LocalConfigRepository.kHasRatedAppTime,
            any(),
          ),
        ).thenAnswer((_) async => true);

        await localConfigRepository.setHasRatedApp(true);

        verify(
          () => mockSharedPreferences.setBool(
            LocalConfigRepository.kHasRatedApp,
            true,
          ),
        ).called(1);
        verify(
          () => mockSharedPreferences.setString(
            LocalConfigRepository.kHasRatedAppTime,
            any(),
          ),
        ).called(1);
      });
    });

    group('rateAppDialogShown', () {
      test('returns false when not set', () {
        when(
          () => mockSharedPreferences.getBool(
            LocalConfigRepository.kRateAppDialogShown,
          ),
        ).thenReturn(null);

        expect(localConfigRepository.rateAppDialogShown, isFalse);
      });

      test('returns true when set to true', () {
        when(
          () => mockSharedPreferences.getBool(
            LocalConfigRepository.kRateAppDialogShown,
          ),
        ).thenReturn(true);

        expect(localConfigRepository.rateAppDialogShown, isTrue);
      });
    });

    group('changelog version', () {
      test('lastChangelogVersionShown returns 1 when not set', () {
        when(
          () => mockSharedPreferences.getInt(
            LocalConfigRepository.kChangelogVersionShown,
          ),
        ).thenReturn(null);

        expect(localConfigRepository.lastChangelogVersionShown, 1);
      });

      test('lastChangelogVersionShown returns stored value', () {
        when(
          () => mockSharedPreferences.getInt(
            LocalConfigRepository.kChangelogVersionShown,
          ),
        ).thenReturn(42);

        expect(localConfigRepository.lastChangelogVersionShown, 42);
      });

      test('setChangelogShown saves version number', () async {
        when(
          () => mockSharedPreferences.setInt(
            LocalConfigRepository.kChangelogVersionShown,
            50,
          ),
        ).thenAnswer((_) async => true);

        await localConfigRepository.setChangelogShown(50);

        verify(
          () => mockSharedPreferences.setInt(
            LocalConfigRepository.kChangelogVersionShown,
            50,
          ),
        ).called(1);
      });
    });

    group('setCrashloggingEnabled', () {
      test('saves crashlytics enabled status', () async {
        when(
          () => mockSharedPreferences.setBool(
            LocalConfigRepository.kCrashlyticsEnabled,
            true,
          ),
        ).thenAnswer((_) async => true);

        await localConfigRepository.setCrashloggingEnabled(isEnabled: true);

        verify(
          () => mockSharedPreferences.setBool(
            LocalConfigRepository.kCrashlyticsEnabled,
            true,
          ),
        ).called(1);
      });
    });

    group('setAnalyticsEnabled', () {
      test('saves analytics enabled status', () async {
        when(
          () => mockSharedPreferences.setBool(
            LocalConfigRepository.kAnalyticsEnabled,
            true,
          ),
        ).thenAnswer((_) async => true);

        await localConfigRepository.setAnalyticsEnabled(isEnabled: true);

        verify(
          () => mockSharedPreferences.setBool(
            LocalConfigRepository.kAnalyticsEnabled,
            true,
          ),
        ).called(1);
      });

      test('saves analytics disabled status', () async {
        when(
          () => mockSharedPreferences.setBool(
            LocalConfigRepository.kAnalyticsEnabled,
            false,
          ),
        ).thenAnswer((_) async => true);

        await localConfigRepository.setAnalyticsEnabled(isEnabled: false);

        verify(
          () => mockSharedPreferences.setBool(
            LocalConfigRepository.kAnalyticsEnabled,
            false,
          ),
        ).called(1);
      });
    });

    group('clear', () {
      test('clears all shared preferences', () async {
        when(() => mockSharedPreferences.clear()).thenAnswer((_) async => true);

        final result = await localConfigRepository.clear();

        expect(result, isTrue);
        verify(() => mockSharedPreferences.clear()).called(1);
      });
    });
  });
}
