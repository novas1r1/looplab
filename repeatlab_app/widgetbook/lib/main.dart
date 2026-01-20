import 'package:accessibility_tools/accessibility_tools.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

// This file does not exist yet,
// it will be generated in the next step
import 'main.directories.g.dart';

void main() {
  runApp(const WidgetbookApp());
}

@widgetbook.App()
class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      appBuilder: (context, child) => AccessibilityTools(child: child),
      addons: [
        ViewportAddon([
          Viewports.none,
          IosViewports.iPhone13,
          AndroidViewports.samsungGalaxyNote20,
        ]),
      ],
      // The [directories] variable does not exist yet,
      // it will be generated in the next step
      directories: directories,
    );
  }
}
