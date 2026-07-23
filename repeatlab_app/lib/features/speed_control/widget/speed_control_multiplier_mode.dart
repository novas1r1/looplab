import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/ui/interaction/custom_slider.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/l10n/l10n.dart';

/// Multiplier mode for speed control. Reads state from SongCubit.
class SpeedControlMultiplierMode extends StatefulWidget {
  /// Current speed from SongCubit state
  final double speed;

  const SpeedControlMultiplierMode({
    super.key,
    required this.speed,
  });

  @override
  State<SpeedControlMultiplierMode> createState() =>
      _SpeedControlMultiplierModeState();
}

class _SpeedControlMultiplierModeState
    extends State<SpeedControlMultiplierMode> {
  // Local state for smooth slider interaction
  double _localSpeed = 1.0;
  bool _paywallShowing = false;

  @override
  void initState() {
    super.initState();
    _localSpeed = widget.speed;
  }

  @override
  void didUpdateWidget(SpeedControlMultiplierMode oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync local state when parent state changes (e.g., reset)
    if (oldWidget.speed != widget.speed) {
      setState(() {
        _localSpeed = widget.speed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasPremium = context.watch<PremiumSubscriptionCubit>().hasPremium;

    return Column(
      children: [
        // Large centred multiplier with the "pitch unchanged" caption.
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${_localSpeed.toStringAsFixed(2)}×',
              style: context.displaySmall.copyWith(
                fontWeight: FontWeight.w700,
                height: 1,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.pitchUnchanged,
              style: context.labelSmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text('0.5×', style: context.labelLarge),
            Expanded(
              child: hasPremium
                  ? _slider(context)
                  : Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (_) => _showPremiumDialog(context),
                      child: AbsorbPointer(child: _slider(context)),
                    ),
            ),
            Text('2.0×', style: context.labelLarge),
          ],
        ),
      ],
    );
  }

  Widget _slider(BuildContext context) {
    return CustomSlider(
      value: _localSpeed,
      min: 0.5,
      max: 2.0,
      divisions: 15,
      onChanged: (value) {
        setState(() {
          _localSpeed = value;
        });
      },
      onChangeEnd: (value) {
        dev.log(
          'setSpeedByMultiplier: $value',
          name: 'SpeedControlMultiplierMode',
        );
        AppAnalytics.trackEvent(
          AppAnalytics.clickUpdateSpeed,
          data: {'speed': value},
        );
        context.read<SongCubit>().setSpeedByMultiplier(value);
      },
    );
  }

  Future<void> _showPremiumDialog(BuildContext context) async {
    if (_paywallShowing) return;
    _paywallShowing = true;

    try {
      await context.read<PremiumSubscriptionCubit>().presentPaywall(
        source: 'song_speed',
      );
    } finally {
      if (mounted) {
        _paywallShowing = false;
      }
    }
  }
}
