import 'package:flutter_test/flutter_test.dart';
import 'package:homevault/core/services/ocr/invoice_parser.dart';

void main() {
  final now = DateTime(2026, 7, 3);

  test('Croma-style invoice: vendor, total, dd/mm/yyyy date', () {
    const text = '''
CROMA
A TATA Enterprise
Tax Invoice
Date: 15/01/2026
Samsung 55" Crystal 4K UHD TV
Qty 1
Amount ₹42,999.00
GST 18% ₹7,739.82
Grand Total ₹50,738.82
''';
    final scan = parseInvoiceText(text, now: now);
    expect(scan.vendor, 'Croma');
    expect(scan.amount, 50738.82);
    expect(scan.purchaseDate, DateTime(2026, 1, 15));
  });

  test('Amazon-style: Rs. amounts, month-name date', () {
    const text = '''
Amazon.in
Order Confirmation
Ordered on 3 Feb 2026
LG 260L Refrigerator
Item total Rs. 28,490
Amount Paid Rs. 28,490
''';
    final scan = parseInvoiceText(text, now: now);
    expect(scan.vendor, 'Amazon');
    expect(scan.amount, 28490);
    expect(scan.purchaseDate, DateTime(2026, 2, 3));
  });

  test('unknown shop falls back to first substantial line', () {
    const text = '''
Tax Invoice
Sharma Electronics & Home Appliances
12-03-2025
INR 15,000
''';
    final scan = parseInvoiceText(text, now: now);
    expect(scan.vendor, 'Sharma Electronics & Home Appliances');
    expect(scan.purchaseDate, DateTime(2025, 3, 12));
    expect(scan.amount, 15000);
  });

  test('Total-labelled amount beats larger stray numbers', () {
    const text = '''
Vijay Sales
Serial ₹99999999 ref
Item price ₹18,000
Total Amount ₹18,499
''';
    final scan = parseInvoiceText(text, now: now);
    expect(scan.amount, 18499);
  });

  test('future dates are rejected, ISO dates parsed', () {
    const text = '''
IKEA
Delivery scheduled 15/09/2027
Invoice date 2026-06-20
Net Payable ₹6,499
''';
    final scan = parseInvoiceText(text, now: now);
    expect(scan.purchaseDate, DateTime(2026, 6, 20));
  });

  test('garbage text yields no fields, keeps raw text', () {
    final scan = parseInvoiceText('zzz\n@@@\n12', now: now);
    expect(scan.hasAnyField, isFalse);
    expect(scan.rawText, contains('zzz'));
  });
}
