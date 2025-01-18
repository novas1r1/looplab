import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:repeatlab/data/repositories/local_config_repository.dart';
import 'package:repeatlab/features/rate_app_dialog/rate_app_dialog.dart';

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
}
