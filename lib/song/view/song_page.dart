import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:looplab/core/utils/duration_extension.dart';
import 'package:looplab/data/repositories/loop_repository.dart';
import 'package:looplab/data/repositories/song_repository.dart';
import 'package:looplab/loop/cubit/song_cubit.dart';
import 'package:looplab/models/song.dart';
import 'package:looplab/song/widgets/wave_form_soloud.dart';

class SongPage extends StatelessWidget {
  final Song song;

  const SongPage({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SongCubit(
        loopRepository: context.read<LoopRepository>(),
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
      ),
      body: BlocConsumer<SongCubit, SongState>(
        listener: (context, state) {
          // TODO: implement listener
        },
        builder: (context, state) {
          switch (state.status) {
            case LoopStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case LoopStatus.loaded:
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (state.data != null)
                    WaveFormSoLoud(
                      data: state.data!,
                      duration: song.duration,
                      currentPosition: _currentPlayerPosition,
                      onStartDrag: () => context.read<SongCubit>().pauseSong(),
                      onPositionChanged: (position) =>
                          context.read<SongCubit>().updatePosition(position),
                      loops: state.loops,
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
                        onPressed: () => context.read<SongCubit>().previousLoop(),
                        icon: const Icon(Icons.skip_previous),
                      ),
                      IconButton(
                        onPressed: () {
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
                      IconButton(
                        onPressed: () => context.read<SongCubit>().nextLoop(),
                        icon: const Icon(Icons.skip_next),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => context.read<SongCubit>().addLoop(),
                    child: const Text('Create Loop'),
                  ),
                  if (state.activeLoop != null) ...[
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
                  ],
                  const SizedBox(height: 20),
                  Column(
                    children: state.loops
                        .map(
                          (loop) => ListTile(
                            selectedColor: Colors.blue,
                            selected: loop == state.activeLoop,
                            onTap: () => context.read<SongCubit>().selectLoop(loop),
                            contentPadding: EdgeInsets.zero,
                            leading: IconButton(
                              onPressed: () => context.read<SongCubit>().playLoop(loop),
                              icon: const Icon(Icons.loop),
                            ),
                            title: Text(loop.name),
                            subtitle: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(loop.start?.toFormattedString() ?? '00:00'),
                                Text(loop.end?.toFormattedString() ?? '00:00'),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              );
            case LoopStatus.error:
              return Center(child: Text('Error: ${state.error ?? 'Unknown error'}'));
          }
        },
      ),
    );
  }
}
