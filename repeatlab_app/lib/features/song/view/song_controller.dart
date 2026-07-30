import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/ui/widgets/app_icon.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/duration_extension.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/features/song_controls/view/song_controls_card.dart';

/// Diameter of the filled accent circle of the play button.
const _playButtonDiameter = 42.0;

/// How far the play button sticks out of the transport bar on each side. The
/// bar reserves this as margin so nothing gets clipped.
const _playButtonOverhang = 10.0;

class SongController extends StatelessWidget {
  const SongController({
    required super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The play button floats above the transport bar (z-wise) inside this
        // Stack, so it needs the extra vertical room the overhang takes.
        Stack(
          alignment: Alignment.center,
          children: [
            _TransportBar(),
            _PlayButton(),
          ],
        ),
        SizedBox(height: 8),
        // Speed, pitch and metronome share one tabbed card; unavailable tabs
        // (pitch/metronome on unsupported platforms) are dropped from it.
        SongControlsCard(),
      ],
    );
  }
}

/// Position, ±10 s skip buttons and total duration. The play button itself is
/// painted on top of this bar by the surrounding [Stack].
class _TransportBar extends StatelessWidget {
  const _TransportBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      margin: const EdgeInsets.symmetric(vertical: _playButtonOverhang),
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
                icon: const AppIcon(
                  iconName: 'ic_back_10',
                  iconSize: 24,
                ),
              ),
            ),
          ),
          // Keeps the skip buttons clear of the floating play button.
          const SizedBox(width: _playButtonDiameter + 24),
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
              icon: const AppIcon(
                iconName: 'ic_forward_10',
                iconSize: 24,
              ),
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
    );
  }
}

/// The prominent play/pause control: a filled accent circle that sits on top
/// of the transport bar, drop-shadowed so it looks like it floats above it.
class _PlayButton extends StatelessWidget {
  const _PlayButton();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: AppColors.primaryContainer,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: BlocSelector<SongCubit, SongState, PlayerState?>(
          selector: (state) => state.playerState,
          builder: (context, playerState) {
            return InkWell(
              key: const Key('song.play'),
              onTap: () => _onTap(context),
              child: SizedBox.square(
                dimension: _playButtonDiameter,
                child: Icon(
                  playerState == PlayerState.playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 24,
                  color: AppColors.onPrimaryContainer,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _onTap(BuildContext context) {
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
