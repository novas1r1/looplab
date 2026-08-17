import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:repeatlab/features/home/widgets/home_tile.dart';

import '../helpers/e2e_app.dart';
import '../helpers/fakes.dart';
import '../helpers/reset_app_state.dart';
import '../helpers/test_media.dart';

void main() {
  registerE2ESetUp();

  // Headline flow for video support. Uses the bundled MP4 from assets/test/ —
  // media_kit probes the container for a non-zero duration, so the clip has to
  // be a real one. Every other video container is covered by
  // add_song_formats_flow_test.dart.
  patrolTest('add video song: faked import appears as a video tile', ($) async {
    await resetAppState();

    final picker = FakeFilePickerWrapper(
      fileToReturn: await TestMedia.writeBundledVideoToTemp(),
    );
    await pumpRepeatLab($, filePicker: picker);

    expect($(const Key('home.empty')), findsOneWidget);

    await $(const Key('home.fab')).tap();
    await $(const Key('home.addVideo')).tap();

    await $(HomeTile).waitUntilVisible();
    expect($(HomeTile), findsOneWidget);
    // Video tiles render the ic_video app icon (audio uses ic_audio).
    expect(homeTileMediaIcon('ic_video'), findsOneWidget);
  });
}
