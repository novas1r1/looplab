import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:looplab/core/utils/duration_extension.dart';
import 'package:looplab/data/repositories/song_repository.dart';
import 'package:looplab/loop/cubit/song_cubit.dart';
import 'package:looplab/models/song.dart';
import 'package:looplab/song/widgets/loop_tile.dart';
import 'package:looplab/song/widgets/wave_form_soloud.dart';

class SongPage extends StatelessWidget {
  final Song song;

  const SongPage({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SongCubit(
        songRepository: context.read<SongRepository>(),
        soloud: SoLoud.instance,
        song: song,
      )..initSong(),
      child: const _SongView(),
    );
  }
}

class _SongView extends StatefulWidget {
  const _SongView();

  @override
  State<_SongView> createState() => _SongViewState();
}

class _SongViewState extends State<_SongView> {
  Duration _currentPlayerPosition = Duration.zero;

  StreamSubscription<Duration>? _positionSubscription;

  @override
  void initState() {
    super.initState();
    _positionSubscription = context.read<SongCubit>().positionStream.listen((position) {
      setState(() {
        _currentPlayerPosition = position;
      });
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final song = context.read<SongCubit>().song;

    return Scaffold(
      appBar: AppBar(
        title: Text(song.title),
        actions: [
          IconButton(
            onPressed: () => _onTapDeleteSong(context),
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: BlocConsumer<SongCubit, SongState>(
        listener: (context, state) {
          if (state.status == SongStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error ?? 'Unknown error')),
            );
          }
          if (state.status == SongStatus.songDeleted) {
            Navigator.of(context).pop();
          }
        },
        builder: (context, state) {
          switch (state.status) {
            case SongStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case SongStatus.loaded:
            case SongStatus.songDeleted:
            case SongStatus.error:
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (state.data != null)
                      WaveFormSoLoud(
                        data: state.data!,
                        duration: song.duration,
                        currentPosition: _currentPlayerPosition,
                        onStartDrag: () => context.read<SongCubit>().pauseSong(),
                        onPositionChanged: (position) =>
                            context.read<SongCubit>().updatePosition(position),
                        loops: state.song.loops,
                      ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_currentPlayerPosition.toFormattedString()),
                        Text(song.duration.toFormattedString()),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {
                            // unselect loop
                            context.read<SongCubit>().unselectLoop();

                            if (context.read<SongCubit>().isPaused) {
                              context.read<SongCubit>().playSong();
                            } else {
                              context.read<SongCubit>().pauseSong();
                            }
                          },
                          icon: Icon(
                            context.read<SongCubit>().isPaused
                                ? Icons.play_arrow_rounded
                                : Icons.pause_rounded,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Loop part of the song',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => context.read<SongCubit>().previousLoop(),
                          icon: const Icon(Icons.skip_previous),
                        ),
                        ElevatedButton(
                          onPressed: () => context.read<SongCubit>().addLoop(),
                          child: const Text('Create Loop'),
                        ),
                        IconButton(
                          onPressed: () => context.read<SongCubit>().nextLoop(),
                          icon: const Icon(Icons.skip_next),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    /* if (state.activeLoop != null) ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: () => context.read<SongCubit>().setLoopStart(),
                            child: const Text('Set Loop Start'),
                          ),
                          ElevatedButton(
                            onPressed: () => context.read<SongCubit>().setLoopEnd(),
                            child: const Text('Set Loop End'),
                          ),
                        ],
                      ), 
                    ],*/
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView(
                        children: [
                          for (var index = 0; index < state.song.loops.length; index++)
                            LoopTile(
                              index: index,
                              loop: state.song.loops[index],
                              isSelected: state.song.loops[index] == state.activeLoop,
                              isPaused: context.read<SongCubit>().isPaused,
                              onTap: (loop) => context.read<SongCubit>().selectLoop(loop),
                              onDelete: (loop) => context.read<SongCubit>().deleteLoop(loop),
                              onPlay: (loop) => context.read<SongCubit>().playLoop(loop),
                              onPause: (loop) => context.read<SongCubit>().pauseLoop(loop),
                              onUpdate: (loop) => context.read<SongCubit>().updateLoop(loop),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
          }
        },
      ),
    );
  }

  Future<void> _onTapDeleteSong(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Song & Loops'),
        content: const Text(
          "Are you sure you want to delete this song and all attached loops? This can't be undone.",
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result != null && result) {
      context.read<SongCubit>().deleteSong();
    }
  }
}
