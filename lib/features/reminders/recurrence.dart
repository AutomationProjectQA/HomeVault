/// Minimal RRULE support for household recurrence. Full RFC 5545 is
/// deliberately out of scope — bills and services need exactly this.
///
/// Supported: FREQ=DAILY|WEEKLY|MONTHLY|YEARLY with optional INTERVAL=n.
DateTime? nextOccurrence(String? rrule, DateTime from) {
  if (rrule == null || rrule.trim().isEmpty) return null;

  String? freq;
  var interval = 1;
  for (final part in rrule.toUpperCase().split(';')) {
    final kv = part.split('=');
    if (kv.length != 2) continue;
    switch (kv[0].trim()) {
      case 'FREQ':
        freq = kv[1].trim();
      case 'INTERVAL':
        interval = int.tryParse(kv[1].trim()) ?? 1;
    }
  }
  if (freq == null || interval < 1) return null;

  switch (freq) {
    case 'DAILY':
      return from.add(Duration(days: interval));
    case 'WEEKLY':
      return from.add(Duration(days: 7 * interval));
    case 'MONTHLY':
      return _addMonths(from, interval);
    case 'YEARLY':
      return _addMonths(from, 12 * interval);
    default:
      return null;
  }
}

/// Month arithmetic with end-of-month clamping: Jan 31 + 1mo → Feb 28/29.
DateTime _addMonths(DateTime from, int months) {
  final totalMonths = from.year * 12 + (from.month - 1) + months;
  final year = totalMonths ~/ 12;
  final month = totalMonths % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = from.day > lastDay ? lastDay : from.day;
  return DateTime(year, month, day, from.hour, from.minute);
}
