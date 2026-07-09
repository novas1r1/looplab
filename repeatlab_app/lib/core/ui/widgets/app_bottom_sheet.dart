import 'package:flutter/material.dart';
import 'package:repeatlab/core/ui/app_colors.dart';
import 'package:repeatlab/core/ui/motion_widgets.dart';

/// Standard presentation for all modal bottom sheets: surface color, rounded
/// top corners, and content that fades in with a small rise layered on the
/// sheet's built-in slide.
// ignore: avoid_classes_with_only_static_members
abstract final class AppBottomSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool isScrollControlled = false,
    Color? backgroundColor,
  }) {
    // Sheets that draw their own container (e.g. with a shadow) pass
    // Colors.transparent and keep their shape.
    final drawsOwnContainer = backgroundColor == Colors.transparent;
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: backgroundColor ?? AppColors.surface,
      shape: drawsOwnContainer
          ? null
          : const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
      builder: (sheetContext) => EntranceSlideFade(
        offsetY: 12,
        child: builder(sheetContext),
      ),
    );
  }
}
