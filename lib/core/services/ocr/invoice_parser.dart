/// Pure-Dart extraction of structured fields from OCR'd invoice text.
/// Kept free of platform dependencies so it is fully unit-testable — this is
/// where scan-to-add accuracy is won, iterated against the real-invoice
/// corpus (Sprint 2 risk plan).
class InvoiceScan {
  const InvoiceScan({
    this.vendor,
    this.purchaseDate,
    this.amount,
    required this.rawText,
  });

  final String? vendor;
  final DateTime? purchaseDate;
  final double? amount;
  final String rawText;

  bool get hasAnyField =>
      vendor != null || purchaseDate != null || amount != null;
}

const _knownVendors = [
  'Croma', 'Reliance Digital', 'Vijay Sales', 'Amazon', 'Flipkart',
  'Tata Cliq', 'Bajaj Electronics', 'Girias', 'Sathya', 'Poorvika',
  'Sangeetha', 'Big Bazaar', 'DMart', 'IKEA', 'Pepperfry', 'Urban Ladder',
];

final _amountPattern = RegExp(
    r'(?:₹|rs\.?|inr)\s*([0-9][0-9,]*(?:\.\d{1,2})?)',
    caseSensitive: false);
final _totalLinePattern =
    RegExp(r'(grand\s*total|net\s*(?:amount|payable)|total\s*(?:amount|payable)?|amount\s*paid)',
        caseSensitive: false);

final _numericDate = RegExp(r'\b(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})\b');
final _isoDate = RegExp(r'\b(\d{4})-(\d{2})-(\d{2})\b');
final _monthNameDate = RegExp(
    r'\b(\d{1,2})[\s\-]*(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*[\s\-,]*(\d{4})\b',
    caseSensitive: false);
const _months = {
  'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
  'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
};

InvoiceScan parseInvoiceText(String text, {DateTime? now}) {
  final today = now ?? DateTime.now();
  return InvoiceScan(
    vendor: _extractVendor(text),
    purchaseDate: _extractDate(text, today),
    amount: _extractAmount(text),
    rawText: text,
  );
}

String? _extractVendor(String text) {
  final lower = text.toLowerCase();
  for (final vendor in _knownVendors) {
    if (lower.contains(vendor.toLowerCase())) return vendor;
  }
  // Fall back to the first substantial line — invoices lead with the seller.
  for (final line in text.split('\n')) {
    final t = line.trim();
    if (t.length < 4) continue;
    final lowerLine = t.toLowerCase();
    if (lowerLine.contains('invoice') ||
        lowerLine.contains('receipt') ||
        lowerLine.contains('bill') ||
        lowerLine.contains('gst')) {
      continue;
    }
    if (RegExp(r'[a-zA-Z]{3,}').hasMatch(t)) return t;
  }
  return null;
}

double? _extractAmount(String text) {
  double? best;
  double? onTotalLine;
  for (final line in text.split('\n')) {
    for (final match in _amountPattern.allMatches(line)) {
      final value = double.tryParse(match.group(1)!.replaceAll(',', ''));
      if (value == null || value <= 0) continue;
      if (_totalLinePattern.hasMatch(line)) {
        onTotalLine =
            onTotalLine == null || value > onTotalLine ? value : onTotalLine;
      }
      best = best == null || value > best ? value : best;
    }
  }
  // A "Total"-labelled amount beats the largest number on the page.
  return onTotalLine ?? best;
}

DateTime? _extractDate(String text, DateTime today) {
  bool plausible(DateTime d) =>
      d.year >= 2000 && d.isBefore(today.add(const Duration(days: 1)));

  DateTime? tryBuild(int y, int m, int d) {
    if (m < 1 || m > 12 || d < 1 || d > 31) return null;
    final date = DateTime(y, m, d);
    return plausible(date) ? date : null;
  }

  for (final m in _isoDate.allMatches(text)) {
    final date = tryBuild(int.parse(m.group(1)!), int.parse(m.group(2)!),
        int.parse(m.group(3)!));
    if (date != null) return date;
  }
  for (final m in _monthNameDate.allMatches(text)) {
    final date = tryBuild(int.parse(m.group(3)!),
        _months[m.group(2)!.toLowerCase()]!, int.parse(m.group(1)!));
    if (date != null) return date;
  }
  for (final m in _numericDate.allMatches(text)) {
    var year = int.parse(m.group(3)!);
    if (year < 100) year += 2000;
    // Indian convention first (dd/mm), then mm/dd as fallback.
    final date = tryBuild(year, int.parse(m.group(2)!), int.parse(m.group(1)!)) ??
        tryBuild(year, int.parse(m.group(1)!), int.parse(m.group(2)!));
    if (date != null) return date;
  }
  return null;
}
