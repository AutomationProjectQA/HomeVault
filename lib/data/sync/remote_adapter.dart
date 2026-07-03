/// Boundary between local persistence and whichever backend syncs it.
///
/// Firestore is the planned implementation (after Firebase setup — Sprint 0
/// story 0.3). Keeping this interface thin is the documented exit path to
/// Supabase/Postgres if Firestore costs bite at scale (docs/03-architecture.md).
abstract interface class RemoteAdapter {
  /// Pushes one entity snapshot. Must be idempotent (retried on failure).
  Future<void> push({
    required String table,
    required String entityId,
    required Map<String, Object?> data,
  });

  /// Streams remote changes for a home, as raw row maps per table.
  Stream<RemoteChange> watchHome(String homeId);
}

class RemoteChange {
  const RemoteChange({
    required this.table,
    required this.entityId,
    required this.data,
  });

  final String table;
  final String entityId;
  final Map<String, Object?> data;
}

/// Used until Firebase is configured, and in tests: sync is a visible no-op,
/// so the whole app works fully offline from day one.
class NoopRemoteAdapter implements RemoteAdapter {
  @override
  Future<void> push({
    required String table,
    required String entityId,
    required Map<String, Object?> data,
  }) async {}

  @override
  Stream<RemoteChange> watchHome(String homeId) => const Stream.empty();
}
