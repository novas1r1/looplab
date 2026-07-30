import 'package:flutter/material.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';
import 'package:repeatlab/core/utils/musical_key.dart';
import 'package:repeatlab/features/pitch_control/widget/edit_song_key_dialog.dart';
import 'package:repeatlab/features/pitch_control/widget/pitch_key_grid.dart';
import 'package:repeatlab/features/pitch_control/widget/set_song_key_panel.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/l10n/l10n.dart';

/// Key mode for pitch control (mirrors [SpeedControlBpmMode]).
/// Reads state from SongCubit.
class PitchControlKeyMode extends StatefulWidget {
  const PitchControlKeyMode({super.key});

  @override
  State<PitchControlKeyMode> createState() => _PitchControlKeyModeState();
}

class _PitchControlKeyModeState extends State<PitchControlKeyMode> {
  @override
  Widget build(BuildContext context) {
    // Premium gating lives in PitchKeyGrid: transposing is paid, but naming
    // your own song's key is metadata and stays free.
    return BlocSelector<SongCubit, SongState,
        ({String? musicalKey, int pitchSemitones, int fineTuneCents})>(
      selector: (state) => (
        musicalKey: state.song.musicalKey,
        pitchSemitones: state.pitchSemitones,
        fineTuneCents: state.fineTuneCents,
      ),
      builder: (context, data) {
        final originalKey = data.musicalKey;

        // If the original key is not set, ask for it first — transposing by
        // key is meaningless without a reference. Never paywalled: naming your
        // own song is metadata, not a feature.
        if (originalKey == null) {
          return SetSongKeyPanel(
            key: const Key('song.pitch.keyOriginal'),
            onKeySelected: (key) => _onSetOriginalKey(context, key),
          );
        }

        final currentKey =
            MusicalKey.transpose(originalKey, data.pitchSemitones) ??
                originalKey;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Original key tile — the whole tile edits the key, with an
                  // ink response so it reads as a button rather than a label
                  // with a small icon.
                  Material(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      key: const Key('song.pitch.editOriginalKey'),
                      onTap: () => _showEditOriginalKeyDialog(
                        context,
                        originalKey,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AutoSizeText(
                                  context.l10n.originalKey,
                                  minFontSize: 14,
                                  maxFontSize: 24,
                                  style: context.bodySmall.copyWith(
                                    color: AppColors.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.edit,
                                  size: 14,
                                  color: AppColors.onPrimaryContainer.withAlpha(
                                    180,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              MusicalKey.displayLabel(originalKey),
                              style: context.titleMedium.copyWith(
                                color: AppColors.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Current key tile - read-only, shows the shift
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText(
                          context.l10n.currentKey,
                          minFontSize: 14,
                          maxFontSize: 24,
                          style: context.bodySmall.copyWith(
                            color: AppColors.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          _formatCurrentKey(
                            currentKey,
                            data.pitchSemitones,
                            data.fineTuneCents,
                          ),
                          style: context.titleMedium.copyWith(
                            color: AppColors.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // The grid replaces a dropdown: the offset badges make the cost
              // of each target key visible, which is the thing a player
              // actually decides on.
              PitchKeyGrid(
                originalKey: originalKey,
                pitchSemitones: data.pitchSemitones,
              ),
            ],
          ),
        );
      },
    );
  }

  /// "Cm (+3 st +18 ct)" — key plus what got it there. The cents are named
  /// because with a fine tune applied the song is not exactly in that key.
  String _formatCurrentKey(
    String currentKey,
    int pitchSemitones,
    int fineTuneCents,
  ) {
    final parts = [
      if (pitchSemitones != 0) '${_signed(pitchSemitones)} st',
      if (fineTuneCents != 0) '${_signed(fineTuneCents)} ct',
    ];
    if (parts.isEmpty) return currentKey;
    return '$currentKey (${parts.join(' ')})';
  }

  String _signed(int value) =>
      value > 0 ? '+$value' : '−${-value}';

  void _onSetOriginalKey(BuildContext context, String? key) {
    if (key == null) return;
    AppAnalytics.trackEvent(
      AppAnalytics.clickSetOriginalKey,
      data: {'key': key, 'source': 'key_mode'},
    );
    context.read<SongCubit>().setOriginalKey(key);
  }

  Future<void> _showEditOriginalKeyDialog(
    BuildContext context,
    String currentOriginalKey,
  ) async {
    final cubit = context.read<SongCubit>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: cubit,
        child: EditSongKeyDialog(currentOriginalKey: currentOriginalKey),
      ),
    );
  }
}
