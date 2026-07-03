# 04 — Reminder Engine

**This is the product.** Assets, bills, and documents are data; the engine is why users return. It is built as core infrastructure (Sprint 3) and every module plugs into it.

## Design Principles

1. **Notifications are one channel, not the system.** Surfaces: push, dashboard task cards, in-app notification center, calendar, widget, health score, monthly report, family escalation.
2. **Tasks, not alerts.** Users see "Today's Home Tasks ☐ Pay electricity bill", never a pile of dismissable notifications.
3. **Snooze, never lose.** Dismissing is snoozing; a reminder only dies when done or explicitly cancelled.
4. **Escalate socially.** The strongest anti-ignore mechanism is another family member finding out.
5. **Recurring is automatic.** Completing a recurring item creates the next occurrence — users never re-create reminders.

## Priority Levels & Schedule Chains

| Priority | Examples | Chain (before due) | If overdue |
|----------|----------|--------------------|-----------|
| 🔴 **Critical** | Bill due, insurance/property tax, warranty expiry, EMI | 7d → 3d → 1d → due-day 9am → due-day 7pm | Daily ×7, then weekly; escalate to family after 2 days |
| 🟡 **Medium** | AC/RO service, tank cleaning, pest control | 30d → 7d → due day | Every 7d; escalate after 14 days (optional) |
| 🟢 **Low** | "Paint house", "organize documents" | Once on due day | Stays on dashboard only; never pushes again |

Chains are **data, not code**: `reminder_policies` table (priority → offsets JSON) so tuning never needs an app release, and Remote Config can A/B them.

## State Machine

```
SCHEDULED ──due date approaches──▶ ACTIVE (in chain, firing)
   ACTIVE ──user taps Done──────▶ COMPLETED ──recurrence?──▶ next SCHEDULED
   ACTIVE ──user snoozes───────▶ SNOOZED (tomorrow/3d/next week/custom) ──▶ ACTIVE
   ACTIVE ──due passes─────────▶ OVERDUE (escalation rules) ──Done──▶ COMPLETED
   any    ──source deleted─────▶ CANCELLED
```

Rules:
- Completion **stops all pending notifications** for that reminder immediately (all family devices, via sync + FCM).
- Overdue escalation caps: max 1 push/day per reminder, max 3 home-task pushes/day total (fatigue guard).
- Family escalation is **opt-in per home** ("If a critical task is ignored 2 days, notify other members") — social pressure with consent.

## Data Model

```
reminders
  id, home_id, source_type (asset|bill|document|event|manual), source_id,
  title, priority (critical|medium|low), due_at, assigned_to (nullable = whole home),
  recurrence_rule (RRULE string, nullable), state, snoozed_until,
  policy_id, escalation_enabled, created_by, timestamps, sync fields

notification_log
  id, reminder_id, user_id, channel (local|fcm), fired_at, action (opened|done|snoozed|ignored)
```

`notification_log` powers the ignore-detection ("3 fired, 0 actioned → escalate / back off") and the reminder-effectiveness KPI.

## Delivery Surfaces (build order)

| # | Surface | Phase |
|---|---------|-------|
| 1 | Local push notifications (chain scheduling) | 1 · Sprint 3 |
| 2 | Dashboard "Today's Tasks" cards with ☐ done / snooze | 1 · Sprint 3 |
| 3 | In-app notification center (Today/This week/History) | 1 · Sprint 5 |
| 4 | Smart snooze sheet (Tomorrow / 3 days / Next week / Custom) | 1 · Sprint 3 |
| 5 | Recurring auto-regeneration | 1 · Sprint 4 |
| 6 | Family escalation via FCM + Cloud Function sweep | 2 |
| 7 | Calendar month view + device-calendar export | 2 |
| 8 | Home-screen widget ("Today's Home") | 2 (Android) / 3 (iOS) |
| 9 | Home Health Score (% on-time, drives dashboard ring) | 2 (v1) / 3 (v2) |
| 10 | Monthly Home Report (push + in-app, 1st of month) | 3 |

## Home Health Score (v1 formula)

```
score = 100
  − 15 × critical_overdue   (cap 45)
  − 5  × medium_overdue     (cap 25)
  − 5  × expiring_unactioned_warranties_30d (cap 15)
  + up to 15 from on-time completion streak
clamped 0–100 · Bands: 90+ Excellent · 70–89 Good · 50–69 Needs attention · <50 At risk
```

Simple, explainable, and every point maps to an action the user can take right now ("Do these 2 tasks → back to 94%").

## Android Reliability Checklist (India-specific)

- Exact alarms (`SCHEDULE_EXACT_ALARM`) with fallback to inexact windows
- In-context battery-optimization exemption request (explain *why* on first critical reminder)
- Reschedule all local notifications on `BOOT_COMPLETED` and app update
- Test matrix: stock Android + MIUI/HyperOS + ColorOS + OneUI (aggressive killers dominate Indian market)
- Daily Cloud Function sweep as the safety net for anything the OS killed

## Engine KPIs

- **Reminder action rate**: fired → done/snoozed within 24h. Target >60% (critical >80%).
- **Escalation rate**: % of criticals reaching family escalation. Target <10% (high = fatigue or broken delivery).
- **On-time completion**: done before due. Target >70% for bills by month 6.
