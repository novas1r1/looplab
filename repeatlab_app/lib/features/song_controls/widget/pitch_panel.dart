import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/ui/interaction/pill_toggle.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';
import 'package:repeatlab/features/pitch_control/widget/pitch_control_key_mode.dart';
import 'package:repeatlab/features/pitch_control/widget/pitch_control_slider.dart';
import 'package:repeatlab/features/pitch_control/widget/pitch_fine_tune_slider.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/l10n/l10n.dart';

/// Pitch section of the SongControlsCard: a "Pitch" label, the Semitone|Key
/// mode toggle and per-section reset, then the semitone stepper or key mode.
class PitchPanel extends StatelessWidget {
  const PitchPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      SongCubit,
      SongState,
      ({
        int pitchSemitones,
        int fineTuneCents,
        String? musicalKey,
        PitchMode pitchMode,
      })
    >(
      selector: (state) => (
        pitchSemitones: state.pitchSemitones,
        fineTuneCents: state.fineTuneCents,
        musicalKey: state.song.musicalKey,
        pitchMode: state.pitchMode,
      ),
      builder: (context, data) {
        return Column(
          spacing: 8,
          children: [
            Row(
              children: [
                Text(
                  context.l10n.pitchControl,
                  style: context.titleMedium.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                const Spacer(),
                PillToggle(
                  key: const Key('song.pitch.toggleMode'),
                  selectedIndex: data.pitchMode == PitchMode.semitones ? 0 : 1,
                  onChanged: (index) => _onChangePitchMode(context, index),
                  segments: [
                    PillSegment(
                      label: context.l10n.pitchSemitone,
                      key: const Key('song.pitch.toggleMode.semitones'),
                    ),
                    PillSegment(
                      label: context.l10n.editSongKey,
                      key: const Key('song.pitch.toggleMode.key'),
                    ),
                  ],
                ),
                /* const SizedBox(width: 4),
                IconButton(
                  key: const Key('song.pitch.reset'),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  onPressed: () => context.read<SongCubit>().resetPitch(),
                  icon: const AppIcon(
                    iconName: 'ic_refresh',
                    iconSize: 24,
                    containerSize: 24,
                  ),
                ), */
              ],
            ),
            if (data.pitchMode == PitchMode.semitones)
              PitchControlSlider(
                pitchSemitones: data.pitchSemitones,
                musicalKey: data.musicalKey,
              )
            else
              const PitchControlKeyMode(),
            // Below the mode body, so it shows in both: a recording sits off
            // pitch regardless of whether you are thinking in semitones or
            // keys, which makes fine tune orthogonal to the mode toggle.
            PitchFineTuneSlider(fineTuneCents: data.fineTuneCents),
          ],
        );
      },
    );
  }

  void _onChangePitchMode(BuildContext context, int index) {
    final newMode = index == 0 ? PitchMode.semitones : PitchMode.key;
    context.read<SongCubit>().setPitchMode(newMode);

    AppAnalytics.trackEvent(
      index == 0 ? AppAnalytics.clickPitchModeSemitones : AppAnalytics.clickPitchModeKey,
    );
  }
}
