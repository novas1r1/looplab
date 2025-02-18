import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';

class PremiumWrapper extends StatelessWidget {
  final Widget child;
  const PremiumWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PremiumSubscriptionCubit, PremiumSubscriptionState>(
      builder: (context, state) {
        return state.status == PremiumSubscriptionStatus.subscribed ||
                state.status == PremiumSubscriptionStatus.lifetimePurchased
            ? child
            : const SizedBox.shrink();
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
