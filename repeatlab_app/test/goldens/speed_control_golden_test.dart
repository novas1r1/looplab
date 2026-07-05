import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/features/speed_control/view/speed_control.dart';

import '../helpers/golden_multi_locale.dart';
import '../helpers/golden_test_device_scenario.dart';
import '../helpers/mock_cubits.dart';
import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPremiumSubscriptionCubit mockPremiumSubscriptionCubit;
  late MockSongCubit mockSongCubit;

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

  setUp(() {
    mockPremiumSubscriptionCubit = MockPremiumSubscriptionCubit();
    mockSongCubit = MockSongCubit();

    when(() => mockPremiumSubscriptionCubit.state).thenReturn(
      const PremiumSubscriptionState(),
    );
    when(() => mockPremiumSubscriptionCubit.hasPremium).thenReturn(true);
  });

  Widget buildSpeedControl({
    required SongState songState,
  }) {
    when(() => mockSongCubit.state).thenReturn(songState);
    when(() => mockSongCubit.stream).thenAnswer((_) => Stream.value(songState));

    return MultiBlocProvider(
      providers: [
        BlocProvider<PremiumSubscriptionCubit>.value(
          value: mockPremiumSubscriptionCubit,
        ),
        BlocProvider<SongCubit>.value(
          value: mockSongCubit,
        ),
      ],
      child: const SpeedControl(),
    );
  }

  group('SpeedControl Golden Tests - Multiplier Mode', () {
    multiLocaleGoldenTest(
      'multiplier mode at 1.0x (default)',
      fileNameBase: 'speed_control_multiplier_1x',
      pumpWidgetWithLocale: (tester, widget, locale) =>
          tester.pumpApp(widget, locale: locale),
      builder: () => GoldenTestDeviceScenario(
        name: 'multiplier_1x',
        builder: () => buildSpeedControl(
          songState: const SongState(
            song: testSongWithoutBpm,
          ),
        ),
      ),
    );

    multiLocaleGoldenTest(
      'multiplier mode at 0.5x (slow)',
      fileNameBase: 'speed_control_multiplier_slow',
      pumpWidgetWithLocale: (tester, widget, locale) =>
          tester.pumpApp(widget, locale: locale),
      builder: () => GoldenTestDeviceScenario(
        name: 'multiplier_slow',
        builder: () => buildSpeedControl(
          songState: const SongState(
            song: testSongWithoutBpm,
            speed: 0.5,
          ),
        ),
      ),
    );

    multiLocaleGoldenTest(
      'multiplier mode at 2.0x (fast)',
      fileNameBase: 'speed_control_multiplier_fast',
      pumpWidgetWithLocale: (tester, widget, locale) =>
          tester.pumpApp(widget, locale: locale),
      builder: () => GoldenTestDeviceScenario(
        name: 'multiplier_fast',
        builder: () => buildSpeedControl(
          songState: const SongState(
            song: testSongWithoutBpm,
            speed: 2.0,
          ),
        ),
      ),
    );

    multiLocaleGoldenTest(
      'multiplier mode at 1.5x (medium fast)',
      fileNameBase: 'speed_control_multiplier_medium',
      pumpWidgetWithLocale: (tester, widget, locale) =>
          tester.pumpApp(widget, locale: locale),
      builder: () => GoldenTestDeviceScenario(
        name: 'multiplier_medium',
        builder: () => buildSpeedControl(
          songState: const SongState(
            song: testSongWithoutBpm,
            speed: 1.5,
          ),
        ),
      ),
    );
  });

  group('SpeedControl Golden Tests - BPM Mode', () {
    multiLocaleGoldenTest(
      'bpm mode without original bpm set',
      fileNameBase: 'speed_control_bpm_no_original',
      pumpWidgetWithLocale: (tester, widget, locale) =>
          tester.pumpApp(widget, locale: locale),
      builder: () => GoldenTestDeviceScenario(
        name: 'bpm_no_original',
        builder: () => buildSpeedControl(
          songState: const SongState(
            song: testSongWithoutBpm,
            tempoMode: TempoMode.bpm,
          ),
        ),
      ),
    );

    multiLocaleGoldenTest(
      'bpm mode with original bpm (120)',
      fileNameBase: 'speed_control_bpm_with_original',
      pumpWidgetWithLocale: (tester, widget, locale) =>
          tester.pumpApp(widget, locale: locale),
      builder: () => GoldenTestDeviceScenario(
        name: 'bpm_with_original',
        builder: () => buildSpeedControl(
          songState: const SongState(
            song: testSongWithBpm,
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
      pumpWidgetWithLocale: (tester, widget, locale) =>
          tester.pumpApp(widget, locale: locale),
      builder: () => GoldenTestDeviceScenario(
        name: 'bpm_slow',
        builder: () => buildSpeedControl(
          songState: const SongState(
            song: testSongWithBpm,
            speed: 0.5,
            tempoMode: TempoMode.bpm,
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
      pumpWidgetWithLocale: (tester, widget, locale) =>
          tester.pumpApp(widget, locale: locale),
      builder: () => GoldenTestDeviceScenario(
        name: 'bpm_fast',
        builder: () => buildSpeedControl(
          songState: const SongState(
            song: testSongWithBpm,
            speed: 2.0,
            tempoMode: TempoMode.bpm,
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
      pumpWidgetWithLocale: (tester, widget, locale) =>
          tester.pumpApp(widget, locale: locale),
      builder: () => GoldenTestDeviceScenario(
        name: 'bpm_medium',
        builder: () => buildSpeedControl(
          songState: const SongState(
            song: testSongWithBpm,
            speed: 1.5,
            tempoMode: TempoMode.bpm,
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
