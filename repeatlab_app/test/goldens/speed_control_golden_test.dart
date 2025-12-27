import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/features/speed_control/cubit/speed_control_cubit.dart';
import 'package:repeatlab/features/speed_control/view/speed_control.dart';

import '../helpers/golden_multi_locale.dart';
import '../helpers/golden_test_device_scenario.dart';
import '../helpers/mock_cubits.dart';
import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPremiumSubscriptionCubit mockPremiumSubscriptionCubit;

  setUp(() {
    mockPremiumSubscriptionCubit = MockPremiumSubscriptionCubit();
    when(() => mockPremiumSubscriptionCubit.state).thenReturn(
      const PremiumSubscriptionState(),
    );
    when(() => mockPremiumSubscriptionCubit.hasPremium).thenReturn(true);
  });

  Widget buildSpeedControl({
    required Song song,
    SpeedControlState? initialState,
  }) {
    return BlocProvider<PremiumSubscriptionCubit>.value(
      value: mockPremiumSubscriptionCubit,
      child: BlocProvider<SpeedControlCubit>(
        create: (_) {
          final cubit = SpeedControlCubit(song: song);
          if (initialState != null) {
            // Emit the desired state
            cubit.emit(initialState);
          }
          return cubit;
        },
        child: SpeedControl(
          song: song,
          onSpeedMultiplierChanged: (_) {},
          onOriginalBpmChanged: (_) {},
          onSpeedBpmChanged: (_) {},
        ),
      ),
    );
  }

  const testSongWithoutBpm = Song(
    id: '1',
    title: 'Test Song',
    artist: 'Test Artist',
    fileName: 'test.mp3',
    duration: Duration(minutes: 3, seconds: 30),
  );

  const testSongWithBpm = Song(
    id: '2',
    title: 'Test Song With BPM',
    artist: 'Test Artist',
    fileName: 'test.mp3',
    duration: Duration(minutes: 3, seconds: 30),
    bpm: 120,
  );

  group('SpeedControl Golden Tests - Multiplier Mode', () {
    multiLocaleGoldenTest(
      'multiplier mode at 1.0x (default)',
      fileNameBase: 'speed_control_multiplier_1x',
      pumpWidgetWithLocale: (tester, widget, locale) => tester.pumpApp(widget, locale: locale),
      builder: () => GoldenTestDeviceScenario(
        name: 'multiplier_1x',
        builder: () => buildSpeedControl(
          song: testSongWithoutBpm,
          initialState: const SpeedControlState(),
        ),
      ),
    );

    multiLocaleGoldenTest(
      'multiplier mode at 0.5x (slow)',
      fileNameBase: 'speed_control_multiplier_slow',
      pumpWidgetWithLocale: (tester, widget, locale) => tester.pumpApp(widget, locale: locale),
      builder: () => GoldenTestDeviceScenario(
        name: 'multiplier_slow',
        builder: () => buildSpeedControl(
          song: testSongWithoutBpm,
          initialState: const SpeedControlState(
            speedMultiplier: 0.5,
          ),
        ),
      ),
    );

    multiLocaleGoldenTest(
      'multiplier mode at 2.0x (fast)',
      fileNameBase: 'speed_control_multiplier_fast',
      pumpWidgetWithLocale: (tester, widget, locale) => tester.pumpApp(widget, locale: locale),
      builder: () => GoldenTestDeviceScenario(
        name: 'multiplier_fast',
        builder: () => buildSpeedControl(
          song: testSongWithoutBpm,
          initialState: const SpeedControlState(
            speedMultiplier: 2.0,
          ),
        ),
      ),
    );

    multiLocaleGoldenTest(
      'multiplier mode at 1.5x (medium fast)',
      fileNameBase: 'speed_control_multiplier_medium',
      pumpWidgetWithLocale: (tester, widget, locale) => tester.pumpApp(widget, locale: locale),
      builder: () => GoldenTestDeviceScenario(
        name: 'multiplier_medium',
        builder: () => buildSpeedControl(
          song: testSongWithoutBpm,
          initialState: const SpeedControlState(
            speedMultiplier: 1.5,
          ),
        ),
      ),
    );
  });

  group('SpeedControl Golden Tests - BPM Mode', () {
    multiLocaleGoldenTest(
      'bpm mode without original bpm set',
      fileNameBase: 'speed_control_bpm_no_original',
      pumpWidgetWithLocale: (tester, widget, locale) => tester.pumpApp(widget, locale: locale),
      builder: () => GoldenTestDeviceScenario(
        name: 'bpm_no_original',
        builder: () => buildSpeedControl(
          song: testSongWithoutBpm,
          initialState: const SpeedControlState(
            tempoMode: TempoMode.bpm,
          ),
        ),
      ),
    );

    multiLocaleGoldenTest(
      'bpm mode with original bpm (120)',
      fileNameBase: 'speed_control_bpm_with_original',
      pumpWidgetWithLocale: (tester, widget, locale) => tester.pumpApp(widget, locale: locale),
      builder: () => GoldenTestDeviceScenario(
        name: 'bpm_with_original',
        builder: () => buildSpeedControl(
          song: testSongWithBpm,
          initialState: const SpeedControlState(
            tempoMode: TempoMode.bpm,
            originalBpm: 120,
            currentBpm: 120,
            minBpm: 60,
            maxBpm: 240,
          ),
        ),
      ),
    );

    multiLocaleGoldenTest(
      'bpm mode at slow speed (60 bpm)',
      fileNameBase: 'speed_control_bpm_slow',
      pumpWidgetWithLocale: (tester, widget, locale) => tester.pumpApp(widget, locale: locale),
      builder: () => GoldenTestDeviceScenario(
        name: 'bpm_slow',
        builder: () => buildSpeedControl(
          song: testSongWithBpm,
          initialState: const SpeedControlState(
            tempoMode: TempoMode.bpm,
            speedMultiplier: 0.5,
            originalBpm: 120,
            currentBpm: 60,
            minBpm: 60,
            maxBpm: 240,
          ),
        ),
      ),
    );

    multiLocaleGoldenTest(
      'bpm mode at fast speed (240 bpm)',
      fileNameBase: 'speed_control_bpm_fast',
      pumpWidgetWithLocale: (tester, widget, locale) => tester.pumpApp(widget, locale: locale),
      builder: () => GoldenTestDeviceScenario(
        name: 'bpm_fast',
        builder: () => buildSpeedControl(
          song: testSongWithBpm,
          initialState: const SpeedControlState(
            tempoMode: TempoMode.bpm,
            speedMultiplier: 2.0,
            originalBpm: 120,
            currentBpm: 240,
            minBpm: 60,
            maxBpm: 240,
          ),
        ),
      ),
    );

    multiLocaleGoldenTest(
      'bpm mode at medium speed (180 bpm)',
      fileNameBase: 'speed_control_bpm_medium',
      pumpWidgetWithLocale: (tester, widget, locale) => tester.pumpApp(widget, locale: locale),
      builder: () => GoldenTestDeviceScenario(
        name: 'bpm_medium',
        builder: () => buildSpeedControl(
          song: testSongWithBpm,
          initialState: const SpeedControlState(
            tempoMode: TempoMode.bpm,
            speedMultiplier: 1.5,
            originalBpm: 120,
            currentBpm: 180,
            minBpm: 60,
            maxBpm: 240,
          ),
        ),
      ),
    );
  });
}
