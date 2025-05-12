import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
import 'package:repeatlab/features/rate_app_dialog/rate_app_dialog.dart';
import 'package:repeatlab/l10n/l10n.dart';

abstract class DialogHelper {
  const DialogHelper._();

  static Future<void> displayRateAppDialog(BuildContext context) async {
    final localConfigRepository = context.read<LocalConfigRepository>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) => RepositoryProvider.value(
        value: localConfigRepository,
        child: const RateAppDialog(),
      ),
    );
  }

  static Future<bool?> displayDeleteDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
  }
}
