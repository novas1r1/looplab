import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/features/speed_control/widget/speed_control_bpm_mode.dart';
import 'package:repeatlab/features/speed_control/widget/speed_control_multiplier_mode.dart';
import 'package:repeatlab/l10n/l10n.dart';

/// Speed control widget that reads and updates state directly from SongCubit.
/// No longer uses a separate SpeedControlCubit - all state is managed in SongCubit.
final class SpeedControl extends StatefulWidget {
  const SpeedControl({super.key});

  @override
  State<SpeedControl> createState() => _SpeedControlState();
}

class _SpeedControlState extends State<SpeedControl> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      SongCubit,
      SongState,
      ({TempoMode tempoMode, double speed, int? currentBpm})
    >(
      selector: (state) => (
        tempoMode: state.tempoMode,
        speed: state.speed,
        currentBpm: state.currentBpm,
      ),
      builder: (context, data) {
        final tempoMode = data.tempoMode;
        final speed = data.speed;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(
            8,
          ).copyWith(right: 0, top: 8, bottom: 8),
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
                      key: const Key('song.speed.toggleMode'),
                      borderRadius: BorderRadius.circular(10),
                      selectedColor: AppColors.onPrimaryContainer,
                      color: AppColors.secondary,
                      fillColor: AppColors.primaryContainer,
                      disabledColor: AppColors.secondary,
                      isSelected: [
                        tempoMode == TempoMode.multiplier,
                        tempoMode == TempoMode.bpm,
                      ],
                      onPressed: (index) => _onChangeTempoMode(context, index),
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
                            key: const Key('song.speed.reset'),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _onResetSpeed(context),
                            icon: const Icon(
                              Icons.refresh_rounded,
                              color: AppColors.secondaryFixed,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 32,
                          child: IconButton(
                            key: const Key('song.speed.expand'),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: _onToggleExpand,
                            icon: Icon(
                              _isExpanded
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
              if (_isExpanded && tempoMode == TempoMode.multiplier)
                SpeedControlMultiplierMode(
                  speed: speed,
                ),
              if (_isExpanded && tempoMode == TempoMode.bpm)
                const SpeedControlBpmMode(),
            ],
          ),
        );
      },
    );
  }

  void _onToggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _onChangeTempoMode(BuildContext context, int index) {
    final newMode = index == 0 ? TempoMode.multiplier : TempoMode.bpm;
    context.read<SongCubit>().setTempoMode(newMode);

    if (!_isExpanded) {
      setState(() {
        _isExpanded = true;
      });
    }

    if (index == 0) {
      AppAnalytics.trackEvent(AppAnalytics.clickTempoModeMultiplier);
    } else {
      AppAnalytics.trackEvent(AppAnalytics.clickTempoModeBpm);
    }
  }

  void _onResetSpeed(BuildContext context) {
    dev.log('onResetSpeed', name: 'SpeedControl');
    context.read<SongCubit>().resetSpeed();
  }
}
