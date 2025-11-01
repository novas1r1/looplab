import 'package:alchemist/alchemist.dart';
import 'package:flutter/widgets.dart';

import 'device.dart';
import 'scaffold_golden_test_scenario.dart';

class ConstrainedGoldenTestGroup extends StatelessWidget {
  final List<ScaffoldGoldenTestScenario> children;

  const ConstrainedGoldenTestGroup({
    super.key,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return GoldenTestGroup(
      scenarioConstraints: BoxConstraints.tight(Device.pixel8a.size),
      children: children,
    );
  }
}
