import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homevault/core/services/auth_service.dart';
import 'package:homevault/core/services/notifications/notification_scheduler.dart';
import 'package:homevault/data/local/database.dart';
import 'package:homevault/main.dart';

import 'helpers.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = newTestDatabase());

  Widget app() => ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          authServiceProvider.overrideWithValue(const FakeAuthService()),
          notificationSchedulerProvider
              .overrideWithValue(NoopNotificationScheduler()),
        ],
        child: const HomeVaultApp(),
      );

  testWidgets('fresh install: onboarding → create home → dashboard',
      (tester) async {
    await tester.pumpWidget(app());

    // Fresh install lands on Welcome.
    await pumpUntil(tester, find.text('Get started'));
    expect(find.text('HomeVault'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await pumpUntil(tester, find.text('Name your home'));

    // Create home with a custom name.
    await tester.enterText(
        find.widgetWithText(TextField, 'My Home').first, 'Ahmedabad Flat');
    await tester.tap(find.text('Create my home'));

    // Redirected to dashboard showing the real home. (Wait on the dashboard
    // marker — the home name also matches the create-form's text field.)
    await pumpUntil(tester, find.text("Today's tasks"));
    expect(find.text('Ahmedabad Flat'), findsOneWidget);

    // Empty-state CTA goes straight to the add-asset flow.
    await tester.tap(find.text('Add your first appliance'));
    await pumpUntil(tester, find.text('Add asset'));

    await disposeAppAndDb(tester, db);
  });

  testWidgets('existing home skips onboarding', (tester) async {
    await seedHome(db, 'Rajkot House');

    await tester.pumpWidget(app());
    await pumpUntil(tester, find.text('Rajkot House'));

    expect(find.text('Get started'), findsNothing);

    await disposeAppAndDb(tester, db);
  });
}

Future<void> seedHome(AppDatabase db, String name) async {
  final now = DateTime(2026, 7, 3);
  await db.upsertWithOutbox(
    db.homes,
    HomesCompanion.insert(
      id: 'home-1',
      name: name,
      ownerId: 'test-user',
      createdAt: now,
      updatedAt: now,
    ),
    entityId: 'home-1',
  );
}
