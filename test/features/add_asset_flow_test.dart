import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homevault/core/services/auth_service.dart';
import 'package:homevault/core/services/notifications/notification_scheduler.dart';
import 'package:homevault/data/local/database.dart';
import 'package:homevault/main.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = newTestDatabase();
    // Seed a home so the app opens straight to the dashboard.
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

  // Note: the app shell keeps all tab branches alive in an IndexedStack, so
  // finders can match widgets on hidden tabs. Assertions here use texts that
  // exist on exactly one screen, and taps target the topmost route.
  testWidgets('add asset from dashboard CTA updates list and stats',
      (tester) async {
    // Tall phone-shaped surface so the whole form stays mounted.
    await tester.binding.setSurfaceSize(const Size(420, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(app());
    await pumpUntil(tester, find.text('Add your first appliance'));

    // Dashboard CTA → add asset form.
    await tester.tap(find.text('Add your first appliance'));
    await pumpUntil(tester, find.text('Save asset'));

    // Name + category, then save.
    await tester.enterText(
        find.widgetWithText(TextField, 'Name'), 'Samsung TV');
    await tester.tap(find.text('Kitchen'));
    await tester.pump();
    await tester.tap(find.text('Save asset'));

    // Save lands on the assets list. Wait for the add screen to fully unmount
    // first — until then find.text('Samsung TV') matches the form's own text
    // field, and the offstage list's stream subscription is paused.
    await pumpUntilGone(tester, find.text('Save asset'));
    await pumpUntil(tester, find.text('Samsung TV'));

    // Detail screen shows the purchase timeline event.
    await tester.tap(find.text('Samsung TV'));
    await pumpUntil(tester, find.text('Timeline'));
    await pumpUntil(tester, find.text('Purchased'));

    // Dashboard stat reflects the live asset count.
    await tester.pageBack();
    await tester.pump();
    await tester.tap(find.descendant(
        of: find.byType(NavigationBar), matching: find.text('Home')));
    await pumpUntil(tester, find.text('1'));

    await disposeAppAndDb(tester, db);
  });
}
