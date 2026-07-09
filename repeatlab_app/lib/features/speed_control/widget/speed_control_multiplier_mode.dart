import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/ui/interaction/custom_slider.dart';
import 'package:repeatlab/core/ui/motion.dart';
import 'package:repeatlab/core/ui/motion_widgets.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';

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
  final _shakeKey = GlobalKey<ShakeOnDeniedState>();

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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: AnimatedSwitcher(
            duration: Motion.of(context, Motion.fast),
            switchInCurve: Motion.enter,
            switchOutCurve: Motion.exit,
            transitionBuilder: (child, animation) => FadeTransition(
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
              '${_localSpeed.toStringAsFixed(1)}×',
              key: ValueKey(_localSpeed.toStringAsFixed(1)),
              style: context.titleMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.onPrimaryContainer,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Min speed label
        Text('0.5×', style: context.labelLarge),
        // Speed slider
        Expanded(
          child: hasPremium
              ? CustomSlider(
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
                )
              : Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (_) {
                    _shakeKey.currentState?.shake();
                    _showPremiumDialog(context);
                  },
                  child: AbsorbPointer(
                    child: ShakeOnDenied(
                      key: _shakeKey,
                      child: CustomSlider(
                        value: _localSpeed,
                        min: 0.5,
                        max: 2.0,
                        divisions: 15,
                        onChanged: (_) {},
                      ),
                    ),
                  ),
                ),
        ),
        // Max speed label
        Text('2.0×', style: context.labelLarge),
        const SizedBox(width: 8),
      ],
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
