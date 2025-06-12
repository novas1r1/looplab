import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/duration_extension.dart';
import 'package:repeatlab/data/models/loop.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/features/paywall/premium_screen.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';

class SongController extends StatelessWidget {
  final Duration currentPlayerPosition;
  final Duration songDuration;
  final bool isLoopModeEnabled;
  final Loop? activeLoop;
  final double speed;

  const SongController({
    required this.currentPlayerPosition,
    required this.isLoopModeEnabled,
    required this.activeLoop,
    required this.songDuration,
    required this.speed,
    required super.key,
  });

  @override
  Widget build(BuildContext context) {
    final playerState = context.watch<SongCubit>().state.playerState;
    final isPaused =
        playerState == PlayerState.paused ||
        playerState == null ||
        playerState == PlayerState.stopped;

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
                child: Text(
                  currentPlayerPosition.toFormattedString(),
                ),
              ),
              IconButton(
                onPressed: () => context.read<SongCubit>().back(10),
                icon: const Icon(Icons.replay_10_rounded),
              ),
              const SizedBox(width: 8),
              IconButton(
                iconSize: 36,
                onPressed: () => _onTapPlay(context),
                icon: Icon(
                  isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => context.read<SongCubit>().forward(10),
                icon: const Icon(Icons.forward_10_rounded),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    songDuration.toFormattedString(),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
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
          ),
        ),
      ],
    );
  }

  void _onTapPlay(BuildContext context) {
    if (isLoopModeEnabled) {
      context.read<SongCubit>().togglePlayLoop(activeLoop!);
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
