import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:repeatlab/features/home/widgets/home_tile.dart';

import '../helpers/e2e_app.dart';
import '../helpers/reset_app_state.dart';

void main() {
  patrolTest('settings: delete all data empties the library', ($) async {
    await resetAppState();
    await seedAudioSong(title: 'Disposable');
    await pumpRepeatLab($);

    expect($(HomeTile), findsOneWidget);

    // Drawer → Settings.
    await $(const Key('home.drawer')).tap();
    await $(const Key('drawer.settings')).tap();
    await $.pumpAndSettle();

    // Delete all data → confirm.
    await $(const Key('settings.deleteAll')).tap();
    await $(const Key('dialog.delete.confirm')).tap();
    await $.pumpAndSettle();

    // Back on home, now empty.
    expect($(const Key('home.empty')), findsOneWidget);
  });
}
