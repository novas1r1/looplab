import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/features/song_controls/view/song_controls_card.dart';
import 'package:repeatlab/features/song_controls/widget/metronome_panel.dart';

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

  const stateWithBpm = SongState(
    song: testSongWithBpm,
    originalBpm: 120,
    currentBpm: 120,
    minBpm: 60,
    maxBpm: 240,
  );

  setUp(() {
    mockPremiumSubscriptionCubit = MockPremiumSubscriptionCubit();
    mockSongCubit = MockSongCubit();

    when(() => mockPremiumSubscriptionCubit.state).thenReturn(
      const PremiumSubscriptionState(),
    );
    when(() => mockPremiumSubscriptionCubit.hasPremium).thenReturn(true);
    when(() => mockSongCubit.isPitchControlSupported).thenReturn(true);
    when(() => mockSongCubit.isMetronomeSupported).thenReturn(true);
  });

  Widget wrapWithProviders(Widget child, {required SongState songState}) {
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
      child: child,
    );
  }

  Widget buildMetronomePanel({required SongState songState}) {
    return wrapWithProviders(
      // The panel normally renders inside the SongControlsCard container;
      // recreate that chrome so the golden shows realistic contrast.
      Container(
        decoration: BoxDecoration(
          color: AppColors.secondaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(8).copyWith(right: 0),
        child: const MetronomePanel(),
      ),
      songState: songState,
    );
  }

  group('SongControlsCard Golden Tests', () {
    multiLocaleGoldenTest(
      'collapsed card with all three tabs',
      fileNameBase: 'song_controls_card_collapsed',
      pumpWidgetWithLocale: (tester, widget, locale) =>
          tester.pumpApp(widget, locale: locale),
      builder: () => GoldenTestDeviceScenario(
        name: 'collapsed',
        builder: () => wrapWithProviders(
          const SongControlsCard(),
          songState: stateWithBpm,
        ),
      ),
    );
  });

  group('MetronomePanel Golden Tests', () {
    multiLocaleGoldenTest(
      'no bpm set shows prompt',
      fileNameBase: 'metronome_panel_no_bpm',
      pumpWidgetWithLocale: (tester, widget, locale) =>
          tester.pumpApp(widget, locale: locale),
      builder: () => GoldenTestDeviceScenario(
        name: 'no_bpm',
        builder: () => buildMetronomePanel(
          songState: const SongState(song: testSongWithoutBpm),
        ),
      ),
    );

    multiLocaleGoldenTest(
      'disabled with bpm',
      fileNameBase: 'metronome_panel_disabled',
      pumpWidgetWithLocale: (tester, widget, locale) =>
          tester.pumpApp(widget, locale: locale),
      builder: () => GoldenTestDeviceScenario(
        name: 'disabled',
        builder: () => buildMetronomePanel(songState: stateWithBpm),
      ),
    );

    multiLocaleGoldenTest(
      'enabled with offset and subdivision',
      fileNameBase: 'metronome_panel_enabled',
      pumpWidgetWithLocale: (tester, widget, locale) =>
          tester.pumpApp(widget, locale: locale),
      builder: () => GoldenTestDeviceScenario(
        name: 'enabled',
        builder: () => buildMetronomePanel(
          songState: SongState(
            song: testSongWithBpm.copyWith(
              metronomeOffsetMs: 50,
              metronomeBeatsPerBar: 6,
              metronomeBeatUnit: 8,
            ),
            originalBpm: 120,
            currentBpm: 120,
            minBpm: 60,
            maxBpm: 240,
            isMetronomeEnabled: true,
            metronomeVolume: 0.8,
            metronomeSubdivision: MetronomeSubdivision.triplets,
          ),
        ),
      ),
    );
  });
}
