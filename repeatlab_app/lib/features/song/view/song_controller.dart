import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
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
                  builder:
                      (BuildContext context, AsyncSnapshot<Duration> snapshot) {
                        if (snapshot.hasData) {
                          return AutoSizeText(
                            snapshot.data!.toFormattedString(),
                            minFontSize: 14,
                            maxFontSize: 24,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                ),
              ),
              SizedBox(
                height: 32,
                child: Center(
                  child: IconButton(
                    key: const Key('song.back10'),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      AppAnalytics.trackEvent(
                        AppAnalytics.clickBack10Seconds,
                      );
                      context.read<SongCubit>().back(10);
                    },
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
                      key: const Key('song.play'),
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
                  key: const Key('song.forward10'),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    AppAnalytics.trackEvent(
                      AppAnalytics.clickForward10Seconds,
                    );
                    context.read<SongCubit>().forward(10);
                  },
                  icon: const Icon(Icons.forward_10_rounded, size: 24),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: BlocSelector<SongCubit, SongState, Duration>(
                    selector: (state) => state.song.duration,
                    builder: (context, duration) => AutoSizeText(
                      duration.toFormattedString(),
                      minFontSize: 14,
                      maxFontSize: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // SpeedControl now reads state directly from SongCubit - no callbacks needed
        const SpeedControl(),
      ],
    );
  }

  void _onTapPlay(BuildContext context) {
    final cubit = context.read<SongCubit>();
    final isPlaying = cubit.state.playerState == PlayerState.playing;

    if (cubit.state.isLoopModeEnabled) {
      final activeLoop = cubit.state.activeLoop;
      if (activeLoop != null) {
        AppAnalytics.trackEvent(
          isPlaying ? AppAnalytics.clickStopLoop : AppAnalytics.clickPlayLoop,
        );
        cubit.togglePlayLoop(activeLoop);
      }
    } else {
      AppAnalytics.trackEvent(
        isPlaying ? AppAnalytics.clickPauseSong : AppAnalytics.clickPlaySong,
      );
      cubit.togglePlaySong();
    }
  }
}
