import 'dart:async';
import 'dart:developer';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/data/repositories/crash_reporting_repository.dart';
import 'package:repeatlab/data/repositories/purchases_repository.dart';

part 'premium_subscription_cubit.mapper.dart';
part 'premium_subscription_state.dart';

class PremiumSubscriptionCubit extends Cubit<PremiumSubscriptionState> {
  // final AuthRepository authRepository;
  final CrashReportingRepository crashReportingRepository;
  final PurchasesRepository purchasesRepository;

  // StreamSubscription<bool>? _internetSubscription;

  PremiumSubscriptionCubit({
    // required this.authRepository,
    required this.crashReportingRepository,
    required this.purchasesRepository,
  }) : super(const PremiumSubscriptionState()) {
    /*  _internetSubscription = purchaseRepository.internetSubscription.listen((isConnected) {
      emit(state.copyWith(isConnected: isConnected));
    }); */
  }

  @override
  Future<void> close() async {
    // _internetSubscription?.cancel();
    super.close();
  }

  bool get hasPremium =>
      state.hasWeeklySubscription || state.hasYearlySubscription || state.hasLifetimePurchase;

  /// Initializes the [Purchases] SDK.
  /// Checks if the user is subscribed to the premium plan.
  /// Checks if the user has an internet connection.
  Future<void> init() async {
    log('--- REVENUECAT: init()');

    try {
      await purchasesRepository.setup();

      // final isConnected = await purchasesRepository.isConnected;
      // emit(state.copyWith(isConnected: isConnected));

      await checkStatus();

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
    /*     if (kDebugMode) {
      emit(state.copyWith(status: PremiumSubscriptionStatus.premium));

      return;
    } */

    try {
      final hasWeeklySubscription = await purchasesRepository.hasWeeklySubscription;
      final hasYearlySubscription = await purchasesRepository.hasYearlySubscription;

      final hasLifetimePurchase = await purchasesRepository.hasLifetimePurchase;

      log('--- REVENUECAT: hasWeeklySubscription: $hasWeeklySubscription');
      log('--- REVENUECAT: hasYearlySubscription: $hasYearlySubscription');
      log('--- REVENUECAT: hasLifetimePurchase: $hasLifetimePurchase');

      if (hasWeeklySubscription || hasYearlySubscription || hasLifetimePurchase) {
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

  Future<void> presentPaywall({bool ifNeeded = true}) async {
    if (ifNeeded) {
      await RevenueCatUI.presentPaywallIfNeeded("Pro");
    } else {
      await RevenueCatUI.presentPaywall();
    }
    await checkStatus();
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
