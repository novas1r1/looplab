import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:repeatlab/features/song/widgets/loop_tile.dart';

import '../helpers/e2e_app.dart';
import '../helpers/reset_app_state.dart';

void main() {
  // Drives the export entry point up to the export sheet. Confirming the export
  // triggers a real render and then the NATIVE save dialog (export uses
  // `FilePicker.saveFile` directly, NOT the injectable wrapper — see the TODO in
  // export_loop_bottom_up.dart). On a real device, tap confirm and dismiss/drive
  // the save dialog via `$.native`; here we stop at the sheet so CI stays
  // deterministic and never blocks on an un-fakeable native dialog.
  patrolTest('loop export: opens the export sheet', ($) async {
    await resetAppState();
    final song = await seedAudioSong(title: 'Export Song');
    await pumpRepeatLab($);

    await $(song.title).tap();
    await $.pumpAndSettle();

    // Create a loop, then open its export sheet via the tile's export button.
    await $(FloatingActionButton).tap();
    await $(LoopTile).waitUntilVisible();
    await $.tester.tap(loopTileButton('song.loop.export.'));
    await $.pumpAndSettle();

    expect($(const Key('exportLoop.confirm')), findsOneWidget);
  });
}
