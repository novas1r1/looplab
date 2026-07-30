import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/features/song_controls/widget/pitch_panel.dart';

import '../helpers/golden_multi_locale.dart';
import '../helpers/golden_test_device_scenario.dart';
import '../helpers/mock_cubits.dart';
import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockPremiumSubscriptionCubit mockPremiumSubscriptionCubit;
  late MockSongCubit mockSongCubit;

  const testSong = Song(
    id: '1',
    title: 'Test Song',
    artist: 'Test Artist',
    fileName: 'test.mp3',
    duration: Duration(minutes: 3, seconds: 30),
  );

  setUp(() {
    mockPremiumSubscriptionCubit = MockPremiumSubscriptionCubit();
    mockSongCubit = MockSongCubit();

    when(() => mockPremiumSubscriptionCubit.state).thenReturn(
      const PremiumSubscriptionState(),
    );
    when(() => mockPremiumSubscriptionCubit.hasPremium).thenReturn(true);
  });

  Widget buildPitchPanel({
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
      // The panel normally renders inside the SongControlsCard container;
      // recreate that chrome so the golden shows realistic contrast.
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.secondaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(8).copyWith(right: 0),
        child: const PitchPanel(),
      ),
    );
  }

  group('PitchPanel Golden Tests', () {
    multiLocaleGoldenTest(
      'pitch at 0 st (default)',
      fileNameBase: 'pitch_control_default',
      pumpWidgetWithLocale: (tester, widget, locale) =>
          tester.pumpApp(widget, locale: locale),
      builder: () => GoldenTestDeviceScenario(
        name: 'pitch_default',
        builder: () => buildPitchPanel(
          songState: const SongState(
            song: testSong,
          ),
        ),
      ),
    );

    multiLocaleGoldenTest(
      'pitch shifted up (+5 st)',
      fileNameBase: 'pitch_control_up',
      pumpWidgetWithLocale: (tester, widget, locale) =>
          tester.pumpApp(widget, locale: locale),
      builder: () => GoldenTestDeviceScenario(
        name: 'pitch_up',
        builder: () => buildPitchPanel(
          songState: const SongState(
            song: testSong,
            pitchSemitones: 5,
          ),
        ),
      ),
    );

    multiLocaleGoldenTest(
      'pitch shifted with musical key (Am +3 st)',
      fileNameBase: 'pitch_control_with_key',
      pumpWidgetWithLocale: (tester, widget, locale) =>
          tester.pumpApp(widget, locale: locale),
      builder: () => GoldenTestDeviceScenario(
        name: 'pitch_with_key',
        builder: () => buildPitchPanel(
          songState: const SongState(
            song: Song(
              id: '2',
              title: 'Test Song With Key',
              artist: 'Test Artist',
              fileName: 'test.mp3',
              duration: Duration(minutes: 3, seconds: 30),
              musicalKey: 'Am',
            ),
            pitchSemitones: 3,
          ),
        ),
      ),
    );

    multiLocaleGoldenTest(
      'fine tune engaged (+18 ct)',
      fileNameBase: 'pitch_control_fine_tune',
      pumpWidgetWithLocale: (tester, widget, locale) =>
          tester.pumpApp(widget, locale: locale),
      builder: () => GoldenTestDeviceScenario(
        name: 'pitch_fine_tune',
        builder: () => buildPitchPanel(
          // No transposition, only fine tune: pins the readout swapping from
          // the hint to the concert-pitch reference (A ~ 444.6 Hz).
          songState: const SongState(
            song: testSong,
            fineTuneCents: 18,
          ),
        ),
      ),
    );

    multiLocaleGoldenTest(
      'pitch shifted down (-12 st)',
      fileNameBase: 'pitch_control_down',
      pumpWidgetWithLocale: (tester, widget, locale) =>
          tester.pumpApp(widget, locale: locale),
      builder: () => GoldenTestDeviceScenario(
        name: 'pitch_down',
        builder: () => buildPitchPanel(
          songState: const SongState(
            song: testSong,
            pitchSemitones: -12,
          ),
        ),
      ),
    );
  });
}
