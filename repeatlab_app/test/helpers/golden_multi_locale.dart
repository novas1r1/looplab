import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repeatlab/l10n/arb/app_localizations.dart';

/// Signature for a pumpWidget function that also receives the desired locale.
typedef PumpWidgetWithLocale =
    Future<void> Function(
      WidgetTester tester,
      Widget widget,
      Locale locale,
    );

/// Runs an Alchemist [goldenTest] once for every supported locale and writes a
/// separate file per language in locale-specific folders (e.g. `en/`, `de/`, `fr/`).
void multiLocaleGoldenTest(
  String description, {
  required String fileNameBase,
  required PumpWidgetWithLocale pumpWidgetWithLocale,
  required Widget Function() builder,
  PumpAction? pumpBeforeTest,
}) {
  for (final locale in AppLocalizations.supportedLocales) {
    final localeCode = locale.toString();

    if (pumpBeforeTest != null) {
      goldenTest(
        '$description – $localeCode',
        fileName: '$localeCode/$fileNameBase',
        pumpWidget: (tester, widget) => pumpWidgetWithLocale(
          tester,
          widget,
          locale,
        ),
        pumpBeforeTest: pumpBeforeTest,
        builder: builder,
      );
    } else {
      goldenTest(
        '$description – $localeCode',
        fileName: '$localeCode/$fileNameBase',
        pumpWidget: (tester, widget) => pumpWidgetWithLocale(
          tester,
          widget,
          locale,
        ),
        builder: builder,
      );
    }
  }
}
