import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:repeatlab/features/song/widgets/loop_tile.dart';

import '../helpers/e2e_app.dart';
import '../helpers/reset_app_state.dart';

/// Song page on one seeded song, in one test (each patrolTest is a fresh app
/// process): speed control (multiplier <-> BPM), loop CRUD and the loop export
/// sheet. Sliders are intentionally not dragged (drag-on-slider is
/// device-fragile); assertions are on UI state.
void main() {
  registerE2ESetUp();

  patrolTest('song page: speed control, loop CRUD, loop export sheet', (
    $,
  ) async {
    await resetAppState();
    final song = await seedAudioSong(title: 'Song Page Song');
    await pumpRepeatLab($);

    // --- Speed control: multiplier <-> BPM ---------------------------------
    // Expand the controls card; the speed tab is selected by default and
    // starts in multiplier mode showing "1.00×".
    await openSongControls($, song.title);
    expect($('1.00×'), findsOneWidget);

    // Switch to BPM mode and set an original BPM.
    await $(const Key('song.speed.toggleMode.bpm')).tap();
    await $.pumpAndSettle();
    await $(const Key('song.speed.bpmOriginal')).enterText('120');
    await $(const Key('song.speed.bpmSet')).tap();
    await $.pumpAndSettle();
    // The current-BPM stepper shows 120 (speed is still 1.00×).
    expect($('120'), findsWidgets);

    // Back to multiplier mode: still 1.00×.
    await $(const Key('song.speed.toggleMode.multiplier')).tap();
    await $.pumpAndSettle();
    expect($('1.00×'), findsOneWidget);

    // Collapse the controls again so the loop list has room.
    await $(const Key('song.controls.expand')).tap();
    await $.pumpAndSettle();

    // --- Loop CRUD: create, rename, delete ---------------------------------
    // Create a loop via the add-loop FAB (the only FAB on the song page).
    await $(FloatingActionButton).tap();
    await $(LoopTile).waitUntilVisible();
    expect($(LoopTile), findsOneWidget);

    // Rename via the loop's edit sheet (the tile's `song.loop.edit.<id>` button).
    Future<void> openEditSheet() async {
      await $.tester.tap(loopTileButton('song.loop.edit.'));
      await $.pumpAndSettle();
    }

    await openEditSheet();
    await $(const Key('editLoop.name')).enterText('Renamed Loop');
    await $(const Key('editLoop.save')).tap();
    await $.pumpAndSettle();
    expect($('Renamed Loop'), findsWidgets);

    // Delete via the edit sheet.
    await openEditSheet();
    await $(const Key('editLoop.delete')).tap();
    await $.pumpAndSettle();
    expect($(LoopTile), findsNothing);

    // --- Loop export: opens the export sheet -------------------------------
    // Drives the export entry point up to the export sheet. Confirming the
    // export triggers a real render and then the NATIVE save dialog (export
    // uses `FilePicker.saveFile` directly, NOT the injectable wrapper — see
    // the TODO in export_loop_bottom_up.dart), so we stop at the sheet.
    await $(FloatingActionButton).tap();
    await $(LoopTile).waitUntilVisible();
    await $.tester.tap(loopTileButton('song.loop.export.'));
    await $.pumpAndSettle();
    expect($(const Key('exportLoop.confirm')), findsOneWidget);
  });
}
