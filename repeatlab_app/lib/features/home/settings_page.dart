import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';
import 'package:repeatlab/core/utils/dialog_helper.dart';
import 'package:repeatlab/data/repositories/backup/backup_repository.dart';
import 'package:repeatlab/data/repositories/crash_reporting_repository.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
import 'package:repeatlab/features/backup/cubit/backup_cubit.dart';
import 'package:repeatlab/features/backup/widgets/export_options_sheet.dart';
import 'package:repeatlab/features/home/cubit/all_songs_cubit.dart';
import 'package:repeatlab/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart';
import 'package:repeatlab/l10n/l10n.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BackupCubit(
        backupRepository: context.read<BackupRepository>(),
        crashReportingRepository: context.read<CrashReportingRepository>(),
      ),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatefulWidget {
  const _SettingsView();

  @override
  State<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<_SettingsView> {
  bool analyticsEnabled = false;

  @override
  void initState() {
    super.initState();
    analyticsEnabled = context.read<LocalConfigRepository>().acceptedAnalytics;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BackupCubit, BackupState>(
      listener: _onBackupStateChange,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.settings),
        ),
        body: ListView(
          children: [
            CheckboxListTile(
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.l10n.analytics, style: context.titleLarge),
                  Text(
                    context.l10n.analyticsDescription,
                    style: context.bodySmall,
                  ),
                ],
              ),
              value: analyticsEnabled,
              onChanged: (value) async {
                setState(() {
                  analyticsEnabled = value ?? false;
                });
                await context.read<LocalConfigRepository>().setAnalyticsEnabled(
                  isEnabled: value ?? false,
                );
              },
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                context.l10n.backupAndRestore,
                style: context.titleLarge,
              ),
            ),
            _BackupTiles(),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(context.l10n.localData, style: context.titleLarge),
            ),
            ListTile(
              key: const Key('settings.deleteAll'),
              leading: const Icon(Icons.delete_forever),
              title: Text(context.l10n.deleteAllLocalData),
              onTap: () => _onDeleteAllData(context),
            ),
          ],
        ),
      ),
    );
  }

  void _onBackupStateChange(BuildContext context, BackupState state) {
    final messenger = ScaffoldMessenger.of(context);
    switch (state.status) {
      case BackupStatus.exportSuccess:
      // Sharing is handled inside the cubit; no visible toast needed on
      // success because the share sheet already confirms the action.
      case BackupStatus.importSuccess:
        final s = state.lastImportSummary;
        if (s != null) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.backupImportSuccess(
                  s.songsImported,
                  s.songsSkipped,
                  s.filesRenamed,
                ),
              ),
            ),
          );
        }
        context.read<AllSongsCubit>().loadSongs();
      case BackupStatus.failure:
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.backupExportFailed(state.errorMessage ?? ''),
            ),
          ),
        );
      case BackupStatus.idle:
      case BackupStatus.exporting:
      case BackupStatus.importing:
        break;
    }
  }

  Future<void> _onDeleteAllData(BuildContext context) async {
    AppAnalytics.trackEvent(AppAnalytics.clickDeleteAllData);

    // show confirmation dialog
    final result = await DialogHelper.displayDeleteDialog(
      context,
      title: context.l10n.deleteAllDataTitle,
      message: context.l10n.deleteAllDataMessage,
    );

    if (result == null || !result || !context.mounted) return;

    bool success = false;

    success = await context.read<AllSongsCubit>().clearDb();

    // clear local config
    if (context.mounted) {
      success = await context.read<LocalConfigRepository>().clear();
    }

    // Rotate the anonymous PostHog distinct id so the wiped local identity is
    // no longer linked to future events (GDPR right-to-erasure for the device).
    unawaited(Posthog().reset());

    if (!context.mounted) return;

    Navigator.pop(context);

    if (success) {
      // show success dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.deleteAllDataSuccess),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.deleteAllDataError),
        ),
      );
    }
  }
}

class _BackupTiles extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hasPremium = context.select<PremiumSubscriptionCubit, bool>(
      (c) => c.hasPremium,
    );
    final busy = context.select<BackupCubit, bool>(
      (c) =>
          c.state.status == BackupStatus.exporting ||
          c.state.status == BackupStatus.importing,
    );
    final importing = context.select<BackupCubit, bool>(
      (c) => c.state.status == BackupStatus.importing,
    );
    final exporting = context.select<BackupCubit, bool>(
      (c) => c.state.status == BackupStatus.exporting,
    );

    return Column(
      children: [
        ListTile(
          key: const Key('settings.backupExport'),
          leading: exporting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(hasPremium ? Icons.upload_file : Icons.lock_outline),
          title: Text(
            exporting
                ? context.l10n.backupExporting
                : context.l10n.backupExport,
          ),
          subtitle: Text(
            hasPremium
                ? context.l10n.backupExportSubtitle
                : context.l10n.backupProOnly,
          ),
          enabled: !busy,
          onTap: busy ? null : () => _handleExportTap(context, hasPremium),
        ),
        ListTile(
          key: const Key('settings.backupImport'),
          leading: importing
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(hasPremium ? Icons.file_download : Icons.lock_outline),
          title: Text(
            importing
                ? context.l10n.backupImporting
                : context.l10n.backupImport,
          ),
          subtitle: Text(
            hasPremium
                ? context.l10n.backupImportSubtitle
                : context.l10n.backupProOnly,
          ),
          enabled: !busy,
          onTap: busy
              ? null
              : () {
                  if (!hasPremium) {
                    AppAnalytics.trackEvent(
                      AppAnalytics.viewPaywallFromBackup,
                    );
                    context.read<PremiumSubscriptionCubit>().presentPaywall();
                    return;
                  }
                  _handleImportTap(context);
                },
        ),
      ],
    );
  }

  Future<void> _handleExportTap(BuildContext context, bool hasPremium) async {
    if (!hasPremium) {
      AppAnalytics.trackEvent(AppAnalytics.viewPaywallFromBackup);
      context.read<PremiumSubscriptionCubit>().presentPaywall();
      return;
    }

    // Capture the share-sheet anchor BEFORE awaiting the picker — the bottom
    // sheet's own render box would otherwise become the anchor and dismiss
    // when the user picks an app to share to.
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;

    final options = await showBackupExportOptionsSheet(context);
    if (options == null || !context.mounted) return;

    await context.read<BackupCubit>().exportAndShare(
      sharePositionOrigin: origin,
      options: options,
    );
  }

  Future<void> _handleImportTap(BuildContext context) async {
    final cubit = context.read<BackupCubit>();
    final candidate = await cubit.pickBackupForImport();
    if (candidate == null || !context.mounted) return;

    final mode = await _displayImportModeDialog(
      context,
      songCount: candidate.manifest.songCount,
      exportedAt: candidate.manifest.exportedAt,
    );
    if (mode == null || !context.mounted) return;

    if (mode == BackupImportMode.replace) {
      final confirmed = await DialogHelper.displayDeleteDialog(
        context,
        title: context.l10n.backupImportReplaceConfirmTitle,
        message: context.l10n.backupImportReplaceConfirmMessage,
      );
      if (confirmed != true || !context.mounted) return;
    }

    await cubit.confirmImport(file: candidate.file, mode: mode);
  }

  Future<BackupImportMode?> _displayImportModeDialog(
    BuildContext context, {
    required int songCount,
    required String exportedAt,
  }) {
    return showDialog<BackupImportMode>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.backupImportConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.backupImportConfirmMessage(songCount, exportedAt),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.merge_type),
              title: Text(context.l10n.backupImportModeMerge),
              subtitle: Text(context.l10n.backupImportModeMergeDescription),
              onTap: () =>
                  Navigator.of(dialogContext).pop(BackupImportMode.merge),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.swap_horiz),
              title: Text(context.l10n.backupImportModeReplace),
              subtitle: Text(context.l10n.backupImportModeReplaceDescription),
              onTap: () =>
                  Navigator.of(dialogContext).pop(BackupImportMode.replace),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.l10n.cancel),
          ),
        ],
      ),
    );
  }
}
