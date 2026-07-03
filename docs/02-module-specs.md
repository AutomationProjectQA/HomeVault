# 02 — Module Specifications

All modules from the concept, consolidated and prioritized. **MoSCoW** per phase: M = Must, S = Should, C = Could, W = Won't (this phase).

## Priority Matrix (all 19 modules)

| Module | Phase 1 (MVP) | Phase 2 | Phase 3 | Phase 4 |
|--------|:---:|:---:|:---:|:---:|
| M1 Dashboard | **M** (core widgets) | S (customization) | S (health score v2) | — |
| M2 Home Profile | **M** (single home) | — | M (multi-home) | — |
| M3 Rooms | W | **M** | — | — |
| M4 Assets | **M** | S (QR, health status) | — | — |
| M5 Bills | **M** | S (SMS import) | S (analytics v2) | — |
| M6 Expenses | W | **M** | S (budgets) | — |
| M7 Documents | S (attach-only) | **M** (standalone vault) | — | — |
| M8 Maintenance | **M** (reminders + log) | S (technician, photos) | — | — |
| M9 Inventory | W | **M** (lightweight) | — | — |
| M10 Contacts | C | **M** | — | S (marketplace link) |
| M11 Family | **M** (invite + shared view) | — | M (roles/permissions) | — |
| M12 Notifications | **M** (engine v1) | M (engine v2: escalation) | — | — |
| M13 Reports | W | S (monthly summary) | **M** (full reports + export) | — |
| M14 QR Codes | W | **M** | — | — |
| M15 Search | C (basic) | **M** (global + OCR text) | — | — |
| M16 Calendar | S (list view) | **M** (month view) | — | — |
| M17 Backup/Sync | M (cloud sync core) | S (export) | **M** (offline hardening, import) | — |
| M18 Security | **M** (app lock, encryption) | — | S (device mgmt) | — |
| M19 Settings | **M** (basics) | S | M (languages) | — |
| — Marketplace/Affiliate | W | W | W | **M** |

---

## Phase 1 Modules — Full Specs

### M4 · Assets (the anchor module)

**Purpose:** Every appliance/valuable item, with its paper trail and future obligations.

**Fields:** name*, category* (Electronics/Furniture/Vehicle/Kitchen/Other — extensible), brand, model, serial no., purchase date, purchase price, vendor, warranty end date, photos (≤5), invoice attachment (image/PDF), notes, room (Phase 2), status (active/sold/disposed).

**Behaviors:**
- Camera-first add flow: snap invoice → ML Kit OCR pre-fills brand/date/price → user confirms
- Warranty end date auto-generates a **reminder chain** (30d / 7d / expiry day)
- Optional service interval ("service every 12 months") → recurring maintenance reminder
- Asset timeline: purchased → services → repairs (append-only event log)

**Acceptance criteria:**
- [ ] Add asset with only a name in ≤3 taps; full detail optional
- [ ] Invoice photo attached and viewable offline
- [ ] Warranty reminder fires on schedule with app killed (verified on Android 12+ battery optimization)
- [ ] Asset visible to all home members within 30s when online

### M5 · Bills

**Purpose:** Every recurring obligation, with history and never-miss reminders.

**Fields:** type* (Electricity/Water/Gas/Internet/Mobile/Society/Insurance/Property Tax/Rent/Other), provider, amount, due date*, status (upcoming/paid/overdue), paid date, payment method, receipt attachment, recurrence rule (monthly/quarterly/yearly/custom), notes.

**Behaviors:**
- Templates for Indian billers (pre-filled type + typical cycle)
- Marking paid on a recurring bill **auto-creates the next occurrence**
- Overdue bills escalate per Reminder Engine critical rules
- Simple trend: this month vs last month per type ("Electricity up 24%") — pure arithmetic, no AI

**Acceptance criteria:**
- [ ] Create a recurring monthly bill in ≤5 taps
- [ ] Mark-paid generates next occurrence + stops current reminders
- [ ] Bill history filterable by type/date; totals correct
- [ ] Critical escalation schedule fires: 7d / 3d / 1d / due-day AM / due-day PM / daily-overdue

### M8 · Maintenance (MVP slice)

**Purpose:** Service reminders and a service log per asset (or standalone, e.g., water-tank cleaning).

**Fields:** title*, linked asset (optional), service date, cost, provider/technician name + phone, next due date / recurrence, notes, receipt photo.

**Acceptance criteria:**
- [ ] Log a completed service in ≤4 taps from the asset screen
- [ ] "Next due" creates a recurring reminder (medium priority: 30d / 7d / due / every-7d-after)
- [ ] Service history renders on asset timeline

### M11 · Family (MVP slice)

**Purpose:** Shared home — the retention moat.

**Scope MVP:** invite via share link/code → member joins home → sees all data; roles limited to **Owner** (can delete home, remove members) and **Member** (full read/write). Activity log records who added/edited (display-only).

**Acceptance criteria:**
- [ ] Invite link joins a second account to the home in <60s
- [ ] Two members' edits sync both directions; last-write-wins conflicts don't lose attachments
- [ ] Owner can remove a member; removed member loses access on next sync

### M12 · Notifications / Reminder Engine v1

See [doc 04](04-reminder-engine.md) — this is core infrastructure. MVP scope: priority levels, schedule chains, local notifications + FCM, snooze, mark-done, dashboard task cards.

### M1 · Dashboard (MVP slice)

Widgets: **Today's Tasks** (actionable checkboxes, not a notification list), Upcoming (7-day), stats strip (assets / bills this month / pending), quick-add FAB (Asset / Bill / Service), setup progress ring.

### M18 · Security (MVP slice)

- Biometric/PIN app lock (opt-in, prompted during onboarding)
- TLS everywhere; Firestore security rules per-home; attachments in Cloud Storage with per-home path rules
- DPDP basics: consent screen, privacy policy, account delete (full erasure), data export stub

### M2 / M19 · Home Profile & Settings (MVP slice)

Single home: name, address (optional), photo. Settings: notification time preferences, theme, currency (default ₹), sign-out, delete account.

---

## Phase 2 Modules — Summary Specs

- **M7 Documents (standalone vault):** categories (Property/Insurance/Identity/Tax/Warranty/Other), expiry + renewal reminders, OCR full-text extraction on upload, tags, link-to-asset. *The OCR text index powers global search.*
- **M3 Rooms:** room list per home; assets assigned to rooms; room photo. Pure organization layer over existing assets.
- **M9 Inventory:** lightweight counted items (utensils, tools, linen) — name, qty, room, photo. Explicitly not asset-grade detail.
- **M6 Expenses:** one-off home spends (repair, furniture, decor); category charts; month/year totals; merges bills into a unified "home cost" view.
- **M10 Contacts:** service providers with one-tap call/WhatsApp, rating, "last used" auto-stamped from maintenance logs.
- **M14 QR Codes:** generate printable QR per asset → scan opens asset card (deep link). Differentiator feature; also a physical-world marketing surface.
- **M15 Search:** global — assets, bills, documents (incl. OCR text), contacts.
- **M16 Calendar:** month view of all dated items; device-calendar export (opt-in).
- **SMS bill import (Android):** parse biller SMS → draft bill entries user confirms. Explicit consent, Play policy compliant, manual always available.
- **iOS release** from the same Flutter codebase.

## Phase 3 Modules — Summary Specs

- **Multi-home** (M2): home switcher; per-home membership.
- **Roles & permissions** (M11): Admin/Member/Guest; per-module view/edit; activity log UI.
- **Reports & export** (M13): monthly/yearly expense, warranty report, asset register PDF/CSV.
- **Offline & backup hardening** (M17): full offline queue, conflict UI, manual export/import.
- **Localization**: Hindi + Gujarati + one more; currency/date formats.
- **Home Health Score v2 + widgets** (Android home-screen, iOS).

## Phase 4 — Ecosystem

- Local service marketplace (booking + affiliate), extended-warranty/insurance affiliate, contextual ads on free tier, benchmarking ("homes like yours spend ₹X"), community-recommended providers.
