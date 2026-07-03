import 'package:flutter_test/flutter_test.dart';
import 'package:homevault/core/services/analytics_service.dart';
import 'package:homevault/core/services/notifications/notification_scheduler.dart';
import 'package:homevault/data/local/database.dart';
import 'package:homevault/data/repositories/asset_repository.dart';
import 'package:homevault/data/repositories/reminder_repository.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late AssetRepository repo;

  setUp(() {
    db = newTestDatabase();
    final reminders = ReminderRepository(db, const FakeAuthService(),
        NoopNotificationScheduler(), NoopAnalyticsService());
    repo = AssetRepository(db, const FakeAuthService(), reminders);
  });
  tearDown(() => db.close());

  test('addAsset creates asset + purchase event + warranty reminder',
      () async {
    // Whole-second precision: SQLite stores DateTime as unix seconds.
    final warrantyEnd =
        DateTime(DateTime.now().year + 2, 1, 15);
    final asset = await repo.addAsset(
      AssetDraft(
        name: '  Samsung TV  ',
        category: 'electronics',
        brand: 'Samsung',
        purchasePrice: 45000,
        warrantyEndDate: warrantyEnd,
      ),
      homeId: 'home-1',
    );

    expect(asset.name, 'Samsung TV'); // trimmed
    expect(asset.warrantyEndDate, warrantyEnd);

    final event = (await db.select(db.events).get()).single;
    expect(event.assetId, asset.id);
    expect(event.type, 'purchase');
    expect(event.cost, 45000);

    final reminder = (await db.select(db.reminders).get()).single;
    expect(reminder.sourceType, 'asset');
    expect(reminder.sourceId, asset.id);
    expect(reminder.priority, 'critical');
    expect(reminder.dueAt, warrantyEnd);
    expect(reminder.state, 'scheduled');
  });

  test('addAsset without warranty creates no reminder', () async {
    await repo.addAsset(const AssetDraft(name: 'Sofa', category: 'furniture'),
        homeId: 'home-1');

    expect(await db.select(db.reminders).get(), isEmpty);
    expect((await db.select(db.events).get()).single.type, 'purchase');
  });

  test('expired warranty date does not create a reminder', () async {
    await repo.addAsset(
      AssetDraft(
        name: 'Old Fridge',
        warrantyEndDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
      homeId: 'home-1',
    );

    expect(await db.select(db.reminders).get(), isEmpty);
  });

  test('deleteAsset soft-deletes and cancels pending reminders', () async {
    final asset = await repo.addAsset(
      AssetDraft(
        name: 'AC',
        warrantyEndDate: DateTime.now().add(const Duration(days: 100)),
      ),
      homeId: 'home-1',
    );

    await repo.deleteAsset(asset.id);

    expect(await repo.watchActiveAssets().first, isEmpty);

    final stored = (await db.select(db.assets).get()).single;
    expect(stored.deletedAt, isNotNull); // soft delete, history preserved

    final reminder = (await db.select(db.reminders).get()).single;
    expect(reminder.state, 'cancelled');
  });

  test('updateAsset replaces only the warranty reminder, keeps service ones',
      () async {
    final asset = await repo.addAsset(
      AssetDraft(
        name: 'AC',
        warrantyEndDate: DateTime.now().add(const Duration(days: 100)),
      ),
      homeId: 'home-1',
    );
    await repo.logService(
      homeId: 'home-1',
      assetId: asset.id,
      assetName: 'AC',
      title: 'Serviced',
      serviceDate: DateTime.now(),
      nextDue: DateTime.now().add(const Duration(days: 365)),
    );

    final newWarranty = DateTime(DateTime.now().year + 3, 1, 15);
    final updated = await repo.updateAsset(
        asset.id,
        AssetDraft(
            name: 'AC Bedroom',
            brand: 'Daikin',
            warrantyEndDate: newWarranty));

    expect(updated.name, 'AC Bedroom');
    expect(updated.brand, 'Daikin');
    expect(updated.warrantyEndDate, newWarranty);

    final reminders = await db.select(db.reminders).get();
    final open = reminders.where((r) => r.state == 'scheduled').toList();
    expect(open, hasLength(2)); // new warranty + untouched service reminder
    expect(open.where((r) => r.title.startsWith('Warranty')).single.dueAt,
        newWarranty);
    expect(open.any((r) => r.title.startsWith('Service due')), isTrue);
    expect(reminders.where((r) => r.state == 'cancelled'), hasLength(1));
  });

  test('watchActiveAssets emits newest first and hides deleted', () async {
    final a = await repo.addAsset(const AssetDraft(name: 'A'), homeId: 'h');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await repo.addAsset(const AssetDraft(name: 'B'), homeId: 'h');
    await repo.deleteAsset(a.id);

    final assets = await repo.watchActiveAssets().first;
    expect(assets.map((x) => x.name).toList(), ['B']);
  });
}
