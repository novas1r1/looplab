# RepeatLab — Business Potential Assessment

*Assessment date: 2026-06-10. Based on codebase review (v2.0.2, `feature/video-support` branch) and self-reported metrics.*

## TL;DR

Raise the prices — the app is dramatically underpriced, and that's the single biggest lever available. The conversion rate is actually good (~5% of actives paying, vs. 1–5% typical for freemium utility apps), which means the product converts; it just earns almost nothing per subscriber. $6/year works out to $0.50/month, while the closest comparable apps charge 5–10x that. The unpublished video feature is the perfect occasion to reprice.

## Current state

### Metrics (June 2026)

| Metric | Value |
|---|---|
| Active users (Android) | ~5,000 |
| Active users (iOS) | ~5–7% of Android (~250–350) |
| Subscribers | 262 |
| MRR | $126 |
| Weekly price | $1 |
| Yearly price | $6 |
| Lifetime price | $19 |

### Reading the numbers

- ~5,300 active users, 262 subscribers → **~5% paid conversion**. That's healthy; the funnel isn't the problem.
- $126 MRR / 262 subscribers ≈ **$0.48 per subscriber per month** — almost exactly $6/12, so nearly everyone is on yearly (rational, since yearly costs the same as 6 weeks of weekly). The price ladder funnels everyone to the cheapest option.
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
- Analytics fragmented: events in Wiredash, purchases in RevenueCat, PostHog used only for the other app
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
3. **Consolidate funnel visibility.** Before/while changing prices, get RevenueCat's charts in view (trial start → conversion rate, churn by product). Pointing RepeatLab's events at PostHog (account already exists) would show paywall-view → purchase conversion per trigger (onboarding vs. 2nd-loop vs. speed-control), revealing where the paywall actually earns.
4. **Test onboarding paywall timing.** The paywall currently shows immediately after onboarding, before the user has imported a single song. For a tool like this, the "aha" moment is hearing their own song slowed down in a loop — a variant where the onboarding paywall is skipped and the user instead hits it at the 2nd loop might convert better. Cheap to A/B test alongside the price experiment.

## Bottom line

Solid, mature product with proven willingness to pay — currently selling a $30 product for $6. Fix the price first, then go after iOS.
