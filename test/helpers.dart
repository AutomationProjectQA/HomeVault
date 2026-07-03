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

/// Pumps until [finder] matches, or fails after [maxPumps] frames.
/// Prefer this over pumpAndSettle: screens with indeterminate spinners or
/// long-lived animations never "settle", but they do reach target states.
Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  Duration step = const Duration(milliseconds: 100),
  int maxPumps = 100,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(step);
  }
  final visible = tester.allWidgets
      .whereType<Text>()
      .map((t) => t.data)
      .whereType<String>()
      .take(40)
      .toList();
  fail('pumpUntil: $finder still absent after $maxPumps pumps.\n'
      'Visible texts: $visible');
}

/// Pumps until [finder] matches nothing (e.g. a route finishes its exit
/// transition), or fails after [maxPumps] frames.
Future<void> pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  Duration step = const Duration(milliseconds: 100),
  int maxPumps = 100,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    if (finder.evaluate().isEmpty) return;
    await tester.pump(step);
  }
  fail('pumpUntilGone: $finder still present after $maxPumps pumps');
}

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
