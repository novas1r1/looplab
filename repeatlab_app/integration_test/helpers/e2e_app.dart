import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:repeatlab/app/view/repository_wrapper.dart';
import 'package:repeatlab/bootstrap.dart';
import 'package:repeatlab/core/ui/widgets/app_icon.dart';
import 'package:repeatlab/core/ui/widgets/loading.dart';
import 'package:repeatlab/features/home/cubit/all_songs_cubit.dart';
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
  await settleBounded($, 'after launch');

  // Startup sanity check: the home FAB (or the onboarding CTA) must be
  // tappable now. Intermittently something has been observed covering the
  // home page right after launch (buttons found but not hit-testable); dump
  // what is on screen so the following failure is diagnosable.
  final cta = find.byKey(const Key('home.fab')).evaluate().isNotEmpty
      ? const Key('home.fab')
      : const Key('onboarding.next');
  if (find.byKey(cta).evaluate().isNotEmpty &&
      find.byKey(cta).hitTestable().evaluate().isEmpty) {
    dumpScreenDiagnostics($, 'after launch: $cta not hit-testable');
  }
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

/// Opens the song titled [title] from the home list and expands the controls
/// card (collapsed by default). Optionally switches to a controls [tab]
/// (`'speed'` / `'pitch'`, see `ControlsTab`).
Future<void> openSongControls(
  PatrolIntegrationTester $,
  String title, {
  String? tab,
}) async {
  await $(title).tap(settlePolicy: SettlePolicy.trySettle);
  await $(const Key('song.play')).waitUntilVisible();
  await $(const Key('song.controls.expand')).tap();
  if (tab != null) {
    await $(Key('song.controls.tab.$tab')).tap();
  }
  await settleBounded($, 'song controls expanded ($title, tab: $tab)');
}

/// Finds an [AppIcon] by its [iconName], optionally restricted to the widget
/// carrying [key] (e.g. an icon whose asset changes with state).
Finder appIcon(String iconName, {Key? key}) => find.byWidgetPredicate(
  (w) =>
      w is AppIcon && w.iconName == iconName && (key == null || w.key == key),
);

/// Prints what is on screen when an interaction unexpectedly fails: route
/// overlays (barriers, dialogs, sheets, snackbars), the song-list status and
/// every visible text. Call from a catch block, then rethrow.
void dumpScreenDiagnostics(PatrolIntegrationTester $, String context) {
  int count(Type t) => find.byType(t).evaluate().length;
  final texts = $.tester.allWidgets
      .whereType<Text>()
      .map((t) => t.data ?? t.textSpan?.toPlainText())
      .whereType<String>()
      .toList();
  String status = 'n/a';
  try {
    status = $.tester
        .element(find.byType(HomeTile).first)
        .read<AllSongsCubit>()
        .state
        .status
        .toString();
  } catch (_) {}
  debugPrint(
    'E2E-DIAG [$context] barriers=${count(ModalBarrier)} '
    'dialogs=${count(Dialog)}/${count(AlertDialog)} '
    'sheets=${count(BottomSheet)} snackbars=${count(SnackBar)} '
    'loading=${count(Loading)} allSongsStatus=$status\n'
    'E2E-DIAG texts: $texts',
  );
}

/// Leaves the song page and waits for the home list to be back.
Future<void> backToHome(PatrolIntegrationTester $) async {
  await $(BackButton).tap(settlePolicy: SettlePolicy.trySettle);
  await $(const Key('home.fab')).waitUntilVisible();
}

/// Bounded settle: pumps until no frame is scheduled, but gives up after
/// [cap] instead of Patrol's default (which has been observed to sit for
/// ~4 minutes on a long-lived animation and then succeed). On overrun it
/// prints [dumpScreenDiagnostics] — so the culprit is visible in logcat — and
/// returns; the caller's next assertion decides whether that matters.
Future<void> settleBounded(
  PatrolIntegrationTester $,
  String context, {
  Duration cap = const Duration(seconds: 15),
}) async {
  const step = Duration(milliseconds: 100);
  var waited = Duration.zero;
  await $.tester.pump();
  while ($.tester.binding.hasScheduledFrame) {
    if (waited >= cap) {
      dumpScreenDiagnostics($, 'still animating after $cap: $context');
      return;
    }
    await $.tester.pump(step);
    waited += step;
  }
  if (waited > const Duration(seconds: 3)) {
    debugPrint('E2E-DIAG settle took ${waited.inMilliseconds} ms: $context');
  }
}

/// Pumps until [condition] holds or [timeout] elapses (then fails with
/// [reason]). For state that updates asynchronously after a tap — e.g.
/// `SongCubit.selectLoop` seeks before emitting — where a settle would either
/// return too early (`noSettle`) or never (playback running).
Future<void> waitUntil(
  PatrolIntegrationTester $,
  bool Function() condition, {
  required String reason,
  Duration timeout = const Duration(seconds: 10),
}) async {
  const step = Duration(milliseconds: 100);
  var waited = Duration.zero;
  while (!condition()) {
    if (waited >= timeout) fail('Timed out waiting for: $reason');
    await $.tester.pump(step);
    waited += step;
  }
}
