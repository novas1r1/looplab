# Changelog

All notable developer-facing changes to this project are documented in this file.

The format is loosely based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Known gaps
- Skip-next/prev (both UI and media-session controls) can still auto-advance into a locked loop.
- `ReorderableListView` still allows non-premium users to drag a locked loop to position 0, promoting it to the accessible slot.

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
