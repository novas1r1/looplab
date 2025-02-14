import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:repeatlab/core/utils/cubit_extension.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';

part 'changelog_dialog_cubit.mapper.dart';
part 'changelog_dialog_state.dart';

class ChangelogDialogCubit extends Cubit<ChangelogDialogState> {
  final LocalConfigRepository localConfigRepository;
  final PackageInfo packageInfo;

  ChangelogDialogCubit({
    required this.localConfigRepository,
    required this.packageInfo,
  }) : super(const ChangelogDialogState());

  /// Check on starting the app if changelog dialog for the current version was shown
  Future<void> checkChangelogDialog() async {
    await Future.delayed(const Duration(seconds: 3));
    // get current build number
    final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

    final lastChangelogVersionShown = localConfigRepository.lastChangelogVersionShown;

    if (lastChangelogVersionShown < currentBuildNumber) {
      emit(state.copyWith(shouldShowDialog: true));
    } else {
      maybeEmit(state.copyWith(shouldShowDialog: false));
    }
  }

  /// Save the current build version to be shown
  Future<void> setChangelogDialogSeen() async {
    final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

    await localConfigRepository.setChangelogShown(currentBuildNumber);
  }
}
