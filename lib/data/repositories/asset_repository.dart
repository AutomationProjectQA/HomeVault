import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/auth_service.dart';
import '../local/database.dart';

class AssetDraft {
  const AssetDraft({
    required this.name,
    this.category = 'other',
    this.brand,
    this.model,
    this.serialNumber,
    this.vendor,
    this.purchaseDate,
    this.purchasePrice,
    this.warrantyEndDate,
    this.notes,
  });

  final String name;
  final String category;
  final String? brand;
  final String? model;
  final String? serialNumber;
  final String? vendor;
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final DateTime? warrantyEndDate;
  final String? notes;
}

class AssetRepository {
  AssetRepository(this._db, this._auth);

  final AppDatabase _db;
  final AuthService _auth;

  Future<int> countActiveAssets() async {
    final count = _db.assets.id.count();
    final query = _db.selectOnly(_db.assets)
      ..addColumns([count])
      ..where(_db.assets.deletedAt.isNull() &
          _db.assets.status.equals('active'));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Stream<List<Asset>> watchActiveAssets() {
    final query = _db.select(_db.assets)
      ..where((t) => t.deletedAt.isNull() & t.status.equals('active'))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    return query.watch();
  }

  Stream<Asset?> watchAsset(String id) {
    return (_db.select(_db.assets)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }

  /// Asset timeline, newest first.
  Stream<List<Event>> watchEvents(String assetId) {
    final query = _db.select(_db.events)
      ..where((t) => t.assetId.equals(assetId) & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.occurredAt)]);
    return query.watch();
  }

  /// Creates the asset plus its derived records in one shot:
  /// a purchase event on the timeline, and — when a warranty end date is
  /// known — a critical reminder row. (Sprint 3's engine turns reminder rows
  /// into scheduled notification chains; the data contract starts now.)
  Future<Asset> addAsset(AssetDraft draft, {required String homeId}) async {
    final user = await _auth.currentUser();
    final now = DateTime.now();
    final assetId = const Uuid().v4();

    String? clean(String? s) {
      final t = s?.trim();
      return (t == null || t.isEmpty) ? null : t;
    }

    await _db.upsertWithOutbox(
      _db.assets,
      AssetsCompanion.insert(
        id: assetId,
        homeId: homeId,
        createdBy: user.id,
        createdAt: now,
        updatedAt: now,
        name: draft.name.trim(),
        category: Value(draft.category),
        brand: Value.absentIfNull(clean(draft.brand)),
        model: Value.absentIfNull(clean(draft.model)),
        serialNumber: Value.absentIfNull(clean(draft.serialNumber)),
        vendor: Value.absentIfNull(clean(draft.vendor)),
        purchaseDate: Value.absentIfNull(draft.purchaseDate),
        purchasePrice: Value.absentIfNull(draft.purchasePrice),
        warrantyEndDate: Value.absentIfNull(draft.warrantyEndDate),
        notes: Value.absentIfNull(clean(draft.notes)),
      ),
      entityId: assetId,
    );

    final eventId = const Uuid().v4();
    await _db.upsertWithOutbox(
      _db.events,
      EventsCompanion.insert(
        id: eventId,
        homeId: homeId,
        createdBy: user.id,
        createdAt: now,
        updatedAt: now,
        assetId: Value(assetId),
        type: 'purchase',
        title: 'Purchased',
        occurredAt: draft.purchaseDate ?? now,
        cost: Value.absentIfNull(draft.purchasePrice),
      ),
      entityId: eventId,
    );

    final warrantyEnd = draft.warrantyEndDate;
    if (warrantyEnd != null && warrantyEnd.isAfter(now)) {
      final reminderId = const Uuid().v4();
      await _db.upsertWithOutbox(
        _db.reminders,
        RemindersCompanion.insert(
          id: reminderId,
          homeId: homeId,
          createdBy: user.id,
          createdAt: now,
          updatedAt: now,
          sourceType: 'asset',
          sourceId: Value(assetId),
          title: 'Warranty expires: ${draft.name.trim()}',
          priority: 'critical',
          dueAt: warrantyEnd,
        ),
        entityId: reminderId,
      );
    }

    return (_db.select(_db.assets)..where((t) => t.id.equals(assetId)))
        .getSingle();
  }

  /// Soft delete; cancels the asset's pending reminders so ghosts of removed
  /// appliances never fire notifications.
  Future<void> deleteAsset(String id) async {
    final now = DateTime.now();
    final asset = await (_db.select(_db.assets)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (asset == null) return;

    await _db.upsertWithOutbox(
      _db.assets,
      asset.copyWith(deletedAt: Value(now), updatedAt: now),
      entityId: id,
    );

    final reminders = await (_db.select(_db.reminders)
          ..where((t) =>
              t.sourceType.equals('asset') &
              t.sourceId.equals(id) &
              t.state.isNotIn(['completed', 'cancelled'])))
        .get();
    for (final reminder in reminders) {
      await _db.upsertWithOutbox(
        _db.reminders,
        reminder.copyWith(state: 'cancelled', updatedAt: now),
        entityId: reminder.id,
      );
    }
  }
}

final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  return AssetRepository(
    ref.watch(databaseProvider),
    ref.watch(authServiceProvider),
  );
});

final activeAssetsProvider = StreamProvider<List<Asset>>((ref) {
  return ref.watch(assetRepositoryProvider).watchActiveAssets();
});

final assetProvider = StreamProvider.family<Asset?, String>((ref, id) {
  return ref.watch(assetRepositoryProvider).watchAsset(id);
});

final assetEventsProvider = StreamProvider.family<List<Event>, String>((ref, id) {
  return ref.watch(assetRepositoryProvider).watchEvents(id);
});
