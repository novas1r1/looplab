part of 'changelog_dialog_cubit.dart';

@MappableClass()
class ChangelogDialogState with ChangelogDialogStateMappable {
  final ChangelogStatus status;

  /// Whether the current app version has a changelog the user hasn't seen yet.
  /// Drives the "What's new" badge on the home page rather than auto-opening
  /// the changelog dialog.
  final bool hasUnseenChangelog;
  final String? errorMessage;

  const ChangelogDialogState({
    this.status = ChangelogStatus.loading,
    this.hasUnseenChangelog = false,
    this.errorMessage,
  });
}

@MappableEnum()
enum ChangelogStatus { loading, loaded, error }
