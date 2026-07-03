import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/auth_service.dart';
import '../local/database.dart';

class DocumentRepository {
  DocumentRepository(this._db, this._auth);

  final AppDatabase _db;
  final AuthService _auth;

  /// Attachments linked to a record (asset invoice, bill receipt, …).
  /// `remotePath` stays null until the Firestore/Storage sync adapter lands;
  /// the outbox row is already queued so uploads start retroactively.
  Future<Document> attach({
    required String homeId,
    required String sourceType,
    required String sourceId,
    required String title,
    required String localPath,
    String? category,
    String? mimeType,
  }) async {
    final user = await _auth.currentUser();
    final now = DateTime.now();
    final id = const Uuid().v4();

    await _db.upsertWithOutbox(
      _db.documents,
      DocumentsCompanion.insert(
        id: id,
        homeId: homeId,
        createdBy: user.id,
        createdAt: now,
        updatedAt: now,
        title: title,
        category: Value.absentIfNull(category),
        sourceType: Value(sourceType),
        sourceId: Value(sourceId),
        localPath: Value(localPath),
        mimeType: Value.absentIfNull(mimeType),
      ),
      entityId: id,
    );
    return (_db.select(_db.documents)..where((t) => t.id.equals(id)))
        .getSingle();
  }

  Stream<List<Document>> watchFor(String sourceType, String sourceId) {
    final query = _db.select(_db.documents)
      ..where((t) =>
          t.sourceType.equals(sourceType) &
          t.sourceId.equals(sourceId) &
          t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch();
  }
}

final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  return DocumentRepository(
    ref.watch(databaseProvider),
    ref.watch(authServiceProvider),
  );
});

final assetDocumentsProvider =
    StreamProvider.family<List<Document>, String>((ref, assetId) {
  return ref.watch(documentRepositoryProvider).watchFor('asset', assetId);
});
