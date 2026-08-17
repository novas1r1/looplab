import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../helpers/e2e_app.dart';
import '../helpers/reset_app_state.dart';

void main() {
  registerE2ESetUp();

  // Drives the backup export entry up to the options sheet. Confirming triggers
  // `exportAndShare` → the NATIVE share sheet (share_plus), which has no Flutter
  // key; import likewise opens a native file picker not behind our wrapper. On a
  // real device, confirm and dismiss the share sheet via `$.native`; here we stop
  // at the options sheet so CI stays deterministic.
  patrolTest('backup: opens the export options sheet', ($) async {
    await resetAppState();
    await seedAudioSong(title: 'Backup Song');
    await pumpRepeatLab($);

    await $(const Key('home.drawer')).tap();
    await $(const Key('drawer.settings')).tap();
    await $.pumpAndSettle();

    // Pro user → export tile opens the include-options sheet.
    await $(const Key('settings.backupExport')).tap();
    await $.pumpAndSettle();

    expect($(const Key('backupExport.confirm')), findsOneWidget);
  });
}
