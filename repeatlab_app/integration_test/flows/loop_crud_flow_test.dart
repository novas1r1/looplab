import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:repeatlab/features/song/widgets/loop_tile.dart';

import '../helpers/e2e_app.dart';
import '../helpers/reset_app_state.dart';

void main() {
  patrolTest('loop CRUD: create, rename, delete', ($) async {
    await resetAppState();
    final song = await seedAudioSong(title: 'Loop Song');
    await pumpRepeatLab($);

    // Open the seeded song.
    await $(song.title).tap();
    await $.pumpAndSettle();

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
  });
}
