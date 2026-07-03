import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:homevault/core/services/analytics_service.dart';
import 'package:homevault/core/services/export_service.dart';
import 'package:homevault/core/services/notifications/notification_scheduler.dart';
import 'package:homevault/data/repositories/asset_repository.dart';
import 'package:homevault/data/repositories/home_repository.dart';
import 'package:homevault/data/repositories/reminder_repository.dart';

import '../helpers.dart';

void main() {
  test('export contains every table with real data', () async {
    final db = newTestDatabase();
    addTearDown(db.close);

    final homes = HomeRepository(db, const FakeAuthService());
    final home = await homes.createHome(name: 'Ahmedabad Flat');
    final reminders = ReminderRepository(db, const FakeAuthService(),
        NoopNotificationScheduler(), NoopAnalyticsService());
    final assets = AssetRepository(db, const FakeAuthService(), reminders);
    await assets.addAsset(
      AssetDraft(
        name: 'Samsung TV',
        warrantyEndDate: DateTime.now().add(const Duration(days: 400)),
      ),
      homeId: home.id,
    );

    final json = await ExportService(db).buildExportJson();
    final data = jsonDecode(json) as Map<String, dynamic>;

    expect(data['formatVersion'], 1);
    expect((data['homes'] as List).single['name'], 'Ahmedabad Flat');
    expect((data['members'] as List).single['role'], 'owner');
    expect((data['assets'] as List).single['name'], 'Samsung TV');
    expect((data['events'] as List).single['type'], 'purchase');
    expect((data['reminders'] as List).single['priority'], 'critical');
    expect(data.containsKey('bills'), isTrue);
    expect(data.containsKey('documents'), isTrue);
  });
}
