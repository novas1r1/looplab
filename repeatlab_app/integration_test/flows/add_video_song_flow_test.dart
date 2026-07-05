import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:repeatlab/features/home/widgets/home_tile.dart';

import '../helpers/e2e_app.dart';
import '../helpers/fakes.dart';
import '../helpers/reset_app_state.dart';
import '../helpers/test_media.dart';

void main() {
  // Headline flow for feature/video-support. Requires a real bundled MP4
  // (see assets/test/README.md) — media_kit probes the container for a non-zero
  // duration, so the clip can't be synthesised. Skips itself until the asset
  // is added.
  patrolTest('add video song: faked import appears as a video tile', ($) async {
    await resetAppState();

    final video = await TestMedia.writeBundledVideoToTemp();
    if (video == null) {
      markTestSkipped(
        'Add a short assets/test/test_video.mp4 and declare it under '
        'pubspec flutter: assets: to enable the add-video flow.',
      );
      return;
    }

    final picker = FakeFilePickerWrapper(fileToReturn: video);
    await pumpRepeatLab($, filePicker: picker);

    expect($(const Key('home.empty')), findsOneWidget);

    await $(const Key('home.fab')).tap();
    await $(const Key('home.addVideo')).tap();

    await $(HomeTile).waitUntilVisible();
    expect($(HomeTile), findsOneWidget);
    // Video tiles render the videocam icon (audio uses music_note).
    expect($(Icons.videocam), findsOneWidget);
  });
}
