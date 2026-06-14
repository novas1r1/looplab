# Testing Concept — auditneo_app

> Status: **proposal for review.** This document describes *how* we will test the
> app. No test code is written yet beyond the two existing reference files. Once
> this concept is approved, implementation proceeds layer by layer.
>
> **Phasing:** Unit, data, and cubit tests come **first** (Sections 1–8). Golden
> tests (Alchemist) and integration tests (Patrol) — including their dependency
> and native setup — are deferred to the end (Sections 9 and 10) and are tackled
> only after the earlier layers are in place.

## 1. Goals & philosophy

We optimise for **useful coverage, not a coverage number**. A test earns its
place when it can fail for a real reason: a broken SQL query, a wrong cubit state
transition, a mis-formatted export, a visual regression, or a broken end-to-end
flow. We do **not** test generated code or pure delegation.

Four test layers, each with a clear responsibility:


| Layer           | Tool                     | Tests what                                                                                                  | Lives in                                   | Phase          |
| --------------- | ------------------------ | ----------------------------------------------------------------------------------------------------------- | ------------------------------------------ | -------------- |
| **Unit**        | `flutter_test`           | Pure logic: formatters, the export service's plan builder, file/template services                           | `test/core`, `test/data/services`          | First          |
| **Data**        | `drift` + `flutter_test` | DAOs **and** repositories against a real in-memory SQLite DB: SQL, joins, FK cascades, constraints, streams | `test/data/daos`, `test/data/repositories` | First          |
| **Cubit**       | `bloc_test` + `mocktail` | State machines: every emission path, with mocked repositories/services                                      | `test/screens/<feature>/cubits`            | First          |
| **Golden**      | `alchemist`              | Visual regression of **every screen**                                                                       | `test/screens/<feature>`                   | **Last (§9)**  |
| **Integration** | `patrol`                 | Real user flows end-to-end on a device/emulator                                                             | `integration_test/`                        | **Last (§10)** |


### What we deliberately do NOT test

- Generated files: `*.mapper.dart`, `*.g.dart`, `*.drift.dart`, generated
`app_localizations*.dart`. They are owned by their code generators.
- Trivial DI glue (`RepositoryWrapper`, `MainApp` wiring). It is exercised
indirectly by golden and Patrol tests; a dedicated test would only restate it.
- Pure framework behaviour (that `BlocBuilder` rebuilds, that drift's generated
`copyWith` works, etc.).

---

## 2. Tooling & dependencies (first phases)

Everything needed for the first phases is **already present** in `pubspec.yaml`:
`bloc_test`, `mocktail`, `flutter_test`, and `drift` (which provides
`package:drift/native.dart` for the in-memory DB).

> Alchemist and Patrol are **not added yet** — their dependencies live in their
> own phases (§9 and §10) so we don't pull native/integration tooling in before
> we need it.

### Data-layer prerequisite — sqlite3 on the host

`NativeDatabase.memory()` runs an in-process SQLite, so the host running
`flutter test` needs the `sqlite3` native library available.

**Verified:** on the current Windows dev machine this works out of the box —
`flutter test` bundles a usable sqlite3, the in-memory DB boots and enforces
foreign keys with no extra setup (no `sqlite3.dll` wrangling needed). CI on
Linux ships `libsqlite3`, so it runs there unchanged too. If a future host
turns out to lack sqlite3, the fallback is to make `sqlite3.dll` discoverable
on `PATH` or point drift at one via `open.overrideFor(...)` in a test
bootstrap.

---

## 3. Directory layout

Tests mirror `lib/`. Shared assets (fixtures, mocks, helpers) live in dedicated
top-level folders so they are reused across every layer. The screen golden tests
(under each `screens/<feature>/`) and the `integration_test/` folder are created
in the final phases.

```
test/
  fixtures/                      # builder functions, one file per model
    auditor_fixtures.dart
    client_fixtures.dart
    accounting_area_fixtures.dart
    inventory_monitoring_fixtures.dart
    checklist_fixtures.dart      # Checklist + ChecklistItem builders
    article_fixtures.dart
    photo_fixtures.dart
    view_models/
      client_with_accounting_areas_fixtures.dart
      article_with_photos_fixtures.dart
      inventory_monitoring_with_details_fixtures.dart
  mocks/
    mock_repositories.dart       # all MockXRepository in one file
    mock_services.dart           # PhotoFileService, CrashloggingService,
                                 # InventoryMonitoringExportService, ImagePicker
  helpers/
    test_database.dart           # in-memory AppDatabase factory
    seed.dart                    # FK-chain seeding (auditor->client->area->IM)
    register_fallbacks.dart      # registerFallbackValue for mocktail any()
    pump_app.dart                # widget harness: theme + l10n + providers  (§9)
  core/
    utils/                       # pure unit tests (date_time_extensions, ...)
  data/
    daos/                        # in-memory DB tests
    repositories/                # in-memory DB tests
    services/                    # pure unit + faked IO (export svc already here)
  screens/
    <feature>/cubits/            # bloc_test cubit tests
    <feature>/                   # Alchemist full-screen goldens        (§9)
integration_test/                # Patrol flows                         (§10)
```

Naming: every file is `<source>_test.dart` mirroring its `lib/` path
(`lib/core/utils/date_time_extensions.dart` → `test/core/utils/date_time_extensions_test.dart`).

---

## 4. Test data / fixtures convention

**One file per model**, each exposing a **builder function with named overrides**
that default to valid values. This matches the existing `buildIm(...)` style in
`inventory_monitoring_export_service_test.dart` and keeps tests terse — a test
overrides only the field it cares about.

```dart
// test/fixtures/article_fixtures.dart
Article articleFixture({
  String id = 'a1',
  String inventoryMonitoringId = 'im1',
  int position = 1,
  String articleNumber = '1234567890',
  Unit unit = Unit.kg,
  CountingMode countingMode = CountingMode.sheetToFloor,
  bool isCritical = false,
  String? storageLocation,
  int? countingClient,
  int? countingAuditor,
  String? notes,
}) => Article(
      id: id,
      inventoryMonitoringId: inventoryMonitoringId,
      position: position,
      articleNumber: articleNumber,
      unit: unit,
      countingMode: countingMode,
      isCritical: isCritical,
      storageLocation: storageLocation,
      countingClient: countingClient,
      countingAuditor: countingAuditor,
      notes: notes,
    );
```

View-model fixtures **compose** the model builders:

```dart
// test/fixtures/view_models/inventory_monitoring_with_details_fixtures.dart
InventoryMonitoringWithDetails inventoryMonitoringWithDetailsFixture({
  InventoryMonitoring? inventoryMonitoring,
  Client? client,
  AccountingArea? accountingArea,
  int checklistItemCount = 2,
  int unansweredChecklistItemCount = 1,
  int articleCount = 3,
  int incompleteArticleCount = 1,
}) => InventoryMonitoringWithDetails(
      inventoryMonitoring: inventoryMonitoring ?? inventoryMonitoringFixture(),
      client: client ?? clientFixture(),
      accountingArea: accountingArea ?? accountingAreaFixture(),
      checklistItemCount: checklistItemCount,
      unansweredChecklistItemCount: unansweredChecklistItemCount,
      articleCount: articleCount,
      incompleteArticleCount: incompleteArticleCount,
    );
```

**Rules**

- Fixtures return valid-by-default objects; tests override only what is relevant.
- IDs are stable, human-readable strings (`'a1'`, `'im1'`, `'c1'`) so failures are
easy to read. Foreign-key ids line up across fixtures by default.
- `DateTime`s are fixed literals (e.g. `DateTime(2026, 6, 24)`), never
`DateTime.now()`, so tests are deterministic.
- We build fixtures only for **domain models / view models**, never for generated
`.mapper`/`.drift` row types.

---

## 5. Mocks convention

All mocks live in two shared files so a repository/service mock is declared once
and reused everywhere.

```dart
// test/mocks/mock_repositories.dart
class MockAuditorRepository extends Mock implements AuditorRepository {}
class MockClientRepository extends Mock implements ClientRepository {}
class MockAccountingAreaRepository extends Mock implements AccountingAreaRepository {}
class MockInventoryMonitoringRepository extends Mock implements InventoryMonitoringRepository {}
class MockChecklistRepository extends Mock implements ChecklistRepository {}
class MockArticleRepository extends Mock implements ArticleRepository {}
class MockPhotoRepository extends Mock implements PhotoRepository {}
class MockCrashloggingRepository extends Mock implements CrashloggingRepository {}
```

```dart
// test/mocks/mock_services.dart
class MockPhotoFileService extends Mock implements PhotoFileService {}
class MockCrashloggingService extends Mock implements CrashloggingService {}
class MockInventoryMonitoringExportService extends Mock
    implements InventoryMonitoringExportService {}
class MockImagePicker extends Mock implements ImagePicker {}
```

```dart
// test/helpers/register_fallbacks.dart
void registerFallbacks() {
  registerFallbackValue(articleFixture());
  registerFallbackValue(photoFixture());
  registerFallbackValue(StackTrace.empty);
  // ...any custom type passed through `any()` / `any(named:)`.
}
```

**Notes**

- `MockImagePicker` is injected into `CreateArticleCubit` /
`CreateInventoryMonitoringCubit` via their existing `imagePicker` constructor
parameter — no production change required.
- **No DAO mocks.** The data layer is tested against a real in-memory DB
(Section 6b), so mocking DAOs would be both redundant and lower-fidelity.
- `registerFallbacks()` is called once in a `setUpAll` (commonly from the harness).

---

## 6. Layer-by-layer strategy (first phases)

### 6a. Unit tests — pure logic


| Target                                                  | What to assert                                                                                                                         |
| ------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| `core/utils/date_time_extensions.dart` (`ddMMyyyy`)     | Formats a known date to `dd.MM.yyyy`; locale-independent.                                                                              |
| `InventoryMonitoringExportService.buildPlan`            | Already covered in `test/data/services/...`. Extend edge cases: empty articles/checklist, missing counts, EN/DE label coverage.        |
| `InventoryMonitoringExportService.writeZip`             | Against a temp dir: produces a ZIP with the expected entries; cleans up intermediate files. Inject/override `path_provider`.           |
| `PhotoFileService` (`persist` / `delete` / `deleteAll`) | Real `dart:io` against a temp dir: file copied to permanent path; delete is a no-op on a missing file; `deleteAll` removes every path. |
| `ChecklistTemplateService.loadCurrentTemplate`          | Loads `assets/data/checklist.json` via the test asset bundle; parses into a `ChecklistTemplate` with the expected item count/keys.     |


`buildPlan` is the gold-standard example to follow — see
`test/data/services/inventory_monitoring_export_service_test.dart`.

### 6b. Data layer — in-memory drift DB

This is the drift author's officially documented approach
([https://drift.simonbinder.eu/testing/](https://drift.simonbinder.eu/testing/)). We test **DAOs and repositories
together** against `NativeDatabase.memory()` — repositories are thin facades, so
running them on the real DB covers both layers and exercises the actual SQL.

```dart
// test/helpers/test_database.dart
AppDatabase newTestDb() => AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true, // avoids timer errors in widget tests
      ),
    );
```

`AppDatabase` already accepts an optional `QueryExecutor`
(`lib/data/db_models/database.dart`), so **no production change is needed**. Each
test gets a fresh DB in `setUp` and closes it in `tearDown`; seed data via
fixtures + the repository's own `upsert`* methods.

Assert the behaviour mocks cannot prove:

- **CRUD round-trips** and `**watch*()` stream emissions** on write (use
`expectLater(stream, emitsInOrder([...]))`).
- **FK cascade deletes:** deleting a `Client` removes its `AccountingAreas` →
`InventoryMonitorings` → `Articles`/`Checklists`/`ChecklistItems` → `Photos`.
- **Constraints:**
  - `Photos` CHECK — inserting a photo with both or neither of
  `articleId`/`inventoryMonitoringId` fails.
  - `AccountingAreas` case-insensitive unique `(clientId, name)` — `"BK-17"` and
  `"bk-17"` collide.
- **Join / aggregate queries:** `InventoryMonitoringWithDetails` count fields,
`nextArticlePosition`, `ensureChecklistForInventoryMonitoring` idempotency
(safe to call repeatedly), and the transactional
`upsertInventoryMonitoringWithPhotos` orphan reconciliation.

### 6c. Cubit tests — `bloc_test` + `mocktail`

All **10 cubits**, using the shared mocks/fixtures. Follow the established pattern
in `test/screens/auth/cubits/auth_cubit_test.dart`: `build` / `act` / `expect`
with `isA<State>().having(...)` matchers and `verify(...)` on collaborators.

```dart
blocTest<ExportCubit, ExportState>(
  'emits [inProgress, success] and writes a zip',
  setUp: () {
    when(() => articleRepository.getArticlesForInventoryMonitoring(any()))
        .thenAnswer((_) async => [articleFixture()]);
    // ...stub the other repos + exportService.buildPlan / writeZip
  },
  build: buildCubit,
  act: (cubit) => cubit.exportInventoryMonitoring(detailsFixture, l10n),
  expect: () => [
    isA<ExportState>().having((s) => s.status, 'status', ExportStatus.inProgress),
    isA<ExportState>()
        .having((s) => s.status, 'status', ExportStatus.success)
        .having((s) => s.zipPath, 'zipPath', isNotNull),
  ],
);
```

Priorities (highest logic density first):


| Cubit                                      | Key cases to cover                                                                                                                                                                                                                                                                                              |
| ------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `CreateArticleCubit`                       | Draft-photo lifecycle; `removePhoto` cleans a draft temp file (`verify(photoFileService.delete)`) but defers persisted deletes; `save` persists drafts (`verify persist` / `deleteAll`); `isValid` transitions; create vs edit `init`; `save` / `saveAndCreateNew` / `deleteArticle`. Inject `MockImagePicker`. |
| `CreateInventoryMonitoringCubit`           | Same photo/file lifecycle; form setters re-compute `isValid`; `selectedAccountingArea` getter; edit-mode reconstruction; checklist ensure on save.                                                                                                                                                              |
| `ExportCubit`                              | idle→inProgress→success/error; per-article photo gathering loop; l10n pass-through; error path logs via crashlogging.                                                                                                                                                                                           |
| `ArticleCubit`, `InventoryMonitoringCubit` | Two stream subscriptions emit success states; stream error → error state; `close()` cancels subscriptions. Seed mock streams with `StreamController`.                                                                                                                                                           |
| `ClientCubit`, `ChecklistCubit`            | Stream success/empty/error; `ChecklistCubit.init` calls `ensure...`; `setAnswer` upserts; `isComplete` getter.                                                                                                                                                                                                  |
| `CreateClientCubit`                        | Form validation; save success/error.                                                                                                                                                                                                                                                                            |
| `SettingsCubit`                            | `init` reads prefs + package info; `setLanguage` persists and emits.                                                                                                                                                                                                                                            |
| `AuthCubit`                                | **Already covered** — reference implementation.                                                                                                                                                                                                                                                                 |


---

## 7. Conventions & CI

- **Naming:** `<source>_test.dart` mirroring the `lib/` path; one `group()` per
class or method; descriptive `blocTest` names ("emits [...] when ...").
- **Coverage:** `flutter test --coverage`, then strip generated files from
`coverage/lcov.info` before reporting:
  ```bash
  lcov --remove coverage/lcov.info \
    '*.mapper.dart' '*.g.dart' '*.drift.dart' '*/l10n/app_localizations*.dart' \
    -o coverage/lcov.info
  ```
- **CI suggestion:** run unit + data + cubit on every push (Linux, where sqlite3
is present). Golden and Patrol jobs are added with their phases (§9, §10).
- **Style:** follows `very_good_analysis` (trailing commas, 80-col) exactly like
the existing tests.

---

## 8. Implementation order

**First (done):**

1. ✅ **Foundation:** `fixtures/`, `mocks/`, `helpers/` (`test_database.dart`,
  `seed.dart`, `register_fallbacks.dart`). `pump_app.dart` is deferred to the
  golden phase (§9) — nothing before it needs a widget harness.
2. ✅ **Unit tests:** services (export, photo file, checklist template) and
  `core/utils`.
3. ✅ **Data tests:** DAOs/repositories on the in-memory DB.
4. ✅ **Cubit tests:** all 10 cubits.

**Last (only after the above are green):**

1. **Golden tests (Alchemist)** — see §9.
2. **Integration tests (Patrol)** — see §10.

Each step is independently runnable with `flutter test`.

---

---

# Deferred phases — Golden & Integration

> The two sections below are intentionally placed last. Their dependencies and
> native setup are **not** added until we reach them, so the first phases stay
> free of golden/native tooling.

## 9. Golden tests — Alchemist (deferred)

Covers **every screen**. Reusable `lib/ui` components are **not** golden-tested
on their own — they are exercised indirectly through the screen goldens.

### 9.1 Setup (do at the start of this phase)

1. Add the dependency:
  ```bash
   flutter pub add dev:alchemist
  ```
   (Resolved to `alchemist ^0.14.0` at time of writing.)
2. Create `test/flutter_test_config.dart` — Flutter auto-discovers this and wraps
  every test in the `test/` tree. It loads the app fonts (so goldens render with
   `PPNeueMontreal` instead of the fallback box font) and sets a shared
   `AlchemistConfig`:
3. Add a golden helper that wraps the subject in `AppThemes.light` + the
  `AppLocalizations` delegates, and standardise CI-vs-platform goldens
   (`ciGoldensConfig` renders text blocks for host-independent CI;
   `platformGoldensConfig` for local pixel-accurate goldens).
4. Workflow: generate/refresh with `flutter test --update-goldens`; CI compares
  against the checked-in goldens.

### 9.2 What to cover

**Screens** (`test/screens/<feature>/`) — **every screen**: onboarding, splash,
clients list, create client, inventory-monitoring list, create IM, articles list,
create article, checklist, export, settings. Each is pumped (via `pump_app.dart`)
with its cubit backed by mock repositories returning fixtures, rendered in
representative states: **loading / success / empty / error** where applicable.

`pump_app.dart` replicates the provider graph from `RepositoryWrapper` /
`MainApp` so screens see the repositories and app-level cubits they expect.

---

## 10. Integration tests — Patrol (deferred)

Covers most app flows end-to-end on a device/emulator.

> The detailed strategy (test architecture, injection seams, reset hook, widget
> keys, flow list) now lives in [`e2e_testing_concept.md`](./e2e_testing_concept.md).
> The setup notes below remain here for reference.

### 10.1 Setup (do at the start of this phase)

1. Add the dependencies:
  ```bash
   flutter pub add dev:patrol "dev:integration_test:{\"sdk\":\"flutter\"}"
  ```
   (Resolved to `patrol ^4.6.1` at time of writing.)
2. Install the CLI globally: `dart pub global activate patrol_cli`.
3. Add the `patrol` block to `pubspec.yaml` (app id confirmed from the native
  projects: `com.auditneo.inventory`):
4. **Android** (`android/app/build.gradle.kts`, Kotlin DSL) — inside
  `defaultConfig`:
   inside the `android { }` block:
   inside `dependencies { }`:
   and create the instrumentation entry point
   `android/app/src/androidTest/java/com/auditneo/inventory/MainActivityTest.java`
   per the patrol docs for the installed version (verify against
   `patrol`'s README at setup time, as the boilerplate is version-specific).
5. **iOS** — the project already has a `RunnerTests` target
  (`com.auditneo.inventory.RunnerTests`); wire it up for Patrol per the docs.
   This must be done on macOS/Xcode and is **out of scope on the current Windows
   dev machine** — track as a follow-up for the iOS CI/build host.

### 10.2 What to cover — most app flows

Each flow runs against a fresh app with an empty DB:

- Client: create → edit → delete.
- Accounting area: add to a client.
- Inventory monitoring: create → edit.
- Article: create → edit → delete, including **photo capture** (Patrol's native
camera/gallery automation, or an injected picker in the integration build).
- Checklist: answer all items → `isComplete`.
- Export: run an export and assert a ZIP / share sheet is produced.
- Settings: switch language (DE/EN) and verify the UI updates.
- Onboarding: first-run flow.

### 10.3 Running

```bash
patrol test                       # all integration_test/ flows on a device/emulator
patrol test -t integration_test/<flow>_test.dart
```

