import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:purchases_flutter/object_wrappers.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:repeatlab/core/utils/cubit_extension.dart';
import 'package:repeatlab/data/repositories/crash_reporting_repository.dart';
import 'package:repeatlab/data/repositories/purchases_repository.dart';

part 'fetch_products_cubit.mapper.dart';
part 'fetch_products_state.dart';

class FetchProductsCubit extends Cubit<FetchProductsState> {
  final PurchasesRepository purchasesRepository;
  final CrashReportingRepository crashReportingRepository;

  FetchProductsCubit({
    required this.purchasesRepository,
    required this.crashReportingRepository,
  }) : super(const FetchProductsState());

  Future<void> fetchProducts() async {
    emit(
      state.copyWith(
        status: FetchProductsStatus.loading,
        action: FetchProductsAction.fetch,
      ),
    );

    try {
      final offers = await purchasesRepository.offers;

      final lifetimePackage = offers.firstOrNull?.lifetime;
      final annualPackage = offers.firstOrNull?.annual;

      maybeEmit(
        state.copyWith(
          status: FetchProductsStatus.success,
          lifetimePackage: lifetimePackage,
          annualPackage: annualPackage,
        ),
      );
    } catch (ex, stackTrace) {
      crashReportingRepository.reportError(ex, stackTrace);
      emit(
        state.copyWith(
          status: FetchProductsStatus.failure,
          errorMessage: ex.toString(),
        ),
      );
    }
  }

  Future<void> purchase(Package package) async {
    emit(
      state.copyWith(
        status: FetchProductsStatus.loading,
        action: FetchProductsAction.purchase,
      ),
    );

    try {
      final isPurchased = await purchasesRepository.purchase(package);

      if (isPurchased) {
        emit(state.copyWith(status: FetchProductsStatus.success));
      } else {
        crashReportingRepository.reportError(
          Exception(
            'Something went wrong while purchasing. Please contact our support.',
          ),
          StackTrace.current,
        );

        emit(
          state.copyWith(
            status: FetchProductsStatus.failure,
            errorMessage: 'Something went wrong while purchasing. Please contact our support.',
          ),
        );
      }
    } on PlatformException catch (e, stackTrace) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);

      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        emit(
          state.copyWith(
            status: FetchProductsStatus.success,
            action: FetchProductsAction.none,
          ),
        );
        return;
      }

      crashReportingRepository.reportError(e, stackTrace);
      emit(
        state.copyWith(
          status: FetchProductsStatus.failure,
          errorMessage: e.message ?? e.toString(),
        ),
      );
    } catch (ex, stackTrace) {
      crashReportingRepository.reportError(ex, stackTrace);
      emit(
        state.copyWith(
          status: FetchProductsStatus.failure,
          errorMessage: ex.toString(),
        ),
      );
    }
  }
}
