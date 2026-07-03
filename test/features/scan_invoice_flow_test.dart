import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homevault/core/services/attachment_service.dart';
import 'package:homevault/core/services/auth_service.dart';
import 'package:homevault/core/services/ocr/ocr_service.dart';
import 'package:homevault/data/local/database.dart';
import 'package:homevault/main.dart';

import '../helpers.dart';

class FakePicker implements AttachmentPicker {
  @override
  Future<PickedAttachment?> pickImage({required bool fromCamera}) async =>
      const PickedAttachment(path: '/fake/invoice.jpg', mimeType: 'image/jpeg');
}

class FakeOcr implements OcrService {
  @override
  bool get isSupported => true;

  @override
  Future<String?> extractText(String imagePath) async => '''
CROMA
Tax Invoice
Date: 15/01/2026
Samsung 55" TV
Grand Total ₹50,738.82
''';
}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = newTestDatabase();
    final now = DateTime(2026, 7, 3);
    await db.upsertWithOutbox(
      db.homes,
      HomesCompanion.insert(
        id: 'home-1',
        name: 'Test Home',
        ownerId: 'test-user',
        createdAt: now,
        updatedAt: now,
      ),
      entityId: 'home-1',
    );
  });

  testWidgets('scan invoice pre-fills fields and attaches document',
      (tester) async {
    // Tall phone-shaped surface so the whole form stays mounted.
    await tester.binding.setSurfaceSize(const Size(420, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        authServiceProvider.overrideWithValue(const FakeAuthService()),
        attachmentPickerProvider.overrideWithValue(FakePicker()),
        ocrServiceProvider.overrideWithValue(FakeOcr()),
      ],
      child: const HomeVaultApp(),
    ));
    await pumpUntil(tester, find.text('Add your first appliance'));
    await tester.tap(find.text('Add your first appliance'));
    await pumpUntil(tester, find.text('Scan invoice'));

    // Scan → OCR prefills vendor, price, date; invoice chip appears.
    await tester.tap(find.text('Scan invoice'));
    await pumpUntil(tester, find.text('Invoice attached'));
    expect(find.widgetWithText(TextField, 'Croma'), findsOneWidget);
    expect(find.widgetWithText(TextField, '50739'), findsOneWidget);
    expect(find.text('15 Jan 2026'), findsOneWidget);

    // Name it and save.
    await tester.enterText(
        find.widgetWithText(TextField, 'Name'), 'Samsung TV');
    await tester.tap(find.text('Save asset'));
    await pumpUntilGone(tester, find.text('Save asset'));

    // Document row persisted, linked to the asset.
    final docs = await db.select(db.documents).get();
    expect(docs.single.title, 'Invoice');
    expect(docs.single.localPath, '/fake/invoice.jpg');
    final asset = (await db.select(db.assets).get()).single;
    expect(docs.single.sourceId, asset.id);
    expect(asset.vendor, 'Croma');
    expect(asset.purchasePrice, 50739);

    await disposeAppAndDb(tester, db);
  });
}
