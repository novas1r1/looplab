import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:flutter/widgets.dart';

/// Reports the current route name to Clarity so recordings show logical
/// screens instead of the native `FlutterActivity`/`FlutterViewController`.
class ClarityNavigatorObserver extends NavigatorObserver {
  void _setScreen(Route<dynamic>? route) {
    // Only full pages count as screens; dialogs and bottom sheets must not
    // clobber the current screen name.
    if (route is! PageRoute) return;
    final name = route.settings.name;
    if (name != null && name.isNotEmpty) {
      Clarity.setCurrentScreenName(name);
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _setScreen(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _setScreen(previousRoute);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _setScreen(newRoute);
}
