import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/ui/motion.dart';
import 'package:repeatlab/core/ui/motion_widgets.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/duration_extension.dart';
import 'package:repeatlab/features/pitch_control/view/pitch_control.dart';
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
                  child: _SeekButton(
                    buttonKey: const Key('song.back10'),
                    icon: Icons.replay_10_rounded,
                    nudgeTurns: -0.06,
                    onPressed: () {
                      AppAnalytics.trackEvent(
                        AppAnalytics.clickBack10Seconds,
                      );
                      context.read<SongCubit>().back(10);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              BlocSelector<SongCubit, SongState, PlayerState?>(
                selector: (state) => state.playerState,
                builder: (context, playerState) {
                  return SizedBox(
                    height: 32,
                    child: PressableScale(
                      child: _PlayPauseButton(
                        isPlaying: playerState == PlayerState.playing,
                        onPressed: () => _onTapPlay(context),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 32,
                child: _SeekButton(
                  buttonKey: const Key('song.forward10'),
                  icon: Icons.forward_10_rounded,
                  nudgeTurns: 0.06,
                  onPressed: () {
                    AppAnalytics.trackEvent(
                      AppAnalytics.clickForward10Seconds,
                    );
                    context.read<SongCubit>().forward(10);
                  },
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
        // PitchControl hides itself (incl. its top spacing) when pitch is not
        // supported for the current song/platform
        const PitchControl(),
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

/// Play/pause button whose icon morphs between the two glyphs instead of
/// swapping instantly.
class _PlayPauseButton extends StatefulWidget {
  final bool isPlaying;
  final VoidCallback onPressed;

  const _PlayPauseButton({
    required this.isPlaying,
    required this.onPressed,
  });

  @override
  State<_PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<_PlayPauseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.fast,
    value: widget.isPlaying ? 1 : 0,
  );

  @override
  void didUpdateWidget(_PlayPauseButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      key: const Key('song.play'),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: widget.onPressed,
      icon: AnimatedIcon(
        icon: AnimatedIcons.play_pause,
        progress: _controller,
      ),
    );
  }
}

/// Seek button that gives a small one-shot rotation nudge on each tap.
class _SeekButton extends StatefulWidget {
  final Key buttonKey;
  final IconData icon;
  final double nudgeTurns;
  final VoidCallback onPressed;

  const _SeekButton({
    required this.buttonKey,
    required this.icon,
    required this.nudgeTurns,
    required this.onPressed,
  });

  @override
  State<_SeekButton> createState() => _SeekButtonState();
}

class _SeekButtonState extends State<_SeekButton> {
  int _taps = 0;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(widget.icon, size: 24);
    return IconButton(
      key: widget.buttonKey,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: () {
        setState(() => _taps++);
        widget.onPressed();
      },
      icon: _taps == 0
          ? icon
          : TweenAnimationBuilder<double>(
              // A new key restarts the nudge on every tap.
              key: ValueKey(_taps),
              tween: Tween(begin: widget.nudgeTurns, end: 0),
              duration: Motion.of(context, Motion.fast),
              curve: Motion.enter,
              builder: (context, turns, child) => RotationTransition(
                turns: AlwaysStoppedAnimation(turns),
                child: child,
              ),
              child: icon,
            ),
    );
  }
}
