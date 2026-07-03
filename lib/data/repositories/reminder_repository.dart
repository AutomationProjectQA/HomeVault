import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/services/analytics_service.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/notifications/notification_scheduler.dart';
import '../../features/reminders/recurrence.dart';
import '../../features/reminders/reminder_policies.dart';
import '../local/database.dart';

/// The Reminder Engine's mutations and queries. State machine:
/// scheduled → (due passes) overdue → completed / cancelled, with snoozed as
/// a user-controlled pause. Chains are derived from policies at scheduling
/// time; completing a recurring reminder spawns the next occurrence.
class ReminderRepository {
  ReminderRepository(this._db, this._auth, this._scheduler, this._analytics);

  final AppDatabase _db;
  final AuthService _auth;
  final NotificationScheduler _scheduler;
  final AnalyticsService _analytics;

  static const _openStates = ['scheduled', 'active', 'snoozed', 'overdue'];

  // ---- Queries ----

  /// Today's actionable tasks: due today, overdue, or snoozed-until-now.
  Stream<List<Reminder>> watchToday() {
    final endOfToday = _endOfToday();
    final query = _db.select(_db.reminders)
      ..where((t) =>
          t.deletedAt.isNull() &
          t.state.isIn(_openStates) &
          t.dueAt.isSmallerOrEqualValue(endOfToday))
      ..orderBy([(t) => OrderingTerm.asc(t.dueAt)]);
    return query.watch().map((rows) => rows
        .where((r) =>
            r.snoozedUntil == null || !r.snoozedUntil!.isAfter(DateTime.now()))
        .toList());
  }

  /// The next 7 days, excluding today's list.
  Stream<List<Reminder>> watchUpcoming() {
    final endOfToday = _endOfToday();
    final horizon = endOfToday.add(const Duration(days: 7));
    final query = _db.select(_db.reminders)
      ..where((t) =>
          t.deletedAt.isNull() &
          t.state.isIn(_openStates) &
          t.dueAt.isBiggerThanValue(endOfToday) &
          t.dueAt.isSmallerOrEqualValue(horizon))
      ..orderBy([(t) => OrderingTerm.asc(t.dueAt)]);
    return query.watch();
  }

  // ---- Mutations ----

  Future<Reminder> create({
    required String homeId,
    required String sourceType,
    String? sourceId,
    required String title,
    required String priority,
    required DateTime dueAt,
    String? recurrenceRule,
  }) async {
    final user = await _auth.currentUser();
    final now = DateTime.now();
    final id = const Uuid().v4();
    await _db.upsertWithOutbox(
      _db.reminders,
      RemindersCompanion.insert(
        id: id,
        homeId: homeId,
        createdBy: user.id,
        createdAt: now,
        updatedAt: now,
        sourceType: sourceType,
        sourceId: Value.absentIfNull(sourceId),
        title: title,
        priority: priority,
        dueAt: dueAt,
        recurrenceRule: Value.absentIfNull(recurrenceRule),
      ),
      entityId: id,
    );
    final reminder = await _byId(id);
    await _schedule(reminder);
    return reminder;
  }

  /// Done: stop all notifications; recurring reminders spawn their next
  /// occurrence so the user never re-creates them.
  Future<Reminder?> complete(String id) async {
    final reminder = await _byId(id);
    final now = DateTime.now();
    await _db.upsertWithOutbox(
      _db.reminders,
      reminder.copyWith(
        state: 'completed',
        completedAt: Value(now),
        snoozedUntil: const Value(null),
        updatedAt: now,
      ),
      entityId: id,
    );
    await _scheduler.cancelChain(id);
    await _logAction(id, 'done');
    _analytics.logEvent(AnalyticsEvents.reminderActioned,
        {'action': 'done', 'priority': reminder.priority});

    final nextDue = nextOccurrence(reminder.recurrenceRule, reminder.dueAt);
    if (nextDue == null) return null;
    return create(
      homeId: reminder.homeId,
      sourceType: reminder.sourceType,
      sourceId: reminder.sourceId,
      title: reminder.title,
      priority: reminder.priority,
      dueAt: nextDue,
      recurrenceRule: reminder.recurrenceRule,
    );
  }

  /// Snooze, never lose: pauses task-list presence and reschedules the next
  /// nudge for the chosen time.
  Future<void> snooze(String id, DateTime until) async {
    final reminder = await _byId(id);
    await _db.upsertWithOutbox(
      _db.reminders,
      reminder.copyWith(
        state: 'snoozed',
        snoozedUntil: Value(until),
        updatedAt: DateTime.now(),
      ),
      entityId: id,
    );
    await _scheduler.scheduleChain(
      reminderId: id,
      title: reminder.title,
      body: _bodyFor(reminder),
      times: [until],
    );
    await _logAction(id, 'snoozed');
    _analytics.logEvent(AnalyticsEvents.reminderActioned,
        {'action': 'snoozed', 'priority': reminder.priority});
  }

  /// Marks past-due open reminders overdue. Run at app start and via the
  /// daily sweep; returns how many changed.
  Future<int> sweepOverdue() async {
    final now = DateTime.now();
    final rows = await (_db.select(_db.reminders)
          ..where((t) =>
              t.deletedAt.isNull() &
              t.state.isIn(['scheduled', 'active', 'snoozed']) &
              t.dueAt.isSmallerThanValue(now)))
        .get();
    for (final r in rows) {
      if (r.snoozedUntil != null && r.snoozedUntil!.isAfter(now)) continue;
      await _db.upsertWithOutbox(
        _db.reminders,
        r.copyWith(state: 'overdue', updatedAt: now),
        entityId: r.id,
      );
    }
    return rows.length;
  }

  /// Completes all open reminders for a source (e.g. a bill that was paid).
  Future<void> completeForSource(String sourceType, String sourceId) async {
    final rows = await (_db.select(_db.reminders)
          ..where((t) =>
              t.sourceType.equals(sourceType) &
              t.sourceId.equals(sourceId) &
              t.state.isIn(_openStates)))
        .get();
    for (final r in rows) {
      await complete(r.id);
    }
  }

  /// Cancels all open reminders for a source record (e.g. a deleted asset)
  /// including their scheduled notifications.
  Future<void> cancelForSource(String sourceType, String sourceId,
      {String? titlePrefix}) async {
    final now = DateTime.now();
    final rows = await (_db.select(_db.reminders)
          ..where((t) =>
              t.sourceType.equals(sourceType) &
              t.sourceId.equals(sourceId) &
              t.state.isIn(_openStates)))
        .get()
        .then((rows) => titlePrefix == null
            ? rows
            : rows.where((r) => r.title.startsWith(titlePrefix)).toList());
    for (final r in rows) {
      await _db.upsertWithOutbox(
        _db.reminders,
        r.copyWith(state: 'cancelled', updatedAt: now),
        entityId: r.id,
      );
      await _scheduler.cancelChain(r.id);
    }
  }

  /// Reschedules every open reminder's chain — called on app start, which
  /// covers reboots, app updates, and OEM-killed alarms.
  Future<void> rescheduleAll() async {
    final rows = await (_db.select(_db.reminders)
          ..where((t) => t.deletedAt.isNull() & t.state.isIn(_openStates)))
        .get();
    for (final r in rows) {
      await _schedule(r);
    }
  }

  // ---- Internals ----

  Future<Reminder> _byId(String id) =>
      (_db.select(_db.reminders)..where((t) => t.id.equals(id))).getSingle();

  Future<void> _schedule(Reminder reminder) async {
    final times = notificationTimesFor(
      dueAt: reminder.dueAt,
      priority: reminder.priority,
      now: DateTime.now(),
    );
    await _scheduler.scheduleChain(
      reminderId: reminder.id,
      title: reminder.title,
      body: _bodyFor(reminder),
      times: times,
    );
  }

  String _bodyFor(Reminder r) => switch (r.priority) {
        'critical' => 'Due soon — tap to see today\'s home tasks',
        _ => 'Open HomeVault to review',
      };

  Future<void> _logAction(String reminderId, String action) {
    return _db.into(_db.notificationLogs).insert(
          NotificationLogsCompanion.insert(
            reminderId: reminderId,
            firedAt: DateTime.now(),
            action: Value(action),
            actionedAt: Value(DateTime.now()),
          ),
        );
  }
}

DateTime _endOfToday() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day, 23, 59, 59);
}

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepository(
    ref.watch(databaseProvider),
    ref.watch(authServiceProvider),
    ref.watch(notificationSchedulerProvider),
    ref.watch(analyticsProvider),
  );
});

/// One-shot engine bootstrap at app start: marks overdue, re-schedules all
/// chains (covers reboot, app update, and OEM-killed alarms).
final reminderEngineBootstrapProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(reminderRepositoryProvider);
  await repo.sweepOverdue();
  await repo.rescheduleAll();
});

final todayTasksProvider = StreamProvider<List<Reminder>>((ref) {
  return ref.watch(reminderRepositoryProvider).watchToday();
});

final upcomingTasksProvider = StreamProvider<List<Reminder>>((ref) {
  return ref.watch(reminderRepositoryProvider).watchUpcoming();
});
