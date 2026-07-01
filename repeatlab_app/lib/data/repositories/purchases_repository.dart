import 'dart:developer';
import 'dart:io';

import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PurchasesRepository {
  const PurchasesRepository();

  /// Reserved RevenueCat subscriber attribute the RevenueCat → PostHog
  /// integration reads to align identities. See [linkPostHogIdentity].
  static const kPostHogUserIdAttribute = r'$posthogUserId';

  /// Custom subscriber attribute carrying the paywall trigger so it rides
  /// along on the server-side `rc_*` events. See [setPaywallSource].
  static const kPaywallSourceAttribute = 'last_paywall_source';

  /// Aligns RevenueCat's identity with PostHog so the server-side
  /// RevenueCat → PostHog integration attributes purchase / trial / renewal
  /// events to the SAME person as the in-app client events.
  ///
  /// RevenueCat sends events keyed on the [kPostHogUserIdAttribute] subscriber
  /// attribute, falling back to its own anonymous app-user-id when unset. We
  /// configure RevenueCat anonymously (no `appUserID`) and never call PostHog
  /// `identify()`, so without this the two anonymous ids diverge and the
  /// monetization funnel can't connect paywall views to purchases.
  ///
  /// Consent-gated: when [consented] is false the attribute is CLEARED (an
  /// empty string deletes it in RevenueCat) so opted-out users' server events
  /// fall back to an unlinked anonymous id and never build a PostHog person.
  static Future<void> linkPostHogIdentity({required bool consented}) async {
    try {
      if (consented) {
        final distinctId = await Posthog().getDistinctId();
        await Purchases.setAttributes({kPostHogUserIdAttribute: distinctId});
      } else {
        await Purchases.setAttributes({kPostHogUserIdAttribute: ''});
      }
    } catch (error) {
      // Best-effort; analytics wiring must never break purchases or startup.
      log('Failed to sync PostHog identity to RevenueCat: $error');
    }
  }

  /// Records the trigger that opened the paywall as a RevenueCat subscriber
  /// attribute so it appears on the server-side `rc_*` events (which otherwise
  /// carry no client context). Keeps "which trigger converts" answerable once
  /// the purchase funnel is built on the RevenueCat events.
  static Future<void> setPaywallSource(String source) async {
    try {
      await Purchases.setAttributes({kPaywallSourceAttribute: source});
    } catch (error) {
      log('Failed to set last_paywall_source on RevenueCat: $error');
    }
  }

  Future<void> setup() async {
    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration? configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(
        'goog_NhdNoPthClDEMfKSoFnpljqybdX',
      );
    } else if (Platform.isIOS) {
      configuration = PurchasesConfiguration(
        'appl_sUAEypMdINdSIzcVlkUWvVZPjlN',
      );
    }

    if (configuration != null) {
      await Purchases.configure(configuration);
    }
  }

  Future<bool> get hasWeeklySubscription async {
    final purchaserInfo = await Purchases.getCustomerInfo();

    if (purchaserInfo.activeSubscriptions.contains('repeatlab_full_weekly')) {
      log(
        '--- REVENUECAT: WEEKLY SUBSCRIPTION ACTIVE (via activeSubscriptions)',
      );
      return true;
    }

    // Fallback: check entitlements (activeSubscriptions can be empty in sandbox)
    final proEntitlement = purchaserInfo.entitlements.all['Pro'];
    if (proEntitlement?.isActive == true &&
        proEntitlement?.productIdentifier == 'repeatlab_full_weekly') {
      log('--- REVENUECAT: WEEKLY SUBSCRIPTION ACTIVE (via entitlement)');
      return true;
    }

    log('--- REVENUECAT: WEEKLY SUBSCRIPTION NOT ACTIVE');
    return false;
  }

  Future<bool> get hasYearlySubscription async {
    final purchaserInfo = await Purchases.getCustomerInfo();

    if (purchaserInfo.activeSubscriptions.contains('repeatlab_full_yearly')) {
      log(
        '--- REVENUECAT: YEARLY SUBSCRIPTION ACTIVE (via activeSubscriptions)',
      );
      return true;
    }

    // Fallback: check entitlements (activeSubscriptions can be empty in sandbox)
    final proEntitlement = purchaserInfo.entitlements.all['Pro'];
    if (proEntitlement?.isActive == true &&
        proEntitlement?.productIdentifier == 'repeatlab_full_yearly') {
      log('--- REVENUECAT: YEARLY SUBSCRIPTION ACTIVE (via entitlement)');
      return true;
    }

    log('--- REVENUECAT: YEARLY SUBSCRIPTION NOT ACTIVE');
    return false;
  }

  Future<bool> get hasLifetimePurchase async {
    final purchaserInfo = await Purchases.getCustomerInfo();

    final proEntitlement = purchaserInfo.entitlements.all['Pro'];
    log('--- REVENUECAT: LIFETIME PURCHASE ENTITLEMENT: $proEntitlement');

    // Only treat as lifetime if the entitlement is active AND not from a subscription product
    if (proEntitlement?.isActive == true &&
        proEntitlement?.productIdentifier != 'repeatlab_full_weekly' &&
        proEntitlement?.productIdentifier != 'repeatlab_full_yearly') {
      log('--- REVENUECAT: LIFETIME PURCHASE ACTIVE');
      return true;
    }

    log('--- REVENUECAT: NO ACTIVE LIFETIME PURCHASE');
    return false;
  }

  Future<List<Offering>> get offers async {
    log('--- REVENUECAT: getOfferings()');
    final offerings = await Purchases.getOfferings();

    return offerings.current != null &&
            offerings.current!.availablePackages.isNotEmpty
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

    final eligibilityMap =
        await Purchases.checkTrialOrIntroductoryPriceEligibility(
          productIdentifiers,
        );

    // User is eligible if any product has an intro eligible status
    return eligibilityMap.values.any(
      (eligibility) =>
          eligibility.status ==
          IntroEligibilityStatus.introEligibilityStatusEligible,
    );
  }

  Future<CustomerInfo> restorePurchases() async {
    return await Purchases.restorePurchases();
  }

  Future<CustomerInfo> get revenueCatUser async {
    return await Purchases.getCustomerInfo();
  }
}
