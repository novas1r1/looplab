part of 'premium_subscription_cubit.dart';

@MappableClass()
class PremiumSubscriptionState with PremiumSubscriptionStateMappable {
  final PremiumSubscriptionStatus status;
  // final bool isConnected;
  final String? errorMessage;

  const PremiumSubscriptionState({
    this.status = PremiumSubscriptionStatus.initial,
    // this.isConnected = true,
    this.errorMessage,
  });
}

enum PremiumSubscriptionStatus {
  initial,
  subscribed,
  notSubscribed,
  failure,
}
