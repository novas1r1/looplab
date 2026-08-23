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

  patrolTest('add audio song: faked import appears in the list', ($) async {
    await resetAppState();

    // The fake picker hands back a synthesised silent WAV; FileRepository then
    // runs its real copy-into-docs logic and SoLoud loads it.
    final picker = FakeFilePickerWrapper(
      fileToReturn: await TestMedia.writeSilentWavToTemp(),
    );
    await pumpRepeatLab($, filePicker: picker);

    // Starts empty.
    expect($(const Key('home.empty')), findsOneWidget);

    await $(const Key('home.fab')).tap();
    await $(const Key('home.addAudio')).tap();

    // Import → copy → SoLoud load → persist → list refresh.
    await $(HomeTile).waitUntilVisible();
    expect($(HomeTile), findsOneWidget);
  });
}
