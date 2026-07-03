import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homevault/core/services/analytics_service.dart';
import 'package:homevault/core/services/auth_service.dart';
import 'package:homevault/core/services/notifications/notification_scheduler.dart';
import 'package:homevault/data/local/database.dart';
import 'package:homevault/data/repositories/reminder_repository.dart';
import 'package:homevault/features/reminders/today_tasks.dart';
import 'package:homevault/main.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late ReminderRepository reminders;

  setUp(() async {
    db = newTestDatabase();
    reminders = ReminderRepository(db, const FakeAuthService(),
        NoopNotificationScheduler(), NoopAnalyticsService());
    final now = DateTime(2026, 7, 3);
    await db.upsertWithOutbox(
      db.homes,
      HomesCompanion.insert(
        id: 'home-1',
        name: 'Test Home',
        ownerId: 'test-user',
        createdAt: now,
        updatedAt: now,
      ),
      entityId: 'home-1',
    );
  });

  Widget app() => ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          authServiceProvider.overrideWithValue(const FakeAuthService()),
          notificationSchedulerProvider
              .overrideWithValue(NoopNotificationScheduler()),
        ],
        child: const HomeVaultApp(),
      );

  testWidgets('task card: complete removes it, snooze hides until chosen day',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await reminders.create(
      homeId: 'home-1',
      sourceType: 'bill',
      title: 'Pay electricity bill',
      priority: 'critical',
      dueAt: DateTime.now(),
    );
    await reminders.create(
      homeId: 'home-1',
      sourceType: 'asset',
      title: 'Warranty expires: AC',
      priority: 'critical',
      dueAt: DateTime.now().subtract(const Duration(days: 2)),
    );

    await tester.pumpWidget(app());
    await pumpUntil(tester, find.text('Pay electricity bill'));
    expect(find.text('Due today'), findsOneWidget);
    expect(find.text('2 days overdue'), findsOneWidget);
    // Live pending-tasks stat reflects both.
    expect(find.text('2'), findsWidgets);

    // Complete the bill (target its card — the list is ordered by due date).
    await tester.tap(find.descendant(
      of: find.widgetWithText(TaskCard, 'Pay electricity bill'),
      matching: find.byIcon(Icons.radio_button_unchecked),
    ));
    await pumpUntilGone(tester, find.text('Due today'));
    final billRow = (await db.select(db.reminders).get())
        .firstWhere((r) => r.title == 'Pay electricity bill');
    expect(billRow.state, 'completed');

    // Snooze the warranty task until tomorrow.
    await tester.tap(find.byIcon(Icons.snooze_outlined));
    await pumpUntil(tester, find.text('Remind me again'));
    await tester.pump(const Duration(milliseconds: 400)); // sheet slide-in
    await tester.tap(find.text('Tomorrow'));
    await pumpUntilGone(tester, find.text('Warranty expires: AC'));

    // Empty state returns once nothing is actionable today.
    await pumpUntil(tester, find.text('Nothing due today'));

    await disposeAppAndDb(tester, db);
  });
}
