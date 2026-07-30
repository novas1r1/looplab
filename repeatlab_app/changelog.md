# Changelog

All notable developer-facing changes to this project are documented in this file.

The format is loosely based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Pitch shifting for audio on iOS.** Audio pitch control is no longer Android-only: the Signalsmith DSP stage now also runs inside the darwin plugin's `MTAudioProcessingTap` (alongside the metronome click), so `isPitchControlSupported` covers iOS and the pitch card no longer hides itself for audio songs there. `FEATURES.md` updated accordingly (and the pitch section's "Beta" marker dropped, matching the strings).
- **Seamless loop playback (Android).** Loop wraps now use a native ExoPlayer loop region (`AudioPlayer.setLoopRegion`) so the engine handles the boundary itself, eliminating the audible gap/click on re-entry. A predictive Dart-side wrap (fast-path seek scheduled to fire exactly at the loop boundary) remains the fallback on iOS, for video, and if the native call fails for any reason.
- **Empty state for the song page's loop list.** A song with no loops now shows "No loops created yet" / "Tap to create your first loop" (the whole text block is tappable and runs the same add-loop flow as the FAB, paywall check included), instead of a blank area. Translated into all 16 supported locales.
- **Automatic cleanup of deleted media files.** Deleting a song, deleting a loop's song, or clearing the library now also deletes the underlying audio/video file from disk (unless another song still references it), instead of leaving it orphaned forever. A one-time startup sweep reclaims files left behind by past deletions. Both are guarded against an in-flight library backup export/import so cleanup never races a file the backup is reading or writing.

### Fixed
- **Background battery drain while idle (RL-371).** With the `audio` background mode declared, the always-on SoLoud engine (used only as an offline decoder for waveforms/duration) and the 200 ms loop-poll timer could keep the process alive indefinitely in the background — reported as >10%/day drain on iPadOS 26. A new `BackgroundAudioGuard` now reacts to backgrounding without active playback: it cancels the audio handler's polling timers, deinitializes SoLoud, and deactivates the audio session so the OS can suspend the process; everything is restored on foregrounding / next play. Backgrounded *playing* audio is untouched, and a pause from the lock screen triggers the same suspension. Also removed the unused `fetch` and `remote-notification` background modes from the iOS Info.plist.
- The ±10 s skip buttons clamped to the active loop's start/end even while the song was paused, making it impossible to park the playhead outside the loop to set new bounds. Both the audio and the video handler now only enforce the loop bounds while playback is actually running (the timeline/waveform drag already behaved this way); pressing play still jumps back into the loop.
- The loop timeline could fail to show any loop blocks until playback started, because its width was read from a render object that wasn't laid out yet; it now uses a `LayoutBuilder` so saved loops render immediately when the song page opens.
- OS media-notification skip-next/skip-previous controls could advance a free user into a loop that's locked behind premium, bypassing the in-app lock. The premium check now lives in `SongCubit.selectLoop` itself, so it applies regardless of what triggers loop navigation.

### Changed
- The song page's play/pause button is now the visual anchor of the transport bar: a filled circle in the accent colour, drop-shadowed and floating on top of the bar (z-wise) instead of sitting inline with the ±10 s skip buttons.
- The metronome panel's "Reset sync" button now reads "Reset".

### Known gaps
- On iOS, the file picker can't show `.avi` files: iOS's document picker requires every custom extension to map to a Uniform Type Identifier (UTI), and `.avi` has no UTI registered in `ios/Runner/Info.plist`. Fixing means declaring `public.avi` (or an imported type) in `CFBundleDocumentTypes` / `UTImportedTypeDeclarations` and adding `'avi'` to the allowlist in `pickVideoFiles`. Skipped for now — libmpv plays `.avi` once a file is in by other means, and `.avi` is rare on mobile. Android isn't affected (its picker uses `FileType.video`, no extension allowlist) though end-to-end `.avi` playback there hasn't been verified yet.

## [2.2.2]

### Changed
- Android `minSdk` lowered from 28 to 26 (Android 8.0), following `precise_metronome`'s own `minSdk` drop in 0.3.3 — the plugin's Oboe audio engine already used the AAudio fast path and version-guarded API calls at 26, so 28 was never strictly required. Partially walks back the minSdk 24→28 raise from the previous release.

### Dependencies
- Updated `precise_metronome` to `0.3.3`.

## [2.2.1]

### Added
- **Revamped onboarding.** Four informational slides (Practice Like a Pro / Loop / Speed & Tempo / Pitch), a progress-dot header, a "Skip" button that jumps straight to consent, and back/next navigation between slides. The consent slide replaces the two checkboxes with full-width tappable cards: a required "Data protection" card (privacy policy / terms links) and an optional, off-by-default "Anonymous analytics" card.
- **On-demand "What's New" changelog.** The changelog dialog no longer auto-opens after launch. A gift/update icon in the home app bar plus an animated "What's New" bubble (shown only while there's unseen content) let the user open it when they want to.
- **Guided metronome sync.** The metronome now stages itself by sync state instead of exposing every control at once: while unsynced it shows only a "Sync to song" button (tap starts playback, then each tap records a beat) with a hint explaining why the click is a plain, unaccented tick; the time signature and downbeat accent only appear once a beat anchor exists, since "beat 1" is otherwise arbitrary. A "Reset sync" link returns to the plain click. Turning the metronome on without a BPM set now shows a "Set BPM first" dialog instead of doing nothing.
- **Cloud-provider audio picking on Android.** Picking audio now browses all providers (e.g. OneDrive), not just local audio, then filters the result down to supported audio extensions in-app.
- **Custom branded icon set.** Replaced Material icons across the app (transport controls, delete/edit/export/import/save/settings, zoom, loop/repeat, drawer menu, add-audio/add-video, backup, speed/pitch/metronome steppers) with a new `AppIcon` widget rendering SVGs from `assets/icons/`.

### Changed
- Metronome panel: volume, time signature, subdivision, re-tap alignment and the ±ms nudge all moved inside the collapsible "advanced" section, reachable only once the song is synced. The half-beat (½) shift button was removed entirely.
- Home page app bar: dropped the debug-only "clear DB"/"clear shared prefs" icons and the manual refresh icon.

### Fixed
- Bumped several plugins that ship native libraries (ffmpeg_kit, precise_metronome, wakelock_plus, sentry, posthog, purchases_flutter/ui, share_plus) ahead of Google Play's Android 16 KB memory page-size requirement for new native libraries.

## [2.1.2]

### Added
- **Pitch shifting (Premium).** Change a song's pitch ±12 semitones without affecting tempo. A "key mode" lets you set the song's original musical key and pick a target key — the semitone offset is computed automatically. Video songs are pitch-shifted on all platforms via media_kit/libmpv; audio songs via a native Signalsmith DSP processor added to the `audioplayers` fork — on Android (an ExoPlayer audio processor) and iOS (a Signalsmith stage in the MTAudioProcessingTap alongside the metronome click).
- **Metronome.** A full click-track metronome, gated by subscription (on/off, BPM and volume stay free):
  - **Tap-to-align beat anchor** — tap along with the beat a few times and the phase is persisted per song, so the click grid deterministically realigns on play/seek/loop/tempo-change instead of drifting.
  - **Baked click track** for audio songs: the click is rendered to a WAV and mixed into the song audio via ffmpeg, sample-locked across loops/seeks/speed changes.
  - **Native in-pipeline clicks for Android**, superseding the baked-track approach there: clicks are synthesized inside the `audioplayers` fork's ExoPlayer processor for instant toggle/volume with no ffmpeg re-mix. iOS audio still uses the baked track; video still uses the live native metronome.
- **Multi-file import.** Select and import several audio or video files at once, with a real-time "File 2 of 5" progress indicator on the home page. Files are moved into the app's documents directory instead of copied where possible, speeding up large imports.
- **Selective backup export.** Exporting a `.rlbackup` now opens an options sheet to include/exclude audio songs, video songs, and loops/settings, instead of always exporting everything.
- **MKV/WebM video import on iOS**, via a new `UTImportedTypeDeclarations` entry for formats with no system UTI.
- **PostHog analytics**, replacing the previous Wiredash integration: screen/monetization/activation events, a unified `paywall_viewed` event with a `trigger` property, an `is_premium` super property, a GDPR-safe pre-consent event buffer, and RevenueCat ↔ PostHog identity linking.

### Fixed
- Setting an out-of-range original BPM no longer throws from an inverted min/max clamp range — BPM is now capped to a supported maximum of 400.
- Loading an audio file that fails to decode no longer misreports "unsupported format"; it's now surfaced as a genuine load failure.
- Backup import in "Replace" mode now clears the existing library only after the incoming backup has been fully decoded to disk, preventing data loss if the backup turns out to be corrupt; malicious backup filenames (zip-slip) are now rejected.
- Imported audio files and internal WAV conversions that collide with an existing filename are now renamed instead of silently overwriting the existing file and its loops.
- Fixed Android audio randomly dropping out while the metronome kept clicking, caused by the metronome's exclusive/MMAP audio stream claiming the device; `precise_metronome` was bumped to always open the stream in shared mode.
- Loop start/end can now be freely dragged while paused for editing — loop boundary enforcement now only applies during active playback.
- The in-app tutorial no longer crashes if the song page is unmounted before the tutorial's skip/finish callback runs.

### Changed
- Speed, pitch and metronome controls were merged from two stacked cards into a single tabbed controls card; tabs that don't apply (e.g. pitch/metronome on desktop) drop out automatically.
- Removed the tempo-driven metronome beat-dots visual, which was never sample-accurate to the actual click.
- Raised Android `minSdk` from 24 to 28 due to updated package requirements (later revised down in 2.2.2).
- Added a Patrol-based end-to-end integration test suite (onboarding, add song/video, backup, loop CRUD/export, language switch, freemium gating, delete-all-data flows).

### Dependencies
- Added `precise_metronome` (git dependency).
- Pinned the `audioplayers` fork (`ap` submodule) to track native click-track/pitch-shift processor changes.
- Removed unused `connectivity_plus` and `mockito`.

## [2.0.1]

### Added
- **Video song support.** Import video files (mp4, mov, m4v, mkv, webm) and loop them with the same loop / BPM / speed controls as audio songs. Available on iOS and Android. The "Add" flow on the home page now lets you pick Audio or Video.
- **Adjustable video preview size.** Three steps (small / medium / large) via a `+ / −` overlay on the video frame. The chosen size persists per song.
- **Landscape full-height video.** In landscape, the size steps go larger and `large` fills the visible viewport (below the app bar); the timeline and controls stay reachable by scrolling.

### Fixed
- Tapping `×` or `BPM` in the speed-control row when the panel was collapsed now expands the panel so the slider you switched to is visible.
- The BPM slider now opens the paywall on first touch for non-premium users — previously a drag did nothing because only a clean tap was being detected. Guarded against opening the paywall multiple times from one touch.
- The multiplier slider (`×` mode) gets the same paywall-on-touch fix.
- Loop drag-and-drop reordering is now disabled for non-premium users — they only have access to the first loop anyway, so reordering was meaningless and the half-recognised long-press gesture was confusing.
- iOS video playback (texture stayed black on first iOS build).

### Changed
- Changelog dialog gets a "Video support" entry at the top, translated to all 16 supported locales.

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
