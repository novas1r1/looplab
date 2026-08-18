# Setting up a Patrol E2E test suite for a Flutter app

> A self-contained, copy-paste guide distilled from the working setup in
> RepeatLab (`repeatlab_app`). Every version below is what is **verified
> working** as of 2026-08-18 on a Windows host with a physical Android device.
> Hand this file to another project / Claude session and follow it top to
> bottom. iOS is covered at the end but was not exercised in RepeatLab (Windows
> dev machine).

## 0. Verified version matrix

| Piece | Version | Notes |
| --- | --- | --- |
| Flutter | ≥ 3.44.4 | RepeatLab pins 3.44.4 via FVM (`.fvmrc` → `{"flutter": "3.44.4"}`); a plain global install of 3.44.4 or newer works the same |
| Dart SDK | ≥ 3.12.2 | comes with the Flutter above |
| `patrol` (pub, dev dep) | `^4.6.1` → resolves to **4.8.0** | `patrol_finders 3.6.0`, `patrol_log 1.2.2` come transitively |
| `patrol_cli` (global) | **4.6.1** | `fvm dart pub global activate patrol_cli 4.6.1`. 4.7.0 exists but 4.6.1 is the proven one; check the [compatibility table](https://patrol.leancode.co/documentation/compatibility-table) before bumping either side |
| `integration_test` | SDK package | `sdk: flutter` |
| `androidx.test:orchestrator` | 1.5.1 | Gradle `androidTestUtil` |
| `androidx.test.ext:junit` | 1.2.1 | Gradle `androidTestImplementation` |
| Android `minSdk` / `targetSdk` | 26 / 36 | Patrol needs ≥ 21; irrelevant otherwise |
| Java | 17 | `jvmTarget = 17` in `build.gradle.kts` |

**Rule:** the `patrol` package major/minor and the `patrol_cli` version must be
compatible per the table. Pin both; do not let one drift.

**FVM or not:** every command in this guide is written as `fvm flutter …` /
`fvm dart …` because that is how RepeatLab runs. If the target project does not
use FVM, drop the `fvm ` prefix and use the globally installed `flutter` /
`dart` (must be ≥ 3.44.4 — check with `flutter --version`). `patrol_cli`
itself is a global pub package either way; it shells out to whichever `flutter`
is on PATH (or the FVM-managed one when run inside an FVM project), so nothing
else changes.

## 1. Dependencies (`pubspec.yaml`)

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  patrol: ^4.6.1

# Top-level (sibling of `flutter:`), NOT under dev_dependencies.
patrol:
  app_name: MyApp
  test_directory: integration_test
  android:
    package_name: com.example.myapp     # = applicationId in build.gradle.kts
  ios:
    bundle_id: com.example.myapp
```

Then `flutter pub get` and install the CLI once per machine:

```bash
# with FVM
fvm flutter pub get
fvm dart pub global activate patrol_cli 4.6.1
# without FVM (global Flutter ≥ 3.44.4)
flutter pub get
dart pub global activate patrol_cli 4.6.1

patrol --version        # → patrol_cli v4.6.1
patrol doctor           # checks flutter / adb / Android SDK / Xcode
```

`~/.pub-cache/bin` (Windows: `%LOCALAPPDATA%\Pub\Cache\bin`) must be on PATH so
`patrol` resolves.

## 2. Android native harness

Two files. Nothing else on the Android side.

### 2.1 `android/app/build.gradle.kts`

```kotlin
android {
    defaultConfig {
        applicationId = "com.example.myapp"
        // ...
        // Patrol E2E (integration_test) native harness.
        testInstrumentationRunner = "pl.leancode.patrol.PatrolJUnitRunner"
        testInstrumentationRunnerArguments["clearPackageData"] = "true"
    }

    // Patrol requires the AndroidX test orchestrator so each test runs in its
    // own instrumentation instance with cleared state.
    testOptions {
        execution = "ANDROIDX_TEST_ORCHESTRATOR"
    }
}

dependencies {
    // Patrol E2E (integration_test) native harness.
    androidTestUtil("androidx.test:orchestrator:1.5.1")
    androidTestImplementation("androidx.test.ext:junit:1.2.1")
}
```

(Groovy `build.gradle` equivalent: `testInstrumentationRunner "pl.leancode.patrol.PatrolJUnitRunner"`,
`testInstrumentationRunnerArguments clearPackageData: "true"`,
`testOptions { execution 'ANDROIDX_TEST_ORCHESTRATOR' }`.)

### 2.2 `android/app/src/androidTest/java/<package path>/MainActivityTest.java`

Package path mirrors `applicationId` (`com/example/myapp/`).

```java
package com.example.myapp;

import androidx.test.platform.app.InstrumentationRegistry;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;
import org.junit.runners.Parameterized.Parameters;
import pl.leancode.patrol.PatrolJUnitRunner;

@RunWith(Parameterized.class)
public class MainActivityTest {
    @Parameters(name = "{0}")
    public static Object[] testCases() {
        PatrolJUnitRunner instrumentation = (PatrolJUnitRunner) InstrumentationRegistry.getInstrumentation();
        // Use io.flutter.embedding.android.FlutterActivity.class if the
        // AndroidManifest activity is android:name="io.flutter.embedding.android.FlutterActivity"
        instrumentation.setUp(MainActivity.class);
        instrumentation.waitForPatrolAppService();
        return instrumentation.listDartTests();
    }

    public MainActivityTest(String dartTestName) {
        this.dartTestName = dartTestName;
    }

    private final String dartTestName;

    @Test
    public void runDartTest() {
        PatrolJUnitRunner instrumentation = (PatrolJUnitRunner) InstrumentationRegistry.getInstrumentation();
        instrumentation.runDartTest(dartTestName);
    }
}
```

Consequence of the orchestrator: **every `patrolTest` runs in a fresh app
process** (~10–15 s overhead each). Merge tests that share a fixture into one
test with soft per-item assertions rather than writing many tiny tests.

## 3. Test layout

```
integration_test/
  test_bundle.dart            # GENERATED by `patrol test`/`patrol build` — do not edit;
                              # commit or ignore, either works (RepeatLab commits it)
  flows/
    onboarding_flow_test.dart
    <feature>_flow_test.dart
  helpers/
    e2e_app.dart              # pumpApp() + shared finders/wait helpers
    reset_app_state.dart      # known state before each test
    fakes.dart                # fakes for native/network seams
    test_media.dart           # bundled / synthesised fixtures (if needed)
```

Only files matching `*_test.dart` under `test_directory` are bundled. Helpers
live in `helpers/` precisely so they are *not* picked up as tests.

## 4. The app-side seams (the part that makes it deterministic)

Patrol drives the **real app**, so anything non-deterministic (native pickers,
in-app purchases, network SDKs, crash reporters) must be injectable. Pattern:

1. Extract app *construction* out of `main()` into `lib/bootstrap.dart`:

   ```dart
   Future<App> bootstrap({
     FilePickerWrapper? filePicker,
     PurchasesRepository? purchases,
   }) async {
     WidgetsFlutterBinding.ensureInitialized();
     // open DB, init plugins, load prefs, ...
     return App(
       // ...
       filePicker: filePicker ?? const FilePickerWrapper(),
       purchases: purchases ?? const PurchasesRepository(),
     );
   }
   ```

   `main()` = `runApp(SentryWidget(await bootstrap()))` etc. Sentry / Clarity /
   analytics init stay in `main()`, so tests never touch them.
2. Every seam **defaults to the real implementation** — no test-only branches in
   production widgets. Thread the fields through `App → RepositoryWrapper`.
3. Tests pass fakes (`FakeFilePickerWrapper`, `FakePurchasesRepository(isPro:)`)
   that extend the real classes and never call the native/plugin API.

## 5. Helper skeletons (copy and adapt)

### 5.1 `helpers/e2e_app.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:myapp/bootstrap.dart';

import 'fakes.dart';

/// Pumps the real bootstrap()-built app with fakes injected.
Future<void> pumpMyApp(
  PatrolIntegrationTester $, {
  FilePickerWrapper? filePicker,
  bool isPro = true,
}) async {
  final app = await bootstrap(
    filePicker: filePicker ?? FakeFilePickerWrapper(),
    purchases: FakePurchasesRepository(isPro: isPro),
  );
  await $.pumpWidget(app);
  // If the app shows a looping animation on startup, pumpAndSettle never
  // settles: pump until the loader widget is gone (bounded), then settleBounded.
  const budget = Duration(seconds: 60);
  const step = Duration(milliseconds: 100);
  var waited = Duration.zero;
  while (find.byType(Loading).evaluate().isNotEmpty) {
    if (waited >= budget) fail('App still loading after $budget');
    await $.tester.pump(step);
    waited += step;
  }
  await settleBounded($, 'after launch');
}

/// Call first thing in every flow's main(). Patrol drives Android through
/// UiAutomator (an accessibility service); in the first process of a run
/// Flutter learns "semantics enabled" a moment AFTER testWidgets records its
/// SemanticsHandle baseline → spurious "A SemanticsHandle was active at the
/// end of the test". Waiting in a plain setUp moves the flip before the
/// baseline.
void registerE2ESetUp({Duration maxWait = const Duration(seconds: 3)}) {
  setUp(() async {
    final dispatcher = PlatformDispatcher.instance;
    const step = Duration(milliseconds: 50);
    var waited = Duration.zero;
    while (!dispatcher.semanticsEnabled && waited < maxWait) {
      await Future<void>.delayed(step);
      waited += step;
    }
  });
}

/// Bounded settle: Patrol's default settle has been seen to sit ~4 min on a
/// long-lived animation. Give up after [cap], dump diagnostics, return.
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
      debugPrint('E2E-DIAG still animating after $cap: $context');
      return;
    }
    await $.tester.pump(step);
    waited += step;
  }
}

/// Pump until [condition] holds or fail — for state that updates async after a
/// tap where a settle either returns too early or never (playback running).
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
```

### 5.2 `helpers/reset_app_state.dart`

```dart
/// Resets the app to a known state BEFORE the app is pumped.
Future<void> resetAppState({bool skipOnboarding = true, String? languageCode = 'en'}) async {
  // 1. Wipe on-disk DB through a THROWAWAY handle and CLOSE it before
  //    bootstrap() opens the app's own handle (two handles on one file race).
  final db = await databaseFactoryIo.openDatabase(await _dbPath());
  await _store.delete(db);
  await db.close();

  // 2. Real SharedPreferences (NOT setMockInitialValues — the test isolate and
  //    the app share the on-device store under Patrol).
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  await prefs.setInt(kChangelogVersionShown, 1 << 30); // suppress "what's new" bubble
  await prefs.setBool(kHasRatedApp, true);             // suppress rate dialog
  if (skipOnboarding) await prefs.setBool(kIntroShown, true);
  if (languageCode != null) await prefs.setString(kLanguageCode, languageCode);
}
```

Also seed fixtures here (write rows into the DB / files into
`getApplicationDocumentsDirectory()`), again closing the handle before pumping.

### 5.3 `helpers/fakes.dart`

Extend the real wrappers; return canned results:

```dart
class FakeFilePickerWrapper extends FilePickerWrapper {
  List<File> filesToReturn;
  FakeFilePickerWrapper({List<File>? filesToReturn}) : filesToReturn = [...?filesToReturn];

  @override
  Future<FilePickerResult?> pickFiles({...}) async {
    if (filesToReturn.isEmpty) return null; // = user cancelled
    return FilePickerResult([for (final f in filesToReturn) PlatformFile(name: p.basename(f.path), size: f.lengthSync(), path: f.path)]);
  }

  @override
  Future<String?> saveFile({...}) async => p.join((await getTemporaryDirectory()).path, 'export_$fileName');
}

class FakePurchasesRepository extends PurchasesRepository {
  FakePurchasesRepository({required this.isPro});
  final bool isPro;
  @override Future<bool> get hasLifetimePurchase async => isPro;
  // ...never calls Purchases.*
}
```

Fixture files: bundle tiny assets (`assets/test/`, declared in `pubspec.yaml`
`assets:`) and copy them via `rootBundle.load` → temp file, or synthesise
(e.g. a silent 16-bit PCM WAV) at runtime.

## 6. Writing a flow

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import '../helpers/e2e_app.dart';
import '../helpers/reset_app_state.dart';

void main() {
  registerE2ESetUp();

  patrolTest('onboarding: first run walks to the home screen', ($) async {
    await resetAppState(skipOnboarding: false);
    await pumpMyApp($);

    expect($(const Key('onboarding.next')), findsOneWidget);
    await $(const Key('onboarding.next')).tap();
    await $(const Key('onboarding.next')).tap(settlePolicy: SettlePolicy.trySettle);
    await $(const Key('home.fab')).waitUntilVisible();
    expect($(const Key('home.fab')), findsOneWidget);
  });
}
```

Conventions that paid off:

- **Keys, not text.** `Key('<screen>.<element>')`, e.g. `home.fab`,
  `song.controls.tab.speed`, `editLoop.save`; repeated rows get an id suffix
  (`song.loop.edit.<loopId>`). Set keys at the call site. Text is localised
  and brittle (RepeatLab ships 16 locales; the reset pins `en` anyway).
- `$(...).tap()` uses Patrol's settle; on screens with continuous animation
  use `tap(settlePolicy: SettlePolicy.trySettle)` or `noSettle` +
  `waitUntilVisible()` / `waitUntil(...)`.
- Assert on **UI / cubit state**, not on side effects you can't observe
  (audio output, OS dialogs).
- Wrap risky steps in try/catch → dump diagnostics (visible texts, overlay
  counts) via `debugPrint` → rethrow. Everything printed lands in `adb logcat`.
- Reading cubit state from a test:
  `$.tester.element(find.byType(SomeWidget).first).read<SomeCubit>().state`.

### 6.1 Native UI via the platform automator

Native sheets (share sheet, RevenueCat paywall, permission dialogs) have no
Flutter keys. Use `$.platformAutomator` (Patrol 4.x name; older docs say
`$.native`):

```dart
final native = $.platformAutomator;
final views = await native.android.getNativeViews(AndroidSelector(text: 'Restore'));
final visible = views.roots.isNotEmpty;
await native.android.pressBack();               // dismiss
await native.android.getNativeViews(null);      // dump full tree for debugging
// permission dialogs: await native.grantPermissionWhenInUse();
```

UiAutomator only reports what's *on screen*, so probe for text at the top of a
sheet. Native SDKs localise by **device** locale, so list every locale a test
device may run in. After returning from a native activity give Flutter a
moment (`Future.delayed(500 ms)` then `pumpAndSettle`).

## 7. Running

```bash
patrol test                                          # whole suite, first connected device
patrol test -d <deviceId>                            # pick device (`[fvm] flutter devices`)
patrol test -t integration_test/flows/foo_flow_test.dart   # single file
patrol test --verbose                                # show gradle/adb output
adb logcat -s flutter:V                              # follow app + test output live
```

Makefile shortcut used in RepeatLab:

```make
e2e:
	patrol test $(if $(DEVICE),-d $(DEVICE),) $(if $(TARGET),-t $(TARGET),)
```

`patrol test` regenerates `integration_test/test_bundle.dart`, builds the debug
APK + `androidTest` APK, installs both, and runs them through the orchestrator.
First build is slow (several minutes); incremental runs are fast. `patrol build
android` produces the APKs without running (Firebase Test Lab etc.).

## 8. Gotchas checklist (all hit in practice)

- **`patrol_cli` ↔ `patrol` mismatch** → cryptic bundle/build errors. Pin both.
- **`patrol:` block missing / wrong `package_name`** → "app not found" at install.
- **Two DB handles on one file** (reset hook vs. app) → hangs/corruption. Close
  the throwaway handle before pumping.
- **`setMockInitialValues`** does nothing on-device; use the real
  `SharedPreferences`.
- **Prefs read at build time** (onboarding flag, locale) → `await` all writes
  before `pumpWidget`.
- **Looping animations** (Lottie loaders, bobbing hints, rate dialogs) make
  `pumpAndSettle` time out → suppress via prefs in `resetAppState` and use the
  bounded settle helpers.
- **"A SemanticsHandle was active at the end of the test"** on the first test of
  a run → `registerE2ESetUp()` (§5.1).
- **Fresh process per test** (orchestrator) → keep the number of tests small;
  seed several fixtures into one test.
- **Native paywall / share sheet close buttons** are often unlabeled icons →
  dismiss with `pressBack()`.
- **Emulator media decode is slow** → tiny fixture clips (~1–2 s), generous but
  bounded waits.
- Never hit live purchase/analytics/crash SDKs from tests; keep their init in
  `main()`, outside `bootstrap()`.

## 9. iOS (not verified in RepeatLab — Windows host)

Per the Patrol docs for 4.x, on a Mac:

1. `open ios/Runner.xcworkspace` → File → New → Target → **UI Testing Bundle**
   named `RunnerUITests`, iOS deployment target ≥ 13, delete the generated
   Swift file, add `RunnerUITests.m`:

   ```objc
   @import XCTest;
   @import patrol;
   @import ObjectiveC.runtime;
   PATROL_INTEGRATION_TEST_IOS_RUNNER(RunnerUITests)
   ```
2. In the `RunnerUITests` target's Build Settings, set the same
   `Bundle Identifier` base and add `$(inherited)` framework search paths; in
   `ios/Podfile` add `target 'RunnerUITests' do inherit! :complete end` inside
   the `Runner` target and run `pod install`.
3. Xcode → Product → Scheme → Edit `Runner` → Test → add `RunnerUITests`.
4. `patrol test -d "iPhone 15"` (simulator) — the same Dart tests and helpers
   run unchanged; replace `native.android.*` calls with `native.ios.*` or the
   cross-platform `$.platformAutomator` API where used.

Always cross-check with https://patrol.leancode.co/documentation for the exact
Xcode steps of the pinned version.

## 10. New-project bootstrap order

1. Add deps + `patrol:` block; `pub get`; activate `patrol_cli 4.6.1`
   (`dart pub global activate …`, with or without the `fvm` prefix).
2. Android `build.gradle.kts` + `MainActivityTest.java`.
3. `lib/bootstrap.dart` seam; move SDK init out into `main()`.
4. `integration_test/helpers/` (pump, reset, fakes).
5. Add stable `Key`s to the widgets the first flow touches.
6. Write ONE smoke flow (launch → main screen visible); `patrol test -t` it on a
   real device/emulator until green.
7. Add flows one at a time; merge fixture-sharing tests.
8. Wire CI (`reactivecircus/android-emulator-runner` + `patrol test`) as a
   separate job from host unit tests.
