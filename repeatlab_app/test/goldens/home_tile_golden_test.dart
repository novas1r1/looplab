import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repeatlab/data/models/song.dart';
import 'package:repeatlab/features/home/widgets/home_tile.dart';

import '../helpers/device.dart';
import '../helpers/golden_test_device_scenario.dart';
import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeTile Golden Tests', () {
    goldenTest(
      'renders correctly',
      fileName: 'home_tile',
      pumpWidget: (tester, widget) => tester.pumpApp(
        widget,
      ),
      builder: () => GoldenTestDeviceScenario(
        name: 'android',
        device: Device.storeAndroidPhone.copyWith(
          size: const Size(1107 / 2, 1968),
        ),
        builder: () => const HomeTile(
          song: Song(
            id: '1',
            title: 'Test',
            artist: 'Test',
            fileName: 'test',
            duration: Duration(seconds: 1000),
          ),
        ),
      ),
    );
  });
}
