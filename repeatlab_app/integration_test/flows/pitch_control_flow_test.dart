import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../helpers/e2e_app.dart';
import '../helpers/reset_app_state.dart';

/// Pitch tab of the controls card: semitone stepper, key mode (set the song's
/// key, then pick a target key from the grid) and the round trip between the
/// two. The fine-tune slider is not dragged (drag-on-slider is
/// device-fragile). Assertions are on UI state; the DSP itself is exercised
/// by unit tests.
void main() {
  registerE2ESetUp();

  // One test, two seeded songs (each patrolTest is a fresh app process): the
  // first walks the semitone stepper and then key mode, the second starts
  // with a known key.
  patrolTest('pitch: semitone stepper, key mode, seeded key', ($) async {
    await resetAppState();
    final noKey = await seedAudioSong(title: 'Pitch Song');
    final amSong = await seedAudioSong(
      title: 'Am Song',
      musicalKey: 'Am',
      sortOrder: 1,
    );
    await pumpRepeatLab($);

    // --- Semitone stepper names the interval -------------------------------
    await openSongControls($, noKey.title, tab: 'pitch');

    // Starts at the original pitch.
    expect($('Original pitch'), findsOneWidget);

    // Two up → "+2", "whole step up".
    await $(const Key('song.pitch.semitonePlus')).tap();
    await $(const Key('song.pitch.semitonePlus')).tap();
    await $.pumpAndSettle();
    expect($('+2'), findsOneWidget);
    expect($('whole step up'), findsOneWidget);

    // Three down → "−1", "half step down".
    for (var i = 0; i < 3; i++) {
      await $(const Key('song.pitch.semitoneMinus')).tap();
    }
    await $.pumpAndSettle();
    expect($('−1'), findsOneWidget);
    expect($('half step down'), findsOneWidget);

    // Back to 0 before switching to key mode.
    await $(const Key('song.pitch.semitonePlus')).tap();
    await $.pumpAndSettle();
    expect($('Original pitch'), findsOneWidget);

    // --- Key mode sets the song key and transposes to a target -------------

    // Key mode without a known key asks for it first (major grid by default).
    await $(const Key('song.pitch.toggleMode.key')).tap();
    await $(const Key('song.pitch.key.C')).scrollTo();
    expect($(const Key('song.pitch.keyOriginal')), findsOneWidget);
    await $(const Key('song.pitch.key.C')).tap();
    await $.pumpAndSettle();

    // Original and current key tiles both read C; the target grid is shown.
    expect($(const Key('song.pitch.editOriginalKey')), findsOneWidget);
    expect($('C'), findsWidgets);

    // Pick D as target: +2 semitones, shown next to the current key.
    await $(const Key('song.pitch.key.D')).scrollTo();
    await $(const Key('song.pitch.key.D')).tap();
    await $.pumpAndSettle();
    expect($('D (+2 st)'), findsOneWidget);

    // Back in semitone mode the stepper reflects the transposition and the
    // caption names both the interval and the resulting key.
    await $(const Key('song.pitch.toggleMode.semitones')).scrollTo();
    await $(const Key('song.pitch.toggleMode.semitones')).tap();
    await $.pumpAndSettle();
    expect($('+2'), findsOneWidget);
    expect($('whole step up · D'), findsOneWidget);
    await backToHome($);

    // --- Seeded song key shows in the stepper caption ----------------------
    await openSongControls($, amSong.title, tab: 'pitch');

    // Original pitch, key Am.
    expect($('Original pitch · Am'), findsOneWidget);

    // Up a fifth → Em.
    for (var i = 0; i < 7; i++) {
      await $(const Key('song.pitch.semitonePlus')).tap();
    }
    await $.pumpAndSettle();
    expect($('+7'), findsOneWidget);
    // Beyond ±5 the caption also warns that it may sound artificial.
    expect($('5th up · Em · may sound artificial'), findsOneWidget);
  });
}
