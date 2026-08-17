import 'package:audioplayers/audioplayers.dart' show PlayerState;
import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:repeatlab/features/home/widgets/home_tile.dart';
import 'package:repeatlab/features/song/cubit/song/song_cubit.dart';
import 'package:repeatlab/features/song/widgets/loop_tile.dart';

import '../helpers/e2e_app.dart';
import '../helpers/reset_app_state.dart';

/// A returning user's practice session — the mid-funnel actions that follow
/// the first loop in the product analytics (30 days, unique users: play loop
/// 469, edit loop 271, skip next/previous 172/121, back/forward 10 s 152/147,
/// delete loop 148, delete song 98):
///
///   library with two songs, one carrying two loops → open it → tap a loop
///   (activates it) → play the loop → skip to the next / previous loop →
///   seek ±10 s → rename a loop → delete a loop → back → delete the other song
///   from the list.
void main() {
  registerE2ESetUp();

  patrolTest('practice session: loops, navigation, seek, delete', ($) async {
    await resetAppState();
    final practice = await seedAudioSong(
      title: 'Practice Song',
      loopCount: 2,
      durationSeconds: 20,
    );
    await seedAudioSong(title: 'Other Song', sortOrder: 1);
    await pumpRepeatLab($);
    expect($(HomeTile), findsNWidgets(2));

    // --- Open the song with loops, activate the second one by tapping it ----
    await $(practice.title).tap(settlePolicy: SettlePolicy.trySettle);
    await $(const Key('song.play')).waitUntilVisible();
    await $(LoopTile).waitUntilVisible();
    expect($(LoopTile), findsNWidgets(2));

    SongCubit songCubit() =>
        $.tester.element(find.byKey(const Key('song.play'))).read<SongCubit>();

    // Selecting a loop switches loop mode on and (default setting) auto-plays
    // it; let it run for a moment, then pause.
    await $('Loop 2').tap(settlePolicy: SettlePolicy.noSettle);
    await waitUntil(
      $,
      () => songCubit().state.activeLoop?.name == 'Loop 2',
      reason: 'tapping a loop tile activates it',
    );
    expect(songCubit().state.isLoopModeEnabled, isTrue);
    await $.tester.pump(const Duration(milliseconds: 1200));
    await $(const Key('song.play')).tap(settlePolicy: SettlePolicy.noSettle);
    await settleBounded($, 'after playing the loop');

    // The switch turns loop mode off (and clears the active loop); tapping a
    // loop brings it back (auto-playing again — pause it).
    await $(CupertinoSwitch).tap();
    await waitUntil(
      $,
      () => !songCubit().state.isLoopModeEnabled,
      reason: 'loop mode off after switch tap',
    );
    expect(songCubit().state.activeLoop, isNull);
    await $('Loop 2').tap(settlePolicy: SettlePolicy.noSettle);
    await waitUntil(
      $,
      () => songCubit().state.activeLoop?.name == 'Loop 2',
      reason: 'loop re-activated',
    );
    await $.tester.pump(const Duration(milliseconds: 500));
    await $(const Key('song.play')).tap(settlePolicy: SettlePolicy.noSettle);
    await settleBounded($, 'after re-selecting the loop');

    // --- Skip previous / next between loops ---------------------------------
    // Next from the last loop wraps to the first.
    await $(appIcon('ic_next')).tap(settlePolicy: SettlePolicy.noSettle);
    await waitUntil(
      $,
      () => songCubit().state.activeLoop?.name == 'Loop 1',
      reason: 'skip next wraps to Loop 1',
    );
    // Previous follows the music-player convention: a single tap restarts the
    // current loop, a quick double tap goes to the previous loop.
    await $(appIcon('ic_previous')).tap(settlePolicy: SettlePolicy.noSettle);
    await $(appIcon('ic_previous')).tap(settlePolicy: SettlePolicy.noSettle);
    await waitUntil(
      $,
      () => songCubit().state.activeLoop?.name == 'Loop 2',
      reason: 'double-tap previous goes to Loop 2',
    );
    // Skipping auto-plays the target loop; pause before seeking.
    await $.tester.pump(const Duration(milliseconds: 300));
    if (songCubit().state.playerState == PlayerState.playing) {
      await $(const Key('song.play')).tap(settlePolicy: SettlePolicy.noSettle);
    }
    await settleBounded($, 'after skipping between loops');

    // --- Seek ±10 s ---------------------------------------------------------
    await $(const Key('song.forward10')).tap();
    await $.tester.pump(const Duration(milliseconds: 300));
    final afterForward = await songCubit().position;
    await $(const Key('song.back10')).tap();
    await $.tester.pump(const Duration(milliseconds: 300));
    final afterBack = await songCubit().position;
    expect(afterForward, greaterThan(afterBack));

    // --- Rename the active loop, then delete it ------------------------------
    Future<void> openEditSheetOf(String loopName) async {
      await $.tester.tap(
        find.descendant(
          of: find.ancestor(
            of: find.text(loopName),
            matching: find.byType(LoopTile),
          ),
          matching: loopTileButton('song.loop.edit.'),
        ),
      );
      await $.pumpAndSettle();
    }

    await openEditSheetOf('Loop 2');
    await $(const Key('editLoop.name')).enterText('Chorus');
    await $(const Key('editLoop.save')).tap();
    await $.pumpAndSettle();
    expect($('Chorus'), findsWidgets);
    expect($('Loop 2'), findsNothing);

    await openEditSheetOf('Chorus');
    await $(const Key('editLoop.delete')).tap();
    await $.pumpAndSettle();
    expect($(LoopTile), findsOneWidget);
    expect($('Loop 1'), findsWidgets);

    // --- Back to the library, delete the other song --------------------------
    await backToHome($);
    expect($(HomeTile), findsNWidgets(2));
    // HomeTile is a Slidable: swipe left to reveal Delete, confirm the dialog.
    await $.tester.drag(find.text('Other Song'), const Offset(-300, 0));
    await $.pumpAndSettle();
    await $('Delete').tap(); // slidable action
    await $(AlertDialog).waitUntilVisible();
    await $.tester.tap(
      find.descendant(of: find.byType(AlertDialog), matching: find.text('Delete')),
    );
    await $.pumpAndSettle();
    expect($(HomeTile), findsOneWidget);
    expect($('Practice Song'), findsOneWidget);
    expect($('Other Song'), findsNothing);
  });
}
