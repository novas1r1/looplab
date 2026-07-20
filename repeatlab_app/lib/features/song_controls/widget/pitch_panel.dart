import 'package:flutter/material.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';
import 'package:repeatlab/core/utils/musical_key.dart';
import 'package:repeatlab/features/pitch_control/widget/pitch_control_key_mode.dart';
import 'package:repeatlab/features/pitch_control/widget/pitch_control_slider.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/l10n/l10n.dart';

/// Pitch tab of the SongControlsCard: the st|key mode toggle, the key label
/// ("Am → Cm" when shifted) and the unchanged slider/key mode widgets
/// (previously the PitchControl card). Only reachable when
/// `SongCubit.isPitchControlSupported` — the card drops the tab otherwise.
class PitchPanel extends StatelessWidget {
  const PitchPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      SongCubit,
      SongState,
      ({int pitchSemitones, String? musicalKey, PitchMode pitchMode})
    >(
      selector: (state) => (
        pitchSemitones: state.pitchSemitones,
        musicalKey: state.song.musicalKey,
        pitchMode: state.pitchMode,
      ),
      builder: (context, data) {
        return Column(
          spacing: 4,
          children: [
            Row(
              children: [
                SizedBox(
                  height: 36,
                  child: ToggleButtons(
                    key: const Key('song.pitch.toggleMode'),
                    borderRadius: BorderRadius.circular(10),
                    selectedColor: AppColors.onPrimaryContainer,
                    color: AppColors.secondary,
                    fillColor: AppColors.primaryContainer,
                    disabledColor: AppColors.secondary,
                    isSelected: [
                      data.pitchMode == PitchMode.semitones,
                      data.pitchMode == PitchMode.key,
                    ],
                    onPressed: (index) => _onChangePitchMode(context, index),
                    children: [
                      const AutoSizeText(
                        'st',
                        minFontSize: 16,
                        maxFontSize: 24,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      AutoSizeText(
                        context.l10n.editSongKey,
                        minFontSize: 12,
                        maxFontSize: 24,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (data.musicalKey != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    _formatKey(data.musicalKey!, data.pitchSemitones),
                    style: context.labelLarge.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ],
            ),
            if (data.pitchMode == PitchMode.semitones)
              PitchControlSlider(
                pitchSemitones: data.pitchSemitones,
                musicalKey: data.musicalKey,
              )
            else
              const PitchControlKeyMode(),
          ],
        );
      },
    );
  }

  /// "Am" at 0 st; "Am → Cm" when shifted. Falls back to the raw tag value
  /// when the key isn't in a transposable format.
  String _formatKey(String musicalKey, int pitchSemitones) {
    if (pitchSemitones == 0) return musicalKey;
    final transposed = MusicalKey.transpose(musicalKey, pitchSemitones);
    if (transposed == null) return musicalKey;
    return '$musicalKey → $transposed';
  }

  void _onChangePitchMode(BuildContext context, int index) {
    final newMode = index == 0 ? PitchMode.semitones : PitchMode.key;
    context.read<SongCubit>().setPitchMode(newMode);

    AppAnalytics.trackEvent(
      index == 0
          ? AppAnalytics.clickPitchModeSemitones
          : AppAnalytics.clickPitchModeKey,
    );
  }
}
