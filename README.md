# HomeVault 🏠

**Everything about your home, in one secure place.**

HomeVault is a "Home OS" for households (India-first): appliances & warranties, bills & reminders, documents, maintenance history, and shared family access — unified behind one intelligent Reminder Engine.

> Core promise: **"Never forget anything about your home again."**

## Status

🚧 **Sprint 0 in progress.** Flutter app scaffolded: design tokens, app shell (dashboard + quick-add + settings), Drift database (schema v1), offline-first outbox sync engine (Firestore adapter pending Firebase setup), CI pipeline, tests passing.

All product and engineering planning lives in [`docs/`](docs/).

### Run it

```bash
flutter pub get
dart run build_runner build   # regenerate Drift code after schema changes
flutter run                    # dev by default; add --dart-define=APP_ENV=prod for prod
flutter test
```

## Planning Documents

| Doc | What it covers |
|-----|----------------|
| [00 — Executive Summary & Analysis](docs/00-executive-summary.md) | Synthesis of all research, key decisions, top risks |
| [01 — Product Plan](docs/01-product-plan.md) | Vision, personas, jobs-to-be-done, positioning, success metrics |
| [02 — Module Specifications](docs/02-module-specs.md) | All 19 modules, prioritized (MoSCoW), with data fields & acceptance criteria |
| [03 — Architecture & Data Model](docs/03-architecture.md) | Tech stack, offline-first sync, folder structure, ERD, security/DPDP |
| [04 — Reminder Engine](docs/04-reminder-engine.md) | The core product: priority levels, escalation, delivery surfaces |
| [05 — Roadmap & KPIs](docs/05-roadmap.md) | 12-month phased roadmap, KPI targets, monetization timeline |
| [06 — Sprint Plan](docs/06-sprint-plan.md) | Sprint-by-sprint execution plan (Sprint 0–24) with stories, points, acceptance criteria |

## The One-Line Strategy

Ship 3 jobs exceptionally well before anything else:

1. **Asset & warranty vault** — add an appliance in <60 seconds, never lose an invoice again
2. **Bills & recurring reminders** — an escalating reminder engine users can't accidentally ignore
3. **Shared family access** — the whole household sees the same home

Everything else (inventory, QR stickers, expenses, marketplace) layers on top *after* these are habitual.

## Tech Stack (decided)

- **App:** Flutter (Android-first, iOS from same codebase) · Riverpod · GoRouter
- **Local-first data:** Drift (SQLite) with background sync
- **Backend:** Firebase — Auth, Firestore, Cloud Storage, FCM, Crashlytics, Analytics
- **On-device intelligence:** ML Kit OCR (receipts/invoices, Devanagari support), ML Kit barcode/QR
