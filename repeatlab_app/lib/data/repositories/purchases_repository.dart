import 'dart:developer';
import 'dart:io';

import 'package:purchases_flutter/purchases_flutter.dart';

class PurchasesRepository {
  const PurchasesRepository();

  Future<void> setup() async {
    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration? configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration('goog_NhdNoPthClDEMfKSoFnpljqybdX');
    } else if (Platform.isIOS) {
      configuration = PurchasesConfiguration('appl_sUAEypMdINdSIzcVlkUWvVZPjlN');
    }

    if (configuration != null) {
      await Purchases.configure(configuration);
    }
  }

  Future<bool> get hasActiveSubscription async {
    // always enabled for testing
    // if (FlavorConfig.instance.name == 'DEV') return true;

    final purchaserInfo = await Purchases.getCustomerInfo();

    //drumbitious_149_1m
    if (purchaserInfo.activeSubscriptions.isNotEmpty) {
      log('--- REVENUECAT: SUBSCRIBED');

      return true;
    }

    log('--- REVENUECAT: UNSUBSCRIBED');

    return false;
  }

  Future<List<Offering>> get offers async {
    log('--- REVENUECAT: getOfferings()');
    final offerings = await Purchases.getOfferings();

    return offerings.current != null && offerings.current!.availablePackages.isNotEmpty
        ? [offerings.current!]
        : [];
  }

  // Future<CustomerInfo> get purchaserInfo => Purchases.getCustomerInfo();

  // https://docs.revenuecat.com/docs/displaying-products
  // Future<Offerings> get offerings => Purchases.getOfferings();

  Future<bool> purchase(Package package) async {
    log('--- REVENUECAT: purchase()');

    try {
      final purchaserInfo = await Purchases.purchasePackage(package);

      final proEntitlement = purchaserInfo.entitlements.all['Pro'];

      if (proEntitlement == null) {
        throw Exception('REVENUECAT: Entitlement not found. $purchaserInfo');
      }

      return proEntitlement.isActive;
    } catch (e) {
      print('RevenueCat error: $e');
      rethrow;
    }
  }

  Future<void> presentCodeRedemptionSheet() async {
    log('--- REVENUECAT: presentCodeRedemptionSheet()');

    await Purchases.presentCodeRedemptionSheet();
  }

  Future<CustomerInfo> restorePurchases() async {
    return await Purchases.restorePurchases();
  }

  /// RevenueCatUI Paywall V1
  /* Future<PaywallResult> presentPaywallIfNeeded() async {
    return await RevenueCatUI.presentPaywallIfNeeded(
      "default",
      displayCloseButton: true,
    );
  } */

  /// RevenueCatUI Paywall V1
  /* Future<PaywallResult> presentPaywall() async {
    return await RevenueCatUI.presentPaywall(
      displayCloseButton: true,
    );
  } */
}
