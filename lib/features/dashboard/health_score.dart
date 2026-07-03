import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/database.dart';

/// Home Health Score v1 (docs/04-reminder-engine.md): simple, explainable,
/// and every lost point maps to an action the user can take right now.
class HealthScore {
  const HealthScore(this.score, this.pendingCount);

  final int score;
  final int pendingCount;

  String get band => switch (score) {
        >= 90 => 'Excellent',
        >= 70 => 'Good',
        >= 50 => 'Needs attention',
        _ => 'At risk',
      };
}

int computeHealthScore({
  required int criticalOverdue,
  required int mediumOverdue,
  required int expiringWarranties30d,
}) {
  final penalty = (criticalOverdue * 15).clamp(0, 45) +
      (mediumOverdue * 5).clamp(0, 25) +
      (expiringWarranties30d * 5).clamp(0, 15);
  return (100 - penalty).clamp(0, 100);
}

final healthScoreProvider = StreamProvider<HealthScore>((ref) {
  final db = ref.watch(databaseProvider);
  final query = db.select(db.reminders)
    ..where((t) =>
        t.deletedAt.isNull() &
        t.state.isIn(['scheduled', 'active', 'snoozed', 'overdue']));
  return query.watch().map((open) {
    final now = DateTime.now();
    final overdue = open.where((r) => r.dueAt.isBefore(now));
    final expiringSoon = open.where((r) =>
        r.title.startsWith('Warranty expires:') &&
        !r.dueAt.isBefore(now) &&
        r.dueAt.difference(now).inDays <= 30);
    final score = computeHealthScore(
      criticalOverdue: overdue.where((r) => r.priority == 'critical').length,
      mediumOverdue: overdue.where((r) => r.priority != 'critical').length,
      expiringWarranties30d: expiringSoon.length,
    );
    return HealthScore(score, overdue.length);
  });
});
