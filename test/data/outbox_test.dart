import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homevault/data/local/database.dart';
import 'package:homevault/data/sync/remote_adapter.dart';
import 'package:homevault/data/sync/sync_engine.dart';

AssetsCompanion _asset(String id, {String name = 'Samsung TV'}) {
  final now = DateTime(2026, 7, 3);
  return AssetsCompanion.insert(
    id: id,
    homeId: 'home-1',
    createdBy: 'user-1',
    createdAt: now,
    updatedAt: now,
    name: name,
    category: const Value('electronics'),
  );
}

class RecordingAdapter extends NoopRemoteAdapter {
  final pushed = <String>[];

  @override
  Future<void> push({
    required String table,
    required String entityId,
    required Map<String, Object?> data,
  }) async {
    pushed.add('$table/$entityId');
  }
}

class FailingAdapter extends NoopRemoteAdapter {
  @override
  Future<void> push({
    required String table,
    required String entityId,
    required Map<String, Object?> data,
  }) async {
    throw Exception('offline');
  }
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('upsertWithOutbox writes entity and outbox row atomically', () async {
    await db.upsertWithOutbox(db.assets, _asset('a1'), entityId: 'a1');

    final assets = await db.select(db.assets).get();
    final outbox = await db.pendingOutbox();

    expect(assets.single.name, 'Samsung TV');
    expect(outbox.single.entityId, 'a1');
    expect(outbox.single.entityTable, 'assets');
    expect(outbox.single.operation, 'upsert');
  });

  test('drain pushes pending entries to remote and clears outbox', () async {
    final remote = RecordingAdapter();
    final engine = SyncEngine(db, remote);

    await db.upsertWithOutbox(db.assets, _asset('a1'), entityId: 'a1');
    await db.upsertWithOutbox(db.assets, _asset('a2', name: 'LG Fridge'),
        entityId: 'a2');

    await engine.drain();

    expect(remote.pushed, ['assets/a1', 'assets/a2']);
    expect(await db.pendingOutbox(), isEmpty);
  });

  test('failed push keeps entry queued for retry (nothing lost offline)',
      () async {
    final engine = SyncEngine(db, FailingAdapter());

    await db.upsertWithOutbox(db.assets, _asset('a1'), entityId: 'a1');
    await engine.drain();

    expect((await db.pendingOutbox()).single.entityId, 'a1');
    engine.stop(); // cancel scheduled backoff retry
  });

  test('applyRemoteChange respects last-write-wins on updatedAt', () async {
    final engine = SyncEngine(db, NoopRemoteAdapter());
    await db.upsertWithOutbox(db.assets, _asset('a1'), entityId: 'a1');

    final localRow = (await db.select(db.assets).get()).single;

    // Older remote change must NOT overwrite the local row.
    await engine.applyRemoteChange(RemoteChange(
      table: 'assets',
      entityId: 'a1',
      data: {
        ...localRow.toJson(),
        'name': 'Stale name',
        'updatedAt': localRow.updatedAt.subtract(const Duration(days: 1)),
      },
    ));
    expect((await db.select(db.assets).get()).single.name, 'Samsung TV');
  });
}
