part of 'premium_subscription_cubit.dart';

@MappableClass()
class PremiumSubscriptionState with PremiumSubscriptionStateMappable {
  final PremiumSubscriptionStatus status;
  final bool hasWeeklySubscription;
  final bool hasYearlySubscription;
  final bool hasLifetimePurchase;
  final String? errorMessage;

  const PremiumSubscriptionState({
    this.status = PremiumSubscriptionStatus.initial,
    this.hasWeeklySubscription = false,
    this.hasYearlySubscription = false,
    this.hasLifetimePurchase = false,
    this.errorMessage,
  });
}

enum PremiumSubscriptionStatus {
  initial,
  premium,
  noPremium,
  failure,
}
