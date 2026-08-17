import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:repeatlab/features/home/cubit/all_songs_cubit.dart';
import 'package:repeatlab/features/home/widgets/home_tile.dart';

import '../helpers/e2e_app.dart';
import '../helpers/fakes.dart';
import '../helpers/reset_app_state.dart';
import '../helpers/test_media.dart';

/// Every supported media format, imported in one multi-select batch and then
/// opened one by one — each through the real pipeline: picker (faked) → copy
/// into the documents dir → FFmpeg conversion for formats SoLoud can't decode
/// natively → SoLoud / media_kit duration probe → persist → list refresh →
/// song page loads the file for playback.
///
/// One `patrolTest` per media kind (audio / video) rather than one per format:
/// every `patrolTest` is a fresh app process (~10–15 s), and the batch import
/// is itself a feature worth exercising. Per-format granularity is kept with
/// soft assertions — each open is tried, failures are collected and reported
/// together at the end, so a broken `.wma` doesn't hide whether `.opus` works.
///
/// The clips live in `assets/test/` (see its README); the format lists in
/// [TestMedia] mirror the app's picker extensions.
void main() {
  registerE2ESetUp();

  // Conversion + probe + player load can take a moment on a phone.
  const mediaTimeout = Duration(seconds: 30);

  /// Title the app gives a clip imported from [tempName]: the clips carry no
  /// tags, so the title falls back to the stored file name.
  String expectedTitle(String tempName, {required bool convertedToWav}) =>
      convertedToWav ? '${tempName.split('.').first}.wav' : tempName;

  Future<void> importBatchAndOpenEach(
    PatrolIntegrationTester $, {
    required Key addKey,
    required String expectedIcon,
    required Map<String, String> titlesByFormat,
  }) async {
    expect($(const Key('home.empty')), findsOneWidget);

    try {
      await $(const Key('home.fab')).tap();
    } catch (_) {
      dumpScreenDiagnostics($, 'home.fab not tappable');
      rethrow;
    }
    await $(addKey).tap();

    // The batch runs sequentially behind the importing indicator; give every
    // conversion its share of time.
    await $(HomeTile).waitUntilVisible(
      timeout: mediaTimeout * titlesByFormat.length,
    );

    // The list is lazy, so count via the cubit rather than built tiles.
    final cubit = $.tester
        .element(find.byType(HomeTile).first)
        .read<AllSongsCubit>();
    expect(
      cubit.state.songs.length,
      titlesByFormat.length,
      reason: 'every clip should have been imported',
    );

    final failures = <String>[];
    for (final MapEntry(key: ext, value: title) in titlesByFormat.entries) {
      try {
        // Scroll the tile into view, check its media icon, open it and wait
        // for the player to be ready, then go back to the list.
        await $(title).scrollTo();
        expect(
          find.descendant(
            of: find.ancestor(
              of: find.text(title),
              matching: find.byType(HomeTile),
            ),
            matching: homeTileMediaIcon(expectedIcon),
          ),
          findsOneWidget,
        );
        await $(title).tap(settlePolicy: SettlePolicy.trySettle);
        await $(const Key('song.play')).waitUntilVisible(timeout: mediaTimeout);
        await $(BackButton).tap(settlePolicy: SettlePolicy.trySettle);
        await $(const Key('home.fab')).waitUntilVisible();
      } catch (e) {
        failures.add('.$ext ($title): $e');
        // Try to get back to the list for the next format.
        if (find.byType(BackButton).evaluate().isNotEmpty) {
          await $(BackButton).tap(settlePolicy: SettlePolicy.trySettle);
        }
      }
    }
    expect(
      failures,
      isEmpty,
      reason: 'formats that failed to open:\n${failures.join('\n')}',
    );
  }

  patrolTest('media formats: all audio formats import in one batch and open', (
    $,
  ) async {
    await resetAppState();
    final files = [
      for (final ext in TestMedia.bundledAudioFormats)
        await TestMedia.writeBundledAudioToTemp(ext),
    ];
    await pumpRepeatLab(
      $,
      filePicker: FakeFilePickerWrapper(filesToReturn: files),
    );

    // Formats SoLoud can't decode natively are stored as `<stem>.wav`.
    const soloudNative = {'mp3', 'wav', 'ogg', 'flac'};
    await importBatchAndOpenEach(
      $,
      addKey: const Key('home.addAudio'),
      expectedIcon: 'ic_audio',
      titlesByFormat: {
        for (final ext in TestMedia.bundledAudioFormats)
          ext: expectedTitle(
            TestMedia.bundledAudioTempName(ext),
            convertedToWav: !soloudNative.contains(ext),
          ),
      },
    );
  });

  patrolTest('media formats: all video formats import in one batch and open', (
    $,
  ) async {
    await resetAppState();
    final files = [
      for (final ext in TestMedia.bundledVideoFormats)
        await TestMedia.writeBundledVideoToTemp(ext: ext),
    ];
    // The video picker is single-select in production; the import loop still
    // handles a multi-file result, which is what the fake hands back here.
    await pumpRepeatLab(
      $,
      filePicker: FakeFilePickerWrapper(filesToReturn: files),
    );

    await importBatchAndOpenEach(
      $,
      addKey: const Key('home.addVideo'),
      expectedIcon: 'ic_video',
      titlesByFormat: {
        for (final ext in TestMedia.bundledVideoFormats)
          ext: expectedTitle('e2e_video_$ext.$ext', convertedToWav: false),
      },
    );
  });
}
