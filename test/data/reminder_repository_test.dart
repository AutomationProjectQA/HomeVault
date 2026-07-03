import 'package:flutter_test/flutter_test.dart';
import 'package:homevault/core/services/analytics_service.dart';
import 'package:homevault/core/services/notifications/notification_scheduler.dart';
import 'package:homevault/data/local/database.dart';
import 'package:homevault/data/repositories/reminder_repository.dart';

import '../helpers.dart';

class RecordingScheduler implements NotificationScheduler {
  final scheduled = <String, List<DateTime>>{};
  final cancelled = <String>[];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> scheduleChain({
    required String reminderId,
    required String title,
    required String body,
    required List<DateTime> times,
  }) async {
    scheduled[reminderId] = times;
  }

  @override
  Future<void> cancelChain(String reminderId) async {
    cancelled.add(reminderId);
    scheduled.remove(reminderId);
  }
}

void main() {
  late AppDatabase db;
  late RecordingScheduler scheduler;
  late ReminderRepository repo;

  setUp(() {
    db = newTestDatabase();
    scheduler = RecordingScheduler();
    repo = ReminderRepository(
        db, const FakeAuthService(), scheduler, NoopAnalyticsService());
  });
  tearDown(() => db.close());

  Future<Reminder> createBillReminder({String? rrule}) => repo.create(
        homeId: 'home-1',
        sourceType: 'bill',
        sourceId: 'bill-1',
        title: 'Pay electricity bill',
        priority: 'critical',
        dueAt: DateTime.now().add(const Duration(days: 10)),
        recurrenceRule: rrule,
      );

  test('create schedules the notification chain', () async {
    final reminder = await createBillReminder();
    expect(scheduler.scheduled[reminder.id], isNotEmpty);
    expect(reminder.state, 'scheduled');
  });

  test('complete stops notifications and records the action', () async {
    final reminder = await createBillReminder();
    final next = await repo.complete(reminder.id);

    expect(next, isNull); // non-recurring
    final stored = (await db.select(db.reminders).get()).single;
    expect(stored.state, 'completed');
    expect(stored.completedAt, isNotNull);
    expect(scheduler.cancelled, contains(reminder.id));

    final log = (await db.select(db.notificationLogs).get()).single;
    expect(log.action, 'done');
  });

  test('completing a recurring reminder spawns the next occurrence',
      () async {
    final reminder = await createBillReminder(rrule: 'FREQ=MONTHLY');
    final next = await repo.complete(reminder.id);

    expect(next, isNotNull);
    expect(next!.state, 'scheduled');
    expect(next.dueAt.month != reminder.dueAt.month || next.dueAt.year != reminder.dueAt.year, isTrue);
    expect(next.recurrenceRule, 'FREQ=MONTHLY');
    expect(scheduler.scheduled.containsKey(next.id), isTrue);

    final open = await repo.watchToday().first;
    expect(open, isEmpty); // next occurrence is a month out
  });

  test('snooze hides from today and schedules a single nudge', () async {
    final reminder = await repo.create(
      homeId: 'home-1',
      sourceType: 'manual',
      title: 'Water the plants',
      priority: 'low',
      dueAt: DateTime.now(),
    );
    expect((await repo.watchToday().first).single.id, reminder.id);

    final until = DateTime.now().add(const Duration(days: 1));
    await repo.snooze(reminder.id, until);

    expect(await repo.watchToday().first, isEmpty);
    expect(scheduler.scheduled[reminder.id], [until]);
    final stored = (await db.select(db.reminders).get()).single;
    expect(stored.state, 'snoozed');
  });

  test('sweepOverdue flips past-due reminders', () async {
    await repo.create(
      homeId: 'home-1',
      sourceType: 'bill',
      title: 'Overdue bill',
      priority: 'critical',
      dueAt: DateTime.now().subtract(const Duration(days: 2)),
    );
    final changed = await repo.sweepOverdue();
    expect(changed, 1);
    final stored = (await db.select(db.reminders).get()).single;
    expect(stored.state, 'overdue');
    // Overdue tasks stay on today's list until actioned.
    expect(await repo.watchToday().first, hasLength(1));
  });

  test('cancelForSource cancels reminders and their notifications', () async {
    final reminder = await createBillReminder();
    await repo.cancelForSource('bill', 'bill-1');

    final stored = (await db.select(db.reminders).get()).single;
    expect(stored.state, 'cancelled');
    expect(scheduler.cancelled, contains(reminder.id));
    expect(await repo.watchToday().first, isEmpty);
  });

  test('rescheduleAll re-arms every open chain', () async {
    final a = await createBillReminder();
    scheduler.scheduled.clear(); // simulate reboot wiping alarms
    await repo.rescheduleAll();
    expect(scheduler.scheduled.containsKey(a.id), isTrue);
  });
}
