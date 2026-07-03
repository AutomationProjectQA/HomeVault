import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database.dart';

/// Live dashboard stats, straight from reactive Drift queries — the UI
/// updates the instant Sprint 2's asset flows start inserting rows.
class DashboardStats {
  const DashboardStats({
    required this.assetCount,
    required this.billsThisMonth,
    required this.pendingTasks,
  });

  final int assetCount;
  final double billsThisMonth;
  final int pendingTasks;
}

final assetCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  final count = db.assets.id.count();
  final query = db.selectOnly(db.assets)
    ..addColumns([count])
    ..where(db.assets.deletedAt.isNull() &
        db.assets.status.equals('active'));
  return query.map((row) => row.read(count) ?? 0).watchSingle();
});

final billsThisMonthProvider = StreamProvider<double>((ref) {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month);
  final nextMonth = DateTime(now.year, now.month + 1);
  final sum = db.bills.amount.sum();
  final query = db.selectOnly(db.bills)
    ..addColumns([sum])
    ..where(db.bills.deletedAt.isNull() &
        db.bills.dueDate.isBetweenValues(monthStart, nextMonth));
  return query.map((row) => row.read(sum) ?? 0).watchSingle();
});

final pendingTaskCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  final count = db.reminders.id.count();
  final query = db.selectOnly(db.reminders)
    ..addColumns([count])
    ..where(db.reminders.deletedAt.isNull() &
        db.reminders.state.isIn(['scheduled', 'active', 'snoozed', 'overdue']));
  return query.map((row) => row.read(count) ?? 0).watchSingle();
});

final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  return DashboardStats(
    assetCount: ref.watch(assetCountProvider).value ?? 0,
    billsThisMonth: ref.watch(billsThisMonthProvider).value ?? 0,
    pendingTasks: ref.watch(pendingTaskCountProvider).value ?? 0,
  );
});
