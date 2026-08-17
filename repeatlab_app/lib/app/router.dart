import 'package:flutter/material.dart';
import 'package:repeatlab/features/home/dataprotection_page.dart';
import 'package:repeatlab/features/home/home_page.dart';
import 'package:repeatlab/features/home/terms_of_service_page.dart';
import 'package:repeatlab/features/onboarding/view/onboarding_page.dart';

abstract class AppRouter {
  const AppRouter._();

  static const String home = '/';
  static const String onboarding = '/onboarding';
  static const String privacy = '/privacy';
  static const String terms = '/terms';

  // Names for pages pushed directly (not via generateRoute), so navigator
  // observers (Clarity, PostHog) can report a meaningful screen name.
  static const String song = '/song';
  static const String settingsPage = '/settings';
  static const String legalNotices = '/legal-notices';
  static const String licenses = '/licenses';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const HomePage(),
        );
      case onboarding:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const OnboardingPage(),
        );
      case privacy:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const DataprotectionPage(),
        );
      case terms:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const TermsOfServicePage(),
        );
      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
