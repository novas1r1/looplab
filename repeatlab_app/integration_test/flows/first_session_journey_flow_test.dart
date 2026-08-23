import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:repeatlab/features/home/widgets/home_tile.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/features/song/widgets/loop_tile.dart';

import '../helpers/e2e_app.dart';
import '../helpers/fakes.dart';
import '../helpers/reset_app_state.dart';
import '../helpers/test_media.dart';

/// The new-user first session, end to end, in the order the product analytics
/// show real users take it (30-day funnel of users who started onboarding:
/// onboarding 1462 → first song 803 → play 667 → first loop 576 → set loop
/// start 468 → loop mode 426 → play loop 381 → speed 348):
///
///   onboarding → empty home → add a song → open it → tutorial coach marks →
///   skip → play/pause → set loop start (creates the first loop) → seek → set
///   loop end → loop mode on → play the loop → change the tempo → leave and
///   come back: everything persisted.
///
/// Runs as Pro so the tempo step doesn't hit the paywall (a free user's first
/// loop is free; the premium gates themselves are covered by the freemium and
/// paywall flows). Playback happens for real on the device against a 30 s
/// silent clip; the tests wait in real time for the position to move.
void main() {
  registerE2ESetUp();

  patrolTest('first session: onboarding → song → loop → tempo', ($) async {
    await resetAppState(skipOnboarding: false, skipTutorial: false);
    final picker = FakeFilePickerWrapper(
      fileToReturn: await TestMedia.writeSilentWavToTemp(
        name: 'My First Song.wav',
        seconds: 30,
      ),
    );
    await pumpRepeatLab($, filePicker: picker);

    // --- Onboarding ---------------------------------------------------------
    expect($(const Key('onboarding.next')), findsOneWidget);
    for (var i = 0; i < 4; i++) {
      await $(const Key('onboarding.next')).tap();
    }
    // Consent: tap the card's check indicator, not the centre (a link there).
    final privacyCard = $(const Key('onboarding.privacy'));
    await privacyCard.waitUntilVisible();
    await $.tester.tapAt(
      $.tester.getRect(privacyCard).topLeft + const Offset(28, 28),
    );
    await $.pumpAndSettle();
    await $(const Key('onboarding.next')).tap();
    await $(const Key('home.fab')).waitUntilVisible();

    // --- Add the first song --------------------------------------------------
    expect($(const Key('home.empty')), findsOneWidget);
    await $(const Key('home.fab')).tap();
    await $(const Key('home.addAudio')).tap();
    await $(HomeTile).waitUntilVisible(timeout: const Duration(seconds: 30));
    expect($('My First Song.wav'), findsOneWidget);

    // --- Open it: the tutorial coach marks greet a first-time user ----------
    await $(HomeTile).tap(settlePolicy: SettlePolicy.trySettle);
    // The coach-mark overlay covers the page (so wait for it, not the play
    // button); its first target explains the waveform.
    await $('SKIP').waitUntilVisible(timeout: const Duration(seconds: 20));
    // The target's content fades in after the overlay.
    await $(
      'Navigate through the song with dragging and dropping',
    ).waitUntilExists();
    await $('SKIP').tap(settlePolicy: SettlePolicy.trySettle);
    expect($('SKIP'), findsNothing);
    await $(const Key('song.play')).waitUntilVisible();
    expect($(const Key('song.loops.empty')), findsOneWidget);

    SongCubit songCubit() =>
        $.tester.element(find.byKey(const Key('song.play'))).read<SongCubit>();

    // --- Play, let the position move, pause ---------------------------------
    await $(const Key('song.play')).tap(settlePolicy: SettlePolicy.noSettle);
    await $.tester.pump(const Duration(milliseconds: 1500));
    await $(const Key('song.play')).tap(settlePolicy: SettlePolicy.noSettle);
    await settleBounded($, 'after first play/pause');
    final positionAfterPlay = await songCubit().position;
    expect(
      positionAfterPlay,
      greaterThan(Duration.zero),
      reason: 'playback should have advanced the position',
    );

    // --- First loop: set start here, seek ahead, set end --------------------
    await $('Set Loop Start').tap();
    await $(LoopTile).waitUntilVisible();
    expect($(LoopTile), findsOneWidget);
    expect($('Loop 1'), findsWidgets);
    await waitUntil(
      $,
      () => songCubit().state.activeLoop?.start != null,
      reason: 'loop start set',
    );

    await $(const Key('song.forward10')).tap();
    await $('Set Loop End').tap();
    await waitUntil(
      $,
      () => songCubit().state.activeLoop?.end != null,
      reason: 'loop end set',
    );
    final loop = songCubit().state.activeLoop!;
    expect(loop.end, greaterThan(loop.start!));

    // --- Loop mode: creating the loop activated it; play the loop ------------
    expect(songCubit().state.isLoopModeEnabled, isTrue);
    await $(const Key('song.play')).tap(settlePolicy: SettlePolicy.noSettle);
    await $.tester.pump(const Duration(milliseconds: 1200));
    await $(const Key('song.play')).tap(settlePolicy: SettlePolicy.noSettle);
    await settleBounded($, 'after playing the loop');

    // The loop-mode switch (the only CupertinoSwitch while the controls card is
    // collapsed) turns loop mode off — and, with a single loop, back on again.
    await $(CupertinoSwitch).tap();
    await waitUntil(
      $,
      () => !songCubit().state.isLoopModeEnabled,
      reason: 'loop mode off after switch tap',
    );
    expect(songCubit().state.activeLoop, isNull);
    // (Re-selecting auto-plays the loop — pause it again.)
    await $(CupertinoSwitch).tap(settlePolicy: SettlePolicy.noSettle);
    await waitUntil(
      $,
      () => songCubit().state.activeLoop?.name == 'Loop 1',
      reason: 'switch re-selects the only loop',
    );
    expect(songCubit().state.isLoopModeEnabled, isTrue);
    await $.tester.pump(const Duration(milliseconds: 500));
    await $(const Key('song.play')).tap(settlePolicy: SettlePolicy.noSettle);
    await settleBounded($, 'after re-activating the loop');

    // --- Change the tempo (BPM mode) -----------------------------------------
    await $(const Key('song.controls.expand')).tap();
    await $(const Key('song.speed.toggleMode.bpm')).tap();
    await $(const Key('song.speed.bpmOriginal')).enterText('100');
    await $(const Key('song.speed.bpmSet')).tap();
    await $(const Key('song.speed.bpmPlus')).scrollTo();
    for (var i = 0; i < 5; i++) {
      await $(const Key('song.speed.bpmPlus')).tap();
    }
    await $.pumpAndSettle();
    expect($('105'), findsWidgets);
    expect($('BPM · 1.05×'), findsOneWidget);
    expect(songCubit().state.speed, closeTo(1.05, 0.001));

    // --- Leave and come back: song and loop persisted ------------------------
    await backToHome($);
    expect($(HomeTile), findsOneWidget);
    await $(HomeTile).tap(settlePolicy: SettlePolicy.trySettle);
    await $(const Key('song.play')).waitUntilVisible();
    // Tutorial was skipped once and stays away.
    expect($('SKIP'), findsNothing);
    await $(LoopTile).waitUntilVisible();
    expect($('Loop 1'), findsWidgets);
  });
}
