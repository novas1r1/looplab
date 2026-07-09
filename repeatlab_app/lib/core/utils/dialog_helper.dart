import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/core/ui/motion.dart';
import 'package:repeatlab/core/ui/widgets/app_bottom_sheet.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
import 'package:repeatlab/features/rate_app_dialog/rate_app_dialog.dart';
import 'package:repeatlab/l10n/l10n.dart';

abstract class DialogHelper {
  const DialogHelper._();

  /// Drop-in replacement for [showDialog] with the app's standard dialog
  /// motion: a quick fade plus a subtle scale-up.
  static Future<T?> showAnimated<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: Motion.of(context, Motion.fast),
      pageBuilder: (dialogContext, animation, secondaryAnimation) =>
          builder(dialogContext),
      transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Motion.enter);
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  static Future<void> displayRateAppDialog(BuildContext context) async {
    final localConfigRepository = context.read<LocalConfigRepository>();

    await AppBottomSheet.show<void>(
      context,
      isScrollControlled: true,
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
    return await showAnimated<bool>(
      context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            key: const Key('dialog.delete.cancel'),
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            key: const Key('dialog.delete.confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
  }
}
