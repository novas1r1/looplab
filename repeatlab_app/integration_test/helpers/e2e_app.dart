import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:repeatlab/app/view/repository_wrapper.dart';
import 'package:repeatlab/bootstrap.dart';
import 'package:repeatlab/core/ui/widgets/app_icon.dart';
import 'package:repeatlab/core/ui/widgets/loading.dart';
import 'package:repeatlab/features/home/widgets/home_tile.dart';
import 'package:repeatlab/features/song/widgets/loop_tile.dart';

import 'fakes.dart';

/// Pumps the real [bootstrap]-built app with test fakes injected.
///
/// - [filePicker] fakes media import / export (defaults to an empty fake).
/// - [isPro] toggles the faked RevenueCat entitlement.
///
/// Sentry / Clarity are NOT initialised here (they live in `main`), so test
/// runs stay offline and side-effect free.
Future<void> pumpRepeatLab(
  PatrolIntegrationTester $, {
  FilePickerWrapper? filePicker,
  bool isPro = true,
}) async {
  final app = await bootstrap(
    filePicker: filePicker ?? FakeFilePickerWrapper(),
    purchases: FakePurchasesRepository(isPro: isPro),
  );
  await $.pumpWidget(app);
  // The home page shows the looping [Loading] Lottie until the song list has
  // been read from disk (first launch after an install can take a while), and
  // pumpAndSettle can't settle on a looping animation. Pump until the loader
  // is gone, with a generous but finite budget so a real hang fails fast and
  // with a clear message instead of a bare "pumpAndSettle timed out".
  const budget = Duration(seconds: 60);
  const step = Duration(milliseconds: 100);
  var waited = Duration.zero;
  while (find.byType(Loading).evaluate().isNotEmpty) {
    if (waited >= budget) {
      fail('App still showing Loading after $budget (initial song load hung?)');
    }
    await $.tester.pump(step);
    waited += step;
  }
  await $.pumpAndSettle();
}

/// Finds the per-loop action button whose key starts with [prefix]
/// (`song.loop.edit.` / `song.loop.export.` — the suffix is the loop id, which
/// a test usually doesn't know). Scoped to [LoopTile] so it never matches the
/// app bar.
Finder loopTileButton(String prefix) => find.descendant(
  of: find.byType(LoopTile),
  matching: find.byWidgetPredicate((w) {
    final key = w.key;
    return key is ValueKey<String> && key.value.startsWith(prefix);
  }),
);

/// Finds the media-type icon inside a [HomeTile]: `'ic_audio'` or
/// `'ic_video'` (see `HomeTile`, which switches on `song.mediaType`).
Finder homeTileMediaIcon(String iconName) => find.descendant(
  of: find.byType(HomeTile),
  matching: find.byWidgetPredicate(
    (w) => w is AppIcon && w.iconName == iconName,
  ),
);
