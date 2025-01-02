import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:looplab/core/ui/widgets/loading.dart';
import 'package:looplab/core/utils/duration_extension.dart';
import 'package:looplab/data/repositories/file_repository.dart';
import 'package:looplab/home/cubit/all_songs_cubit.dart';
import 'package:looplab/home/widgets/custom_drawer.dart';
import 'package:looplab/models/song.dart';
import 'package:looplab/song/view/song_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
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
          'LoopLab',
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
        ],
      ),
      body: BlocBuilder<AllSongsCubit, AllSongsState>(
        builder: (context, state) {
          switch (state.status) {
            case AllSongsStatus.loading:
              return const Center(child: Loading());
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
                            .withOpacity(0.5),
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
                                  .withOpacity(0.6),
                            ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemCount: state.songs.length,
                itemBuilder: (context, index) {
                  final song = state.songs[index];

                  return HomeTile(song: song);
                },
              );
            case AllSongsStatus.error:
              return Center(child: Text('Error: ${state.errorMessage}'));
            case AllSongsStatus.initial:
              return const SizedBox.shrink();
          }
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addSong',
        onPressed: () => _onAddSong(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Song'),
      ),
    );
  }

  Future<void> _onAddSong(BuildContext context) async {
    final file = await context.read<FileRepository>().pickSingleAudioFile();
    if (file != null && context.mounted) {
      // TODO: Upload song
      context.read<AllSongsCubit>().addSong(file);
    }
  }

  Future<void> _onClearDb(BuildContext context) async {
    await context.read<AllSongsCubit>().clearDb();
  }
}

class HomeTile extends StatelessWidget {
  final Song song;

  const HomeTile({
    super.key,
    required this.song,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/waveform.png'),
            fit: BoxFit.cover,
            opacity: 0.1, // Adjust opacity here (0.0 to 1.0)
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              '${song.loops.length}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          onTap: () => _onTapSong(context, song),
          title: Text(
            song.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              song.duration.toFormattedString(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onTapSong(BuildContext context, Song song) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SongPage(song: song)),
    );
  }
}
