import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/musical_key.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/features/pitch_control/util/interval_label.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/features/song_controls/widget/control_stepper.dart';
import 'package:repeatlab/l10n/l10n.dart';

/// Semitone stepper for pitch control. Reads state from SongCubit. Named for
/// historical reasons — the slider became a ± stepper in the redesign.
class PitchControlSlider extends StatefulWidget {
  /// Current pitch in semitones from SongCubit state
  final int pitchSemitones;

  /// Original key of the song, if known. When set, the caption shows the key
  /// the current shift translates to.
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
  /// Beyond this distance the pitch shifter starts producing audible
  /// artifacts, so the caption says so rather than letting users blame the
  /// app. Placeholder value — RL-134 profiles the real boundary; keeping it a
  /// single constant makes that a one-number change.
  static const int cleanRangeSemitones = 5;

  bool _paywallShowing = false;

  String _formatSemitones(int semitones) {
    if (semitones > 0) return '+$semitones';
    if (semitones < 0) return '−${-semitones}';
    return '0';
  }

  /// The interval as a musician would name it ("whole step down"), plus the
  /// resulting key when known, plus a quality caveat for large shifts —
  /// e.g. "whole step down · A♯ / B♭" or "octave up · may sound artificial".
  String _subtitle(BuildContext context) {
    final parts = [intervalLabel(context.l10n, widget.pitchSemitones)];

    final key = widget.musicalKey;
    if (key != null) {
      final transposed = MusicalKey.transpose(key, widget.pitchSemitones);
      if (transposed != null) {
        parts.add(MusicalKey.displayLabel(transposed));
      }
    }

    if (_isOutsideCleanRange) {
      parts.add(context.l10n.pitchQualityWarning);
    }

    return parts.join(' · ');
  }

  bool get _isOutsideCleanRange =>
      widget.pitchSemitones.abs() > cleanRangeSemitones;

  @override
  Widget build(BuildContext context) {
    final hasPremium = context.watch<PremiumSubscriptionCubit>().hasPremium;
    final pitch = widget.pitchSemitones;
    const min = SongCubit.minPitchSemitones;
    const max = SongCubit.maxPitchSemitones;

    return ControlStepper(
      value: _formatSemitones(pitch),
      subtitle: _subtitle(context),
      // A caveat, not a failure — amber rather than the error colour.
      valueColor: _isOutsideCleanRange ? AppColors.warning : null,
      decrementKey: const Key('song.pitch.semitoneMinus'),
      incrementKey: const Key('song.pitch.semitonePlus'),
      onDecrement: pitch > min
          ? () => _onStep(context, pitch - 1, hasPremium: hasPremium)
          : null,
      onIncrement: pitch < max
          ? () => _onStep(context, pitch + 1, hasPremium: hasPremium)
          : null,
    );
  }

  void _onStep(BuildContext context, int semitones, {required bool hasPremium}) {
    if (!hasPremium) {
      _showPremiumDialog(context);
      return;
    }
    AppAnalytics.trackEvent(
      AppAnalytics.clickUpdatePitch,
      data: {'semitones': semitones},
    );
    context.read<SongCubit>().setPitchSemitones(semitones);
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
