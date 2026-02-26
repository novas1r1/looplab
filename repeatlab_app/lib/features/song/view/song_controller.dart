import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/duration_extension.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/features/song/cubit/recording/recording_cubit.dart';
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
              BlocSelector<RecordingCubit, RecordingState, RecordingStatus>(
                selector: (state) => state.status,
                builder: (context, status) {
                  final isRecording = status == RecordingStatus.recording;
                  final isCountdown = status == RecordingStatus.countdown;
                  return SizedBox(
                    height: 32,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: isCountdown
                          ? null
                          : () => _onTapRecord(context),
                      icon: Icon(
                        isRecording
                            ? Icons.stop_circle_rounded
                            : Icons.fiber_manual_record_rounded,
                        size: 24,
                        color: (isRecording || isCountdown)
                            ? Colors.red
                            : null,
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

  Future<void> _onTapRecord(BuildContext context) async {
    final recordingCubit = context.read<RecordingCubit>();
    final songCubit = context.read<SongCubit>();

    if (recordingCubit.state.status == RecordingStatus.recording) {
      // Stop recording
      songCubit.pauseSong();
      recordingCubit.stopRecording(
        startPosition: Duration.zero,
      );
    } else {
      // Check premium gate: free users get 1 recording per song
      final premiumCubit = context.read<PremiumSubscriptionCubit>();
      if (!premiumCubit.hasPremium &&
          recordingCubit.state.layers.isNotEmpty) {
        AppAnalytics.trackEvent('show_paywall_recording_layers');
        await premiumCubit.presentPaywall();
        return;
      }

      // Start recording
      final activeLoop = songCubit.state.activeLoop;
      final startPos = activeLoop?.start ?? Duration.zero;
      final stopPos = activeLoop?.end;

      // Pause current playback, seek to start
      songCubit.pauseSong();
      songCubit.seekSong(startPos);

      recordingCubit.startRecording(
        startPosition: startPos,
        stopPosition: stopPos,
        positionStream: songCubit.positionStream,
        onCountdownComplete: () async {
          await songCubit.seekSong(startPos);
          if (songCubit.state.isLoopModeEnabled && activeLoop != null) {
            await songCubit.togglePlayLoop(activeLoop);
          } else {
            await songCubit.togglePlaySong();
          }
        },
      );
    }
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
