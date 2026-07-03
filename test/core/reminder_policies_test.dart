import 'package:flutter_test/flutter_test.dart';
import 'package:homevault/features/reminders/reminder_policies.dart';

void main() {
  final now = DateTime(2026, 7, 1, 8); // 8am, 1 Jul 2026

  group('critical chain', () {
    test('full chain for a due date 10 days out', () {
      final times = notificationTimesFor(
        dueAt: DateTime(2026, 7, 11),
        priority: 'critical',
        now: now,
      );
      expect(
        times.take(5),
        [
          DateTime(2026, 7, 4, 9), // 7 days before
          DateTime(2026, 7, 8, 9), // 3 days before
          DateTime(2026, 7, 10, 9), // 1 day before
          DateTime(2026, 7, 11, 9), // due day morning
          DateTime(2026, 7, 11, 19), // due day evening
        ],
      );
      // Overdue tail follows: daily for 7 days.
      expect(times[5], DateTime(2026, 7, 12, 9));
      expect(times.length, maxScheduledPerReminder);
    });

    test('past touchpoints are dropped, future kept', () {
      final times = notificationTimesFor(
        dueAt: DateTime(2026, 7, 2), // due tomorrow
        priority: 'critical',
        now: now,
      );
      // 7d/3d-before are in the past; 1d-before (today 9am) is future.
      expect(times.first, DateTime(2026, 7, 1, 9));
      expect(times[1], DateTime(2026, 7, 2, 9));
      expect(times[2], DateTime(2026, 7, 2, 19));
    });

    test('overdue reminder still schedules its tail', () {
      final times = notificationTimesFor(
        dueAt: DateTime(2026, 6, 25), // 6 days overdue
        priority: 'critical',
        now: now,
      );
      expect(times, isNotEmpty);
      expect(times.first, DateTime(2026, 7, 1, 9)); // today's daily nudge
      expect(times.every((t) => t.isAfter(now)), isTrue);
    });
  });

  group('medium chain', () {
    test('30d/7d/due-day, then weekly', () {
      final times = notificationTimesFor(
        dueAt: DateTime(2026, 8, 15),
        priority: 'medium',
        now: now,
      );
      expect(times.take(3), [
        DateTime(2026, 7, 16, 9),
        DateTime(2026, 8, 8, 9),
        DateTime(2026, 8, 15, 9),
      ]);
      expect(times[3], DateTime(2026, 8, 22, 9)); // weekly overdue
    });
  });

  group('low chain', () {
    test('exactly one touchpoint, never nags again', () {
      final times = notificationTimesFor(
        dueAt: DateTime(2026, 7, 20),
        priority: 'low',
        now: now,
      );
      expect(times, [DateTime(2026, 7, 20, 9)]);
    });

    test('overdue low reminder schedules nothing', () {
      final times = notificationTimesFor(
        dueAt: DateTime(2026, 6, 1),
        priority: 'low',
        now: now,
      );
      expect(times, isEmpty);
    });
  });
}
