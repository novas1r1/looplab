import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/motion.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';

class PremiumWrapper extends StatelessWidget {
  final Widget child;
  const PremiumWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PremiumSubscriptionCubit, PremiumSubscriptionState>(
      builder: (context, state) {
        final hasPremium =
            state.hasWeeklySubscription ||
            state.hasYearlySubscription ||
            state.hasLifetimePurchase;
        // On unlock the gated content fades/scales in while the layout grows
        // smoothly instead of jumping.
        return AnimatedSize(
          duration: Motion.of(context, Motion.standard),
          curve: Motion.emphasized,
          child: AnimatedSwitcher(
            duration: Motion.of(context, Motion.standard),
            switchInCurve: Motion.enter,
            switchOutCurve: Motion.exit,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1).animate(animation),
                child: child,
              ),
            ),
            child: hasPremium
                ? KeyedSubtree(key: const ValueKey(true), child: child)
                : const SizedBox.shrink(key: ValueKey(false)),
          ),
        );
      },
    );
  }
}

// Paywall V1
/* class PremiumWrapper extends StatelessWidget {
  final Widget child;
  const PremiumWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaywallCubit, PaywallState>(
      builder: (context, state) {
        return state.hasPurchased ? child : const SizedBox.shrink();
      },
    );
  }
} */
