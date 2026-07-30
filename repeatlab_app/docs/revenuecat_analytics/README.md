# RevenueCat Analytics — RepeatLab

Pulled from RevenueCat on 2026-07-28. Project: `RepeatLab` (`projbf80aefd`). Apps: RepeatLab (App Store, `com.repeatlab.app`) and RepeatLab (Play Store, `com.repeatlab.app`).

All currency figures in EUR. Monthly data covers 2025-07 through 2026-07 (the 2026-07 row is an in-progress/incomplete month, snapshotted mid-month).

Raw monthly data for import: [`monthly_metrics.csv`](./monthly_metrics.csv).

## Last 28 Days (as of 2026-07-28)

| Metric | Value |
|---|---|
| Active Trials | 8 |
| Active Subscriptions | 261 |
| MRR | €111 |
| Revenue | €289 |
| New Customers | 2,158 |
| Active Users | 3,103 |

## Current Subscription Status Snapshot (261 active subscriptions)

| Status | Count | % |
|---|---|---|
| Set to Renew | 179 | 68.6% |
| Set to Cancel | 80 | 30.6% |
| Billing Issue (grace period) | 2 | 0.8% |

## Monthly Trend Summary (2025-07 → 2026-07)

| Month | Revenue | MRR | Active Subs (EoM) | New Customers | Active Customers | Churn Rate | Conversion to Paying (7d) | Refund Rate |
|---|---|---|---|---|---|---|---|---|
| 2025-07 | €95.68 | €11.82 | 54 | 2,319 | 1,706 | 0.00% | 1.12% | 0.00% |
| 2025-08 | €119.18 | €14.94 | 69 | 2,517 | 2,877 | 0.00% | 0.95% | 8.00% |
| 2025-09 | €155.37 | €19.09 | 89 | 2,556 | 3,173 | 0.00% | 1.29% | 0.00% |
| 2025-10 | €164.77 | €25.48 | 117 | 2,874 | 3,603 | 1.12% | 1.04% | 2.50% |
| 2025-11 | €187.14 | €35.77 | 163 | 3,171 | 3,948 | 0.00% | 1.55% | 0.00% |
| 2025-12 | €163.80 | €43.17 | 197 | 2,755 | 3,647 | 0.61% | 1.02% | 4.44% |
| 2026-01 | €69.69 | €47.69 | 207 | 2,272 | 3,074 | 0.00% | 0.53% | 18.18% |
| 2026-02 | €129.15 | €53.51 | 219 | 1,982 | 2,784 | 0.48% | 0.50% | 0.00% |
| 2026-03 | €212.45 | €73.76 | 234 | 2,075 | 2,888 | 1.37% | 1.16% | 0.00% |
| 2026-04 | €217.72 | €72.80 | 246 | 2,291 | 3,155 | 3.85% | 1.18% | 4.35% |
| 2026-05 | €221.29 | €87.83 | 255 | 2,648 | 3,573 | 4.07% | 0.98% | 0.00% |
| 2026-06 | €254.88 | €111.49 | 264 | 2,771 | 3,715 | 6.27% | 0.97% | 0.00% |
| 2026-07* | €288.49 | €111.64 | 261 | 2,086 | 3,012 | 7.58% | 0.62% | 1.72% |

\* 2026-07 is incomplete (month in progress at time of pull).

## Totals / Averages (13-month window)

- Total revenue: €2,279.61 (avg €175.35/mo)
- Total transactions: 492 (avg 37.85/mo)
- Total new customers: 32,317 (avg 2,485.92/mo)
- Average active customers/mo: 3,165.77
- Average churn rate: 2.84%/mo
- Average refund rate: 2.03%
- Average 7-day conversion to paying: 1.02%

## Notable trend

MRR has grown fairly steadily from €11.82 (2025-07) to €111.64 (2026-07), roughly 9.4x over 12 months. However, the monthly churn rate has climbed sharply since 2026-03 (1.37% → 7.58% by 2026-07), and the 7-day conversion-to-paying rate has trended down from ~1.0–1.5% in mid-2025 to ~0.5–1.0% in 2026. Worth investigating whether these are related (e.g. cohort quality, pricing/paywall changes, or a specific acquisition channel).

## Column glossary (monthly_metrics.csv)

| Column | Meaning |
|---|---|
| `revenue_eur` | Gross revenue recognized in the period |
| `transactions` | Revenue-generating transactions in the period |
| `mrr_eur` | Monthly Recurring Revenue at period end (normalized) |
| `active_subscriptions_eom` | Active paid subscriptions at end of month |
| `active_trials_eom` | Active trials at end of month |
| `new_customers` | Customers first seen in the period |
| `active_customers` | Customers seen (active) during the period |
| `churned_actives` | Subscriptions active at period start that expired without renewing |
| `churn_rate_pct` | churned_actives / active subs at period start |
| `paying_customers_7d` | New customers who converted to paid within 7 days |
| `conversion_rate_7d_pct` | paying_customers_7d / new_customers |
| `refunded_transactions` | Transactions refunded in the period |
| `refund_rate_pct` | refunded_transactions / transactions |
| `incomplete_month` | true if the period was still in progress when data was pulled |
