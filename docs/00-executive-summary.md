# 00 — Executive Summary & Analysis

*Synthesis of the concept document, competitive research, and technical feasibility study. This is the "what we decided and why" document — read this first.*

---

## 1. What the research actually tells us

After analyzing the full concept doc and market research, five findings matter more than everything else:

### Finding 1 — The market gap is real, but narrow
No competitor combines assets + bills + documents + maintenance + family sharing (Homer, Homellow, Under My Roof each cover fragments; axio/Walnut owns bill-SMS parsing but has zero home context). **However**, the gap exists partly because the combined product is hard to onboard. The gap is an opportunity *only if we solve setup friction* — otherwise we become the 15th abandoned organizer app.

### Finding 2 — The product is the Reminder Engine, not the database
Users don't want to "manage" their home; they want **peace of mind**. Storage modules (assets, docs, bills) are just the data that feeds reminders. This inverts the build order: the reminder engine is core infrastructure built in Sprint 3, not a Phase-3 feature. Every module must answer: *"what reminder does this generate?"*

### Finding 3 — Notifications alone fail; retention comes from surfaces
Industry data: ~75% of users churn by day 3; median day-30 retention is ~4%. Push notifications get suppressed within 2–3 weeks. The plan therefore treats notifications as *one of eight* delivery surfaces (dashboard cards, calendar, widget, health score, monthly report, family escalation, badges). Family sharing is the strongest retention lever — a shared home is painful to abandon.

### Finding 4 — Onboarding friction is the #1 kill risk
Nobody will manually type 20 appliances + 15 documents. Mitigations, in order of leverage:
1. **First-value-in-90-seconds onboarding**: create home → add ONE asset (camera + OCR assisted) → get first reminder scheduled
2. **Scan, don't type**: ML Kit OCR on invoices auto-fills brand/date/amount; barcode scan for appliances
3. **SMS bill parsing (Android, Phase 2)**: auto-import electricity/gas/internet bills like axio does
4. **Progressive setup + gamification**: "Home 40% secured" progress, not a 20-field form

### Finding 5 — Monetize late, monetize contextually
Indian banner CPMs are ₹80–250 ($1–3). Ads before ~50k MAU produce noise, not revenue, and damage trust in an app holding property documents. Decision: **zero ads in Phase 1–2**. Revenue starts Phase 3 (premium tier) and Phase 4 (contextual ads + service affiliate), when the app knows what users own.

---

## 2. Key decisions (locked)

| # | Decision | Rationale |
|---|----------|-----------|
| D1 | **Flutter, Android-first** | India is ~95% Android; one codebase; iOS ships Phase 2 from same code |
| D2 | **Offline-first: Drift (SQLite) local, Firestore sync** | Home data must open instantly with no network; Firestore gives free-tier sync + family sharing |
| D3 | **MVP = 3 jobs only**: Assets/warranty, Bills/reminders, Family sharing | The concept's 19 modules are a feature dump; retention research says nail 3 habits first |
| D4 | **Reminder Engine is core infrastructure (Sprint 3)** | See Finding 2 — everything hangs off it |
| D5 | **Documents ship inside Assets/Bills first** (attach invoice/warranty), standalone Documents module in Phase 2 | Reduces MVP surface without losing the "never lose an invoice" promise |
| D6 | **No ads until Phase 4; premium tier in Phase 3** | Trust-first; ad inventory is worthless below scale |
| D7 | **DPDP-compliant from day 1**: consent screens, minimal PII, export/delete, no Aadhaar/PAN storage | Cheaper to build in than retrofit; trust is the moat for a documents app |
| D8 | **English UI first; Hindi + 2 regional languages in Phase 3** | Localization before marketplace, after PMF |

---

## 3. Top risks & mitigations

| Risk | Severity | Mitigation |
|------|----------|-----------|
| Setup friction → day-1 abandonment | 🔴 Critical | 90-second first-value onboarding; OCR scan-to-add; empty states that teach; measure "first asset added" as the activation metric |
| Notification fatigue → reminders ignored | 🔴 Critical | Multi-surface engine (doc 04); smart snooze instead of dismiss; escalation caps |
| Solo/small team burns out on 19 modules | 🔴 Critical | Ruthless MoSCoW in doc 02; Phase 1 scope frozen at 3 jobs; "later" list is a feature, not a failure |
| Firestore costs at scale | 🟡 Medium | Offline-first design minimizes reads; aggregate documents; monitor from Sprint 1; Supabase/self-hosted exit path documented in doc 03 |
| SMS permission = Play Store policy risk | 🟡 Medium | SMS parsing is Phase 2, behind explicit consent, with manual entry always available; follow axio's declared-use precedent |
| Family sharing complexity (permissions, conflicts) | 🟡 Medium | MVP sharing = invite + shared view + simple roles (owner/member); granular permissions deferred to Phase 3 |
| Trust: users won't upload property docs to an unknown app | 🟡 Medium | Encryption messaging in UI; biometric app lock in MVP; privacy policy in plain language |

---

## 4. What success looks like

**Activation metric (the one number that matters in Phase 1):**
> % of new users who add ≥1 asset or bill **and** receive their first reminder within 48 hours. Target: **>60%**.

| Milestone | 6 months | 12 months |
|-----------|----------|-----------|
| Installs | 10,000 | 50,000 |
| Day-30 retention | 8% | 10%+ |
| Assets per active home | 5+ | 10+ |
| Homes with ≥2 members | 20% | 35% |
| App rating | ≥4.2 | ≥4.5 |

Full KPI tree in [doc 05](05-roadmap.md).

---

## 5. Where to go from here

1. Read [01 — Product Plan](01-product-plan.md) for the full product definition
2. [02 — Module Specs](02-module-specs.md) is the complete feature reference (all 19 modules, prioritized)
3. [06 — Sprint Plan](06-sprint-plan.md) is the execution plan — Sprint 0 can start today
