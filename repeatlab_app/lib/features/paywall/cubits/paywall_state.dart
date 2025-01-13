part of 'paywall_cubit.dart';

@MappableClass()
class PaywallState with PaywallStateMappable {
  final PaywallStatus status;
  final PaywallResult? paywallResult;
  final bool hasPurchased;

  const PaywallState({
    this.status = PaywallStatus.initial,
    this.hasPurchased = false,
    this.paywallResult,
  });
}

@MappableEnum()
enum PaywallStatus {
  initial,
  loading,
  loaded,
  error,
}
