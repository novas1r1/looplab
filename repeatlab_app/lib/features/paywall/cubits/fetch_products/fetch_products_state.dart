part of 'fetch_products_cubit.dart';

@MappableClass()
class FetchProductsState with FetchProductsStateMappable {
  final FetchProductsStatus status;
  final FetchProductsAction action;

  final Package? annualPackage;
  final Package? lifetimePackage;

  final String? errorMessage;

  const FetchProductsState({
    this.status = FetchProductsStatus.loading,
    this.action = FetchProductsAction.none,
    this.annualPackage,
    this.lifetimePackage,
    this.errorMessage,
  });
}

@MappableEnum()
enum FetchProductsStatus {
  loading,
  success,
  failure,
}

@MappableEnum()
enum FetchProductsAction {
  none,
  fetch,
  purchase,
}
