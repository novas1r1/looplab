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

  /// Check whether the current app version has a changelog the user hasn't
  /// seen yet. Drives the "What's new" badge instead of auto-opening a dialog.
  Future<void> checkForUnseenChangelog() async {
    // get current build number
    final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

    final lastChangelogVersionShown =
        localConfigRepository.lastChangelogVersionShown;

    maybeEmit(
      state.copyWith(
        hasUnseenChangelog: lastChangelogVersionShown < currentBuildNumber,
      ),
    );
  }

  /// Mark the current build's changelog as seen and clear the badge.
  Future<void> markChangelogSeen() async {
    final currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

    await localConfigRepository.setChangelogShown(currentBuildNumber);
    maybeEmit(state.copyWith(hasUnseenChangelog: false));
  }
}
