part of 'rate_app_cubit.dart';

@MappableClass()
class RateAppState with RateAppStateMappable {
  final RateAppStatus status;
  final bool shouldShowDialog;

  const RateAppState({
    this.status = RateAppStatus.initial,
    this.shouldShowDialog = false,
  });
}

@MappableEnum()
enum RateAppStatus {
  initial,
  rated,
  notRated,
}
