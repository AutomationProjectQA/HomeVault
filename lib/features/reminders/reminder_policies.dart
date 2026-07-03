/// Notification chains as data (docs/04-reminder-engine.md). Tuning these
/// never touches engine code; Remote Config can override them later.
class ReminderPolicy {
  const ReminderPolicy({
    required this.priority,
    required this.beforeDueDays,
    required this.dueDayHours,
    required this.overdueEveryDays,
    required this.overdueDailyPhaseDays,
  });

  final String priority;

  /// Days before due to notify (e.g. [7, 3, 1]).
  final List<int> beforeDueDays;

  /// Hours (0-23) on the due day itself to notify.
  final List<int> dueDayHours;

  /// After the daily phase, repeat every N days until actioned.
  final int overdueEveryDays;

  /// For this many days after due, remind daily.
  final int overdueDailyPhaseDays;
}

const _critical = ReminderPolicy(
  priority: 'critical',
  beforeDueDays: [7, 3, 1],
  dueDayHours: [9, 19],
  overdueDailyPhaseDays: 7,
  overdueEveryDays: 7,
);

const _medium = ReminderPolicy(
  priority: 'medium',
  beforeDueDays: [30, 7],
  dueDayHours: [9],
  overdueDailyPhaseDays: 0,
  overdueEveryDays: 7,
);

const _low = ReminderPolicy(
  priority: 'low',
  beforeDueDays: [],
  dueDayHours: [9],
  overdueDailyPhaseDays: 0,
  overdueEveryDays: 0, // never pushes again; dashboard only
);

const reminderPolicies = {
  'critical': _critical,
  'medium': _medium,
  'low': _low,
};

ReminderPolicy policyFor(String priority) =>
    reminderPolicies[priority] ?? _medium;

/// Default notification hour for before-due touchpoints.
const defaultNotifyHour = 9;

/// Cap on future notifications scheduled per reminder (OS limits pending
/// notifications; Android allows ~500 app-wide).
const maxScheduledPerReminder = 12;

/// Computes the future notification times for a reminder given its policy.
/// Pure function — the table-driven tests live on this.
List<DateTime> notificationTimesFor({
  required DateTime dueAt,
  required String priority,
  required DateTime now,
}) {
  final policy = policyFor(priority);
  final dueDay = DateTime(dueAt.year, dueAt.month, dueAt.day);
  final times = <DateTime>[];

  for (final days in policy.beforeDueDays) {
    times.add(dueDay
        .subtract(Duration(days: days))
        .add(const Duration(hours: defaultNotifyHour)));
  }
  for (final hour in policy.dueDayHours) {
    times.add(dueDay.add(Duration(hours: hour)));
  }
  // Overdue: daily phase, then a bounded weekly tail.
  for (var d = 1; d <= policy.overdueDailyPhaseDays; d++) {
    times.add(dueDay
        .add(Duration(days: d, hours: defaultNotifyHour)));
  }
  if (policy.overdueEveryDays > 0) {
    final tailStart = policy.overdueDailyPhaseDays;
    for (var i = 1; i <= 8; i++) {
      times.add(dueDay.add(Duration(
          days: tailStart + i * policy.overdueEveryDays,
          hours: defaultNotifyHour)));
    }
  }

  final clamped = times.map(_clampToWakingHours).toSet().toList();
  final future = clamped.where((t) => t.isAfter(now)).toList()..sort();
  return future.take(maxScheduledPerReminder).toList();
}

/// Quiet hours: nothing fires 21:00–08:00. Late-evening times pull back to
/// 20:00 same day; small-hours times move to 09:00 that morning.
const quietStartHour = 21;
const quietEndHour = 8;

DateTime _clampToWakingHours(DateTime t) {
  if (t.hour >= quietStartHour) {
    return DateTime(t.year, t.month, t.day, 20);
  }
  if (t.hour < quietEndHour) {
    return DateTime(t.year, t.month, t.day, defaultNotifyHour);
  }
  return t;
}
