import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repeatlab/app/router.dart';
import 'package:repeatlab/core/ui/theme.dart';
import 'package:repeatlab/core/ui/util.dart';
import 'package:repeatlab/l10n/arb/app_localizations.dart';

/// Helper extension to pump widgets with proper app setup for golden tests
extension PumpApp on WidgetTester {
  /// Pumps a widget wrapped with MaterialApp, theme, and localization
  Future<void> pumpApp(
    Widget widget, {
    Locale locale = const Locale('de'),
  }) async {
    await pumpWidget(
      Builder(
        builder: (context) {
          final baseTextTheme = ThemeData.dark().textTheme;
          final textTheme = createTextTheme(
            baseTextTheme,
            'Nunito Sans',
            'Oswald',
          );
          final theme = MaterialTheme(textTheme);

          return MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            themeMode: ThemeMode.dark,
            theme: theme.dark(),
            home: widget,
          );
        },
      ),
    );

    // Wait for localization to initialize
    await pump();
  }

  /// Pumps a widget with a fixed number of frames instead of waiting for settle
  /// Useful for widgets with infinite animations like shimmer loading
  Future<void> pumpAppWithFrames(
    Widget widget, {
    Locale locale = const Locale('de'),
    int frames = 3,
  }) async {
    await pumpWidget(
      Builder(
        builder: (context) {
          final baseTextTheme = ThemeData.dark().textTheme;
          final textTheme = createTextTheme(
            baseTextTheme,
            'Nunito Sans',
            'Oswald',
          );
          final theme = MaterialTheme(textTheme);

          return MaterialApp(
            locale: locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            onGenerateRoute: AppRouter.generateRoute,
            themeMode: ThemeMode.dark,
            theme: theme.dark(),
            home: widget,
          );
        },
      ),
    );

    // Pump a fixed number of frames
    for (var i = 0; i < frames; i++) {
      await pump();
    }
  }
}
