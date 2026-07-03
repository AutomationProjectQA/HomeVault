import 'package:flutter_test/flutter_test.dart';
import 'package:homevault/data/local/database.dart';
import 'package:homevault/data/repositories/document_repository.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late DocumentRepository repo;

  setUp(() {
    db = newTestDatabase();
    repo = DocumentRepository(db, const FakeAuthService());
  });
  tearDown(() => db.close());

  test('attach links a document to its source and queues sync', () async {
    final doc = await repo.attach(
      homeId: 'home-1',
      sourceType: 'asset',
      sourceId: 'asset-1',
      title: 'Invoice',
      category: 'invoice',
      localPath: '/tmp/invoice.jpg',
      mimeType: 'image/jpeg',
    );

    expect(doc.sourceType, 'asset');
    expect(doc.sourceId, 'asset-1');
    expect(doc.localPath, '/tmp/invoice.jpg');
    expect(doc.remotePath, isNull); // uploaded once sync adapter lands

    final outbox = await db.pendingOutbox();
    expect(outbox.single.entityTable, 'documents');

    final watched = await repo.watchFor('asset', 'asset-1').first;
    expect(watched.single.title, 'Invoice');
    expect(await repo.watchFor('asset', 'other').first, isEmpty);
  });
}
