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

/// Registers a [setUp] that lets the platform finish enabling accessibility
/// before each test body starts. Call it first thing in every flow's `main()`.
///
/// Patrol drives the device through UiAutomator, which is an accessibility
/// service, so Android reports `semanticsEnabled = true` to Flutter — and
/// [SemanticsBinding] then holds its own [SemanticsHandle]. In the first app
/// process of a run that report arrives a moment *after* the test has started,
/// i.e. after `testWidgets` recorded its baseline handle count, and the test
/// then fails at teardown with "A SemanticsHandle was active at the end of the
/// test" although every step passed. Waiting here (a plain `setUp` runs before
/// the baseline is taken) moves the flip in front of it. On a device that never
/// enables semantics this costs at most [maxWait] per test.
void registerE2ESetUp({Duration maxWait = const Duration(seconds: 3)}) {
  setUp(() async {
    final dispatcher = PlatformDispatcher.instance;
    const step = Duration(milliseconds: 50);
    var waited = Duration.zero;
    while (!dispatcher.semanticsEnabled && waited < maxWait) {
      await Future<void>.delayed(step);
      waited += step;
    }
    debugPrint(
      'E2E setUp: platform semanticsEnabled=${dispatcher.semanticsEnabled} '
      'after ${waited.inMilliseconds} ms',
    );
  });
}
