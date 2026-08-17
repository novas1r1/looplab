import 'package:flutter/material.dart';
import 'package:patrol/patrol.dart';
import 'package:repeatlab/core/ui/interaction/custom_slider.dart';
import 'package:repeatlab/features/song/widgets/loop_tile.dart';

import '../helpers/e2e_app.dart';
import '../helpers/fakes.dart';
import '../helpers/reset_app_state.dart';

/// Every entry point that opens the RevenueCat paywall for a non-Pro user,
/// walked in ONE test (each `patrolTest` is a fresh app process): the paywall
/// is the real native sheet (real SDK, see [NonProRealPurchasesRepository]),
/// which Patrol waits for and closes via [dismissNativePaywall] — no purchase.
///
/// Trigger inventory (`presentPaywall(source: …)` call sites in `lib/`):
///  - onboarding      finishing onboarding
///  - drawer          "Buy RepeatLab Pro"
///  - debug_drawer    (version-tap debug dialog → "Open Paywall" — developer
///                    tooling, deliberately NOT covered)
///  - backup          settings: export / import
///  - song_loops      "Add Loop" FAB, "Set Loop Start" (no active loop),
///                    locked loop tile: tap / export / edit
///  - waveform_zoom   zoom in (zoom out is disabled at min zoom, and a
///                    non-Pro user can never zoom in — unreachable)
///  - song_speed      multiplier slider, BPM stepper, BPM slider
///  - song_pitch      semitone stepper, fine-tune slider, key grid
///  - song_metronome  sync-to-song (unsynced song), time signature (synced)
void main() {
  registerE2ESetUp();

  patrolTest('paywall: every trigger opens the paywall, close without buying', (
    $,
  ) async {
    // Onboarding not skipped: it is the first trigger.
    await resetAppState(skipOnboarding: false);
    final song = await seedAudioSong(
      title: 'Gated Song',
      loopCount: 2,
      bpm: 120,
      musicalKey: 'Am',
    );
    final synced = await seedAudioSong(
      title: 'Synced Song',
      bpm: 100,
      metronomeBeatAnchorMs: 0,
      sortOrder: 1,
    );
    await pumpRepeatLab($, purchases: const NonProRealPurchasesRepository());

    // ---- onboarding -------------------------------------------------------
    for (var i = 0; i < 4; i++) {
      await $(const Key('onboarding.next')).tap();
    }
    final privacyCard = $(const Key('onboarding.privacy'));
    await privacyCard.waitUntilVisible();
    final cardRect = $.tester.getRect(privacyCard);
    await $.tester.tapAt(cardRect.topLeft + const Offset(28, 28));
    await $.pumpAndSettle();
    await $(const Key('onboarding.next')).tap(
      settlePolicy: SettlePolicy.noSettle,
    );
    await dismissNativePaywall($, 'onboarding');
    await $(const Key('home.fab')).waitUntilVisible();

    // ---- drawer: Buy RepeatLab Pro ---------------------------------------
    await $(const Key('home.drawer')).tap();
    await $('Buy RepeatLab Pro').tap(settlePolicy: SettlePolicy.noSettle);
    await dismissNativePaywall($, 'drawer');

    // ---- settings: backup export / import ---------------------------------
    await $(const Key('drawer.settings')).tap();
    await $(const Key('settings.backupExport')).tap(
      settlePolicy: SettlePolicy.noSettle,
    );
    await dismissNativePaywall($, 'backup export');
    await $(const Key('settings.backupImport')).tap(
      settlePolicy: SettlePolicy.noSettle,
    );
    await dismissNativePaywall($, 'backup import');
    // Settings is pushed on top of the (still open) drawer: back to the
    // drawer, then close it via the system back button.
    await $(BackButton).tap();
    await $(const Key('drawer.settings')).waitUntilVisible();
    await $.platformAutomator.android.pressBack();
    await $(const Key('home.fab')).waitUntilVisible();

    // ---- song page: loops --------------------------------------------------
    await $(song.title).tap(settlePolicy: SettlePolicy.trySettle);
    await $(const Key('song.play')).waitUntilVisible();

    await $('Add Loop').tap(settlePolicy: SettlePolicy.noSettle);
    await dismissNativePaywall($, 'add loop');

    await $('Set Loop Start').tap(settlePolicy: SettlePolicy.noSettle);
    await dismissNativePaywall($, 'set loop start');

    // Second loop is locked: tapping the tile / its buttons opens the paywall.
    await $(LoopTile).at(1).tap(settlePolicy: SettlePolicy.noSettle);
    await dismissNativePaywall($, 'locked loop tile');
    await $(loopTileButton('song.loop.export.'))
        .at(1)
        .tap(
          settlePolicy: SettlePolicy.noSettle,
        );
    await dismissNativePaywall($, 'locked loop export');
    await $(loopTileButton('song.loop.edit.'))
        .at(1)
        .tap(
          settlePolicy: SettlePolicy.noSettle,
        );
    await dismissNativePaywall($, 'locked loop edit');

    // ---- waveform zoom -----------------------------------------------------
    await $(appIcon('ic_zoom_in')).tap(settlePolicy: SettlePolicy.noSettle);
    await dismissNativePaywall($, 'waveform zoom in');

    // ---- speed -------------------------------------------------------------
    await $(const Key('song.controls.expand')).tap();
    await $(const Key('song.controls.tab.speed')).tap();
    await $(CustomSlider).first.tap(settlePolicy: SettlePolicy.noSettle);
    await dismissNativePaywall($, 'speed multiplier slider');

    await $(const Key('song.speed.toggleMode.bpm')).tap();
    await $(const Key('song.speed.bpmPlus')).tap(
      settlePolicy: SettlePolicy.noSettle,
    );
    await dismissNativePaywall($, 'speed bpm stepper');
    await $(CustomSlider).first.tap(settlePolicy: SettlePolicy.noSettle);
    await dismissNativePaywall($, 'speed bpm slider');

    // ---- pitch -------------------------------------------------------------
    await $(const Key('song.controls.tab.pitch')).tap();
    await $(const Key('song.pitch.semitonePlus')).tap(
      settlePolicy: SettlePolicy.noSettle,
    );
    await dismissNativePaywall($, 'pitch semitone stepper');

    await $(const Key('song.pitch.fineTune')).scrollTo();
    await $(const Key('song.pitch.fineTune')).tap(
      settlePolicy: SettlePolicy.noSettle,
    );
    await dismissNativePaywall($, 'pitch fine-tune slider');

    await $(const Key('song.pitch.toggleMode.key')).tap();
    await $(const Key('song.pitch.key.C')).scrollTo();
    await $(const Key('song.pitch.key.C')).tap(
      settlePolicy: SettlePolicy.noSettle,
    );
    await dismissNativePaywall($, 'pitch key grid');

    // ---- metronome: unsynced → sync-to-song is gated -----------------------
    await $(const Key('song.controls.tab.speed')).tap();
    await $(const Key('song.metronome.toggle')).scrollTo();
    await $(const Key('song.metronome.toggle')).tap();
    await $(const Key('song.metronome.syncToSong')).scrollTo();
    await $(const Key('song.metronome.syncToSong')).tap(
      settlePolicy: SettlePolicy.noSettle,
    );
    await dismissNativePaywall($, 'metronome sync to song');
    await backToHome($);

    // ---- metronome: synced → time signature is gated -----------------------
    await openSongControls($, synced.title);
    await $(const Key('song.metronome.toggle')).scrollTo();
    await $(const Key('song.metronome.toggle')).tap();
    await $(const Key('song.metronome.advancedToggle')).scrollTo();
    await $(const Key('song.metronome.advancedToggle')).tap();
    await $(const Key('song.metronome.timeSignature')).scrollTo();
    await $(const Key('song.metronome.timeSignature')).tap(
      settlePolicy: SettlePolicy.noSettle,
    );
    await dismissNativePaywall($, 'metronome time signature');
  });
}
