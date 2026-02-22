import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // ignore: do_not_use_environment, avoid_redundant_argument_values
  const isRunningInCi = bool.fromEnvironment('CI', defaultValue: false);

  // Create text theme without context
  /* final textTheme = TextTheme(
    displayLarge: GoogleFonts.oswald(),
    displayMedium: GoogleFonts.oswald(),
    displaySmall: GoogleFonts.oswald(),
    headlineLarge: GoogleFonts.oswald(),
    headlineMedium: GoogleFonts.oswald(),
    headlineSmall: GoogleFonts.oswald(),
    titleLarge: GoogleFonts.nunitoSans(),
    titleMedium: GoogleFonts.nunitoSans(),
    titleSmall: GoogleFonts.nunitoSans(),
    bodyLarge: GoogleFonts.nunitoSans(),
    bodyMedium: GoogleFonts.nunitoSans(),
    bodySmall: GoogleFonts.nunitoSans(),
    labelLarge: GoogleFonts.nunitoSans(),
    labelMedium: GoogleFonts.nunitoSans(),
    labelSmall: GoogleFonts.nunitoSans(),
  );
  final theme = MaterialTheme(textTheme); */

  final baseTheme = ThemeData.dark();

  /* final bodyTextTheme = GoogleFonts.getTextTheme("Nunito Sans", baseTheme.textTheme);
  final displayTextTheme = GoogleFonts.getTextTheme("Oswald", baseTheme.textTheme);
  final textTheme = displayTextTheme.copyWith(
    bodyLarge: bodyTextTheme.bodyLarge,
    bodyMedium: bodyTextTheme.bodyMedium,
    bodySmall: bodyTextTheme.bodySmall,
    labelLarge: bodyTextTheme.labelLarge,
    labelMedium: bodyTextTheme.labelMedium,
    labelSmall: bodyTextTheme.labelSmall,
  ); */

  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      forceUpdateGoldenFiles: false,
      theme: baseTheme,
      // theme: baseTheme.copyWith(textTheme: textTheme),
      // theme: theme.dark(),
      platformGoldensConfig: const PlatformGoldensConfig(
        // ignore: avoid_redundant_argument_values
        enabled: !isRunningInCi,
        // theme: theme.dark(),
      ),
      ciGoldensConfig: const CiGoldensConfig(
        // ignore: avoid_redundant_argument_values
        enabled: isRunningInCi,
        // theme: theme.dark(),
      ),
    ),
    run: testMain,
  );
}
