# RepeatLab — Business Potential Assessment

*Assessment date: 2026-06-10. Based on codebase review (v2.0.2, `feature/video-support` branch) and self-reported metrics.*

*Updated 2026-07-28: metrics and the conversion claim below refreshed against a live RevenueCat pull (see `docs/revenuecat_analytics/` and the "RevenueCat Analytics" wiki page). Superseded numbers are struck through rather than deleted.*

## TL;DR

Raise the prices — the app is dramatically underpriced, and that's the single biggest lever available. The funnel itself isn't the constraint: RevenueCat's trial-to-paid conversion averages **32%** over the trailing 13 months — strong for a freemium utility app — it just earns almost nothing per subscriber. (~~The conversion rate is actually good (~5% of actives paying, vs. 1–5% typical for freemium utility apps)~~ — that figure was actually subscriber penetration, active subscriptions ÷ active users, not a conversion rate; see "Reading the numbers" below.) $6/year works out to $0.50/month, while the closest comparable apps charge 5–10x that. The unpublished video feature is the perfect occasion to reprice — though monthly churn has been climbing since March 2026 and is worth diagnosing alongside any price change (see below).

## Current state

### Metrics (June 2026, ~~superseded values struck through~~ / current as of 2026-07-28)

| Metric | Value |
|---|---|
| Active users (Android) | ~~≈5,000~~ (platform split not re-verified in the 2026-07-28 pull) |
| Active users (iOS) | ~~≈5–7% of Android (≈250–350)~~ (platform split not re-verified in the 2026-07-28 pull) |
| Active users (last 28 days, all platforms, RevenueCat) | 3,103 |
| Subscribers | ~~262~~ 261 |
| MRR | ~~$126~~ $129 |
| Weekly price | $1 |
| Yearly price | $6 |
| Lifetime price | $19 |

Full monthly trend (revenue, MRR, actives, trials, churn, conversion) for the trailing 13 months is in `docs/revenuecat_analytics/monthly_metrics.csv` and the wiki page "RevenueCat Analytics."

### Reading the numbers

- ~~≈5,300 active users, 262 subscribers → **≈5% paid conversion**. That's healthy; the funnel isn't the problem.~~ **Corrected 2026-07-28:** that "~5%" was subscriber penetration (active subscriptions ÷ active users), not a funnel conversion rate, and the 5,300 active-users figure it was built on doesn't match RevenueCat's own Active Customers data for the same period (avg ~3,165/mo). The actual RevenueCat funnel metrics: **trial-to-paid conversion averages 32%** (273 conversions / 847 trial starts, trailing 13 months, noisy but no clear trend) — the funnel genuinely isn't the problem, more emphatically than the old figure suggested. The other candidate metric, new-customer-to-paying within 7 days, averages 1.02% and has been declining (1.55% → 0.62% over the same window) — expected, since it includes all new customers, most of whom never start a trial.
- **New since June:** monthly churn has climbed steadily from 1.37% (2026-03) to 7.58% (2026-07, month in progress) — a real trend, not a blip. Current subscriber growth is outpacing it, masking the MRR impact for now, but it's worth diagnosing (which product, platform, or cohort) before or alongside a price change, since a higher price typically raises sensitivity to whatever is driving cancellations.
- $129 MRR / 261 subscribers ≈ **$0.49 per subscriber per month** — still almost exactly $6/12, so nearly everyone is on yearly (rational, since yearly costs the same as 6 weeks of weekly). The price ladder funnels everyone to the cheapest option.
- Market reference points: Moises ~$40–70/year, Anytune Pro+ ~$30 one-time, Amazing Slow Downer ~$15 one-time *per platform*, Capo ~$20–30. A looper/slowdowner for musicians with unlimited loops, tempo, pitch, waveform zoom **and video** at $6/year is priced like a hobby project, not a tool.

### Product maturity (from codebase review)

Strengths:
- Clean BLoC architecture, Sentry crash reporting, tests, lint enforcement
- Localized for 16 languages
- Mature monetization stack: RevenueCat 10.x, 3-tier offering, trial eligibility handling, restore flow
- Freemium gating in sensible places: 1 free loop, Pro unlocks unlimited loops, speed/BPM, waveform zoom, backup/restore
- Video support (beta, v2.0.1+): MP4/MOV/M4V/MKV/WebM, all loop/speed/pitch controls work on video
- Rating prompts, feature voting (UserOrient), feedback loop (Wiredash)

Gaps:
- No referral mechanism, deep links, or shareable content
- Paywall shown immediately after onboarding, before the user's "aha" moment
- ~~Analytics fragmented: events in Wiredash, purchases in RevenueCat, PostHog used only for the other app~~ **Corrected 2026-07-28:** outdated — PostHog is fully wired for RepeatLab (~60 named events, consent-gated, plus a server-side RevenueCat integration; see `docs/analytics.md`). The real remaining gap is a *standing* RevenueCat funnel/churn view: a one-off pull now exists (2026-07-28, `docs/revenuecat_analytics/`) but it isn't yet a recurring habit.
- Video is fully free (only loop/speed gating applies) — fine as acquisition hook, but it isn't sold as part of the Pro value story

## Pricing recommendation

**Raise for new users, grandfather existing subscribers.** Don't touch current subscribers — Google/Apple price increases on existing subs trigger opt-in flows and churn, and 262 subscribers at $126 MRR isn't worth the risk. Create new products and a new RevenueCat offering, keeping the old products as legacy.

Suggested ladder:

| Tier | Current | Suggested |
|---|---|---|
| Weekly | $1 | $1.99 — or replace with monthly $2.99 (weekly subs churn brutally; $1/week mostly serves as a decoy) |
| Yearly | $6 | **$14.99** (the new anchor — still cheap vs. Moises) |
| Lifetime | $19 | $39.99 (at $19 it cannibalizes yearly; lifetime should be ~2.5–3x yearly) |

Even if conversion dropped 40% at $14.99/year (unlikely — utility-app price elasticity is well below proportional), revenue per cohort would still be ~50% ahead.

Execution:
1. Use **RevenueCat Experiments** to A/B test the new offering against the current one instead of guessing — e.g. $6 vs. $12.99 vs. $19.99 yearly — and let the data decide.
2. **Tie it to the video launch.** "RepeatLab now does video" is a legitimate value-add that justifies repricing without feeling arbitrary.
3. Update the store listing and paywall to *sell* video as part of Pro's value story, even if video import stays free.

## Growth levers beyond pricing

1. **iOS is the largest untapped market.** 5–7% iOS share is unusually low for a musician's tool — musicians and music students skew heavily iOS, and iOS users monetize 2–3x better. The app is already built and localized. ASO work, screenshots/preview videos showing the video feature, and a small Apple Search Ads budget on terms like "slow down music practice" could plausibly do more for revenue than anything else on this list.
2. **Add a viral loop.** A shareable "loop pack" (the `.rlbackup` export is 90% of the way there) that a teacher sends to students would put the app in front of exactly the right new users. Deep links would make this land in-app.
3. **Consolidate funnel visibility.** ~~Before/while changing prices, get RevenueCat's charts in view (trial start → conversion rate, churn by product). Pointing RepeatLab's events at PostHog (account already exists) would show paywall-view → purchase conversion per trigger (onboarding vs. 2nd-loop vs. speed-control), revealing where the paywall actually earns.~~ **Updated 2026-07-28:** PostHog is already fully wired (see Gaps, above) and a first RevenueCat pull now exists (`docs/revenuecat_analytics/`), covering trial conversion (32%), churn (climbing since March 2026), and revenue trend. What's still missing: turning that one-off pull into a recurring review, a per-product/platform churn breakdown, and the PostHog paywall-view → purchase conversion-per-trigger analysis (onboarding vs. 2nd-loop vs. speed-control) — the data exists in PostHog but hasn't been analyzed yet.
4. **Test onboarding paywall timing.** The paywall currently shows immediately after onboarding, before the user has imported a single song. For a tool like this, the "aha" moment is hearing their own song slowed down in a loop — a variant where the onboarding paywall is skipped and the user instead hits it at the 2nd loop might convert better. Cheap to A/B test alongside the price experiment.

## Bottom line

Solid, mature product with proven willingness to pay — currently selling a $30 product for $6. Fix the price first, then go after iOS.
