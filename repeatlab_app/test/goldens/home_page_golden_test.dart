import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
import 'package:repeatlab/features/changelog_dialog/cubits/changelog_dialog_cubit.dart';
import 'package:repeatlab/features/home/cubit/all_songs_cubit.dart';
import 'package:repeatlab/features/home/home_page.dart';

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
    goldenTest(
      'renders empty state',
      fileName: 'home_page_empty',
      pumpWidget: (tester, widget) => tester.pumpApp(widget),
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

    goldenTest(
      'renders with songs',
      fileName: 'home_page_with_songs',
      pumpWidget: (tester, widget) => tester.pumpApp(widget),
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

    goldenTest(
      'renders loading state',
      fileName: 'home_page_loading',
      pumpWidget: (tester, widget) => tester.pumpAppWithFrames(widget),
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

    goldenTest(
      'renders error state',
      fileName: 'home_page_error',
      pumpWidget: (tester, widget) => tester.pumpApp(widget),
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
