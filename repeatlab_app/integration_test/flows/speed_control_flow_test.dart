import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../helpers/e2e_app.dart';
import '../helpers/reset_app_state.dart';

void main() {
  // Drives tempo-mode toggling + BPM input + reset. Sliders are intentionally
  // not dragged (drag-on-slider is device-fragile); assertions are on UI state.
  patrolTest('speed control: multiplier <-> BPM and reset', ($) async {
    await resetAppState();
    final song = await seedAudioSong(title: 'Speed Song');
    await pumpRepeatLab($);

    await $(song.title).tap();
    await $.pumpAndSettle();

    // Expand the speed panel; starts in multiplier mode showing "1.0×".
    await $(const Key('song.speed.expand')).tap();
    await $.pumpAndSettle();
    expect($('1.0×'), findsOneWidget);

    // Switch to BPM mode and set an original BPM.
    await $('BPM').tap();
    await $.pumpAndSettle();
    await $(const Key('song.speed.bpmOriginal')).enterText('120');
    await $(const Key('song.speed.bpmSet')).tap();
    await $.pumpAndSettle();
    // Both the original and current BPM tiles show 120.
    expect($('120'), findsWidgets);

    // Back to multiplier mode and reset to 1.0×.
    await $('×').tap();
    await $.pumpAndSettle();
    await $(const Key('song.speed.reset')).tap();
    await $.pumpAndSettle();
    expect($('1.0×'), findsOneWidget);
  });
}
