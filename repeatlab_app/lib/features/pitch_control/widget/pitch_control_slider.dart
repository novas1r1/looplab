import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/ui/interaction/custom_slider.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';
import 'package:repeatlab/core/utils/musical_key.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';

/// Semitone slider for pitch control. Reads state from SongCubit.
class PitchControlSlider extends StatefulWidget {
  /// Current pitch in semitones from SongCubit state
  final int pitchSemitones;

  /// Original key of the song, if known. When set, the value chip shows the
  /// key the drag position translates to, live while dragging.
  final String? musicalKey;

  const PitchControlSlider({
    super.key,
    required this.pitchSemitones,
    this.musicalKey,
  });

  @override
  State<PitchControlSlider> createState() => _PitchControlSliderState();
}

class _PitchControlSliderState extends State<PitchControlSlider> {
  // Local state for smooth slider interaction
  int _localPitch = 0;
  bool _paywallShowing = false;

  @override
  void initState() {
    super.initState();
    _localPitch = widget.pitchSemitones;
  }

  @override
  void didUpdateWidget(PitchControlSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync local state when parent state changes (e.g., reset)
    if (oldWidget.pitchSemitones != widget.pitchSemitones) {
      setState(() {
        _localPitch = widget.pitchSemitones;
      });
    }
  }

  String _formatSemitones(int semitones) {
    if (semitones > 0) return '+$semitones st';
    if (semitones < 0) return '−${-semitones} st';
    return '0 st';
  }

  /// Key the current drag position translates to, tracking [_localPitch]
  /// live while dragging. Null when the song's key is unknown/unparseable.
  String? get _transposedKey {
    final key = widget.musicalKey;
    if (key == null) return null;
    return MusicalKey.transpose(key, _localPitch);
  }

  @override
  Widget build(BuildContext context) {
    final hasPremium = context.watch<PremiumSubscriptionCubit>().hasPremium;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatSemitones(_localPitch),
                style: context.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.onPrimaryContainer,
                ),
              ),
              if (_transposedKey != null)
                Text(
                  _transposedKey!,
                  style: context.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Min pitch label
        Text('−12', style: context.labelLarge),
        // Pitch slider
        Expanded(
          child: hasPremium
              ? CustomSlider(
                  value: _localPitch.toDouble(),
                  min: SongCubit.minPitchSemitones.toDouble(),
                  max: SongCubit.maxPitchSemitones.toDouble(),
                  divisions:
                      SongCubit.maxPitchSemitones - SongCubit.minPitchSemitones,
                  onChanged: (value) {
                    setState(() {
                      _localPitch = value.round();
                    });
                  },
                  onChangeEnd: (value) {
                    dev.log(
                      'setPitchSemitones: ${value.round()}',
                      name: 'PitchControlSlider',
                    );
                    AppAnalytics.trackEvent(
                      AppAnalytics.clickUpdatePitch,
                      data: {'semitones': value.round()},
                    );
                    context.read<SongCubit>().setPitchSemitones(value.round());
                  },
                )
              : Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (_) => _showPremiumDialog(context),
                  child: AbsorbPointer(
                    child: CustomSlider(
                      value: _localPitch.toDouble(),
                      min: SongCubit.minPitchSemitones.toDouble(),
                      max: SongCubit.maxPitchSemitones.toDouble(),
                      divisions:
                          SongCubit.maxPitchSemitones -
                          SongCubit.minPitchSemitones,
                      onChanged: (_) {},
                    ),
                  ),
                ),
        ),
        // Max pitch label
        Text('+12', style: context.labelLarge),
        const SizedBox(width: 8),
      ],
    );
  }

  Future<void> _showPremiumDialog(BuildContext context) async {
    if (_paywallShowing) return;
    _paywallShowing = true;

    try {
      await context.read<PremiumSubscriptionCubit>().presentPaywall(
        source: 'song_pitch',
      );
    } finally {
      if (mounted) {
        _paywallShowing = false;
      }
    }
  }
}
