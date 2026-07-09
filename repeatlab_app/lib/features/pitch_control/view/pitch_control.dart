import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/ui/motion.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';
import 'package:repeatlab/core/utils/musical_key.dart';
import 'package:repeatlab/features/pitch_control/widget/pitch_control_key_mode.dart';
import 'package:repeatlab/features/pitch_control/widget/pitch_control_slider.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/l10n/l10n.dart';

/// Pitch control widget that reads and updates state directly from SongCubit,
/// mirroring the SpeedControl card. Hides itself when pitch shifting is not
/// supported for the current song/platform (audio on iOS).
final class PitchControl extends StatefulWidget {
  const PitchControl({super.key});

  @override
  State<PitchControl> createState() => _PitchControlState();
}

class _PitchControlState extends State<PitchControl> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (!context.read<SongCubit>().isPitchControlSupported) {
      return const SizedBox.shrink();
    }

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
        final pitchSemitones = data.pitchSemitones;
        final pitchMode = data.pitchMode;

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
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
                      child: Row(
                        children: [
                          Flexible(
                            child: AutoSizeText(
                              minFontSize: 14,
                              maxFontSize: 24,
                              context.l10n.pitchControl,
                              style: context.titleLarge.copyWith(
                                color: AppColors.secondaryFixed,
                              ),
                            ),
                          ),
                          if (data.musicalKey != null) ...[
                            const SizedBox(width: 8),
                            AnimatedSwitcher(
                              duration: Motion.of(context, Motion.fast),
                              switchInCurve: Motion.enter,
                              switchOutCurve: Motion.exit,
                              transitionBuilder: (child, animation) =>
                                  FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.3),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  ),
                              child: Text(
                                _formatKey(data.musicalKey!, pitchSemitones),
                                key: ValueKey(
                                  _formatKey(data.musicalKey!, pitchSemitones),
                                ),
                                style: context.labelLarge.copyWith(
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
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
                          pitchMode == PitchMode.semitones,
                          pitchMode == PitchMode.key,
                        ],
                        onPressed: (index) =>
                            _onChangePitchMode(context, index),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
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
                              key: const Key('song.pitch.reset'),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _onResetPitch(context),
                              icon: const Icon(
                                Icons.refresh_rounded,
                                color: AppColors.secondaryFixed,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 32,
                            child: IconButton(
                              key: const Key('song.pitch.expand'),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: _onToggleExpand,
                              icon: AnimatedRotation(
                                turns: _isExpanded ? 0.5 : 0,
                                duration: Motion.of(context, Motion.standard),
                                curve: Motion.emphasized,
                                child: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.secondaryFixed,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // AnimatedSize makes expand/collapse (and mode switches) glide
                // instead of snapping.
                AnimatedSize(
                  duration: Motion.of(context, Motion.standard),
                  curve: Motion.emphasized,
                  alignment: Alignment.topCenter,
                  child: !_isExpanded
                      ? const SizedBox(width: double.infinity)
                      : pitchMode == PitchMode.semitones
                      ? PitchControlSlider(
                          pitchSemitones: pitchSemitones,
                          musicalKey: data.musicalKey,
                        )
                      : const PitchControlKeyMode(),
                ),
              ],
            ),
          ),
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

  void _onToggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _onChangePitchMode(BuildContext context, int index) {
    final newMode = index == 0 ? PitchMode.semitones : PitchMode.key;
    context.read<SongCubit>().setPitchMode(newMode);

    if (!_isExpanded) {
      setState(() {
        _isExpanded = true;
      });
    }

    if (index == 0) {
      AppAnalytics.trackEvent(AppAnalytics.clickPitchModeSemitones);
    } else {
      AppAnalytics.trackEvent(AppAnalytics.clickPitchModeKey);
    }
  }

  void _onResetPitch(BuildContext context) {
    dev.log('onResetPitch', name: 'PitchControl');
    context.read<SongCubit>().resetPitch();
  }
}
