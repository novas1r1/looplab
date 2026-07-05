import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_auto_size_text/flutter_auto_size_text.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';
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

    return BlocSelector<SongCubit, SongState, int>(
      selector: (state) => state.pitchSemitones,
      builder: (context, pitchSemitones) {
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
                      child: AutoSizeText(
                        minFontSize: 14,
                        maxFontSize: 24,
                        context.l10n.pitchControl,
                        style: context.titleLarge.copyWith(
                          color: AppColors.secondaryFixed,
                        ),
                      ),
                    ),
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
                if (_isExpanded)
                  PitchControlSlider(
                    pitchSemitones: pitchSemitones,
                  ),
              ],
            ),
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

  void _onResetPitch(BuildContext context) {
    dev.log('onResetPitch', name: 'PitchControl');
    context.read<SongCubit>().resetPitch();
  }
}
