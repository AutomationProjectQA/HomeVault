import 'package:flutter_test/flutter_test.dart';
import 'package:homevault/core/services/analytics_service.dart';
import 'package:homevault/core/services/notifications/notification_scheduler.dart';
import 'package:homevault/data/local/database.dart';
import 'package:homevault/data/repositories/bill_repository.dart';
import 'package:homevault/data/repositories/reminder_repository.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late BillRepository repo;

  setUp(() {
    db = newTestDatabase();
    final reminders = ReminderRepository(db, const FakeAuthService(),
        NoopNotificationScheduler(), NoopAnalyticsService());
    repo = BillRepository(db, const FakeAuthService(), reminders);
  });
  tearDown(() => db.close());

  test('addBill creates the bill and its critical reminder', () async {
    final due = DateTime(2026, 8, 10);
    final bill = await repo.addBill(
      homeId: 'home-1',
      type: 'electricity',
      provider: 'Torrent Power',
      amount: 1450,
      dueDate: due,
      recurrenceRule: 'FREQ=MONTHLY',
    );

    expect(bill.status, 'upcoming');
    final reminder = (await db.select(db.reminders).get()).single;
    expect(reminder.sourceType, 'bill');
    expect(reminder.sourceId, bill.id);
    expect(reminder.priority, 'critical');
    expect(reminder.title, 'Pay Electricity bill (Torrent Power)');
    expect(reminder.dueAt, due);
  });

  test('markPaid completes reminder and spawns next month\'s bill + chain',
      () async {
    final bill = await repo.addBill(
      homeId: 'home-1',
      type: 'electricity',
      amount: 1450,
      dueDate: DateTime(2026, 7, 10),
      recurrenceRule: 'FREQ=MONTHLY',
    );

    final next = await repo.markPaid(bill.id);

    expect(next, isNotNull);
    expect(next!.dueDate, DateTime(2026, 8, 10));
    expect(next.recurrenceRule, 'FREQ=MONTHLY');
    expect(next.status, 'upcoming');

    final bills = await db.select(db.bills).get();
    expect(bills, hasLength(2));
    final paid = bills.firstWhere((b) => b.id == bill.id);
    expect(paid.status, 'paid');
    expect(paid.paidDate, isNotNull);

    // Old reminder completed, new one scheduled for the next bill.
    final reminders = await db.select(db.reminders).get();
    expect(reminders.where((r) => r.state == 'completed'), hasLength(1));
    final open = reminders.singleWhere((r) => r.state == 'scheduled');
    expect(open.sourceId, next.id);
    expect(open.dueAt, DateTime(2026, 8, 10));
  });

  test('markPaid on one-time bill spawns nothing', () async {
    final bill = await repo.addBill(
      homeId: 'home-1',
      type: 'gas',
      dueDate: DateTime(2026, 7, 10),
    );
    expect(await repo.markPaid(bill.id), isNull);
    expect(await db.select(db.bills).get(), hasLength(1));
  });

  test('typeDeltas computes vs-last-month percentages', () async {
    final now = DateTime(2026, 7, 15);
    await repo.addBill(
        homeId: 'h',
        type: 'electricity',
        amount: 1240,
        dueDate: DateTime(2026, 7, 10));
    await repo.addBill(
        homeId: 'h',
        type: 'electricity',
        amount: 1000,
        dueDate: DateTime(2026, 6, 10));
    await repo.addBill(
        homeId: 'h', type: 'water', amount: 300, dueDate: DateTime(2026, 7, 5));

    final deltas = await repo.typeDeltas(now: now);
    final electricity = deltas.singleWhere((d) => d.type == 'electricity');
    expect(electricity.percentChange, 24); // 1000 → 1240
    final water = deltas.singleWhere((d) => d.type == 'water');
    expect(water.percentChange, isNull); // nothing last month
  });

  test('watchBills lists open bills by due date, then paid history', () async {
    final a = await repo.addBill(
        homeId: 'h', type: 'water', dueDate: DateTime(2026, 7, 20));
    await repo.addBill(
        homeId: 'h', type: 'internet', dueDate: DateTime(2026, 7, 5));
    await repo.markPaid(a.id);

    final bills = await repo.watchBills().first;
    expect(bills.first.type, 'internet'); // open first
    expect(bills.last.status, 'paid');
  });
}
