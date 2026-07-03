import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Homes,
  Members,
  Assets,
  Bills,
  Events,
  Documents,
  Reminders,
  OutboxEntries,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'homevault'));

  /// In-memory constructor for tests.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        // Future versions: use m.addColumn / m.createTable per version bump.
      );

  // ---- Outbox helpers (used by all repositories) ----

  /// Writes an entity change and its outbox entry in one transaction, so a
  /// crash can never produce a local change the sync engine doesn't know about.
  Future<void> upsertWithOutbox<T extends Table, R>(
    TableInfo<T, R> table,
    Insertable<R> entity, {
    required String entityId,
  }) {
    return transaction(() async {
      await into(table).insertOnConflictUpdate(entity);
      await into(outboxEntries).insert(OutboxEntriesCompanion.insert(
        entityTable: table.actualTableName,
        entityId: entityId,
        operation: 'upsert',
        queuedAt: DateTime.now(),
      ));
    });
  }

  Future<List<OutboxEntry>> pendingOutbox({int limit = 50}) {
    return (select(outboxEntries)
          ..orderBy([(t) => OrderingTerm.asc(t.seq)])
          ..limit(limit))
        .get();
  }

  Future<void> clearOutboxEntry(int seq) {
    return (delete(outboxEntries)..where((t) => t.seq.equals(seq))).go();
  }
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
