import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../helpers/e2e_app.dart';
import '../helpers/reset_app_state.dart';

/// Metronome panel (bottom of the Speed tab), staged by sync state — see the
/// `MetronomePanel` doc. Playback / tap-along sync is deliberately not driven
/// (timing-dependent on a phone); the synced stage is reached by seeding a
/// song that already carries a beat anchor.
void main() {
  registerE2ESetUp();

  const toggle = Key('song.metronome.toggle');

  // One test, three seeded songs (each patrolTest is a fresh app process).
  patrolTest('metronome: no-BPM guard, unsynced stage, synced stage', ($) async {
    await resetAppState();
    final noBpm = await seedAudioSong(title: 'No BPM Song');
    final tempo = await seedAudioSong(title: 'Tempo Song', bpm: 120, sortOrder: 1);
    final synced = await seedAudioSong(
      title: 'Synced Song',
      bpm: 100,
      metronomeBeatAnchorMs: 0,
      sortOrder: 2,
    );
    await pumpRepeatLab($);

    // --- Without a BPM the toggle asks to set one first -------------------
    await openSongControls($, noBpm.title);

    // Header reads "off" and the switch is off.
    expect($('off'), findsOneWidget);

    await $(toggle).scrollTo();
    await $(toggle).tap();
    await $(const Key('song.metronome.setBpmDialog')).waitUntilVisible();
    expect($("Set the song's BPM first to use the metronome."), findsOneWidget);

    await $('Close').tap();
    expect($(const Key('song.metronome.setBpmDialog')), findsNothing);
    // Still off — the tap did not enable anything.
    expect($('off'), findsOneWidget);
    expect($(const Key('song.metronome.syncToSong')), findsNothing);
    await backToHome($);

    // --- With a BPM: toggles on and offers sync-to-song --------------------
    await openSongControls($, tempo.title);
    expect($('off'), findsOneWidget);

    // On, not synced: header shows the tempo only (no time signature — the
    // click is a plain tick until beat 1 is known) and the sync call to action.
    await $(toggle).scrollTo();
    await $(toggle).tap();
    await $(const Key('song.metronome.syncToSong')).scrollTo();
    expect($('120 BPM'), findsOneWidget);
    expect($(const Key('song.metronome.timeSignature')), findsNothing);
    expect($(const Key('song.metronome.advancedToggle')), findsNothing);

    // Off again.
    await $(toggle).scrollTo();
    await $(toggle).tap();
    await $.pumpAndSettle();
    expect($('off'), findsOneWidget);
    expect($(const Key('song.metronome.syncToSong')), findsNothing);
    await backToHome($);

    // --- Synced song exposes time signature and subdivision ----------------
    await openSongControls($, synced.title);

    await $(toggle).scrollTo();
    await $(toggle).tap();
    await $(const Key('song.metronome.advancedToggle')).scrollTo();

    // Synced header: tempo · time signature, quarter-note subdivision badge,
    // gear toggle; the sync call to action is gone.
    expect($('100 BPM · 4/4 ·'), findsOneWidget);
    expect($(const Key('song.metronome.syncToSong')), findsNothing);
    expect(
      appIcon(
        'ic_note_quarter',
        key: const Key('song.metronome.subdivisionIndicator'),
      ),
      findsOneWidget,
    );

    // Everything that refines the alignment sits behind the gear toggle (an
    // AnimatedCrossFade, so the collapsed widgets stay in the tree — assert
    // via scrollTo/hit-testability rather than presence).
    await $(const Key('song.metronome.advancedToggle')).tap();
    await $(const Key('song.metronome.timeSignature')).scrollTo();

    // Change the time signature via the dropdown.
    await $(const Key('song.metronome.timeSignature')).tap();
    await $('3/4').tap();
    await $.pumpAndSettle();
    expect($('100 BPM · 3/4 ·'), findsOneWidget);

    // Pick eighth-note subdivision; the header badge follows. (Target the
    // button's icon, not the ToggleButtons row: its centre lies between two
    // buttons and hit-tests nothing.)
    final eighth = $(
      find.descendant(
        of: find.byKey(const Key('song.metronome.subdivision')),
        matching: appIcon('ic_note_eighth'),
      ),
    );
    await eighth.scrollTo();
    await eighth.tap();
    await $.pumpAndSettle();
    expect(
      appIcon(
        'ic_note_eighth',
        key: const Key('song.metronome.subdivisionIndicator'),
      ),
      findsOneWidget,
    );

    // Reset sync: back to the un-synced stage with the sync call to action.
    await $(const Key('song.metronome.resetSync')).scrollTo();
    await $(const Key('song.metronome.resetSync')).tap();
    await $(const Key('song.metronome.syncToSong')).scrollTo();
    expect($('100 BPM'), findsOneWidget);
    expect($(const Key('song.metronome.timeSignature')), findsNothing);
  });
}
