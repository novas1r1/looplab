import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:looplab/core/utils/duration_extension.dart';
import 'package:looplab/data/repositories/file_repository.dart';
import 'package:looplab/home/cubit/all_songs_cubit.dart';
import 'package:looplab/models/song.dart';
import 'package:looplab/song/view/song_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LoopLab'),
        actions: [
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
              return const Center(child: CircularProgressIndicator());
            case AllSongsStatus.loaded:
              return ListView.builder(
                itemCount: state.songs.length,
                itemBuilder: (context, index) {
                  final song = state.songs[index];

                  return ListTile(
                    onTap: () => _onTapSong(context, song),
                    title: Text(song.title),
                    trailing: Text(
                      song.duration.toFormattedString(),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              );
            case AllSongsStatus.error:
              return Center(child: Text('Error: ${state.errorMessage}'));
            case AllSongsStatus.initial:
              return const SizedBox.shrink();
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addSong',
        onPressed: () => _onAddSong(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _onAddSong(BuildContext context) async {
    final file = await context.read<FileRepository>().pickSingleAudioFile();
    if (file != null) {
      // TODO: Upload song
      context.read<AllSongsCubit>().addSong(file);
    }
  }

  void _onTapSong(BuildContext context, Song song) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SongPage(song: song)),
    );
  }

  Future<void> _onClearDb(BuildContext context) async {
    await context.read<AllSongsCubit>().clearDb();
  }
}
