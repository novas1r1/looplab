import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/utils/duration_extension.dart';
import 'package:repeatlab/core/utils/snackbar_helper.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/l10n/l10n.dart';

class LoopController extends StatelessWidget {
  final Loop? activeLoop;

  const LoopController({
    required this.activeLoop,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SongCubit>().state;
    final isPaused = state.isPaused;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: activeLoop?.color.color ?? Colors.transparent,
          width: 2,
        ),
      ),
      child: (activeLoop == null)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      context.l10n.noActiveLoop,
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
                      iconSize: 36,
                      onPressed: activeLoop?.start != null && activeLoop?.end != null
                          ? () => context.read<SongCubit>().togglePlayLoop(activeLoop!)
                          : null,
                      icon: Icon(
                        isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
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
                      onPressed: () {
                        if (activeLoop?.end != null &&
                            context.read<SongCubit>().state.position! < activeLoop!.end!) {
                          context.read<SongCubit>().setLoopStart();
                        } else if (activeLoop?.end != null) {
                          SnackbarHelper.showError(
                            context,
                            context.l10n.startMustBeBeforeEnd,
                          );
                        } else {
                          // No end position set yet, so it's safe to set start
                          context.read<SongCubit>().setLoopStart();
                        }
                      },
                      child: Text(context.l10n.setLoopStart),
                    ),
                    TextButton(
                      onPressed: () {
                        if (activeLoop?.start != null &&
                            context.read<SongCubit>().state.position! > activeLoop!.start!) {
                          context.read<SongCubit>().setLoopEnd();
                        } else if (activeLoop?.start != null) {
                          SnackbarHelper.showError(
                            context,
                            context.l10n.endMustBeAfterStart,
                          );
                        } else {
                          // No start position set yet, so it's safe to set end
                          context.read<SongCubit>().setLoopEnd();
                        }
                      },
                      child: Text(context.l10n.setLoopEnd),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
