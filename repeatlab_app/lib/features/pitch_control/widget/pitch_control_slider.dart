import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/musical_key.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
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
  bool _paywallShowing = false;

  String _formatSemitones(int semitones) {
    if (semitones > 0) return '+$semitones';
    if (semitones < 0) return '−${-semitones}';
    return '0';
  }

  /// "Semitones" alone, or "Semitones · C♯m" when the song's key is known.
  String _subtitle(BuildContext context) {
    final key = widget.musicalKey;
    final label = context.l10n.semitones;
    if (key == null) return label;
    final transposed = MusicalKey.transpose(key, widget.pitchSemitones);
    if (transposed == null) return label;
    return '$label · ${MusicalKey.displayLabel(transposed)}';
  }

  @override
  Widget build(BuildContext context) {
    final hasPremium = context.watch<PremiumSubscriptionCubit>().hasPremium;
    final pitch = widget.pitchSemitones;
    const min = SongCubit.minPitchSemitones;
    const max = SongCubit.maxPitchSemitones;

    return ControlStepper(
      value: _formatSemitones(pitch),
      subtitle: _subtitle(context),
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
