import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/utils/app_analytics.dart';
import 'package:repeatlab/core/utils/build_context_extension.dart';
import 'package:repeatlab/core/utils/dialog_helper.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
import 'package:repeatlab/features/home/cubit/all_songs_cubit.dart';
import 'package:repeatlab/l10n/l10n.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool analyticsEnabled = false;

  @override
  void initState() {
    super.initState();
    analyticsEnabled = context.read<LocalConfigRepository>().acceptedAnalytics;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.settings),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.l10n.analytics, style: context.titleLarge),
                Text(context.l10n.analyticsDescription, style: context.bodySmall),
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
            child: Text(context.l10n.localData, style: context.titleLarge),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: Text(context.l10n.deleteAllLocalData),
            onTap: () => _onDeleteAllData(context),
          ),
        ],
      ),
    );
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
