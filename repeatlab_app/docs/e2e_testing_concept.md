# End-to-End Testing Concept — RepeatLab (Patrol)

> Status: **proposal for review.** This document describes *how* we will write
> Patrol end-to-end (integration) tests for RepeatLab. It is a clean-slate plan:
> there is **no** Patrol harness, `integration_test/` directory, or E2E test code
> in the repo yet. The seams, fakes, native harness, and CI job described here are
> **follow-up implementation work** — this doc specifies them; it does not
> implement them.
>
> Context: RepeatLab is a solo-maintained app with 33k+ downloads, shipping
> features and updates constantly. E2E tests give a single safety net that proves
> the whole app — navigation, the cubit graph, Sembast persistence across screens,
> and media plumbing — still works before each release, runnable in CI today and
> on a device farm later.

## 1. Goals & philosophy

E2E tests exercise **real user flows on a real device**, through the real widget
tree, the real cubits, and a real on-disk Sembast database. They are the only
layer that proves the app *as a whole* works: navigation, the provider/bloc
graph, DB persistence across screens, and platform plumbing (audio via SoLoud /
audioplayers, video via media_kit).

They are **expensive and slow**, so we keep them **few, high-value, and
deterministic**:

- We cover **flows**, not units. Per-emission cubit logic, repository edge
  cases, and pixel rendering are already owned by the existing cubit / repository
  / golden layers (`test/`) — E2E does not re-litigate them.
- Every flow is **deterministic**: no real native file picker, no live RevenueCat
  store, no real share targets. Native results that can't be made stable on an
  emulator are injected (§3).
- Every flow starts from a **known, reset state** (§3.5).

| | E2E (this doc) | Cubit / Repo / Golden (`test/`) |
| --- | --- | --- |
| Runs on | device / emulator | host `flutter test` |
| DB | real on-disk Sembast (`repeatlab.db`) | in-memory / mocked repositories |
| Widget tree | real `App` via `bootstrap()` | `pumpApp` harness (`test/helpers/`) |
| Proves | the app works end-to-end | a unit behaves correctly |

## 2. Tooling

**Nothing is wired yet.** Adding Patrol requires:

- **`patrol`** + **`integration_test`** as dev dependencies, plus a `patrol`
  block in `pubspec.yaml` (`app_name: RepeatLab`, Android
  `package_name: com.repeatlab.app`, iOS `bundle_id` placeholder).
- **Android native harness** —
  `android/app/src/androidTest/java/com/repeatlab/app/MainActivityTest.java`,
  `PatrolJUnitRunner` + `androidx.test:orchestrator` configured in
  `android/app/build.gradle.kts`.

Already present and reusable:

- `test/helpers/` — `pump_app.dart`, `mock_repositories.dart`, `mock_data.dart`,
  `mock_cubits.dart`. The mock repositories overlap with the fakes we need (§3.3,
  §3.4) and should be reused where the shapes match.
- `bloc_test`, `mocktail`, `alchemist` (golden) are present.
- iOS `RunnerTests` target exists but is an **empty stub** — iOS Patrol wiring is
  deferred (§7).

Test layout:

```
integration_test/
  flows/
    onboarding_flow_test.dart
    add_audio_song_flow_test.dart
    add_video_song_flow_test.dart      # the feature/video-support headline flow
    loop_crud_flow_test.dart
    speed_control_flow_test.dart
    loop_export_flow_test.dart
    backup_flow_test.dart
    language_switch_flow_test.dart
    delete_all_data_flow_test.dart
    song_reorder_flow_test.dart
    freemium_gate_flow_test.dart
  helpers/
    e2e_app.dart                       # pumpApp() via bootstrap() + fakes
    reset_app_state.dart               # the setUp reset hook (§3.5)
    fakes.dart                         # FakeFilePickerWrapper, FakePurchasesRepository, asset→temp
    keys.dart                          # shared Key constants (§4)
  assets/
    test_audio.mp3                     # short (~5–10s) bundled clip
    test_video.mp4                     # short bundled clip
```

## 3. Test architecture & seams

The whole design rests on running **one shared app entry** for both production
and tests, with a few narrow injection seams. None of these change production
behaviour — **every seam defaults to the real implementation**.

> Today `main()` builds everything inline in `_initializeApp()` and there is no
> test seam. The seams below are follow-up work.

### 3.1 Shared `bootstrap()` entry

`lib/main.dart::_initializeApp()` currently opens the Sembast DB, registers the
`DurationMapper`, inits SoLoud + media_kit, loads `PackageInfo` /
`SharedPreferences`, builds `LocalConfigRepository`, and then wraps `App` in
`SentryWidget` / `ClarityWidget` before `runApp`. Extract the **construction**
half into a shared function:

```dart
// lib/bootstrap.dart
Future<App> bootstrap({
  Database? db,
  FilePickerWrapper? filePicker,
  PurchasesRepository? purchases,
  SharedPreferences? prefs,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = db ?? await _openDatabase();      // path_provider + repeatlab.db
  MapperContainer.globals.use(const DurationMapper());
  final soloud = SoLoud.instance..init();            // (awaited)
  MediaKit.ensureInitialized();
  final packageInfo = await PackageInfo.fromPlatform();
  final sharedPreferences = prefs ?? await SharedPreferences.getInstance();
  final localConfig = LocalConfigRepository(sharedPreferences: sharedPreferences);
  return App(
    db: database,
    soloud: soloud,
    packageInfo: packageInfo,
    localConfigRepository: localConfig,
    filePicker: filePicker ?? FilePickerWrapper(),   // new App field, real default (§3.3)
    purchases: purchases ?? const PurchasesRepository(), // new App field, real default (§3.4)
  );
}
```

- `main()` calls `await bootstrap()` and keeps its existing
  **Sentry / Clarity / UserOrient init and `runApp(SentryWidget(...))`** — those
  stay in `main`, so **test runs never initialise Sentry or Clarity**.
- `App` gains two fields (`filePicker`, `purchases`) that it threads into
  `RepositoryWrapper` (§3.3, §3.4).
- The Patrol entry pumps the returned widget:

```dart
await $.pumpWidgetAndSettle(
  await bootstrap(
    filePicker: FakeFilePickerWrapper(audio: testAudioPath),
    purchases: FakePurchasesRepository(isPro: true),
  ),
);
```

### 3.2 No new production code paths

These seams add two constructor fields and one extracted function. They do **not**
add test-only branches inside production widgets — production always passes the
real `FilePickerWrapper()` / `PurchasesRepository()`, exactly as today. The
existing host `test/` suite (cubits, repositories, goldens) is unaffected.

### 3.3 FilePicker seam — *the* key seam

Every media import (audio and video) and the loop/backup export save dialog go
through `FilePickerWrapper` (`lib/app/view/repository_wrapper.dart`). It is
already a constructor dependency of `FileRepository`
(`file_repository.dart:11-14`) — but `RepositoryWrapper` constructs it **inline**
(`repository_wrapper.dart:39-41`), so it isn't reachable for tests yet.

1. Thread a `FilePickerWrapper` field from `bootstrap → App → RepositoryWrapper`
   (default `FilePickerWrapper()`), mirroring how `db` / `localConfigRepository`
   are already threaded.
2. Tests inject a `FakeFilePickerWrapper extends FilePickerWrapper` whose
   `pickFiles` returns a `FilePickerResult` pointing at a **bundled test asset**
   (`test_audio.mp3` / `test_video.mp4`) copied to a temp path. `FileRepository`'s
   real "copy into app documents dir" logic
   (`pickAudioFiles` / `pickVideoFiles`) then runs **unchanged** on the
   real file, so `SongRepository.addSongFile` / `addVideoFile` and playback work
   end-to-end. `saveFile` returns a canned temp path for the export flow.

This is the single most valuable seam: it removes the **native file picker** —
the only blocking native UI on the import path — making every add-song flow fully
deterministic.

### 3.4 Purchases (RevenueCat) seam

`PurchasesRepository` (`purchases_repository.dart`) getters hit the live
RevenueCat store (`Purchases.getCustomerInfo()` etc.), which is non-deterministic
in CI and gates the freemium loop limit. `RepositoryWrapper` builds
`const PurchasesRepository()` inline (`repository_wrapper.dart:56-58`).

1. Thread a `PurchasesRepository` from `bootstrap → App → RepositoryWrapper`
   (default `const PurchasesRepository()`).
2. Most flows inject a `FakePurchasesRepository(isPro: true)` so the multi-loop /
   premium-gated paths aren't blocked. The **freemium gate** flow (§5) injects
   `isPro: false` to assert the paywall fires on the 2nd loop.

`FakePurchasesRepository` overrides the `hasWeeklySubscription` /
`hasYearlySubscription` / `hasLifetimePurchase` getters and `offers`; it never
calls `Purchases.*`, so RevenueCat is never reached in tests.

### 3.5 Reset hook — known state before each test

The app opens a real on-disk Sembast DB (`repeatlab.db` in the app documents
dir). Before each test, a Dart-side `setUp` resets it through a **separate,
throwaway** handle and clears preferences:

```dart
// integration_test/helpers/reset_app_state.dart
Future<void> resetAppState({bool skipOnboarding = true}) async {
  // 1. Wipe the songs store via a throwaway handle, then CLOSE it.
  final dir = await getApplicationDocumentsDirectory();
  final db = await databaseFactoryIo.openDatabase(join(dir.path, 'repeatlab.db'));
  await SongRepository(db: db, soLoud: SoLoud.instance).clearDb(); // deletes 'songs' store
  await db.close();           // release the file handle BEFORE bootstrap() opens it

  // 2. Clear preferences.
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  if (skipOnboarding) {
    await prefs.setBool(kIntroShown, true);   // skip onboarding for all but the onboarding flow
  }
}
```

Critical ordering and gotchas:

- **Two Sembast handles on one file race.** The reset hook's throwaway DB **must**
  be `await close()`-d before `bootstrap()` opens the app's own handle. Never
  reset the app's *live* DB instance mid-test through a second handle.
- **`introShown` is read at build.** `App` decides `HomePage` vs `OnboardingPage`
  from `LocalConfigRepository.introShown` (`app.dart:90-103`), and `LocaleCubit`
  reads the saved locale eagerly. The reset hook's prefs writes must be **awaited
  before** pump.
- **On-device SharedPreferences.** Use the real store
  (`getInstance().clear()` / `setBool`), **not** `setMockInitialValues` (which
  only affects the in-process mock). The test isolate and the app share the same
  store under Patrol.
- For the **onboarding** flow only, call `resetAppState(skipOnboarding: false)`.

### 3.6 Media playback determinism

Audio plays through real `audioplayers` / SoLoud; video through real media_kit.
Keep flows stable by:

- Using **short** bundled clips (~5–10s). Long files time out; video decode is
  slow on emulators.
- Driving loop bounds and seeking through **cubit methods / keyed inputs**, not
  waveform drags — touch-based seek on the waveform is known to time out
  (see `AGENTS.md` / `MANUAL_TEST.md`).
- Asserting on **cubit/UI state** (playing flag, loop markers, position label),
  not on actual emitted audio.

## 4. Finder strategy & key convention

The app today has only `ValueKey(song.id)` / `ValueKey(loop.id)` on list tiles
and `GlobalKey`s for the tutorial coach marks. All UI text is localized across
**16 locales**, so text finders are brittle. We add **stable keys** to the
interactive widgets the tests touch.

**Convention:** `Key('<screen>.<element>')` — dot-namespaced, camelCase segments.
Repeated rows keep a stable id suffix: `Key('home.tile.<songId>')`,
`Key('song.loop.tile.<loopId>')`.

**Placement:** keys are set **at the call site** on the existing widget instance
(do not bake a screen's key inside a shared component).

Per-flow keys to add:

| Flow / screen | Keys |
| --- | --- |
| Onboarding | `onboarding.next`, `onboarding.finish` |
| Home | `home.fab`, `home.addAudio`, `home.addVideo`, `home.drawer`, `home.empty`, `home.tile.<id>` |
| Song detail | `song.play`, `song.back10`, `song.forward10`, `song.addLoop`, `song.loop.tile.<id>`, `song.loop.export.<id>`, `song.loop.edit.<id>`, `song.video.resize` |
| Speed control | `song.speed.toggleMode`, `song.speed.multiplierSlider`, `song.speed.bpmOriginal`, `song.speed.bpmTarget`, `song.speed.reset` |
| Edit loop (sheet) | `editLoop.name`, `editLoop.start`, `editLoop.end`, `editLoop.save`, `editLoop.delete` |
| Export loop (sheet) | `exportLoop.format`, `exportLoop.sampleRate`, `exportLoop.confirm` |
| Settings | `settings.language`, `settings.backupExport`, `settings.backupImport`, `settings.deleteAll`, `settings.deleteAll.confirm` |
| Paywall | `paywall.weekly`, `paywall.yearly`, `paywall.lifetime`, `paywall.close` |

## 5. Flow coverage

Each flow starts from a fresh `resetAppState()` and drives the real app.

- **Onboarding:** first-run flow — the **only** test that runs
  `resetAppState(skipOnboarding: false)`; walk the slides, tap finish, assert
  landing on `HomePage` and that `introShown` is now set.
- **Add audio song:** `home.fab` → `home.addAudio` → `FakeFilePickerWrapper`
  returns the bundled mp3 → assert the song tile appears with the resolved title.
- **Add video song (headline):** `home.fab` → `home.addVideo` → fake mp4 → assert
  the video tile appears (videocam icon / `MediaType.video`) and opening it
  renders `VideoPreview`.
- **Loop CRUD:** open a song → `song.addLoop` (set name / start / end via
  `editLoop.*`) → assert the loop tile → edit (rename) → assert the rename → delete
  (`editLoop.delete`) → assert it's gone.
- **Speed control:** `song.speed.toggleMode` between ×-multiplier and BPM;
  in ×-mode the slider changes the multiplier; in BPM-mode original/target derive
  the multiplier (e.g. 90/120 → 0.75×); `song.speed.reset` → 1.0×.
- **Loop export:** export a loop → pick format / sample rate
  (`exportLoop.format` / `exportLoop.sampleRate`) → `exportLoop.confirm` →
  `saveFile` fake returns a temp path → **assert the in-app success snackbar**
  (the `l10n` export-success message). Do not assert on the OS save dialog.
- **Backup:** Settings → `settings.backupExport` → assert the success snackbar,
  then **dismiss the native share sheet via `$.native`** (back / tap-outside) —
  backup export uses `share_plus` (`backup_cubit.dart`), an OS sheet with no
  Flutter key. Then `settings.backupImport` via the fake picker → assert the
  import summary dialog (song/loop counts).
- **Language switch:** drawer → `settings.language` → switch **DE → EN → DE**;
  assert a known label re-localizes each way.
- **Delete all data:** Settings → `settings.deleteAll` → `settings.deleteAll.confirm`
  → assert the home empty state (`home.empty`).
- **Song reorder:** seed 3 songs → drag the first below the others → assert the
  new order persists after a reload (re-pump).
- **Freemium gate:** inject `FakePurchasesRepository(isPro: false)` → create the
  first (free) loop OK → attempt a 2nd → assert the paywall appears
  (`paywall.*`).

## 6. Permissions — almost nothing to grant

Unlike the camera/scanner app this concept was adapted from, RepeatLab's import
path uses **`file_picker`** (Storage Access Framework on Android) with the picker
**fully faked** (§3.3), so the real picker — and any permission dialog — is
**never invoked** during flows. There is no camera, microphone, or photo-library
permission in the tested paths.

The only genuine native UI left is the **`share_plus` share sheet** in the backup
export flow (§5), which is dismissed via `$.native`, not granted. So there is no
dedicated permission smoke test in this round; if a future flow exercises the
real picker, add `$.native` grant handling there only.

## 7. Risks & gotchas

- **Two `repeatlab.db` handles race.** The reset hook's throwaway Sembast handle
  must be `await close()`-d before `bootstrap()` opens the app's instance (§3.5).
- **`introShown` / locale read eagerly at build.** Awaited prefs writes must
  precede pump, or the app branches to the wrong screen / locale (§3.5).
- **On-device SharedPreferences.** Use the real store, not
  `setMockInitialValues` (§3.5).
- **Waveform touch-seek can time out.** Drive seeking via cubit methods / keyed
  controls, not drags (§3.6).
- **Video is slow on emulators.** Short clips + generous settles; the add-video
  flow is the first to exercise media_kit on-device — tune timeouts there first.
- **Native share sheet has no Flutter key.** Assert the in-app success snackbar,
  then dismiss the sheet via `$.native` (§5).
- **Never hit the live RevenueCat store.** Always inject `FakePurchasesRepository`
  in flows (§3.4).
- **CI Flutter version drift.** `.fvmrc` / the app expect **3.41.9** but
  `.github/workflows/main.yaml` currently pins **3.38.4** — align CI to 3.41.9
  when wiring the E2E job (§8).

## 8. Running & next steps

```bash
make e2e                                                     # all integration_test/ flows
make e2e DEVICE=<id> TARGET=integration_test/flows/add_video_song_flow_test.dart
# equivalent: patrol test [-d <id>] [-t <file>]
```

The `patrol_cli` version must match the `patrol` package per the
[compatibility table](https://patrol.leancode.co/documentation/compatibility-table);
for `patrol 4.8.x` that is `fvm dart pub global activate patrol_cli 4.6.1`.

Run target for now: a **local Android emulator** first (prove the harness on the
headline add-video flow), then a **GitHub Actions** `e2e-android` job alongside
the existing `analyze` / `test` jobs, using `reactivecircus/android-emulator-runner`
(AVD + KVM) on a push to `feature/video-support`. Keep it a **separate job** so
the fast host unit/golden suite isn't slowed.

**Explicitly deferred:**

- **iOS** — the `RunnerTests` target exists but is an empty stub; Patrol iOS
  wiring is a macOS/Xcode task, out of scope on the Windows dev machine.
- **Device farm** — Firebase Test Lab (or BrowserStack) as the cloud-device next
  step once the emulator job is green. Patrol + `integration_test` both run on
  Firebase Test Lab.

### Implementation status

Steps 1–5 below are implemented (seams, keys, harness, `integration_test/helpers/`,
all 11 flows) and the suite runs on a physical Android device via `make e2e`
(first verified 2026-08-17 on a Pixel 8a). Step 6 (CI job) is still open. The
original build order, for reference:

1. **Seams** — `lib/bootstrap.dart`; thread `filePicker` + `purchases` through
   `App` → `RepositoryWrapper`; `main()` calls `bootstrap()`.
2. **Keys** — add the §4 keys at call sites.
3. **Harness** — `pubspec.yaml` (`patrol` + `integration_test` + `patrol` block),
   Android `androidTest` + `build.gradle.kts`.
4. **Test infra** — `integration_test/helpers/` (`e2e_app.dart`,
   `reset_app_state.dart`, `fakes.dart`, `keys.dart`) + bundled test media.
5. **Flows** — the 11 flows in §5, starting with add-video to validate the
   harness on-device.
6. **CI** — the `e2e-android` job; align Flutter to 3.41.9.

**Verification:** `flutter analyze` clean and the existing `test/` suite still
green (seams must not break host tests); the add-video flow passes locally on an
emulator; the `e2e-android` CI job goes green.
