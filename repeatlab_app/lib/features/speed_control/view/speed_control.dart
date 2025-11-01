import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/features/speed_control/cubit/speed_control_cubit.dart';
import 'package:repeatlab/features/speed_control/widget/speed_control_bpm_mode.dart';
import 'package:repeatlab/features/speed_control/widget/speed_control_multiplier_mode.dart';
import 'package:repeatlab/l10n/l10n.dart';

final class SpeedControl extends StatelessWidget {
  final Song song;
  final void Function(double) onSpeedMultiplierChanged;
  final void Function(int?) onOriginalBpmChanged;
  final void Function(int?) onSpeedBpmChanged;

  const SpeedControl({
    required this.song,
    required this.onSpeedMultiplierChanged,
    required this.onOriginalBpmChanged,
    required this.onSpeedBpmChanged,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SpeedControlCubit(song: song),
      child: _SpeedControlView(
        song: song,
        onSpeedMultiplierChanged: onSpeedMultiplierChanged,
        onOriginalBpmChanged: onOriginalBpmChanged,
        onSpeedBpmChanged: onSpeedBpmChanged,
      ),
    );
  }
}

class _SpeedControlView extends StatefulWidget {
  final Song song;
  final void Function(double) onSpeedMultiplierChanged;
  final void Function(int?) onOriginalBpmChanged;
  final void Function(int?) onSpeedBpmChanged;

  const _SpeedControlView({
    required this.song,
    required this.onSpeedMultiplierChanged,
    required this.onOriginalBpmChanged,
    required this.onSpeedBpmChanged,
  });

  @override
  State<_SpeedControlView> createState() => _SpeedControlState();
}

class _SpeedControlState extends State<_SpeedControlView> {
  @override
  Widget build(BuildContext context) {
    final tempoMode = context.watch<SpeedControlCubit>().state.tempoMode;
    final speedMultiplier = context.watch<SpeedControlCubit>().state.speedMultiplier;
    final currentBpm = context.watch<SpeedControlCubit>().state.currentBpm;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(8).copyWith(right: 0, top: 8, bottom: 8),
      child: Column(
        children: [
          // Header with tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.speedControl,
                style: context.titleLarge.copyWith(
                  color: AppColors.secondaryFixed,
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 36,
                child: ToggleButtons(
                  borderRadius: BorderRadius.circular(10),
                  selectedColor: AppColors.onPrimaryContainer,
                  color: AppColors.secondary,
                  fillColor: AppColors.primaryContainer,
                  disabledColor: AppColors.secondary,
                  isSelected: [tempoMode == TempoMode.multiplier, tempoMode == TempoMode.bpm],
                  onPressed: (index) => _onChangeTempoMode(index, speedMultiplier, currentBpm),
                  children: const [
                    Text(
                      '×',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    Text(
                      'BPM',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _onResetSpeed(tempoMode),
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.secondaryFixed,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
          if (tempoMode == TempoMode.multiplier)
            SpeedControlMultiplierMode(
              initialSpeedMultiplier: speedMultiplier,
              onSpeedMultiplierChanged: widget.onSpeedMultiplierChanged,
            ),
          if (tempoMode == TempoMode.bpm)
            SpeedControlBpmMode(
              onOriginalBpmChanged: widget.onOriginalBpmChanged,
              onSpeedBpmChanged: widget.onSpeedBpmChanged,
            ),
        ],
      ),
    );
  }

  void _onChangeTempoMode(
    int index,
    double? speedMultiplier,
    int? currentBpm,
  ) {
    context.read<SpeedControlCubit>().setTempoMode(
      index == 0 ? TempoMode.multiplier : TempoMode.bpm,
    );

    if (index == 0) {
      // change track speed to multiplier mode value
      widget.onSpeedMultiplierChanged(speedMultiplier ?? 1.0);
      AppAnalytics.trackEvent(
        AppAnalytics.clickTempoModeMultiplier,
      );
    } else {
      // change track speed to bpm mode value
      widget.onSpeedBpmChanged(currentBpm);
      AppAnalytics.trackEvent(
        AppAnalytics.clickTempoModeBpm,
      );
    }
  }

  void _onResetSpeed(TempoMode tempoMode) {
    dev.log('onResetSpeed', name: 'SpeedControlView');
    context.read<SpeedControlCubit>().resetSpeed();

    final originalBpm = context.read<SpeedControlCubit>().state.originalBpm;

    if (tempoMode == TempoMode.multiplier) {
      widget.onSpeedMultiplierChanged(1.0);
    } else {
      widget.onOriginalBpmChanged(originalBpm);
      widget.onSpeedBpmChanged(originalBpm);
    }
  }
}
