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

/// Import + open, once per supported media format, each through the real
/// pipeline: picker (faked) → copy into the documents dir → FFmpeg conversion
/// for formats SoLoud can't decode natively → SoLoud / media_kit duration
/// probe → persist → list refresh → song page loads the file for playback.
/// A format the on-device decoders reject shows up here as its own failing
/// test rather than as a vague "import broke".
///
/// The clips live in `assets/test/` (see its README); the format lists in
/// [TestMedia] mirror the app's picker extensions.
void main() {
  // Conversion + probe + player load can take a moment on a phone.
  const mediaTimeout = Duration(seconds: 30);

  Future<void> importAndOpen(
    PatrolIntegrationTester $, {
    required Key addKey,
    required String expectedIcon,
  }) async {
    expect($(const Key('home.empty')), findsOneWidget);

    await $(const Key('home.fab')).tap();
    await $(addKey).tap();

    await $(HomeTile).waitUntilVisible(timeout: mediaTimeout);
    expect($(HomeTile), findsOneWidget);
    expect(homeTileMediaIcon(expectedIcon), findsOneWidget);

    // Open the song: the page shows a loader while the player loads the file,
    // and the play button only appears once that succeeded.
    await $(HomeTile).tap(settlePolicy: SettlePolicy.trySettle);
    await $(const Key('song.play')).waitUntilVisible(timeout: mediaTimeout);
  }

  for (final ext in TestMedia.bundledAudioFormats) {
    patrolTest('media formats: .$ext audio imports and opens', ($) async {
      await resetAppState();
      final picker = FakeFilePickerWrapper(
        fileToReturn: await TestMedia.writeBundledAudioToTemp(ext),
      );
      await pumpRepeatLab($, filePicker: picker);
      await importAndOpen(
        $,
        addKey: const Key('home.addAudio'),
        expectedIcon: 'ic_audio',
      );
    });
  }

  for (final ext in TestMedia.bundledVideoFormats) {
    patrolTest('media formats: .$ext video imports and opens', ($) async {
      await resetAppState();
      final picker = FakeFilePickerWrapper(
        fileToReturn: await TestMedia.writeBundledVideoToTemp(ext: ext),
      );
      await pumpRepeatLab($, filePicker: picker);
      await importAndOpen(
        $,
        addKey: const Key('home.addVideo'),
        expectedIcon: 'ic_video',
      );
    });
  }

  patrolTest('media formats: all audio formats import in one batch', ($) async {
    await resetAppState();
    final files = [
      for (final ext in TestMedia.bundledAudioFormats)
        await TestMedia.writeBundledAudioToTemp(ext),
    ];
    final picker = FakeFilePickerWrapper(filesToReturn: files);
    await pumpRepeatLab($, filePicker: picker);
    expect($(const Key('home.empty')), findsOneWidget);

    await $(const Key('home.fab')).tap();
    await $(const Key('home.addAudio')).tap();

    // The batch runs sequentially behind the importing indicator; wait for the
    // list to come back and give every conversion its share of time.
    await $(HomeTile).waitUntilVisible(
      timeout: mediaTimeout * TestMedia.bundledAudioFormats.length,
    );

    // The list is lazy, so count via the cubit rather than built tiles …
    final cubit = $.tester
        .element(find.byType(HomeTile).first)
        .read<AllSongsCubit>();
    expect(cubit.state.songs.length, TestMedia.bundledAudioFormats.length);

    // … and check every clip made it into the UI by scrolling to its title.
    // Formats SoLoud can't decode natively are stored as `<stem>.wav`, and the
    // title falls back to the file name because the clips carry no tags.
    for (final ext in TestMedia.bundledAudioFormats) {
      final stem = 'e2e_audio_$ext';
      final title = const {'mp3', 'wav', 'ogg', 'flac'}.contains(ext)
          ? '$stem.$ext'
          : '$stem.wav';
      await $(title).scrollTo();
      expect($(title), findsOneWidget);
    }
  });
}
