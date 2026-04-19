# Changelog

All notable developer-facing changes to this project are documented in this file.

The format is loosely based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- **Subscription gating for existing loops.** When a user's subscription lapses, all loops beyond the first (by current order) are now visually locked (grey + lock icon) and tapping any locked surface — tile body, edit, export, timeline block — opens the paywall. Loop data is preserved so re-subscribing restores access instantly. Design doc: `ai/2026-04-19_unsubscribe-logic.md`.
  - `lib/features/song/widgets/loop_tile.dart`: added `isLocked` + `onLockedTap`.
  - `lib/features/song/widgets/loop_timeline.dart`: added `isLoopLocked` predicate + `onLockedLoopTap`.
  - `lib/features/song/view/song_page.dart`: wrapped `LoopTile` and `LoopTimeline` in `BlocSelector<PremiumSubscriptionCubit, …>` so gating reacts live; added `_presentLoopPaywall` helper.

### Known gaps
- Skip-next/prev (both UI and media-session controls) can still auto-advance into a locked loop.
- `ReorderableListView` still allows non-premium users to drag a locked loop to position 0, promoting it to the accessible slot.
