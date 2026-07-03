# 01 — Product Plan

## Vision

> Every home becomes a digital entity — its assets, bills, documents, maintenance, and people — living in one shared, secure app. HomeVault is the **digital memory of the home**.

**Tagline:** *Everything about your home, in one place.*
**Emotional promise:** Peace of mind. Never forget, never lose, never depend on one person's memory.

## Positioning

Not a "household management app" (nobody wants more management). HomeVault is positioned as:

- **The vault** — where the invoice/warranty/property paper is *always* findable
- **The memory** — "when was the RO serviced?" answered in 3 seconds
- **The shared brain** — the whole family sees the same home, so nothing depends on one person

Against competitors: Homer/Homellow = single-player inventory tools; axio = money without home context; Cozi = calendar without assets. HomeVault = the only one that connects *what you own* → *what it costs* → *what needs doing* → *who needs to know*.

## Target Users

### Primary persona — "The Household CFO" (Meet, 32, Ahmedabad)
- Married, owns a flat, dual income, 10–15 appliances
- Pain: bills in email/SMS/WhatsApp, invoices lost, warranty claims missed, only he knows the plumber's number
- Trigger moments: AC breaks and warranty status is unknown; insurance lapsed silently; wife can't find the electrician's number when he's traveling
- Wins when: everything findable in <10s, reminders arrive before deadlines, family is self-sufficient

### Secondary personas
- **The Parent Organizer** (38–50): manages parents' house + own house → multi-home (Phase 3)
- **The New Homeowner** (26–32): just bought a flat, motivated to "start right" → best acquisition moment
- **The Tenant/Flat-sharer** (22–28): splits bills, tracks deposits → lighter use, growth channel

## Jobs To Be Done

| # | Job | Today's broken solution | HomeVault |
|---|-----|------------------------|-----------|
| J1 | "When my appliance breaks, tell me if it's under warranty" | Digging through drawers/email | Asset card: warranty status + invoice + service history |
| J2 | "Make sure I never miss a bill/renewal/service" | Memory + scattered SMS | Escalating Reminder Engine across 8 surfaces |
| J3 | "Let my family access home info without asking me" | One person is the single point of failure | Shared home, every member sees everything |
| J4 | "Find any home document instantly" | WhatsApp self-chat, email search | Vault with OCR search (Phase 2) |
| J5 | "Know what my home costs me" | Nothing | Bill/expense analytics & trends |

MVP ships J1 + J2 + J3. J4/J5 follow in Phase 2.

## Core Loop (the habit we're building)

```
Something arrives (bill/purchase/service)
        → 30-second capture (scan > type)
        → Reminder Engine schedules the future
        → Reminder surfaces at the right time, right person
        → One-tap "Done" → next occurrence auto-created
        → Home Health Score improves → satisfaction
```

Weekly active use comes from the *reminder side* of the loop, not the capture side. Design accordingly: capture is rare and must be effortless; acting on reminders is frequent and must be one-tap.

## Feature Principles

1. **Scan > type.** Every entry flow offers camera/OCR before keyboard.
2. **Every record generates a future.** An asset without a next-service date, a bill without a next due date, is a dead record — the UI nudges toward the reminder.
3. **Shared by default.** New homes prompt family invite at the moment of first value, not at signup.
4. **Trust visibly.** Encryption, app lock, and "your data is yours (export/delete)" are UI-visible, not buried in a policy.
5. **Works offline, always.** Opening the app in a basement parking lot must show everything instantly.

## Onboarding Flow (90 seconds to first value)

```
Welcome (1 screen, promise-led)
→ Sign in (Google / phone OTP)
→ "Name your home" (1 field + optional photo)
→ "Add your first appliance" — camera-first: snap invoice → OCR pre-fills → confirm
→ ✅ "TV warranty tracked. We'll remind you 30 days before it expires."  ← FIRST VALUE
→ "Add a bill reminder?" (electricity template, 2 fields)
→ "Invite your family" (share link) — skippable
→ Dashboard with progress ring: "Home 15% secured"
```

Activation metric: **first asset or bill + first reminder scheduled within 48h → target >60%**.

## Retention System

- **Home Health Score** (0–100): visible on dashboard; drops with overdue tasks, expiring warranties. People fix scores.
- **Setup progress + badges**: "5 assets secured", "First month streak".
- **Monthly Home Report** (1st of month, push + in-app): bills paid, spend total, upcoming renewals.
- **Family escalation**: ignored critical reminders notify another member — social accountability.
- **Widget**: today's home tasks on the home screen — value without opening the app.

## Monetization (sequenced — see doc 05 for timing)

1. **Phase 1–2: free, no ads.** Trust and habit first.
2. **Phase 3: HomeVault Plus** (₹99–149/mo or ₹699–999/yr): unlimited homes, unlimited document storage, advanced analytics, priority OCR, family roles.
3. **Phase 4: contextual ads (free tier) + affiliate**: AC service, RO filters, insurance renewal, extended warranty — high-intent inventory because the app knows what users own and when it needs service. Strict consent + relevance rules.

## Non-Goals (explicitly out of scope for year 1)

- Payments/UPI processing (remind, link out — never hold money)
- Smart-home/IoT device control
- Society/community management (notice boards, visitor entry)
- Web app (mobile-first; web read-only console considered Phase 4+)
- iOS before Android is stable (iOS enters late Phase 2)
