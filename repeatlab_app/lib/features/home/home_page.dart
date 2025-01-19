import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/widgets/loading.dart';
import 'package:repeatlab/core/utils/dialog_helper.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
import 'package:repeatlab/features/home/cubit/all_songs_cubit.dart';
import 'package:repeatlab/features/home/widgets/custom_drawer.dart';
import 'package:repeatlab/features/home/widgets/home_tile.dart';

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
          /* if (kDebugMode)
            IconButton(
              onPressed: () => _onClearDb(context),
              icon: const Icon(Icons.delete),
            ), */
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
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No songs found',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap + to add your first song',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
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
        label: const Text('Add Song'),
      ),
    );
  }

  Future<void> _onAddSong(BuildContext context, int numberOfSongs) async {
    // show paywall
    // await context.read<PaywallCubit>().showPaywall();
    // check if user already added 2 songs. If yes, show rating dialog
    final hasRatedAlready = context.read<LocalConfigRepository>().hasRatedApp;

    if (numberOfSongs >= 2 && !hasRatedAlready) {
      await DialogHelper.displayRateAppDialog(context);
    }

    if (context.mounted) {
      context.read<AllSongsCubit>().addSong();
    }
  }

  /* Future<void> _onClearDb(BuildContext context) async {
    await context.read<AllSongsCubit>().clearDb();
  } */
}
