import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'remote_adapter.dart';

/// Firestore layout (docs/03-architecture.md):
///   homes/{homeId}                      — home doc
///   homes/{homeId}/{table}/{entityId}   — all other synced tables
/// Security rules require membership in homes/{homeId}/members.
class FirestoreRemoteAdapter implements RemoteAdapter {
  FirestoreRemoteAdapter(this._firestore);

  final FirebaseFirestore _firestore;

  static const _syncedTables = [
    'members', 'assets', 'bills', 'events', 'documents', 'reminders',
  ];

  @override
  Future<void> push({
    required String table,
    required String entityId,
    required Map<String, Object?> data,
  }) async {
    final homeId = data['homeId'] as String? ?? data['home_id'] as String?;
    final doc = table == 'homes'
        ? _firestore.collection('homes').doc(entityId)
        : _firestore
            .collection('homes')
            .doc(homeId)
            .collection(table)
            .doc(entityId);
    await doc.set(data, SetOptions(merge: true));
  }

  @override
  Stream<RemoteChange> watchHome(String homeId) {
    final controller = StreamController<RemoteChange>.broadcast();
    final subs = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];
    for (final table in _syncedTables) {
      subs.add(_firestore
          .collection('homes')
          .doc(homeId)
          .collection(table)
          .snapshots()
          .listen((snap) {
        for (final change in snap.docChanges) {
          final data = change.doc.data();
          if (data == null) continue;
          controller.add(RemoteChange(
            table: table,
            entityId: change.doc.id,
            data: data,
          ));
        }
      }));
    }
    controller.onCancel = () {
      for (final s in subs) {
        s.cancel();
      }
    };
    return controller.stream;
  }
}
