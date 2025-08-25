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

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomePage());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingPage());
      case privacy:
        return MaterialPageRoute(builder: (_) => const DataprotectionPage());
      case terms:
        return MaterialPageRoute(builder: (_) => const TermsOfServicePage());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
