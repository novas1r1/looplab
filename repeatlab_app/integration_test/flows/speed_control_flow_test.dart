import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../helpers/e2e_app.dart';
import '../helpers/reset_app_state.dart';

void main() {
  registerE2ESetUp();

  // Drives tempo-mode toggling + BPM input. Sliders are intentionally not
  // dragged (drag-on-slider is device-fragile); assertions are on UI state.
  patrolTest('speed control: multiplier <-> BPM', ($) async {
    await resetAppState();
    final song = await seedAudioSong(title: 'Speed Song');
    await pumpRepeatLab($);

    await $(song.title).tap();
    await $.pumpAndSettle();

    // Expand the controls card; the speed tab is selected by default and
    // starts in multiplier mode showing "1.00×".
    await $(const Key('song.controls.expand')).tap();
    await $.pumpAndSettle();
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
  });
}
