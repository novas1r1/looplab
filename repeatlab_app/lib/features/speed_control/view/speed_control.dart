import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
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
  final _isExpanded = ValueNotifier<bool>(false);

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
        spacing: 4,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AutoSizeText(
                  minFontSize: 14,
                  maxFontSize: 24,
                  context.l10n.speedControl,
                  style: context.titleLarge.copyWith(
                    color: AppColors.secondaryFixed,
                  ),
                ),
              ),
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
                    AutoSizeText(
                      '×',
                      minFontSize: 20,
                      maxFontSize: 24,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    AutoSizeText(
                      'BPM',
                      minFontSize: 16,
                      maxFontSize: 24,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
                    SizedBox(
                      height: 32,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _onToggleExpand(context),
                        icon: Icon(
                          _isExpanded.value
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: AppColors.secondaryFixed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isExpanded.value && tempoMode == TempoMode.multiplier)
            SpeedControlMultiplierMode(
              initialSpeedMultiplier: speedMultiplier,
              onSpeedMultiplierChanged: widget.onSpeedMultiplierChanged,
            ),
          if (_isExpanded.value && tempoMode == TempoMode.bpm)
            SpeedControlBpmMode(
              onOriginalBpmChanged: widget.onOriginalBpmChanged,
              onSpeedBpmChanged: widget.onSpeedBpmChanged,
            ),
        ],
      ),
    );
  }

  void _onToggleExpand(BuildContext context) {
    setState(() {
      _isExpanded.value = !_isExpanded.value;
    });
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
