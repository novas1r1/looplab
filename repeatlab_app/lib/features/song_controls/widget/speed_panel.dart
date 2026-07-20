import 'package:flutter/material.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/features/speed_control/widget/speed_control_bpm_mode.dart';
import 'package:repeatlab/features/speed_control/widget/speed_control_multiplier_mode.dart';

/// Speed tab of the SongControlsCard: the ×|BPM mode toggle plus the
/// unchanged multiplier/BPM mode widgets (previously the SpeedControl card).
class SpeedPanel extends StatelessWidget {
  const SpeedPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      SongCubit,
      SongState,
      ({TempoMode tempoMode, double speed})
    >(
      selector: (state) => (
        tempoMode: state.tempoMode,
        speed: state.speed,
      ),
      builder: (context, data) {
        return Column(
          spacing: 4,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                height: 36,
                child: ToggleButtons(
                  key: const Key('song.speed.toggleMode'),
                  borderRadius: BorderRadius.circular(10),
                  selectedColor: AppColors.onPrimaryContainer,
                  color: AppColors.secondary,
                  fillColor: AppColors.primaryContainer,
                  disabledColor: AppColors.secondary,
                  isSelected: [
                    data.tempoMode == TempoMode.multiplier,
                    data.tempoMode == TempoMode.bpm,
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
            ),
            if (data.tempoMode == TempoMode.multiplier)
              SpeedControlMultiplierMode(speed: data.speed)
            else
              const SpeedControlBpmMode(),
          ],
        );
      },
    );
  }

  void _onChangeTempoMode(BuildContext context, int index) {
    final newMode = index == 0 ? TempoMode.multiplier : TempoMode.bpm;
    context.read<SongCubit>().setTempoMode(newMode);

    AppAnalytics.trackEvent(
      index == 0
          ? AppAnalytics.clickTempoModeMultiplier
          : AppAnalytics.clickTempoModeBpm,
    );
  }
}
