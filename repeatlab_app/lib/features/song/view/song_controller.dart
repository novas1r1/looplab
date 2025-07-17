import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/utils/duration_extension.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/features/song/view/speed_control.dart';

class SongController extends StatelessWidget {
  const SongController({
    required super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: StreamBuilder<Duration>(
                  stream: context.read<SongCubit>().positionStream,
                  initialData: Duration.zero,
                  builder: (BuildContext context, AsyncSnapshot<Duration> snapshot) {
                    if (snapshot.hasData) {
                      return Text(snapshot.data!.toFormattedString());
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              IconButton(
                onPressed: () => context.read<SongCubit>().back(10),
                icon: const Icon(Icons.replay_10_rounded),
              ),
              const SizedBox(width: 8),
              BlocSelector<SongCubit, SongState, PlayerState?>(
                selector: (state) => state.playerState,
                builder: (context, playerState) {
                  return IconButton(
                    iconSize: 36,
                    onPressed: () => _onTapPlay(context),
                    icon: Icon(
                      playerState == PlayerState.playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => context.read<SongCubit>().forward(10),
                icon: const Icon(Icons.forward_10_rounded),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: BlocSelector<SongCubit, SongState, Duration>(
                    selector: (state) => state.song.duration,
                    builder: (context, duration) => Text(duration.toFormattedString()),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const SpeedControl(),
      ],
    );
  }

  void _onTapPlay(BuildContext context) {
    if (context.read<SongCubit>().state.isLoopModeEnabled) {
      final activeLoop = context.read<SongCubit>().state.activeLoop;
      if (activeLoop != null) {
        context.read<SongCubit>().togglePlayLoop(activeLoop);
      }
    } else {
      context.read<SongCubit>().togglePlaySong();
    }
  }
}
