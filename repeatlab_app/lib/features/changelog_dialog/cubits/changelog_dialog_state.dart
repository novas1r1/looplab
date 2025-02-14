part of 'changelog_dialog_cubit.dart';

@MappableClass()
class ChangelogDialogState with ChangelogDialogStateMappable {
  final ChangelogStatus status;
  final bool shouldShowDialog;
  final String? errorMessage;

  const ChangelogDialogState({
    this.status = ChangelogStatus.loading,
    this.shouldShowDialog = false,
    this.errorMessage,
  });
}

@MappableEnum()
enum ChangelogStatus { loading, loaded, error }
