import 'package:flutter/material.dart';
import 'package:repeatlab/core/ui/app_colors.dart';

abstract class SnackbarHelper {
  const SnackbarHelper._();

  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        backgroundColor: AppColors.primaryContainer,
        content: Row(
          children: [
            const Icon(
              Icons.check,
              color: AppColors.onPrimaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        backgroundColor: AppColors.errorContainer,
        content: Row(
          children: [
            const Icon(
              Icons.error,
              color: AppColors.onErrorContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        backgroundColor: AppColors.primaryContainer,
        content: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
