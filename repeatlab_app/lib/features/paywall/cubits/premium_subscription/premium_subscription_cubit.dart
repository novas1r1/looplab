import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/data/repositories/crash_reporting_repository.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
import 'package:repeatlab/data/repositories/purchases_repository.dart';

part 'premium_subscription_cubit.mapper.dart';
part 'premium_subscription_state.dart';

class PremiumSubscriptionCubit extends Cubit<PremiumSubscriptionState> {
  final CrashReportingRepository crashReportingRepository;
  final PurchasesRepository purchasesRepository;

  /// Optional so tests can construct the cubit without preferences. When
  /// provided, [init] uses it to consent-gate the RevenueCat → PostHog
  /// identity link.
  final LocalConfigRepository? localConfigRepository;

  PremiumSubscriptionCubit({
    required this.crashReportingRepository,
    required this.purchasesRepository,
    this.localConfigRepository,
  }) : super(const PremiumSubscriptionState());

  bool get hasPremium =>
      state.hasWeeklySubscription ||
      state.hasYearlySubscription ||
      state.hasLifetimePurchase;

  /// Initializes the [Purchases] SDK.
  /// Checks if the user is subscribed to the premium plan.
  /// Checks if the user has an internet connection.
  Future<void> init() async {
    log('--- REVENUECAT: init()');

    if (Platform.isWindows) {
      emit(
        state.copyWith(
          status: PremiumSubscriptionStatus.premium,
          hasLifetimePurchase: true,
        ),
      );
      return;
    }

    try {
      await purchasesRepository.setup();

      // final isConnected = await purchasesRepository.isConnected;
      // emit(state.copyWith(isConnected: isConnected));

      await checkStatus();

      // Align RevenueCat's server-side PostHog identity with the client so the
      // rc_* purchase/trial/renewal events attribute to the same person as the
      // in-app events. Consent-gated; release-only (native SDKs absent in
      // tests, so localConfigRepository is left null there).
      final config = localConfigRepository;
      if (!kDebugMode && config != null) {
        await PurchasesRepository.linkPostHogIdentity(
          consented: config.acceptedAnalytics,
        );
      }

      /* purchases.addPurchaserInfoUpdateListener((purchaserInfo) {
        if (purchaserInfo.activeSubscriptions.isNotEmpty) {
          subscribe();
        } else {
          unsubscribe();
        }
      }); */
    } catch (ex, stackTrace) {
      crashReportingRepository.reportError(ex, stackTrace);
      emit(
        state.copyWith(
          status: PremiumSubscriptionStatus.failure,
          errorMessage: ex.toString(),
        ),
      );
    }
  }

  Future<void> checkStatus() async {
    if (Platform.isWindows) {
      emit(
        state.copyWith(
          status: PremiumSubscriptionStatus.premium,
          hasLifetimePurchase: true,
        ),
      );
      return;
    }

    /*     if (kDebugMode) {
      emit(state.copyWith(status: PremiumSubscriptionStatus.premium));

      return;
    } */

    try {
      final hasWeeklySubscription =
          await purchasesRepository.hasWeeklySubscription;
      final hasYearlySubscription =
          await purchasesRepository.hasYearlySubscription;

      final hasLifetimePurchase = await purchasesRepository.hasLifetimePurchase;

      log('--- REVENUECAT: hasWeeklySubscription: $hasWeeklySubscription');
      log('--- REVENUECAT: hasYearlySubscription: $hasYearlySubscription');
      log('--- REVENUECAT: hasLifetimePurchase: $hasLifetimePurchase');

      if (hasWeeklySubscription ||
          hasYearlySubscription ||
          hasLifetimePurchase) {
        emit(
          state.copyWith(
            status: PremiumSubscriptionStatus.premium,
            hasWeeklySubscription: hasWeeklySubscription,
            hasYearlySubscription: hasYearlySubscription,
            hasLifetimePurchase: hasLifetimePurchase,
          ),
        );
      } else {
        emit(state.copyWith(status: PremiumSubscriptionStatus.noPremium));
      }

      // Keep the `is_premium` analytics super property in sync so every event
      // is segmentable by subscription state.
      AppAnalytics.setPremium(isPremium: hasPremium);
    } catch (ex, stackTrace) {
      crashReportingRepository.reportError(ex, stackTrace);
      emit(
        state.copyWith(
          status: PremiumSubscriptionStatus.failure,
          errorMessage: ex.toString(),
        ),
      );
    }
  }

  /// Presents the RevenueCat paywall. [source] identifies what triggered it
  /// (e.g. `onboarding`, `drawer`, `song_loops`, `song_speed`, `backup`) and is
  /// attached to the `purchase_success` / `paywall_dismissed` analytics so we
  /// can see which trigger converts best.
  Future<void> presentPaywall({
    bool ifNeeded = true,
    String source = 'unknown',
  }) async {
    if (Platform.isWindows) {
      emit(
        state.copyWith(
          status: PremiumSubscriptionStatus.premium,
          hasLifetimePurchase: true,
        ),
      );
      return;
    }

    final wasPremium = hasPremium;

    // Record the trigger on RevenueCat so it appears on the server-side rc_*
    // events (which carry no client context). Mirrors the `paywall_source`
    // property on the client `purchase_success` event.
    if (!kDebugMode) {
      await PurchasesRepository.setPaywallSource(source);
    }

    final PaywallResult result;
    if (ifNeeded) {
      result = await RevenueCatUI.presentPaywallIfNeeded("Pro");
    } else {
      result = await RevenueCatUI.presentPaywall();
    }
    await checkStatus();

    // A non-premium -> premium transition right after the paywall is a
    // purchase. This is step 2 of the monetization funnel (step 1 being the
    // various `view_paywall_from_*` / `show_paywall_*` open events).
    if (!wasPremium && hasPremium) {
      AppAnalytics.trackEvent(
        AppAnalytics.purchaseSuccess,
        data: {
          'tier': state.hasLifetimePurchase
              ? 'lifetime'
              : state.hasWeeklySubscription
              ? 'weekly'
              : state.hasYearlySubscription
              ? 'yearly'
              : 'unknown',
          'paywall_source': source,
        },
      );
    } else if (result == PaywallResult.cancelled) {
      AppAnalytics.trackEvent(
        AppAnalytics.paywallDismissed,
        data: {'source': source},
      );
    }
  }

  Future<void> restore() async {
    try {
      final customerInfo = await purchasesRepository.restorePurchases();
      final proEntitlement = customerInfo.entitlements.all['Pro'];

      if (proEntitlement?.isActive == true) {
        // Check if it's a lifetime purchase by looking at the product identifier
        if (proEntitlement?.productIdentifier.contains(
              'repeatlab_full_extended',
            ) ==
            true) {
          AppAnalytics.trackEvent(
            AppAnalytics.restoreSubscriptionSuccess,
            data: {'tier': 'lifetime'},
          );
          emit(
            state.copyWith(
              status: PremiumSubscriptionStatus.premium,
              hasLifetimePurchase: true,
              hasWeeklySubscription: false,
              hasYearlySubscription: false,
            ),
          );
        } else {
          final isWeekly =
              proEntitlement?.productIdentifier.contains(
                'repeatlab_full_weekly',
              ) ==
              true;
          final isYearly =
              proEntitlement?.productIdentifier.contains(
                'repeatlab_full_yearly',
              ) ==
              true;
          AppAnalytics.trackEvent(
            AppAnalytics.restoreSubscriptionSuccess,
            data: {
              'tier': isWeekly
                  ? 'weekly'
                  : isYearly
                  ? 'yearly'
                  : 'unknown',
            },
          );
          emit(
            state.copyWith(
              status: PremiumSubscriptionStatus.premium,
              hasWeeklySubscription: isWeekly,
              hasYearlySubscription: isYearly,
              hasLifetimePurchase: false,
            ),
          );
        }
      } else {
        AppAnalytics.trackEvent(
          AppAnalytics.restoreSubscriptionFailure,
          data: {'reason': 'no_active_entitlement'},
        );
        emit(state.copyWith(status: PremiumSubscriptionStatus.noPremium));
      }

      AppAnalytics.setPremium(isPremium: hasPremium);
    } catch (ex, stackTrace) {
      AppAnalytics.trackEvent(
        AppAnalytics.restoreSubscriptionFailure,
        data: {'reason': 'exception'},
      );
      crashReportingRepository.reportError(ex, stackTrace);
      emit(
        state.copyWith(
          status: PremiumSubscriptionStatus.failure,
          errorMessage: ex.toString(),
        ),
      );
    }
  }
}
