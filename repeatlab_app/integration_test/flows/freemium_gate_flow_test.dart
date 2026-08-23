import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:repeatlab/features/song/widgets/loop_tile.dart';

import '../helpers/e2e_app.dart';
import '../helpers/reset_app_state.dart';

void main() {
  registerE2ESetUp();

  // The paywall itself is a native RevenueCatUI sheet (can't be asserted in
  // Flutter), so the gate is verified via its in-app effect: for a non-Pro user,
  // every loop beyond the first renders locked.
  patrolTest('freemium gate: non-Pro sees locked loops past the first', (
    $,
  ) async {
    await resetAppState();
    final song = await seedAudioSong(title: 'Gated Song', loopCount: 2);
    await pumpRepeatLab($, isPro: false);

    await $(song.title).tap();
    await $.pumpAndSettle();

    // Two loop tiles, the second locked → a lock icon is shown.
    expect($(LoopTile), findsNWidgets(2));
    expect($(Icons.lock), findsWidgets);
  });
}
