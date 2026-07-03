import 'package:flutter_test/flutter_test.dart';
import 'package:homevault/features/reminders/recurrence.dart';

void main() {
  test('monthly clamps month-end: Jan 31 → Feb 28', () {
    expect(nextOccurrence('FREQ=MONTHLY', DateTime(2026, 1, 31)),
        DateTime(2026, 2, 28));
  });

  test('monthly across leap year: Jan 31 2028 → Feb 29 2028', () {
    expect(nextOccurrence('FREQ=MONTHLY', DateTime(2028, 1, 31)),
        DateTime(2028, 2, 29));
  });

  test('monthly year rollover: Dec 15 → Jan 15', () {
    expect(nextOccurrence('FREQ=MONTHLY', DateTime(2026, 12, 15)),
        DateTime(2027, 1, 15));
  });

  test('quarterly via INTERVAL=3', () {
    expect(nextOccurrence('FREQ=MONTHLY;INTERVAL=3', DateTime(2026, 1, 10)),
        DateTime(2026, 4, 10));
  });

  test('yearly (insurance, property tax)', () {
    expect(nextOccurrence('FREQ=YEARLY', DateTime(2026, 3, 31)),
        DateTime(2027, 3, 31));
  });

  test('every 30 days (wifi recharge)', () {
    expect(nextOccurrence('FREQ=DAILY;INTERVAL=30', DateTime(2026, 7, 1)),
        DateTime(2026, 7, 31));
  });

  test('weekly preserves time of day', () {
    expect(nextOccurrence('FREQ=WEEKLY', DateTime(2026, 7, 1, 9, 30)),
        DateTime(2026, 7, 8, 9, 30));
  });

  test('null, empty, and junk rules yield null', () {
    expect(nextOccurrence(null, DateTime(2026, 1, 1)), isNull);
    expect(nextOccurrence('', DateTime(2026, 1, 1)), isNull);
    expect(nextOccurrence('FREQ=FORTNIGHTLY', DateTime(2026, 1, 1)), isNull);
    expect(nextOccurrence('garbage', DateTime(2026, 1, 1)), isNull);
  });
}
