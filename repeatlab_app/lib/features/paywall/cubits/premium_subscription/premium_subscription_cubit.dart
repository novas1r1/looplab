import 'dart:async';
import 'dart:developer';

import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
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

  bool get hasSubscribed {
    return state.status == PremiumSubscriptionStatus.subscribed;
  }

  /// Initializes the [Purchases] SDK.
  /// Checks if the user is subscribed to the premium plan.
  /// Checks if the user has an internet connection.
  Future<void> init() async {
    log('--- REVENUECAT: init()');

    try {
      await purchasesRepository.setup();

      // final isConnected = await purchasesRepository.isConnected;
      // emit(state.copyWith(isConnected: isConnected));

      checkStatus();

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
    /* if (kDebugMode) {
      emit(state.copyWith(status: PremiumSubscriptionStatus.subscribed));

      return;
    } */

    try {
      if (await purchasesRepository.hasActiveSubscription) {
        emit(state.copyWith(status: PremiumSubscriptionStatus.subscribed));
      } else {
        emit(state.copyWith(status: PremiumSubscriptionStatus.notSubscribed));
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

  Future<void> restore() async {
    try {
      final customerInfo = await purchasesRepository.restorePurchases();

      if (customerInfo.entitlements.all['Pro']?.isActive == true) {
        emit(state.copyWith(status: PremiumSubscriptionStatus.subscribed));
      } else {
        emit(state.copyWith(status: PremiumSubscriptionStatus.notSubscribed));
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
}
