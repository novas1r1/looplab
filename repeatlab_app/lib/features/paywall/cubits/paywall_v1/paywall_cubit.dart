/* import 'dart:io' show Platform;

import 'package:bloc/bloc.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:repeatlab/core/app_constants.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/data/repositories/crash_reporting_repository.dart';
import 'package:repeatlab/data/repositories/purchases_repository.dart';
import 'package:url_launcher/url_launcher.dart';

part 'paywall_cubit.mapper.dart';
part 'paywall_state.dart';

class PaywallCubit extends Cubit<PaywallState> {
  final PurchasesRepository purchasesRepository;
  final CrashReportingRepository crashReportingRepository;

  Future<bool> hasUserPurched() =>
      Purchases.getCustomerInfo().then((info) => info.allPurchasedProductIdentifiers.isNotEmpty);

  PaywallCubit({
    required this.purchasesRepository,
    required this.crashReportingRepository,
  }) : super(const PaywallState());

  Future<void> init() async {
    await purchasesRepository.setup();
  }

  Future<void> showPaywall() async {
    emit(state.copyWith(status: PaywallStatus.loading));

    try {
      final paywallResult = await purchasesRepository.presentPaywall();

      emit(
        state.copyWith(
          status: PaywallStatus.loaded,
          paywallResult: paywallResult,
        ),
      );
    } catch (e, stackTrace) {
      crashReportingRepository.reportError(e, stackTrace);
      emit(state.copyWith(status: PaywallStatus.error));
    }
  }

  Future<void> showPaywallIfNeeded() async {
    emit(state.copyWith(status: PaywallStatus.loading));

    try {
      final paywallResult = await purchasesRepository.presentPaywallIfNeeded();

      emit(
        state.copyWith(
          status: PaywallStatus.loaded,
          paywallResult: paywallResult,
        ),
      );
    } catch (e, stackTrace) {
      crashReportingRepository.reportError(e, stackTrace);
      emit(state.copyWith(status: PaywallStatus.error));
    }
  }

  Future<void> cancelSubscription() async {
    if (Platform.isIOS) {
      AppAnalytics.trackEvent(
        AppAnalytics.clickCancelSubscriptionIos,
      );
      final uri = Uri.parse(AppConstants.urlIosSubscriptions);
      launchUrl(uri);
    } else {
      AppAnalytics.trackEvent(
        AppAnalytics.clickCancelSubscriptionAndroid,
      );
      final uri = Uri.parse(AppConstants.urlAndroidSubscriptions);
      launchUrl(uri);
    }
  }
}
 */
