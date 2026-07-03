# 06 — Sprint Plan

## Working Agreements

- **Cadence:** 2-week sprints. Sprint 0 starts immediately.
- **Team assumption:** 2 Flutter devs + 1 designer (part-time) + founder as PM/QA. **Solo-founder mode:** take each sprint's Must-have stories only and allow 3–4 weeks per sprint; the order doesn't change.
- **Estimation:** story points (1 ≈ half a dev-day). Team velocity assumption: ~40 pts/sprint (2 devs); solo ≈ 18–20 pts.
- **Ceremonies (lightweight):** sprint planning (1h), mid-sprint check (30m), demo + retro (1h). Demo rule: *every sprint ends with something tappable on a real device.*
- **Definition of Done (every story):** code reviewed · unit/widget tests for logic · works offline · analytics events wired · no new crashes in smoke test · runs on a 3GB-RAM Android device.

---

# PHASE 1 — MVP (Sprints 0–6)

## Sprint 0 — Foundations (Weeks 1–2)

**Goal:** A running app skeleton with CI, design system, and the data layer proven end-to-end.

| # | Story | Pts |
|---|-------|-----|
| 0.1 | Repo scaffolding: Flutter project, feature-first folders, Riverpod + GoRouter wired, flavors (dev/prod) | 3 |
| 0.2 | CI/CD: GitHub Actions — analyze, test, build APK → Firebase App Distribution on main | 5 |
| 0.3 | Firebase project setup (dev+prod): Auth, Firestore, Storage, FCM, Crashlytics, Analytics; base security rules | 3 |
| 0.4 | Drift database v1: homes, members, assets, bills, reminders, events, documents, outbox tables + migrations strategy | 8 |
| 0.5 | Sync engine walking skeleton: outbox → Firestore for ONE table (assets), remote listener → Drift; last-write-wins | 8 |
| 0.6 | Design system v1: color/typography tokens, spacing scale, core components (button, card, input, sheet, empty state) — premium feel, not stock Material | 8 |
| 0.7 | App shell: bottom nav (Home / Add / Settings placeholder), theme, splash | 3 |
| **Total** | | **38** |

**Demo:** add a fake asset on device A, see it appear on device B.
**Risks:** sync skeleton is the hard one — timebox to 5 days; if slipping, cut 0.6 scope (tokens only) not 0.5.

## Sprint 1 — Auth, Home & Onboarding (Weeks 3–4)

**Goal:** New user signs in, creates a home, and lands on a real dashboard.

| # | Story | Pts |
|---|-------|-----|
| 1.1 | Auth: Google Sign-In + phone OTP; account bootstrap; sign-out; delete-account stub | 8 |
| 1.2 | Create home flow: name + optional photo; membership record; Firestore rules for per-home access | 5 |
| 1.3 | Onboarding shell: welcome → sign-in → create home → (asset step placeholder) → dashboard; progress indicator; skippable steps | 5 |
| 1.4 | Dashboard v0: greeting, empty states that teach ("Add your first appliance"), quick-add FAB, setup progress ring | 5 |
| 1.5 | Consent & privacy: first-run consent screen, privacy policy page, analytics opt-out toggle | 3 |
| 1.6 | Analytics foundation: event helper, funnel events for onboarding steps | 3 |
| 1.7 | App lock: biometric/PIN opt-in (local_auth), lock screen | 5 |
| **Total** | | **34** |

**Demo:** fresh install → signed in, home created, empty dashboard, app lock on.

## Sprint 2 — Assets Module (Weeks 5–6)

**Goal:** The anchor module, camera-first. First value becomes real.

| # | Story | Pts |
|---|-------|-----|
| 2.1 | Asset CRUD: list, detail, add/edit forms (name-only quick add ≤3 taps; expandable full form), categories, soft delete | 8 |
| 2.2 | Photos & invoice attach: camera/gallery, compression, Cloud Storage upload via outbox, offline thumbnail cache | 8 |
| 2.3 | OCR-assisted add: snap invoice → ML Kit extracts date/price/vendor → pre-filled confirm screen (graceful when OCR misses) | 8 |
| 2.4 | Warranty fields + computed status (active / expiring soon / expired) with visual states on card | 3 |
| 2.5 | Asset timeline v0: purchase event auto-created; events table rendering | 3 |
| 2.6 | Onboarding step "Add your first appliance" wired to camera-first flow; `first_asset_added` activation event | 3 |
| 2.7 | Asset sync + family visibility (extends sync engine to attachments) | 5 |
| **Total** | | **38** |

**Demo:** snap a real Croma/Amazon invoice → asset created with pre-filled fields in <60s.
**Risk:** OCR accuracy on Indian invoices — collect 20 sample invoices *this sprint week 1*; if extraction <50% useful, ship scan-and-attach (manual fields) and iterate in Sprint 5.

## Sprint 3 — Reminder Engine v1 (Weeks 7–8) ⭐ the product

**Goal:** Reliable, priority-based reminders with dashboard tasks and snooze.

| # | Story | Pts |
|---|-------|-----|
| 3.1 | Reminder domain: polymorphic reminders table, policy table (priority → offset chains as data), state machine (scheduled/active/snoozed/overdue/completed/cancelled) — **table-driven unit tests** | 8 |
| 3.2 | Local notification scheduler: chain scheduling, reschedule on boot/update, exact-alarm permission flow, completion cancels pending | 8 |
| 3.3 | Warranty reminders: asset warranty auto-generates critical chain (30d/7d/expiry) | 3 |
| 3.4 | Dashboard "Today's Tasks": actionable cards, ☐ done, snooze sheet (tomorrow/3d/next week/custom), overdue styling (red/orange/yellow) | 8 |
| 3.5 | Android reliability: battery-optimization exemption flow with in-context explainer; OEM test pass (MIUI/ColorOS/OneUI) | 5 |
| 3.6 | Notification fatigue guards: per-day caps, quiet hours setting | 3 |
| 3.7 | Engine analytics: fired/actioned/snoozed/ignored events + notification_log | 3 |
| **Total** | | **38** |

**Demo:** warranty set to expire in 8 days → kill app → notification arrives on schedule on a Xiaomi device; tap → task card → Done → chain stops everywhere.
**Risk:** OEM notification killing — this sprint's test matrix is non-negotiable; budget a full day of device testing.

## Sprint 4 — Bills & Recurrence (Weeks 9–10)

**Goal:** Never miss a bill. Recurring automation closes the core loop.

| # | Story | Pts |
|---|-------|-----|
| 4.1 | Bill CRUD: Indian biller templates (electricity/water/gas/internet/mobile/society/insurance/property tax), quick-add ≤5 taps, receipt attach | 8 |
| 4.2 | Recurrence engine: RRULE storage, mark-paid → auto-create next occurrence + schedule its chain (unit-tested against month-end/leap edge cases) | 8 |
| 4.3 | Critical bill chains + overdue escalation (daily×7 → weekly) via engine policies | 5 |
| 4.4 | Bill history & filters; monthly totals; "vs last month" delta per type ("Electricity up 24%") | 5 |
| 4.5 | Maintenance MVP: log service (from asset or standalone), cost + provider, next-due recurring reminder (medium policy) | 8 |
| 4.6 | Dashboard v1: upcoming-7-days widget, stats strip (assets / this month's bills / pending tasks) | 3 |
| **Total** | | **37** |

**Demo:** create monthly electricity bill → mark paid → next month's bill + reminders exist automatically; log an AC service with next-due next year.

## Sprint 5 — Family Sharing & Notification Center (Weeks 11–12)

**Goal:** The retention moat: a second family member joins and sees everything.

| # | Story | Pts |
|---|-------|-----|
| 5.1 | Invite flow: share-link/code generation, Cloud Function redemption, join-home UX, member list | 8 |
| 5.2 | Roles v1: Owner vs Member; owner can remove member; access revocation on sync; security-rules tests | 5 |
| 5.3 | Multi-device correctness: reminders fire for all members; Done by one clears for all (FCM-assisted); attribution "Added by Meet" | 8 |
| 5.4 | In-app notification center: Today / This week / History, deep links to source records | 5 |
| 5.5 | Cloud Function daily sweep: FCM safety net for missed local notifications | 5 |
| 5.6 | Onboarding "Invite your family" step at first-value moment; invite analytics | 2 |
| 5.7 | OCR iteration from Sprint 2 learnings (top failure patterns on Indian invoices) | 3 |
| **Total** | | **36** |

**Demo:** two phones, one home — add bill on A, reminder fires on both, Done on B clears A.

## Sprint 6 — Polish, Beta & Launch Prep (Weeks 13–14)

**Goal:** Closed beta quality; Play Store submission.

| # | Story | Pts |
|---|-------|-----|
| 6.1 | UX polish pass: micro-animations, transitions, haptics, empty/error/loading states everywhere, one-handed reach audit | 8 |
| 6.2 | Performance: cold start <2.5s on 3GB device, list virtualization, image cache tuning, app size <30MB | 5 |
| 6.3 | Hardening: offline torture tests (airplane-mode CRUD → sync recovery), sync conflict edge cases, Crashlytics triage to >99.5% crash-free | 8 |
| 6.4 | Settings completion: notification preferences (times, quiet hours), currency, theme, export-data stub, delete account (full cascade) | 5 |
| 6.5 | Play Store: listing (screenshots, copy), data-safety form, content rating, closed-beta track rollout to 50–100 households | 5 |
| 6.6 | Feedback loop: in-app feedback form, beta WhatsApp/Telegram group, weekly triage ritual | 2 |
| 6.7 | Launch dashboard: Looker Studio funnel (activation, retention, reminder action rate) | 3 |
| **Total** | | **36** |

**Exit gate → Phase 2** (from doc 05): activation >50%, reminder action rate >50%, crash-free >99.5%, 20+ engaged beta households.

---

# PHASE 2 — Depth (Sprints 7–12, Months 4–6)

One-line goals per sprint; stories drafted at Sprint 6 retro using beta learnings. **Re-plan against beta data — this order is the default, not a contract.**

| Sprint | Theme | Highlights |
|--------|-------|-----------|
| 7 | **Documents vault** | Standalone module: categories, expiry reminders (engine plug-in), OCR text extraction on upload, tags, link-to-asset |
| 8 | **Search + Calendar** | Global search (assets/bills/docs incl. OCR text); calendar month view; device-calendar export opt-in |
| 9 | **SMS bill import (Android)** | Consent-first SMS parsing for top billers → draft bills to confirm; Play policy compliance review; parser rule updates via Remote Config |
| 10 | **Rooms + Inventory + Expenses** | Rooms as organization layer; inventory-lite counted items; one-off expenses + unified home-cost view with charts |
| 11 | **QR codes + Contacts + Widget** | Printable QR per asset → deep-link scan; provider contacts with one-tap call/WhatsApp; Android home-screen widget ("Today's Home") |
| 12 | **Health Score v1 + iOS + launch** | Health score on dashboard; monthly summary v1; iOS build/TestFlight/App Store; public launch push + ASO |

**Exit gate → Phase 3:** 10k installs · D30 >8% · 10+ documents per active home · SMS import >30% of Android actives.

# PHASE 3 — Scale (Sprints 13–18, Months 7–9)

| Sprint | Theme |
|--------|-------|
| 13 | Multi-home + home switcher |
| 14 | Roles/permissions (Admin/Member/Guest) + activity log UI |
| 15 | Reports & export (PDF/CSV asset register, expense reports) + full data import/export |
| 16 | Localization: Hindi + Gujarati; regional ASO |
| 17 | Health Score v2, streaks/badges, monthly Home Report (shareable card), iOS widget |
| 18 | **HomeVault Plus** launch: paywall, entitlements, upgrade moments; offline hardening + conflict UI |

# PHASE 4 — Ecosystem (Sprints 19–24, Months 10–12)

| Sprint | Theme |
|--------|-------|
| 19–20 | Service marketplace pilot (1 city: AC + RO service) — provider onboarding, booking flow, affiliate tracking |
| 21 | Renewal-moment affiliates (extended warranty, insurance) |
| 22 | Contextual native ads on free tier (frequency caps, relevance rules, complaint monitoring) |
| 23 | Benchmarking ("homes like yours") + community provider ratings |
| 24 | Year-1 hardening, cost optimization, year-2 planning |

---

## Backlog Hygiene

- Anything not in the current sprint lives in `BACKLOG.md` (create at Sprint 0) under Next / Later / Ideas. The 19-module concept maps into Later/Ideas — **written down so it stops haunting scope discussions.**
- New ideas mid-sprint → backlog, never into the sprint. Swaps allowed only for launch-blockers.
- Every sprint retro re-scores the next sprint's stories against the phase exit criteria.

## First Actions (this week)

1. Sprint 0 stories 0.1–0.3 (scaffolding + CI + Firebase) — day 1–3
2. Collect 20 real Indian invoices/bills (photos + PDFs) for the OCR test corpus — costs nothing now, de-risks Sprint 2
3. Recruit 10 beta households (family/friends) into a WhatsApp group — they'll shape Sprints 2–6
4. Name check: confirm "HomeVault" availability on Play Store / domain / trademark search before the listing sprint
