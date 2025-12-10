import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/utils/duration_extension.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/features/speed_control/view/speed_control.dart';

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
            color: AppColors.secondaryContainer,
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
              SizedBox(
                height: 32,
                child: Center(
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => context.read<SongCubit>().back(10),
                    icon: const Icon(Icons.replay_10_rounded, size: 24),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              BlocSelector<SongCubit, SongState, PlayerState?>(
                selector: (state) => state.playerState,
                builder: (context, playerState) {
                  return SizedBox(
                    height: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _onTapPlay(context),
                      icon: Icon(
                        playerState == PlayerState.playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => context.read<SongCubit>().forward(10),
                  icon: const Icon(Icons.forward_10_rounded, size: 24),
                ),
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
        BlocBuilder<SongCubit, SongState>(
          buildWhen: (previous, current) =>
              previous.song != current.song || previous.status != current.status,
          builder: (context, state) {
            final isProcessing = state.status == SongStatus.processing;
            
            return Stack(
              children: [
                SpeedControl(
                  onSpeedMultiplierChanged: (value) =>
                      context.read<SongCubit>().updateSpeed(multiplier: value),
                  onSpeedBpmChanged: (value) => context.read<SongCubit>().updateSpeed(bpm: value),
                  onOriginalBpmChanged: (value) => context.read<SongCubit>().updateOriginalBpm(value),
                  song: state.song,
                ),
                // Processing overlay
                if (isProcessing)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.secondaryContainer.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Processing audio...',
                              style: TextStyle(
                                color: AppColors.onSecondaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
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
