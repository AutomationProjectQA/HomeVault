import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homevault/core/services/auth_service.dart';
import 'package:homevault/data/local/database.dart';

class FakeAuthService implements AuthService {
  const FakeAuthService();

  @override
  Future<AppUser> currentUser() async =>
      const AppUser(id: 'test-user', displayName: 'Meet');
}

AppDatabase newTestDatabase() =>
    AppDatabase.forTesting(NativeDatabase.memory());

/// Widget-test teardown for tests that touch the database.
///
/// Drift keeps stream-query eviction timers alive briefly after listeners
/// unsubscribe; closing the DB inside the fake-async test zone hangs on them.
/// So: dispose the tree, advance the clock past the eviction delay, then
/// close outside the fake zone.
Future<void> disposeAppAndDb(WidgetTester tester, AppDatabase db) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(minutes: 1));
  await tester.runAsync(db.close);
}
