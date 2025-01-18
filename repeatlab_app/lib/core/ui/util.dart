import 'package:flutter/material.dart';

TextTheme createTextTheme(
  TextTheme baseTextTheme,
  String bodyFontString,
  String displayFontString,
) {
  // Create body text theme with the body font family
  final bodyTextTheme = baseTextTheme.apply(
    fontFamily: bodyFontString,
  );

  // Create display text theme with the display font family
  final displayTextTheme = baseTextTheme.apply(
    fontFamily: displayFontString,
  );

  // Combine them the same way as before
  final textTheme = displayTextTheme.copyWith(
    bodyLarge: bodyTextTheme.bodyLarge,
    bodyMedium: bodyTextTheme.bodyMedium,
    bodySmall: bodyTextTheme.bodySmall,
    labelLarge: bodyTextTheme.labelLarge,
    labelMedium: bodyTextTheme.labelMedium,
    labelSmall: bodyTextTheme.labelSmall,
  );

  return textTheme;
}
