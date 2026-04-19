# Unsubscribe Handling for Existing Loops — Design Document

**Date:** 2026-04-19
**Status:** Implemented

## Problem

Free users are limited to one loop per song; premium users get unlimited loops. Before this change, when a premium user created multiple loops and then unsubscribed, the gating was only applied at *creation time* — all previously created loops stayed fully interactive, effectively granting permanent multi-loop access after a single month of premium.

## Goal

When a user's subscription lapses and a song has more than one loop, the first loop (by current order) remains fully accessible and every other loop is visually locked and non-interactive until the user re-subscribes. Loop data is never deleted, so re-subscribing instantly restores access.

## Decisions

| Question | Decision |
|----------|----------|
| Which loop stays accessible? | The first loop (by current order). |
| What does "deactivate" mean? | Greyed out + lock icon, tap triggers the existing paywall. Not hidden, not deleted. |
| Restore on re-subscribe? | Automatic — the lock state is purely derived from `PremiumSubscriptionState`, so flipping to premium unlocks immediately. |
| Data deletion? | No. All loops stay in the DB regardless of subscription state. |

## Implementation

### Gating rule

`isLocked = !hasPremium && index > 0`

- For the loop list (`LoopTile` items), index is the order in the list.
- For the timeline (`LoopTimeline` blocks), `loop.id != loops.first.id` is used so the gate survives reorder.

`hasPremium` is derived from `PremiumSubscriptionState` and reads the existing entitlement fields (`hasWeeklySubscription || hasYearlySubscription || hasLifetimePurchase`).

### Changes

**`lib/features/song/widgets/loop_tile.dart`**
- Added `isLocked` bool prop (default `false`) and optional `onLockedTap` callback.
- When locked: the whole tile is wrapped in `Opacity(0.45)`, a lock icon is appended to the loop name, and the tap/edit/export buttons route to `onLockedTap` instead of their normal handlers.

**`lib/features/song/widgets/loop_timeline.dart`**
- Added `isLoopLocked` predicate and `onLockedLoopTap` callback.
- Locked loop blocks render at opacity 0.4, show a lock icon instead of the loop name, and tapping routes to `onLockedLoopTap`.

**`lib/features/song/view/song_page.dart`**
- Wrapped `LoopTimeline` and each `LoopTile` in a `BlocSelector<PremiumSubscriptionCubit, PremiumSubscriptionState, bool>` so they react reactively to subscription state changes (e.g. after a successful restore/purchase flow).
- Added `_presentLoopPaywall` helper that logs the existing `showPaywallSongLoops` analytics event and calls `PremiumSubscriptionCubit.presentPaywall()`.

## Out of scope (flagged)

These edges currently still allow indirect access to locked loops. Left untouched intentionally — pending product decision:

1. **Skip-next / skip-previous buttons.** The audio handler's media controls and the timeline skip buttons can auto-advance into a locked loop. Would require filtering by `isLocked` inside `SongCubit.nextLoop` / `previousLoop`, or disabling the buttons in the UI when `!hasPremium`.
2. **Reorder.** A non-premium user can drag a locked loop to position 0 in the `ReorderableListView`, which promotes it to "the accessible loop". This is arguably user-friendly (pick which loop to keep) but if stricter behavior is desired, reorder should be gated on `hasPremium`.
3. **Loop mode toggle.** Unchanged. Relies on `activeLoop`, which the user can only set via a tap — already gated.

## Non-regressions

- Existing golden test in `test/goldens/song_page_golden_test.dart` still compiles; `LoopTile` without `isLocked` falls back to the default `false`.
- Premium subscription cubit and repository are untouched — no behavior change for users who are/stay premium.
- Loop data model, persistence, and audio handler are untouched — no migration needed.
