import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/ui/widgets/loading.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/features/song/cubit/song_exporter/song_exporter_cubit.dart';
import 'package:repeatlab/features/song/widgets/loop_tile.dart';
import 'package:repeatlab/l10n/l10n.dart';

import '../helpers/golden_multi_locale.dart';
import '../helpers/golden_test_device_scenario.dart';
import '../helpers/mock_cubits.dart';
import '../helpers/mock_data.dart';
import '../helpers/mock_repositories.dart';
import '../helpers/pump_app.dart';

/// Test wrapper for SongPage that allows injecting mock cubits
class TestSongPageView extends StatelessWidget {
  final Song song;

  const TestSongPageView({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SongCubit, SongState, SongStatus>(
      selector: (state) => state.status,
      builder: (context, status) {
        switch (status) {
          case SongStatus.loading:
            return const Scaffold(
              body: Center(child: Loading()),
            );
          case SongStatus.loadError:
            return Scaffold(
              appBar: AppBar(title: Text(song.title)),
              body: Center(
                child: Text(
                  'Error loading song: ${context.read<SongCubit>().state.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          default:
            return _buildLoadedView(context);
        }
      },
    );
  }

  Widget _buildLoadedView(BuildContext context) {
    final state = context.watch<SongCubit>().state;

    return Scaffold(
      appBar: AppBar(
        title: Text(song.title),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.help_outline),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    const Icon(Icons.feedback),
                    const SizedBox(width: 8),
                    Text(context.l10n.reportBugAndFeedback),
                  ],
                ),
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    const Icon(Icons.delete),
                    const SizedBox(width: 8),
                    Text(context.l10n.deleteSong),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Placeholder for waveform
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('Waveform Visualization'),
                  ),
                ),
                const SizedBox(height: 8),
                // Placeholder for loop timeline
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('Loop Timeline'),
                  ),
                ),
                const SizedBox(height: 12),
                // Song controller placeholder
                _buildSongController(context, state),
                const Divider(height: 24),
                _buildLoopsHeader(context, state),
                const SizedBox(height: 8),
                _buildLoopButtons(context, state),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildLoopsList(context, state),
                childCount: 1,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: Text(
          context.l10n.addLoop,
          style: context.bodyLargeDarkBold,
        ),
      ),
    );
  }

  Widget _buildSongController(BuildContext context, SongState state) {
    final isPlaying = state.playerState == PlayerState.playing;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.replay_10),
          iconSize: 32,
        ),
        const SizedBox(width: 16),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () {},
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            iconSize: 48,
          ),
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.forward_10),
          iconSize: 32,
        ),
      ],
    );
  }

  Widget _buildLoopsHeader(BuildContext context, SongState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Loops',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        Row(
          children: [
            Text(
              context.l10n.loopMode,
              style: context.bodySmall,
            ),
            CupertinoSwitch(
              thumbIcon: WidgetStateProperty.resolveWith<Icon?>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.disabled)) {
                    return const Icon(Icons.close);
                  }
                  return const Icon(Icons.loop_rounded);
                },
              ),
              activeTrackColor: Theme.of(context).colorScheme.primaryContainer,
              value: state.isLoopModeEnabled,
              onChanged: (value) {},
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoopButtons(BuildContext context, SongState state) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              context.l10n.setLoopStart,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: state.activeLoop != null ? () {} : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              context.l10n.setLoopEnd,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoopsList(BuildContext context, SongState state) {
    final loops = state.song.loops;

    if (loops.isEmpty) {
      return SizedBox(
        height: 150,
        child: Center(
          child: Text(
            'No loops yet',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.35,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 92),
        itemCount: loops.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: LoopTile(
            index: index,
            loop: loops[index],
            isSelected: loops[index] == state.activeLoop,
            onTap: (loop) {},
            onDelete: (loop) {},
            onPlay: (loop) {},
            onPause: (loop) {},
            onUpdate: (loop) {},
          ),
        ),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSongCubit mockSongCubit;
  late MockSongExporterCubit mockSongExporterCubit;
  late MockPremiumSubscriptionCubit mockPremiumSubscriptionCubit;
  late MockLocalConfigRepository mockLocalConfigRepository;

  setUp(() {
    mockSongCubit = MockSongCubit();
    mockSongExporterCubit = MockSongExporterCubit();
    mockPremiumSubscriptionCubit = MockPremiumSubscriptionCubit();
    mockLocalConfigRepository = MockLocalConfigRepository();

    when(() => mockSongExporterCubit.state).thenReturn(SongExporterState());
    when(() => mockPremiumSubscriptionCubit.state).thenReturn(
      const PremiumSubscriptionState(),
    );
    when(() => mockPremiumSubscriptionCubit.hasPremium).thenReturn(false);
    when(() => mockLocalConfigRepository.hasRatedApp).thenReturn(false);
  });

  Widget buildSongPage(Song song) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<LocalConfigRepository>.value(
          value: mockLocalConfigRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<SongCubit>.value(value: mockSongCubit),
          BlocProvider<SongExporterCubit>.value(value: mockSongExporterCubit),
          BlocProvider<PremiumSubscriptionCubit>.value(
            value: mockPremiumSubscriptionCubit,
          ),
        ],
        child: TestSongPageView(song: song),
      ),
    );
  }

  group('SongPage Golden Tests', () {
    multiLocaleGoldenTest(
      'renders loading state',
      fileNameBase: 'song_page_loading',
      pumpWidgetWithLocale: (tester, widget, locale) =>
          tester.pumpAppWithFrames(widget, locale: locale),
      pumpBeforeTest: (tester) async {
        await tester.pump();
      },
      builder: () {
        when(() => mockSongCubit.state).thenReturn(
          const SongState(
            song: MockData.songMedium,
          ),
        );

        return GoldenTestDeviceScenario(
          name: 'loading',
          builder: () => buildSongPage(MockData.songMedium),
        );
      },
    );

    multiLocaleGoldenTest(
      'renders loaded state without loops',
      fileNameBase: 'song_page_empty',
      pumpWidgetWithLocale: (tester, widget, locale) =>
          tester.pumpApp(widget, locale: locale),
      builder: () {
        when(() => mockSongCubit.state).thenReturn(
          const SongState(
            song: MockData.songMedium,
            status: SongStatus.loadSuccess,
            isTutorialCompleted: true,
          ),
        );

        return GoldenTestDeviceScenario(
          name: 'empty',
          builder: () => buildSongPage(MockData.songMedium),
        );
      },
    );

    multiLocaleGoldenTest(
      'renders loaded state with loops',
      fileNameBase: 'song_page_with_loops',
      pumpWidgetWithLocale: (tester, widget, locale) =>
          tester.pumpApp(widget, locale: locale),
      builder: () {
        final songWithLoops = MockData.songMedium.copyWith(
          loops: MockData.testLoops,
        );

        when(() => mockSongCubit.state).thenReturn(
          SongState(
            song: songWithLoops,
            status: SongStatus.loadSuccess,
            isTutorialCompleted: true,
          ),
        );

        return GoldenTestDeviceScenario(
          name: 'with_loops',
          builder: () => buildSongPage(songWithLoops),
        );
      },
    );

    multiLocaleGoldenTest(
      'renders playing state with active loop',
      fileNameBase: 'song_page_playing',
      pumpWidgetWithLocale: (tester, widget, locale) =>
          tester.pumpApp(widget, locale: locale),
      builder: () {
        final songWithLoops = MockData.songMedium.copyWith(
          loops: MockData.testLoops,
        );

        when(() => mockSongCubit.state).thenReturn(
          SongState(
            song: songWithLoops,
            status: SongStatus.loadSuccess,
            playerState: PlayerState.playing,
            activeLoop: MockData.loopChorus,
            isLoopModeEnabled: true,
            isTutorialCompleted: true,
          ),
        );

        return GoldenTestDeviceScenario(
          name: 'playing',
          builder: () => buildSongPage(songWithLoops),
        );
      },
    );

    multiLocaleGoldenTest(
      'renders error state',
      fileNameBase: 'song_page_error',
      pumpWidgetWithLocale: (tester, widget, locale) =>
          tester.pumpApp(widget, locale: locale),
      builder: () {
        when(() => mockSongCubit.state).thenReturn(
          const SongState(
            song: MockData.songMedium,
            status: SongStatus.loadError,
            error: 'Failed to load audio file',
          ),
        );

        return GoldenTestDeviceScenario(
          name: 'error',
          builder: () => buildSongPage(MockData.songMedium),
        );
      },
    );

    multiLocaleGoldenTest(
      'renders with long song title',
      fileNameBase: 'song_page_long_title',
      pumpWidgetWithLocale: (tester, widget, locale) =>
          tester.pumpApp(widget, locale: locale),
      builder: () {
        when(() => mockSongCubit.state).thenReturn(
          const SongState(
            song: MockData.songSuperLong,
            status: SongStatus.loadSuccess,
            isTutorialCompleted: true,
          ),
        );

        return GoldenTestDeviceScenario(
          name: 'long_title',
          builder: () => buildSongPage(MockData.songSuperLong),
        );
      },
    );
  });
}
