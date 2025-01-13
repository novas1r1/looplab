import 'dart:io' show Platform;

import 'package:bloc/bloc.dart';
import 'package:dart_mappable/dart_mappable.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/paywall_result.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:repeatlab/data/repositories/crash_reporting_repository.dart';
import 'package:repeatlab/data/repositories/purchases_repository.dart';

part 'paywall_cubit.mapper.dart';
part 'paywall_state.dart';

class PaywallCubit extends Cubit<PaywallState> {
  final PurchasesRepository purchasesRepository;
  final CrashReportingRepository crashReportingRepository;

  PaywallCubit({
    required this.purchasesRepository,
    required this.crashReportingRepository,
  }) : super(const PaywallState());

  Future<void> init() async {
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

  Future<void> showPaywall() async {
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
}
