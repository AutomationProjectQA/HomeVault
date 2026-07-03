import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homevault/core/services/auth_service.dart';
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
        ],
        child: const HomeVaultApp(),
      );

  testWidgets('fresh install: onboarding → create home → dashboard',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // Fresh install lands on Welcome.
    expect(find.text('HomeVault'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);

    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    // Create home with a custom name.
    expect(find.text('Name your home'), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextField, 'My Home').first, 'Ahmedabad Flat');
    await tester.tap(find.text('Create my home'));
    await tester.pumpAndSettle();

    // Redirected to dashboard showing the real home.
    expect(find.text('Ahmedabad Flat'), findsOneWidget);
    expect(find.text("Today's tasks"), findsOneWidget);
    expect(find.text('Assets'), findsOneWidget);

    // Quick-add sheet opens from the empty-state CTA.
    await tester.tap(find.text('Add your first appliance'));
    await tester.pumpAndSettle();
    expect(find.text('Add to your home'), findsOneWidget);

    await disposeAppAndDb(tester, db);
  });

  testWidgets('existing home skips onboarding', (tester) async {
    await seedHome(db, 'Rajkot House');

    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Rajkot House'), findsOneWidget);
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
