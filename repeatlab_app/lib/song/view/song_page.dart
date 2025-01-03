import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:repeatlab/core/ui/widgets/loading.dart';
import 'package:repeatlab/core/utils/duration_extension.dart';
import 'package:repeatlab/data/repositories/song_repository.dart';
import 'package:repeatlab/loop/cubit/song_cubit.dart';
import 'package:repeatlab/models/song.dart';
import 'package:repeatlab/song/widgets/loop_controller.dart';
import 'package:repeatlab/song/widgets/loop_tile.dart';
import 'package:repeatlab/song/widgets/loop_timeline.dart';
import 'package:repeatlab/song/widgets/wave_form_soloud.dart';

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
      child: _SongView(song: song),
    );
  }
}

class _SongView extends StatefulWidget {
  final Song song;

  const _SongView({required this.song});

  @override
  State<_SongView> createState() => _SongViewState();
}

class _SongViewState extends State<_SongView> {
  Duration _currentPlayerPosition = Duration.zero;

  StreamSubscription<Duration>? _positionSubscription;

  final ScrollController _loopListController = ScrollController();

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
    _loopListController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.song.title),
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
          } else if (state.status == SongStatus.songDeleted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (state.status == SongStatus.loopAdded) {
            // scroll down in looplist
            _loopListController.animateTo(
              _loopListController.position.maxScrollExtent + 100,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        },
        builder: (context, state) {
          switch (state.status) {
            case SongStatus.loading:
              return const Center(child: Loading());
            case SongStatus.loaded:
            case SongStatus.songDeleted:
            case SongStatus.error:
            case SongStatus.loopAdded:
            case SongStatus.updated:
            case SongStatus.loopDeleted:
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (state.data != null)
                      WaveFormSoLoud(
                        data: state.data!,
                        duration: state.song.duration,
                        currentPosition: _currentPlayerPosition,
                        onStartDrag: () => context.read<SongCubit>().pauseSong(),
                        onPositionChanged: (position) =>
                            context.read<SongCubit>().updatePosition(position),
                        loops: state.song.loops,
                      ),
                    const SizedBox(height: 8),
                    LoopTimeline(
                      loops: state.song.loops,
                      songDuration: state.song.duration,
                      currentPosition: _currentPlayerPosition,
                      onLoopTap: (loop) => context.read<SongCubit>().playLoop(loop),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _currentPlayerPosition.toFormattedString(),
                          ),
                          IconButton(
                            iconSize: 36,
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
                          Text(widget.song.duration.toFormattedString()),
                        ],
                      ),
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Loops',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        ElevatedButton(
                          onPressed: () => context.read<SongCubit>().addLoop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          ),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LoopController(activeLoop: state.activeLoop),
                    const SizedBox(height: 20),
                    Expanded(
                      child: ListView(
                        controller: _loopListController,
                        children: [
                          for (var index = 0; index < state.song.loops.length; index++)
                            LoopTile(
                              index: index,
                              loop: state.song.loops[index],
                              isSelected: state.song.loops[index] == state.activeLoop,
                              isPaused: context.read<SongCubit>().isPaused,
                              onTap: (loop) => context.read<SongCubit>().playLoop(loop),
                              onDelete: (loop) => context.read<SongCubit>().deleteLoop(loop),
                              onPlay: (loop) => context.read<SongCubit>().playLoop(loop),
                              onPause: (loop) => context.read<SongCubit>().pauseLoop(loop),
                              onUpdate: (loop) => context.read<SongCubit>().updateLoop(loop),
                              onSetLoopStart: () => context.read<SongCubit>().setLoopStart(),
                              onSetLoopEnd: () => context.read<SongCubit>().setLoopEnd(),
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 24, // Adds a more prominent shadow
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.8),
            width: 1.5,
          ),
        ),
        title: const Text('Delete Song & Loops'),
        content: const Text(
          "Are you sure you want to delete this song and all attached loops? This can't be undone.",
        ),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.delete),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            label: const Text('Delete'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (result != null && result && context.mounted) {
      context.read<SongCubit>().deleteSong();
      Navigator.of(context).pop();
    }
  }
}
