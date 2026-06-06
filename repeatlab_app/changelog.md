# Changelog

All notable developer-facing changes to this project are documented in this file.

The format is loosely based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Known gaps
- Skip-next/prev (both UI and media-session controls) can still auto-advance into a locked loop.
- On iOS, the file picker can't show `.avi` files: iOS's document picker requires every custom extension to map to a Uniform Type Identifier (UTI), and `.avi` has no UTI registered in `ios/Runner/Info.plist`. Fixing means declaring `public.avi` (or an imported type) in `CFBundleDocumentTypes` / `UTImportedTypeDeclarations` and adding `'avi'` to the allowlist in `pickSingleVideoFile`. Skipped for now — libmpv plays `.avi` once a file is in by other means, and `.avi` is rare on mobile. Android isn't affected (its picker uses `FileType.video`, no extension allowlist) though end-to-end `.avi` playback there hasn't been verified yet.

## [2.0.1]

### Added
- **Video song support (Beta).** Import video files (mp4, mov, m4v, mkv, webm) and loop them with the same loop / BPM / speed controls as audio songs. Available on iOS and Android. The "Add" flow on the home page now lets you pick Audio or Video.
- **Adjustable video preview size.** Three steps (small / medium / large) via a `+ / −` overlay on the video frame. The chosen size persists per song.
- **Landscape full-height video.** In landscape, the size steps go larger and `large` fills the visible viewport (below the app bar); the timeline and controls stay reachable by scrolling.

### Fixed
- Tapping `×` or `BPM` in the speed-control row when the panel was collapsed now expands the panel so the slider you switched to is visible.
- The BPM slider now opens the paywall on first touch for non-premium users — previously a drag did nothing because only a clean tap was being detected. Guarded against opening the paywall multiple times from one touch.
- The multiplier slider (`×` mode) gets the same paywall-on-touch fix.
- Loop drag-and-drop reordering is now disabled for non-premium users — they only have access to the first loop anyway, so reordering was meaningless and the half-recognised long-press gesture was confusing.
- iOS video playback (texture stayed black on first iOS build).

### Changed
- Changelog dialog gets a "Video support (Beta)" entry at the top, translated to all 16 supported locales.

## [1.8.0]

### Added
- **Song reordering.** Users can long-press a song on the home page and drag it to reorder. The order is persisted via a new `sortOrder` field on `Song` (default `0`). New songs appear at the top. Backwards compatible — old app versions ignore the unknown field; old data deserializes with `sortOrder: 0`.
  - Model: `lib/data/models/song.dart` — added `sortOrder` int field with default `0`.
  - Repository: `lib/data/repositories/song_repository.dart` — `getAllSongs` now sorts by `sortOrder` ascending; new `reorderSongs()` and `incrementExistingSortOrders()` methods.
  - Cubit: `lib/features/home/cubit/all_songs_cubit.dart` — `reorderSongs(oldIndex, newIndex)` with optimistic update.
  - UI: `lib/features/home/home_page.dart` — replaced `ListView.separated` with `ReorderableListView.builder`.

## [1.7.0]

### Added
- **Library export & import (Pro).** Users can back up their entire library (songs + loops + audio files) to a single `.rlbackup` file and restore it on another device. Import offers two modes: *Merge* (default, additive — skips songs whose id already exists) and *Replace* (wipes the current library first, double-confirm required). Filename collisions with different content are auto-renamed to `<stem>-imported-<uuid8>.<ext>`; identical content is reused without rewriting. Paywall-gated in Settings, with lock icon + "Pro feature" subtitle driving non-premium users to the RevenueCat paywall.
  - New package: `lib/data/repositories/backup/` — `BackupManifest` (schema-versioned), `BackupSerializer` (pure bytes-in/bytes-out zip encode/decode with SHA-256 hash verification), `BackupRepository` (filesystem + sembast orchestration).
  - New feature: `lib/features/backup/cubit/` — `BackupCubit` with states idle/exporting/importing/exportSuccess/importSuccess/failure. Share sheet powered by `share_plus`.
  - Settings UI: `lib/features/home/settings_page.dart` rewritten around `BlocProvider<BackupCubit>` with a new "Backup & Restore" section above "Local Data".
  - Paywall hook: reuses `PremiumSubscriptionCubit.hasPremium` + `presentPaywall()` — same pattern as the drawer's Pro upsell.
  - Format: `manifest.json` (schemaVersion 1, appVersion, exportedAt, songCount, per-file sha256+size) + `songs.json` (dart_mappable JSON) + `audio/<fileName>` raw bytes, wrapped in a zip.
  - Analytics: `click_backup_export/import`, `backup_export_success/failure/share_canceled`, `backup_import_picked/canceled/success/failure`, `view_paywall_from_backup`.
- **Language switcher.** Users can pick the app language from the drawer under User Settings. 16 locales supported (ar, de, en, es, fr, hi, it, ja, ko, nl, pl, pt, ru, sv, tr, zh) plus a "System default" option that follows the device locale. Each language renders in its native script in the picker.
  - New feature: `lib/features/locale/` — `LocaleCubit` (`Cubit<Locale?>` where `null` = system default) and `LanguagePickerDialog` (`SimpleDialog` with native-script labels).
  - Persistence: `LocalConfigRepository.languageCode` getter/setter backed by `SharedPreferences`; clearing the key restores system-default behavior.
  - Wiring: `MaterialApp.locale` in `lib/app/view/app.dart` is now bound to the cubit state via `context.watch`.
  - Drawer UI: new `ListTile` directly below `Settings` showing the current language as subtitle; tapping opens the picker.
  - Analytics: `click_change_language` (tile tap), `change_language` (with `language_code` data: ISO code or `'system'`).

### Changed
- **Subscription gating for existing loops.** When a user's subscription lapses, all loops beyond the first (by current order) are now visually locked (grey + lock icon) and tapping any locked surface — tile body, edit, export, timeline block — opens the paywall. Loop data is preserved so re-subscribing restores access instantly. Design doc: `ai/2026-04-19_unsubscribe-logic.md`.
  - `lib/features/song/widgets/loop_tile.dart`: added `isLocked` + `onLockedTap`.
  - `lib/features/song/widgets/loop_timeline.dart`: added `isLoopLocked` predicate + `onLockedLoopTap`.
  - `lib/features/song/view/song_page.dart`: wrapped `LoopTile` and `LoopTimeline` in `BlocSelector<PremiumSubscriptionCubit, …>` so gating reacts live; added `_presentLoopPaywall` helper.

### Dependencies
- Added `archive ^4.0.8`, `share_plus ^12.0.0`, `crypto ^3.0.6` (promoted from transitive).
