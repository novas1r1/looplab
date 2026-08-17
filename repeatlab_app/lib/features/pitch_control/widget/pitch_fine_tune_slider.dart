import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/ui/interaction/custom_slider.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/l10n/l10n.dart';

/// Fine tune in cents — a sub-semitone pitch offset, shown in both semitone
/// and key mode because it is orthogonal to either: a recording sits slightly
/// off pitch regardless of which key you are thinking in.
///
/// Exists because plenty of records were never at A=440 (off-speed masters,
/// vinyl rips, orchestras tuning to 442-445), and a fretted instrument cannot
/// be retuned by 30 cents without fighting its own intonation — so the
/// recording has to move instead.
class PitchFineTuneSlider extends StatefulWidget {
  /// Current fine tune in cents from SongCubit state.
  final int fineTuneCents;

  const PitchFineTuneSlider({
    super.key,
    required this.fineTuneCents,
  });

  @override
  State<PitchFineTuneSlider> createState() => _PitchFineTuneSliderState();
}

class _PitchFineTuneSliderState extends State<PitchFineTuneSlider> {
  /// Local value so the thumb tracks the finger; committed on drag end.
  late int _localCents = widget.fineTuneCents;
  bool _paywallShowing = false;

  @override
  void didUpdateWidget(PitchFineTuneSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Follow external changes (e.g. resetPitch) so the thumb does not stick.
    if (oldWidget.fineTuneCents != widget.fineTuneCents) {
      setState(() {
        _localCents = widget.fineTuneCents;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPremium = context.watch<PremiumSubscriptionCubit>().hasPremium;

    final slider = CustomSlider(
      key: const Key('song.pitch.fineTune'),
      value: _localCents.toDouble(),
      min: SongCubit.minFineTuneCents.toDouble(),
      max: SongCubit.maxFineTuneCents.toDouble(),
      divisions: SongCubit.maxFineTuneCents - SongCubit.minFineTuneCents,
      onChanged: (value) => setState(() => _localCents = value.round()),
      onChangeEnd: (value) => _commit(context, value.round()),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FineTuneReadout(cents: _localCents),
        const SizedBox(height: 4),
        Row(
          children: [
            Text('−50', style: context.labelLarge),
            Expanded(
              child: hasPremium
                  ? slider
                  // onPointerDown fires on the first touch of a drag, and
                  // AbsorbPointer stops the Slider claiming the gesture, so
                  // the paywall opens at drag start rather than drag end.
                  : Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (_) => _showPremiumDialog(context),
                      child: AbsorbPointer(child: slider),
                    ),
            ),
            Text('+50', style: context.labelLarge),
          ],
        ),
      ],
    );
  }

  void _commit(BuildContext context, int cents) {
    AppAnalytics.trackEvent(
      AppAnalytics.clickUpdateFineTune,
      data: {'cents': cents},
    );
    context.read<SongCubit>().setFineTuneCents(cents);
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

/// "Fine tune  0 ct   Match a slightly off-pitch record", where the trailing
/// hint turns into the resulting concert pitch once the control is engaged.
class _FineTuneReadout extends StatelessWidget {
  const _FineTuneReadout({required this.cents});

  final int cents;

  @override
  Widget build(BuildContext context) {
    final engaged = cents != 0;

    return Row(
      children: [
        Text(
          context.l10n.fineTune,
          style: context.labelSmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          context.l10n.fineTuneCentsValue(_formatCents(cents)),
          style: context.labelSmall.copyWith(
            color: engaged ? AppColors.primary : AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        // const SizedBox(width: 8),
        // Expanded(
        //   child: Text(
        //     // Once engaged, the useful number is what the player should tune
        //     // their instrument to — not a restatement of what the slider does.
        //     engaged
        //         ? context.l10n.fineTuneReference(
        //             concertPitchHz(cents).toStringAsFixed(1),
        //           )
        //         : context.l10n.fineTuneHint,
        //     maxLines: 1,
        //     overflow: TextOverflow.ellipsis,
        //     textAlign: TextAlign.right,
        //     style: context.labelSmall.copyWith(
        //       color: AppColors.onSurfaceVariant,
        //     ),
        //   ),
        // ),
      ],
    );
  }

  String _formatCents(int cents) {
    if (cents > 0) return '+$cents';
    if (cents < 0) return '−${-cents}';
    return '0';
  }
}
