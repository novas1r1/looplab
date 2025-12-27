import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
import 'package:repeatlab/features/changelog_dialog/cubits/changelog_dialog_cubit.dart';
import 'package:repeatlab/features/home/cubit/all_songs_cubit.dart';
import 'package:repeatlab/features/home/home_page.dart';

import '../helpers/golden_multi_locale.dart';
import '../helpers/golden_test_device_scenario.dart';
import '../helpers/mock_cubits.dart';
import '../helpers/mock_data.dart';
import '../helpers/mock_repositories.dart';
import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAllSongsCubit mockAllSongsCubit;
  late MockChangelogDialogCubit mockChangelogDialogCubit;
  late MockLocalConfigRepository mockLocalConfigRepository;

  setUp(() {
    mockAllSongsCubit = MockAllSongsCubit();
    mockChangelogDialogCubit = MockChangelogDialogCubit();
    mockLocalConfigRepository = MockLocalConfigRepository();

    when(() => mockChangelogDialogCubit.state).thenReturn(
      const ChangelogDialogState(),
    );
    when(() => mockChangelogDialogCubit.checkChangelogDialog()).thenAnswer((_) async {});
    when(() => mockLocalConfigRepository.hasRatedApp).thenReturn(false);
  });

  Widget buildHomePage() {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<LocalConfigRepository>.value(
          value: mockLocalConfigRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AllSongsCubit>.value(value: mockAllSongsCubit),
          BlocProvider<ChangelogDialogCubit>.value(
            value: mockChangelogDialogCubit,
          ),
        ],
        child: const HomePage(),
      ),
    );
  }

  group('HomePage Golden Tests', () {
    multiLocaleGoldenTest(
      'renders empty state',
      fileNameBase: 'home_page_empty',
      pumpWidgetWithLocale: (tester, widget, locale) => tester.pumpApp(widget, locale: locale),
      builder: () {
        when(() => mockAllSongsCubit.state).thenReturn(
          const AllSongsState(status: AllSongsStatus.loaded),
        );

        return GoldenTestDeviceScenario(
          name: 'empty',
          builder: buildHomePage,
        );
      },
    );

    multiLocaleGoldenTest(
      'renders with songs',
      fileNameBase: 'home_page_with_songs',
      pumpWidgetWithLocale: (tester, widget, locale) => tester.pumpApp(widget, locale: locale),
      builder: () {
        when(() => mockAllSongsCubit.state).thenReturn(
          const AllSongsState(
            status: AllSongsStatus.loaded,
            songs: MockData.testSongs,
          ),
        );

        return GoldenTestDeviceScenario(
          name: 'with_songs',
          builder: buildHomePage,
        );
      },
    );

    multiLocaleGoldenTest(
      'renders loading state',
      fileNameBase: 'home_page_loading',
      pumpWidgetWithLocale: (tester, widget, locale) =>
          tester.pumpAppWithFrames(widget, locale: locale),
      pumpBeforeTest: (tester) async {
        // Don't use pumpAndSettle for loading state (infinite animation)
        await tester.pump();
      },
      builder: () {
        when(() => mockAllSongsCubit.state).thenReturn(
          const AllSongsState(status: AllSongsStatus.loading),
        );

        return GoldenTestDeviceScenario(
          name: 'loading',
          builder: buildHomePage,
        );
      },
    );

    multiLocaleGoldenTest(
      'renders error state',
      fileNameBase: 'home_page_error',
      pumpWidgetWithLocale: (tester, widget, locale) => tester.pumpApp(widget, locale: locale),
      builder: () {
        when(() => mockAllSongsCubit.state).thenReturn(
          const AllSongsState(
            status: AllSongsStatus.error,
            errorMessage: 'Failed to load songs',
          ),
        );

        return GoldenTestDeviceScenario(
          name: 'error',
          builder: buildHomePage,
        );
      },
    );
  });
}
