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

  Future<bool> get hasWeeklySubscription async {
    final purchaserInfo = await Purchases.getCustomerInfo();

    if (purchaserInfo.activeSubscriptions.contains('repeatlab_full_weekly')) {
      log('--- REVENUECAT: WEEKLY SUBSCRIPTION ACTIVE');
      return true;
    }

    log('--- REVENUECAT: WEEKLY SUBSCRIPTION NOT ACTIVE');
    return false;
  }

  Future<bool> get hasYearlySubscription async {
    final purchaserInfo = await Purchases.getCustomerInfo();

    if (purchaserInfo.activeSubscriptions.contains('repeatlab_full_yearly')) {
      log('--- REVENUECAT: YEARLY SUBSCRIPTION ACTIVE');
      return true;
    }

    log('--- REVENUECAT: YEARLY SUBSCRIPTION NOT ACTIVE');
    return false;
  }

  Future<bool> get hasLifetimePurchase async {
    final purchaserInfo = await Purchases.getCustomerInfo();

    // Check for lifetime purchase through entitlements
    final proEntitlement = purchaserInfo.entitlements.all['Pro'];
    if (proEntitlement?.isActive == true) {
      log('--- REVENUECAT: LIFETIME PURCHASE ACTIVE');
      return true;
    }

    log('--- REVENUECAT: NO ACTIVE LIFETIME PURCHASE');
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

    final purchaseParams = PurchaseParams.package(package);
    final purchaserInfo = await Purchases.purchase(purchaseParams);

    final proEntitlement = purchaserInfo.customerInfo.entitlements.all['Pro'];

    if (proEntitlement == null) {
      throw Exception('REVENUECAT: Entitlement not found. $purchaserInfo');
    }

    return proEntitlement.isActive;
  }

  Future<void> presentCodeRedemptionSheet() async {
    log('--- REVENUECAT: presentCodeRedemptionSheet()');

    await Purchases.presentCodeRedemptionSheet();
  }

  Future<bool> checkTrialEligibility(List<String> productIdentifiers) async {
    log('--- REVENUECAT: checkTrialEligibility()');

    final eligibilityMap = await Purchases.checkTrialOrIntroductoryPriceEligibility(
      productIdentifiers,
    );

    // User is eligible if any product has an intro eligible status
    return eligibilityMap.values.any(
      (eligibility) => eligibility.status == IntroEligibilityStatus.introEligibilityStatusEligible,
    );
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
