import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';

part 'rate_app_cubit.mapper.dart';
part 'rate_app_state.dart';

class RateAppCubit extends Cubit<RateAppState> {
  final LocalConfigRepository localConfigRepository;

  RateAppCubit({required this.localConfigRepository})
    : super(const RateAppState());

  Future<void> checkRateAppDialog() async {
    await Future.delayed(const Duration(seconds: 3));
    // get current build number
    final wasDialogShown = localConfigRepository.rateAppDialogShown;

    emit(
      state.copyWith(
        shouldShowDialog: !wasDialogShown,
      ),
    );
  }
}
