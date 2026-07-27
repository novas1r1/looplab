import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/ui/interaction/pill_toggle.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/features/speed_control/widget/speed_control_bpm_mode.dart';
import 'package:repeatlab/features/speed_control/widget/speed_control_multiplier_mode.dart';
import 'package:repeatlab/l10n/l10n.dart';

/// Speed section of the SongControlsCard: a "Speed" label, the ×|BPM mode
/// toggle and per-section reset, then the multiplier or BPM mode body.
class SpeedPanel extends StatelessWidget {
  const SpeedPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SongCubit, SongState, ({TempoMode tempoMode, double speed})>(
      selector: (state) => (
        tempoMode: state.tempoMode,
        speed: state.speed,
      ),
      builder: (context, data) {
        return Column(
          spacing: 8,
          children: [
            Row(
              children: [
                Text(
                  context.l10n.speedControl,
                  style: context.titleMedium.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                const Spacer(),
                PillToggle(
                  key: const Key('song.speed.toggleMode'),
                  selectedIndex: data.tempoMode == TempoMode.multiplier ? 0 : 1,
                  onChanged: (index) => _onChangeTempoMode(context, index),
                  segments: const [
                    PillSegment(
                      label: '×',
                      key: Key('song.speed.toggleMode.multiplier'),
                      minFontSize: 16,
                      maxFontSize: 22,
                    ),
                    PillSegment(
                      label: 'BPM',
                      key: Key('song.speed.toggleMode.bpm'),
                      minFontSize: 14,
                    ),
                  ],
                ),
                /* const SizedBox(width: 4),
                IconButton(
                  key: const Key('song.speed.reset'),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  onPressed: () => context.read<SongCubit>().resetSpeed(),
                  icon: const AppIcon(
                    iconName: 'ic_refresh',
                    iconSize: 24,
                    color: AppColors.iconDefault,
                  ),
                ), */
              ],
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
      index == 0 ? AppAnalytics.clickTempoModeMultiplier : AppAnalytics.clickTempoModeBpm,
    );
  }
}
