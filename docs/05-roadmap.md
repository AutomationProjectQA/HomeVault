# 05 — Roadmap & KPIs

12-month plan in four phases. Each phase has a single goal, a hard scope boundary, and exit criteria that gate the next phase. Dates assume start = **July 2026**; adjust proportionally for team size (see doc 06 capacity notes).

## Phase Overview

```
P1  MVP (Jul–Sep '26)      → prove activation & the reminder habit     [Sprints 0–6]
P2  Depth (Oct–Dec '26)    → become the home's primary record          [Sprints 7–12]
P3  Scale (Jan–Mar '27)    → retention, multi-home, languages, Plus    [Sprints 13–18]
P4  Ecosystem (Apr–Jun '27)→ marketplace, ads, integrations            [Sprints 19–24]
```

## Phase 1 — MVP (Months 0–3)

**Goal:** A new user reaches first value in 90 seconds and receives reliable reminders that they act on.

**Scope:** Auth, single home, Assets (+invoice attach), Bills (+recurring), Maintenance log, Reminder Engine v1 (push + dashboard tasks + snooze), Family invite + shared view, app lock, dashboard, closed beta → Play Store launch.

**Exit criteria (gate to P2):**
- Activation (first asset/bill + reminder ≤48h) **>50%** among beta users
- Reminder action rate **>50%**
- Crash-free sessions **>99.5%**
- 20+ beta households giving qualitative "would miss it" feedback

## Phase 2 — Depth (Months 4–6)

**Goal:** HomeVault becomes where the household's record *lives* — documents, rooms, expenses, search.

**Scope:** Documents vault (OCR + expiry reminders), Rooms, Inventory-lite, Expenses, Contacts, QR codes, global search, calendar view, SMS bill import (Android), Android widget, Health Score v1, monthly summary v1, **iOS release**.

**Exit criteria:** 10k installs · D30 retention >8% · 5+ assets and 10+ documents per active home · SMS-import adoption >30% of Android actives.

## Phase 3 — Scale & Retention (Months 7–9)

**Goal:** Retention deepens; the app serves whole families and non-English users; first revenue.

**Scope:** Multi-home, roles/permissions, activity log UI, reports + PDF/CSV export, offline hardening + import/export, Hindi + Gujarati, Health Score v2 + streaks/badges, monthly Home Report, iOS widget, **HomeVault Plus launch** (₹99–149/mo · ₹699–999/yr).

**Exit criteria:** 25k installs · D30 >10% · homes with ≥2 members >30% · Plus conversion >1.5% of MAU · rating ≥4.3.

## Phase 4 — Ecosystem & Monetization (Months 10–12)

**Goal:** Sustainable revenue without breaking trust.

**Scope:** Service marketplace pilot (1 city, 2 categories: AC + RO service) with booking + affiliate fees, extended-warranty/insurance affiliate links at renewal moments, contextual native ads on free tier (strict relevance + frequency caps), spend benchmarking, community-rated providers.

**Exit criteria:** 50k installs · monthly revenue ≥ infra + tooling costs (operational break-even) · ad complaint rate <0.5% · marketplace NPS >40.

## KPI Tree

**North star:** *Weekly Active Homes* (homes where ≥1 member completed ≥1 reminder or added ≥1 record that week).

| KPI | 3 mo | 6 mo | 12 mo |
|-----|------|------|-------|
| Installs | 1k (beta+launch) | 10k | 50k |
| Activation (≤48h) | >50% | >60% | >65% |
| D7 retention | 20% | 25% | 30% |
| D30 retention | 6% | 8% | 10%+ |
| DAU/MAU | 12% | 15% | 20% |
| Assets per active home | 3+ | 5+ | 10+ |
| Homes with ≥2 members | 10% | 20% | 35% |
| Reminder action rate | >50% | >60% | >65% |
| Play rating | ≥4.0 | ≥4.2 | ≥4.5 |
| Revenue/month | ₹0 (by design) | ₹0 (by design) | ₹1.5L+ (Plus + affiliate + ads) |

(Benchmarks: mobile median D30 ≈ 4%; good B2C D7 ≈ 20% — targets are ambitious but justified by shared-home lock-in.)

## Growth Plan (starts Phase 2)

1. **Built-in virality:** family invite at first-value moment; each home averages >1 invite. Cheapest channel we have.
2. **New-homeowner moment:** content + partnerships around possession/moving (packers-movers, interior designers, society WhatsApp groups).
3. **ASO:** "home inventory", "warranty tracker", "bill reminder" (EN + HI); screenshots lead with the dashboard + health score.
4. **QR stickers as physical marketing:** printable asset QR sheets carry the logo — visible to every technician and guest.
5. **Monthly Home Report share card:** "My home health: 94 🏠" — shareable to WhatsApp.
6. **Paid UA only after D30 >8%** — buying users into a leaky bucket is burning money.

## Budget Envelope (indicative)

| Phase | Eng cost (2–3 devs + design) | Infra | Marketing |
|-------|------------------------------|-------|-----------|
| P1 | ₹25–40L | <₹10k/mo (Firebase free tier mostly) | ~₹0 (beta) |
| P2 | ₹30–45L | ₹15–30k/mo | ₹2–5L (ASO, micro-influencers) |
| P3 | ₹35–50L | ₹30–60k/mo | ₹5–10L |
| P4 | ₹35–50L | ₹50k–1L/mo | ₹10L+ (city pilot) |

Total year-1 ≈ ₹1.4–2 crore full-team, consistent with the research benchmark ($120–240k). **Solo/duo founder path:** same phases, double the calendar (each "phase" ≈ 2 quarters) — see doc 06.
