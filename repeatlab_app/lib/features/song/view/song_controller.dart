import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/duration_extension.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/features/paywall/premium_screen.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';

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
              /* Expanded(
                child: BlocSelector<SongCubit, SongState, Duration>(
                  selector: (state) => state.position ?? Duration.zero,
                  builder: (context, position) => RepaintBoundary(
                    child: Text(position.toFormattedString()),
                  ),
                ),
              ), */
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
                      !(playerState?.playing ?? false)
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => context.read<SongCubit>().forward(10),
                icon: const Icon(Icons.forward_10_rounded),
              ),
              /* Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: BlocSelector<SongCubit, SongState, Duration>(
                    selector: (state) => state.song.duration,
                    builder: (context, duration) => Text(duration.toFormattedString()),
                  ),
                ),
              ), */
            ],
          ),
        ),
        const SizedBox(height: 8),
        /* Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: BlocSelector<SongCubit, SongState, double>(
            selector: (state) => state.speed,
            builder: (context, speed) {
              return Row(
                children: [
                  const Icon(Icons.speed),
                  Expanded(
                    child: Slider(
                      value: speed,
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      label: '${speed.toStringAsFixed(1)}x',
                      onChanged: (value) => _onUpdateSpeed(context, value),
                    ),
                  ),
                  Text('${speed.toStringAsFixed(1)}x'),
                ],
              );
            },
          ),
        ), */
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

  Future<void> _onUpdateSpeed(BuildContext context, double value) async {
    AppAnalytics.trackEvent(AppAnalytics.clickUpdateSpeed, data: {'speed': value});

    final hasPurchased = context.read<PremiumSubscriptionCubit>().hasPremium;

    if (!context.mounted) return;

    if (hasPurchased) {
      context.read<SongCubit>().updateSpeed(value);
    } else {
      AppAnalytics.trackEvent(AppAnalytics.showPaywallSongSpeed);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const PremiumScreen(),
        ),
      );
    }
  }
}
