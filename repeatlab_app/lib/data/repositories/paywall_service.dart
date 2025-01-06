import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

class PaywallRepository {
  const PaywallRepository();

  Future<PaywallResult> presentPaywallIfNeeded() async {
    return await RevenueCatUI.presentPaywallIfNeeded(
      "default",
      displayCloseButton: true,
    );
  }

  Future<PaywallResult> presentPaywall() async {
    return await RevenueCatUI.presentPaywall();
  }
}
