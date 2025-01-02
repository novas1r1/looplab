import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:looplab/core/utils/duration_extension.dart';
import 'package:looplab/loop/cubit/song_cubit.dart';
import 'package:looplab/models/loop.dart';

class LoopController extends StatelessWidget {
  final Loop? activeLoop;

  const LoopController({
    required this.activeLoop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: (activeLoop == null)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'No active loop.\nAdd a new loop or select an existing one.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                    ),
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => context.read<SongCubit>().previousLoop(),
                      icon: const Icon(Icons.skip_previous),
                    ),
                    IconButton(
                      onPressed: activeLoop?.start != null &&
                              activeLoop?.end != null
                          ? () => context.read<SongCubit>().isPaused
                              ? context.read<SongCubit>().playLoop(activeLoop!)
                              : context.read<SongCubit>().pauseLoop(activeLoop!)
                          : null,
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        activeLoop?.start?.toFormattedString() ?? '-',
                      ),
                      Text(activeLoop?.end?.toFormattedString() ?? '-'),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => context.read<SongCubit>().setLoopStart(),
                      child: const Text('Set Loop Start'),
                    ),
                    TextButton(
                      onPressed: () => context.read<SongCubit>().setLoopEnd(),
                      child: const Text('Set Loop End'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
