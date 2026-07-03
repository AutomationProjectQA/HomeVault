import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/auth_service.dart';
import '../../features/bills/bill_types.dart';
import '../../features/reminders/recurrence.dart';
import '../local/database.dart';
import 'reminder_repository.dart';

/// Per-type spend vs last month — "Electricity up 24%". Pure arithmetic.
class TypeDelta {
  const TypeDelta(this.type, this.thisMonth, this.lastMonth);

  final String type;
  final double thisMonth;
  final double lastMonth;

  int? get percentChange => lastMonth <= 0
      ? null
      : (((thisMonth - lastMonth) / lastMonth) * 100).round();
}

class BillRepository {
  BillRepository(this._db, this._auth, this._reminders);

  final AppDatabase _db;
  final AuthService _auth;
  final ReminderRepository _reminders;

  Stream<List<Bill>> watchBills() {
    final query = _db.select(_db.bills)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.dueDate)]);
    return query.watch().map((rows) {
      // Open bills first (by due date), then paid history (newest first).
      final open = rows.where((b) => b.status != 'paid').toList();
      final paid = rows.where((b) => b.status == 'paid').toList()
        ..sort((a, b) => b.dueDate.compareTo(a.dueDate));
      return [...open, ...paid];
    });
  }

  /// Creates the bill and its critical reminder chain.
  Future<Bill> addBill({
    required String homeId,
    required String type,
    String? provider,
    double? amount,
    required DateTime dueDate,
    String? recurrenceRule,
    String? notes,
  }) async {
    final user = await _auth.currentUser();
    final now = DateTime.now();
    final id = const Uuid().v4();

    await _db.upsertWithOutbox(
      _db.bills,
      BillsCompanion.insert(
        id: id,
        homeId: homeId,
        createdBy: user.id,
        createdAt: now,
        updatedAt: now,
        type: type,
        provider: Value.absentIfNull(_clean(provider)),
        amount: Value.absentIfNull(amount),
        dueDate: dueDate,
        recurrenceRule: Value.absentIfNull(recurrenceRule),
        notes: Value.absentIfNull(_clean(notes)),
      ),
      entityId: id,
    );

    final label = billTypeByKey(type).label;
    final providerSuffix =
        _clean(provider) == null ? '' : ' (${_clean(provider)})';
    await _reminders.create(
      homeId: homeId,
      sourceType: 'bill',
      sourceId: id,
      title: 'Pay $label bill$providerSuffix',
      priority: 'critical',
      dueAt: dueDate,
    );

    return (_db.select(_db.bills)..where((t) => t.id.equals(id))).getSingle();
  }

  /// Updates an open bill; its reminder chain is replaced to match.
  Future<Bill> updateBill({
    required String billId,
    required String type,
    String? provider,
    double? amount,
    required DateTime dueDate,
    String? recurrenceRule,
    String? notes,
  }) async {
    final existing = await (_db.select(_db.bills)
          ..where((t) => t.id.equals(billId)))
        .getSingle();
    final now = DateTime.now();

    await _db.upsertWithOutbox(
      _db.bills,
      existing.copyWith(
        type: type,
        provider: Value(_clean(provider)),
        amount: Value(amount),
        dueDate: dueDate,
        recurrenceRule: Value(recurrenceRule),
        notes: Value(_clean(notes)),
        updatedAt: now,
      ),
      entityId: billId,
    );

    await _reminders.cancelForSource('bill', billId);
    final label = billTypeByKey(type).label;
    final providerSuffix =
        _clean(provider) == null ? '' : ' (${_clean(provider)})';
    await _reminders.create(
      homeId: existing.homeId,
      sourceType: 'bill',
      sourceId: billId,
      title: 'Pay $label bill$providerSuffix',
      priority: 'critical',
      dueAt: dueDate,
    );

    return (_db.select(_db.bills)..where((t) => t.id.equals(billId)))
        .getSingle();
  }

  /// Soft delete; cancels the bill's reminder chain.
  Future<void> deleteBill(String billId) async {
    final bill = await (_db.select(_db.bills)
          ..where((t) => t.id.equals(billId)))
        .getSingleOrNull();
    if (bill == null) return;
    final now = DateTime.now();
    await _db.upsertWithOutbox(
      _db.bills,
      bill.copyWith(deletedAt: Value(now), updatedAt: now),
      entityId: billId,
    );
    await _reminders.cancelForSource('bill', billId);
  }

  /// Mark paid: completes the reminder chain and — for recurring bills —
  /// auto-creates the next occurrence with its own chain. The user never
  /// re-creates a recurring bill.
  Future<Bill?> markPaid(String billId) async {
    final bill = await (_db.select(_db.bills)
          ..where((t) => t.id.equals(billId)))
        .getSingle();
    final now = DateTime.now();

    await _db.upsertWithOutbox(
      _db.bills,
      bill.copyWith(
        status: 'paid',
        paidDate: Value(now),
        updatedAt: now,
      ),
      entityId: billId,
    );
    await _reminders.completeForSource('bill', billId);

    final nextDue = nextOccurrence(bill.recurrenceRule, bill.dueDate);
    if (nextDue == null) return null;
    return addBill(
      homeId: bill.homeId,
      type: bill.type,
      provider: bill.provider,
      amount: bill.amount,
      dueDate: nextDue,
      recurrenceRule: bill.recurrenceRule,
      notes: bill.notes,
    );
  }

  /// Spend by type, this month vs last (by due date), for the trends header.
  Future<List<TypeDelta>> typeDeltas({DateTime? now}) async {
    final today = now ?? DateTime.now();
    final thisStart = DateTime(today.year, today.month);
    final nextStart = DateTime(today.year, today.month + 1);
    final lastStart = DateTime(today.year, today.month - 1);

    Future<Map<String, double>> totals(DateTime from, DateTime to) async {
      final rows = await (_db.select(_db.bills)
            ..where((t) =>
                t.deletedAt.isNull() &
                t.dueDate.isBiggerOrEqualValue(from) &
                t.dueDate.isSmallerThanValue(to)))
          .get();
      final map = <String, double>{};
      for (final b in rows) {
        map[b.type] = (map[b.type] ?? 0) + (b.amount ?? 0);
      }
      return map;
    }

    final thisMonth = await totals(thisStart, nextStart);
    final lastMonth = await totals(lastStart, thisStart);
    final types = {...thisMonth.keys, ...lastMonth.keys};
    return [
      for (final t in types)
        TypeDelta(t, thisMonth[t] ?? 0, lastMonth[t] ?? 0),
    ]..sort((a, b) => b.thisMonth.compareTo(a.thisMonth));
  }
}

String? _clean(String? s) {
  final t = s?.trim();
  return (t == null || t.isEmpty) ? null : t;
}

final billRepositoryProvider = Provider<BillRepository>((ref) {
  return BillRepository(
    ref.watch(databaseProvider),
    ref.watch(authServiceProvider),
    ref.watch(reminderRepositoryProvider),
  );
});

final billsProvider = StreamProvider<List<Bill>>((ref) {
  return ref.watch(billRepositoryProvider).watchBills();
});
