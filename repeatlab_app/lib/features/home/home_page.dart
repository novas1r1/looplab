import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/widgets/loading.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/dialog_helper.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
import 'package:repeatlab/features/home/cubit/all_songs_cubit.dart';
import 'package:repeatlab/features/home/widgets/custom_drawer.dart';
import 'package:repeatlab/features/home/widgets/home_tile.dart';
import 'package:repeatlab/l10n/l10n.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final songCount = context.watch<AllSongsCubit>().state.songs.length;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).colorScheme.surface,
      drawer: const CustomDrawer(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          'RepeatLab',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        actions: [
          IconButton(
            onPressed: () => context.read<AllSongsCubit>().loadSongs(),
            icon: const Icon(Icons.refresh),
          ),
          if (kDebugMode)
            IconButton(
              onPressed: () => _onClearDb(context),
              icon: const Icon(Icons.delete),
            ),
          if (kDebugMode)
            IconButton(
              onPressed: () => _onClearSharedPrefs(context),
              icon: const Icon(Icons.delete_forever),
            ),
        ],
      ),
      body: BlocBuilder<AllSongsCubit, AllSongsState>(
        builder: (context, state) {
          switch (state.status) {
            case AllSongsStatus.loading:
              return const Center(child: Loading());
            case AllSongsStatus.initial:
            case AllSongsStatus.loaded:
              if (state.songs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_note,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.l10n.noSongsFound,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.tapToAddSong,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 92),
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemCount: state.songs.length,
                itemBuilder: (context, index) {
                  final song = state.songs[index];

                  return HomeTile(song: song);
                },
              );
            case AllSongsStatus.error:
              return Center(child: Text('Error: ${state.errorMessage}'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addSong',
        onPressed: () => _onAddSong(context, songCount),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.addSong),
      ),
    );
  }

  Future<void> _onAddSong(BuildContext context, int numberOfSongs) async {
    AppAnalytics.trackEvent(AppAnalytics.clickAddSong);
    // check if user already added 2 songs. If yes, show rating dialog
    final hasRatedAlready = context.read<LocalConfigRepository>().hasRatedApp;

    if (numberOfSongs >= 2 && !hasRatedAlready) {
      await DialogHelper.displayRateAppDialog(context);
    }

    if (context.mounted) {
      context.read<AllSongsCubit>().addSong();
    }
  }

  Future<void> _onClearDb(BuildContext context) async {
    AppAnalytics.trackEvent(AppAnalytics.clickClearDb);
    await context.read<AllSongsCubit>().clearDb();
  }

  void _onClearSharedPrefs(BuildContext context) {
    context.read<LocalConfigRepository>().clear();
  }
}
