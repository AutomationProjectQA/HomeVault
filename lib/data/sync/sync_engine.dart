import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' show FirebaseFirestore;
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/firebase_bootstrap.dart';
import '../local/database.dart';
import 'firestore_remote_adapter.dart';
import 'remote_adapter.dart';

/// Drains the outbox to the remote with exponential backoff.
///
/// Write path:  repository → Drift + outbox row (one transaction) → [SyncEngine]
/// Read path:   remote listener → applyRemoteChange → Drift → reactive UI
class SyncEngine {
  SyncEngine(this._db, this._remote);

  final AppDatabase _db;
  final RemoteAdapter _remote;

  Timer? _timer;
  bool _draining = false;
  int _backoffSeconds = 2;
  static const _maxBackoffSeconds = 300;

  void start() {
    _timer ??= Timer.periodic(const Duration(seconds: 5), (_) => drain());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Pushes pending outbox entries oldest-first. Stops at the first failure
  /// and backs off, preserving per-entity ordering guarantees.
  Future<void> drain() async {
    if (_draining) return;
    _draining = true;
    try {
      final pending = await _db.pendingOutbox();
      for (final entry in pending) {
        final data = await _snapshot(entry.entityTable, entry.entityId);
        if (data != null) {
          await _remote.push(
            table: entry.entityTable,
            entityId: entry.entityId,
            data: data,
          );
        }
        await _db.clearOutboxEntry(entry.seq);
        _backoffSeconds = 2;
      }
    } catch (_) {
      // Offline or remote error: retry later with backoff. Outbox persists
      // across app restarts, so nothing is lost.
      _timer?.cancel();
      _timer = Timer(Duration(seconds: _backoffSeconds), () {
        _timer = null;
        start();
        drain();
      });
      _backoffSeconds = (_backoffSeconds * 2).clamp(2, _maxBackoffSeconds);
    } finally {
      _draining = false;
    }
  }

  /// Applies a remote change if it is newer than the local row
  /// (last-write-wins on `updatedAt`).
  Future<void> applyRemoteChange(RemoteChange change) async {
    final table = _tableByName(change.table);
    if (table == null) return;

    final local = await (_db.select(table)
          ..where((t) => (t as dynamic).id.equals(change.entityId) as Expression<bool>))
        .getSingleOrNull();

    final remoteUpdated = change.data['updatedAt'];
    if (local != null && remoteUpdated is DateTime) {
      final localUpdated = (local as dynamic).updatedAt;
      if (localUpdated is DateTime && !remoteUpdated.isAfter(localUpdated)) {
        return; // local copy is same or newer
      }
    }

    await _db.into(table).insertOnConflictUpdate(
          RawValuesInsertable(
            change.data.map((k, v) => MapEntry(k, Variable(v))),
          ),
        );
  }

  Future<Map<String, Object?>?> _snapshot(String tableName, String id) async {
    final table = _tableByName(tableName);
    if (table == null) return null;
    final row = await (_db.select(table)
          ..where((t) => (t as dynamic).id.equals(id) as Expression<bool>))
        .getSingleOrNull();
    return row is DataClass ? row.toJson() : null;
  }

  TableInfo<Table, Object?>? _tableByName(String name) {
    for (final table in _db.allTables) {
      if (table.actualTableName == name) return table;
    }
    return null;
  }
}

final remoteAdapterProvider = Provider<RemoteAdapter>((ref) {
  // Lights up when the Firebase key files are added (firebase_bootstrap.dart).
  if (ref.watch(firebaseReadyProvider)) {
    return FirestoreRemoteAdapter(FirebaseFirestore.instance);
  }
  return NoopRemoteAdapter();
});

final syncEngineProvider = Provider<SyncEngine>((ref) {
  final engine = SyncEngine(
    ref.watch(databaseProvider),
    ref.watch(remoteAdapterProvider),
  );
  engine.start();
  ref.onDispose(engine.stop);
  return engine;
});
