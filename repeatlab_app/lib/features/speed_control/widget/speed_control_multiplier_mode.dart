import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/interaction/custom_slider.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/features/paywall/premium_screen.dart';
import 'package:repeatlab/features/speed_control/cubit/speed_control_cubit.dart';

class SpeedControlMultiplierMode extends StatefulWidget {
  final double initialSpeedMultiplier;
  final void Function(double) onSpeedMultiplierChanged;

  const SpeedControlMultiplierMode({
    required this.initialSpeedMultiplier,
    required this.onSpeedMultiplierChanged,
  });

  @override
  State<SpeedControlMultiplierMode> createState() => _SpeedControlMultiplierModeState();
}

class _SpeedControlMultiplierModeState extends State<SpeedControlMultiplierMode> {
  double _speedMultiplier = 1.0;

  @override
  void initState() {
    super.initState();
    _speedMultiplier = widget.initialSpeedMultiplier;
  }

  @override
  void didUpdateWidget(SpeedControlMultiplierMode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSpeedMultiplier != widget.initialSpeedMultiplier) {
      setState(() {
        _speedMultiplier = widget.initialSpeedMultiplier;
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
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${_speedMultiplier.toStringAsFixed(1)}×',
            style: context.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        const SizedBox(width: 8),
        // min speed
        Text('0.5×', style: context.labelLarge),
        // slider
        Expanded(
          child: CustomSlider(
            value: _speedMultiplier,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            onChanged: (value) {
              if (!hasPremium) {
                _showPremiumDialog(context);
                return;
              } else {
                setState(() {
                  _speedMultiplier = value;
                });
              }
            },
            onChangeEnd: (value) {
              if (!hasPremium) {
                _showPremiumDialog(context);
              } else {
                dev.log('updateSpeed: $value', name: 'SpeedControlMultiplierMode');
                context.read<SpeedControlCubit>().setSpeedMultiplier(value);
                widget.onSpeedMultiplierChanged(value);
              }
            },
          ),
        ),
        // max speed
        Text('2.0×', style: context.labelLarge),
        const SizedBox(width: 8),
      ],
    );
  }

  Future<void> _showPremiumDialog(BuildContext context) async {
    AppAnalytics.trackEvent(
      AppAnalytics.viewPremiumScreen,
      data: {
        'from': 'speed_control_multiplier',
      },
    );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PremiumScreen(),
      ),
    );
  }
}
