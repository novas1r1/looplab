import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';

class ScaffoldGoldenTestScenario extends StatelessWidget {
  final String name;
  final Widget child;

  final Color backgroundColor;
  final TextScaler textScaler;

  const ScaffoldGoldenTestScenario({
    super.key,
    required this.name,
    required this.child,
    this.backgroundColor = Colors.white,
    this.textScaler = TextScaler.noScaling,
  });

  @override
  Widget build(BuildContext context) {
    if (textScaler != TextScaler.noScaling) {
      return GoldenTestScenario.withTextScaleFactor(
        name: name,
        textScaler: textScaler,
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: child,
        ),
      );
    }

    return GoldenTestScenario(
      name: name,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: child,
      ),
    );
  }
}
