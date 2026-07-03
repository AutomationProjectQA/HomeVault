import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/auth_service.dart';
import '../local/database.dart';

class HomeRepository {
  HomeRepository(this._db, this._auth);

  final AppDatabase _db;
  final AuthService _auth;

  /// The single active home (multi-home lands Phase 3).
  Stream<Home?> watchCurrentHome() {
    final query = _db.select(_db.homes)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
      ..limit(1);
    return query.watchSingleOrNull();
  }

  Future<Home> createHome({required String name, String? address}) async {
    final user = await _auth.currentUser();
    final now = DateTime.now();
    final homeId = const Uuid().v4();
    final trimmedAddress = address?.trim();

    await _db.upsertWithOutbox(
      _db.homes,
      HomesCompanion.insert(
        id: homeId,
        name: name.trim(),
        address: (trimmedAddress == null || trimmedAddress.isEmpty)
            ? const Value.absent()
            : Value(trimmedAddress),
        ownerId: user.id,
        createdAt: now,
        updatedAt: now,
      ),
      entityId: homeId,
    );
    final memberId = const Uuid().v4();
    await _db.upsertWithOutbox(
      _db.members,
      MembersCompanion.insert(
        id: memberId,
        homeId: homeId,
        userId: user.id,
        displayName: user.displayName ?? 'Owner',
        role: const Value('owner'),
        joinedAt: now,
      ),
      entityId: memberId,
    );

    return (_db.select(_db.homes)..where((t) => t.id.equals(homeId)))
        .getSingle();
  }
}

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(
    ref.watch(databaseProvider),
    ref.watch(authServiceProvider),
  );
});

final currentHomeProvider = StreamProvider<Home?>((ref) {
  return ref.watch(homeRepositoryProvider).watchCurrentHome();
});
