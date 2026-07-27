# RepeatLab Analytics (PostHog + RevenueCat)

> How product analytics work in RepeatLab: SDK setup, consent, the anonymous
> identity model, the RevenueCat → PostHog server-side integration, the event
> taxonomy, and how to build/verify the core funnels.
>
> Last updated: 2026-07-01

---

## 1. Stack overview

| Concern | Tool | Where |
|---|---|---|
| Product events, funnels, retention | **PostHog** (`posthog_flutter`) | client-side, EU host |
| Subscription / revenue lifecycle | **RevenueCat** → PostHog integration | server-side |
| Session replay | Microsoft Clarity | client-side |
| Crash / error reporting | Sentry | client-side |
| In-app feedback / surveys | Wiredash / UserOrient | client-side |

This document covers **PostHog** and the **RevenueCat → PostHog** integration.
PostHog is **EU-hosted** — the ingestion host must be `https://eu.i.posthog.com`
everywhere (Dart config + native manifests + the RC dashboard region).

---

## 2. SDK setup & configuration

PostHog is initialised **manually from Dart**, not via native auto-init.

- Native auto-init is **disabled** so nothing is captured before consent:
  - `android/app/src/main/AndroidManifest.xml` → `com.posthog.posthog.AUTO_INIT = false`
  - `ios/Runner/Info.plist` → `com.posthog.posthog.AUTO_INIT = false`
- Manual setup: `lib/main.dart` → `_initializeApp()` calls `Posthog().setup(...)` with:
  - `host = https://eu.i.posthog.com` (EU)
  - `debug = kDebugMode`
  - `captureApplicationLifecycleEvents = true` → gives `Application Installed`,
    `Application Opened`, `Application Backgrounded` for free
  - `personProfiles = identifiedOnly`
  - `optOut = !(analyticsConsent && !kDebugMode)` → opted out unless the user
    consented **and** this is a release build
- Screen tracking: `PosthogObserver` is registered in `MaterialApp.navigatorObservers`
  (`lib/app/view/app.dart`), auto-capturing `$screen` for named routes. Manual
  `view_*` events additionally mark dialogs/sheets that aren't routes.

**Project token** (`phc_Bq9…`) is a public ingestion key — safe to ship in the
client. It only allows event ingestion, not data reads.

### Debug behaviour (important for verification)

`AppAnalytics.trackEvent` (`lib/core/utils/app_analytics.dart`) **returns early
when `kDebugMode`** — custom events are *not* sent in debug builds. Combined with
`optOut` in debug, this means:

> **You cannot verify events in a debug build.** Use a **profile or release
> build** with analytics consent accepted to see events in PostHog Live Events.

All capture calls are wrapped in `runZonedGuarded` + `catchError` so an analytics
failure can never bubble into a user-facing call site.

---

## 3. Consent / GDPR model

Analytics is **opt-in** and gated end to end.

- Default: `LocalConfigRepository.acceptedAnalytics` is `false` → PostHog starts
  opted out (`main.dart`), Clarity paused.
- Consent is captured during onboarding and persisted via
  `LocalConfigRepository.setAnalyticsEnabled(...)`, which:
  - `Posthog().enable()` / `disable()`
  - `Clarity.resume()` / `pause()`
  - settles the **pre-consent event buffer** via
    `AppAnalytics.onConsentDecision(...)` (see below)
  - **syncs the RevenueCat identity link** (see §5) — release only

### Pre-consent event buffer

Events fired *before* the consent decision (e.g. `view_onboarding` /
`onboarding_started` in the onboarding page's `initState`) would otherwise be
silently dropped by the SDK's opt-out — even for users who later consent.
`AppAnalytics` therefore keeps a consent state (`undecided` / `granted` /
`denied`, restored on startup via `AppAnalytics.init(...)` in `main.dart`):

- **undecided** (first onboarding, no decision yet): events are buffered
  **in memory only** (bounded at 50) — nothing is persisted or transmitted,
  the buffer dies with the process. GDPR: no processing before consent.
- **granted**: buffered events are flushed to PostHog in order, each tagged
  with an `original_timestamp` property; subsequent events capture directly.
- **denied**: the buffer is discarded and later events are dropped. A later
  opt-in via settings never resurrects pre-decision events.

Note: this covers only `AppAnalytics.trackEvent` calls. SDK autocapture
(`$screen`, lifecycle events) still starts at consent — pre-consent
`Application Installed` remains unmeasurable by design.
- `Posthog().reset()` runs **only** on "delete all data"
  (`lib/features/home/settings_page.dart`), rotating the anonymous id for
  right-to-erasure. It is **never** called on app start (that would inflate users
  and destroy retention). The same handler also **unlinks** RevenueCat (§5).

### Server-side caveat

The RevenueCat → PostHog integration is **server-side** and fires independently
of the in-app `optOut`. To respect consent we only set the `$posthogUserId` link
when consent is granted; for opted-out users the attribute is cleared so their
purchase events fall back to an **unlinked** anonymous id and never build a
PostHog person. See §5.

---

## 4. Identity model

RepeatLab has **no login / account** — identity is purely anonymous and
device-scoped.

- **PostHog**: anonymous `distinct_id`, auto-generated and persisted by the SDK,
  stable across restarts. `identify()` is never called (there is no user to
  identify). Retention & funnels work on this stable anonymous id.
- **RevenueCat**: configured anonymously (no `appUserID`), so it has its own
  `$RCAnonymousID:…`.
- These two anonymous ids are **different**. The server-side integration is
  keyed on RevenueCat's `$posthogUserId` subscriber attribute → we must set it
  to PostHog's `distinct_id` (§5), otherwise `rc_*` events land on a different
  person and the purchase funnel can't connect.

`is_premium` is registered as a PostHog **super property** (event-level), kept in
sync via `AppAnalytics.setPremium(...)`, so every event is segmentable by
subscription state without needing person profiles.

---

## 5. RevenueCat → PostHog integration & identity alignment

**Delivery:** server-side (RevenueCat POSTs to PostHog after each subscription
event). Reliable, works when the app is closed, and captures renewals/churn the
client never sees.

### Dashboard config (one-time, in RevenueCat)

1. Project Settings → Integrations → **PostHog**
2. PostHog **Project API Key** = `phc_Bq9…` (public)
3. **Region = EU** (must match `eu.i.posthog.com`)
4. Revenue reporting = **net** (after store commission/tax)
5. Event names = defaults (`rc_*`)

### Identity alignment (in code)

Implemented in `lib/data/repositories/purchases_repository.dart`:

- `PurchasesRepository.linkPostHogIdentity({required bool consented})`
  - consented → `setAttributes({'$posthogUserId': Posthog().getDistinctId()})`
  - not consented → `setAttributes({'$posthogUserId': ''})` (empty string
    **deletes** the attribute → unlinked)
- `PurchasesRepository.setPaywallSource(source)` → sets `last_paywall_source`
  subscriber attribute so the paywall trigger rides along on the `rc_*` events
  (which otherwise carry no client context).

Call sites:

| When | Where | Effect |
|---|---|---|
| App start (after `Purchases.configure`) | `PremiumSubscriptionCubit.init()` | Links id if consent already granted |
| Consent toggled at runtime | `LocalConfigRepository.setAnalyticsEnabled()` | Links on opt-in, unlinks on opt-out |
| Before presenting paywall | `PremiumSubscriptionCubit.presentPaywall()` | Sets `last_paywall_source` |
| Delete all data | `settings_page.dart` (after `Posthog().reset()`) | Unlinks the erased identity |

All SDK calls are `!kDebugMode`-gated and wrapped in try/catch — they can never
break startup or purchases, and are no-ops in tests.

### "Send subscriber attributes as person properties" toggle

Currently **off** by design (data minimisation): we set almost no custom
attributes, so there is nothing worth persisting to person profiles yet. If
enabled later: keep it consent-gated via `$posthogUserId`, never write PII
(`$email`/`$displayName`/`$phoneNumber`/`$idfa`) into RC attributes, and document
the profiling in the privacy policy.

---

## 6. Event taxonomy

- All event names are centralised as constants in
  `lib/core/utils/app_analytics.dart` (no scattered string literals).
- Convention: `snake_case`, object_action (e.g. `loop_created`).
- One-shot activation events (`first_song_added`, `first_loop_created`) are
  guarded by SharedPreferences flags so they fire **exactly once per install**.
- No PII in event names or properties.

Fire an event:

```dart
AppAnalytics.trackEvent(
  AppAnalytics.loopCreated,
  data: {'loop_count': updatedSong.loops.length},
);
```

---

## 7. Tracking plan — the funnel

Canonical funnel:

```
Application Opened            (PostHog lifecycle autocapture)
  → first_loop_created        (activation, client)
  → paywall_viewed            (client, with `trigger` property)
  → rc_trial_started_event    (trial, RevenueCat)
  → rc_trial_converted_event OR rc_initial_purchase_event OR
    rc_non_subscription_purchase_event   (purchase, RevenueCat)
```

### Purchase / subscription events (RevenueCat defaults)

Use these as the **source of truth** for revenue, trials, renewals and churn —
they carry `revenue`, `currency`, `product_id`, `store`, `platform` and fire
server-side.

| Meaning | Event |
|---|---|
| First paid purchase | `rc_initial_purchase_event` |
| Trial started | `rc_trial_started_event` |
| Trial → paid | `rc_trial_converted_event` |
| Trial cancelled | `rc_trial_cancelled_event` |
| Renewal | `rc_renewal_event` |
| Cancellation | `rc_cancellation_event` |
| Uncancellation | `rc_uncancellation_event` |
| Lifetime / one-off (our lifetime tier) | `rc_non_subscription_purchase_event` |
| Subscription paused | `rc_subscription_paused_event` |
| Expiration | `rc_expiration_event` |
| Billing issue | `rc_billing_issue_event` |
| Product change | `rc_product_change_event` |

> Paywall event default names come from the RevenueCat Paywalls feature (not the
> transaction integration) and are **not listed in the public docs** — read the
> literal strings from the RC integration config UI, or confirm them in PostHog
> Live Events after a test purchase.

### Client events (selection)

| Funnel stage | Client event(s) | Key properties |
|---|---|---|
| App start | `Application Opened` (autocapture) | `$os`, `$app_version` |
| Onboarding | `onboarding_started`, `onboarding_completed`, `onboarding_analytics_accepted` (pre-consent events delivered via the buffer, §3) | `original_timestamp` on buffered events |
| Activation | `loop_created`, `first_loop_created`, `first_song_added`, `song_add_success` | `loop_count`, `source`, `format` |
| Core usage | `click_play_song/loop`, `click_stop_loop`, `click_pause_song`, `click_update_speed` | context |
| Paywall viewed | **`paywall_viewed`** (unified) | `trigger` (`drawer`/`onboarding`/`backup`/`song_loops`/`song_speed`/`premium_screen`) |
| Purchase (client mirror) | `purchase_success` | `tier`, `paywall_source` |
| Restore | `restore_subscription_success/failure` | `tier`, `reason` |

### Source-of-truth rule (avoid double counting)

You now have **two** purchase signals: the client `purchase_success` and the
server `rc_initial_purchase_event` / `rc_trial_converted_event`.

- **Revenue, trials, renewals, churn → use the `rc_*` events only.**
- Keep `purchase_success` only for in-session `paywall_source` attribution.
- **Never** combine both in one revenue chart — you'd double count.

For "paywall viewed" use the unified **`paywall_viewed`** event (property
`trigger`). It is emitted centrally in `PremiumSubscriptionCubit.presentPaywall`
for every RC-paywall entry point (drawer/onboarding/backup/song_loops/song_speed)
— only when the paywall was actually shown (`PaywallResult.notPresented` is
skipped) — plus once for the custom `PremiumScreen` (`trigger: premium_screen`).
The legacy `view_paywall_from_*` / `show_paywall_*` events have been removed.

---

## 8. Building insights in PostHog

- **Funnel:** `Application Opened` → `first_loop_created` → `paywall_viewed`
  → `rc_trial_started_event` → (`rc_trial_converted_event` OR
  `rc_initial_purchase_event` OR `rc_non_subscription_purchase_event`).
- **Retention:** based on `Application Opened`, anonymous `distinct_id` (stable).
- **Revenue:** on `rc_*` events, property `revenue` (+ `currency`).
- **Segment by plan:** super property `is_premium`; by trigger:
  `paywall_source` (client) / `last_paywall_source` (RC events).

---

## 9. Verification checklist (before release)

Run on a **profile/release build** with analytics consent accepted:

- [ ] `Application Opened` arrives in PostHog Live Events.
- [ ] Activation (`first_loop_created`) arrives.
- [ ] Paywall open event arrives with the expected trigger.
- [ ] Sandbox purchase → RevenueCat *Customer History* shows delivery →
      `rc_initial_purchase_event` / `rc_trial_started_event` arrives in PostHog
      **on the same person** as `Application Opened` (proves `$posthogUserId`
      alignment).
- [ ] The full funnel (§8) is buildable as a PostHog Insight with no empty stage.
- [ ] Retention insight is buildable.
- [ ] Identity: same device across a restart = **one** person, not two.

---

## 10. Known gaps / backlog

- **Decline is unmeasurable** — a user who declines analytics stays opted out, so
  `onboarding_analytics_declined` can never be delivered. Decline rate can't be
  measured client-side under strict consent (by design). The constant remains
  but is intentionally no longer emitted (`onboarding_page.dart`).
- **Client `purchase_success`** lacks `price`/`currency`/`product_id`/`is_trial`
  — intentionally superseded by the `rc_*` events for revenue.
- **Dev/prod key separation** — one public key across debug & release (debug is
  opted out + early-returns, so no test traffic reaches prod).

---

## 11. Key files

| File | Role |
|---|---|
| `lib/core/utils/app_analytics.dart` | Event constants + `trackEvent` / `setPremium` |
| `lib/main.dart` | PostHog `setup()`, consent-gated `optOut` |
| `lib/app/view/app.dart` | `PosthogObserver`, cubit wiring |
| `lib/data/repositories/local_config_repository.dart` | Consent persistence, enable/disable, RC link sync |
| `lib/data/repositories/purchases_repository.dart` | RevenueCat config + `linkPostHogIdentity` / `setPaywallSource` |
| `lib/features/paywall/cubits/premium_subscription/premium_subscription_cubit.dart` | Startup link, paywall source, purchase events |
| `lib/features/home/settings_page.dart` | `reset()` + RC unlink on delete-all-data |
| `android/.../AndroidManifest.xml`, `ios/Runner/Info.plist` | Native PostHog config (auto-init off, EU host) |
