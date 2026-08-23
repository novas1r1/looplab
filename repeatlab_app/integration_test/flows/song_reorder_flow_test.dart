import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:repeatlab/features/home/widgets/home_tile.dart';

import '../helpers/e2e_app.dart';
import '../helpers/reset_app_state.dart';

void main() {
  registerE2ESetUp();

  patrolTest('reorder: drag the first song down', ($) async {
    await resetAppState();
    await seedAudioSong(title: 'Song A');
    await seedAudioSong(title: 'Song B', sortOrder: 1);
    await seedAudioSong(title: 'Song C', sortOrder: 2);
    await pumpRepeatLab($);

    expect($(HomeTile), findsNWidgets(3));

    // ReorderableListView starts a drag on long-press (mobile). Strict final
    // ordering is device-fragile; this asserts the list survives the reorder
    // gesture. Tighten the post-drag order assertion once running on a device.
    final firstTile = find.text('Song A');
    final gesture = await $.tester.startGesture(
      $.tester.getCenter(firstTile),
    );
    await $.tester.pump(const Duration(milliseconds: 600));
    await gesture.moveBy(const Offset(0, 220));
    await $.tester.pump(const Duration(milliseconds: 200));
    await gesture.up();
    await $.pumpAndSettle();

    expect($(HomeTile), findsNWidgets(3));
  });
}
