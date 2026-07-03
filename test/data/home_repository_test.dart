import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homevault/core/services/auth_service.dart';
import 'package:homevault/data/local/database.dart';
import 'package:homevault/data/repositories/home_repository.dart';

class FakeAuthService implements AuthService {
  @override
  Future<AppUser> currentUser() async =>
      const AppUser(id: 'user-1', displayName: 'Meet');
}

void main() {
  late AppDatabase db;
  late HomeRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = HomeRepository(db, FakeAuthService());
  });
  tearDown(() => db.close());

  test('createHome persists home, owner membership, and outbox entries',
      () async {
    final home = await repo.createHome(
        name: '  Ahmedabad Flat  ', address: '  ');

    expect(home.name, 'Ahmedabad Flat'); // trimmed
    expect(home.address, isNull); // blank address stored as null
    expect(home.ownerId, 'user-1');

    final member = (await db.select(db.members).get()).single;
    expect(member.homeId, home.id);
    expect(member.role, 'owner');
    expect(member.displayName, 'Meet');

    // Both rows queued for sync, home first.
    final outbox = await db.pendingOutbox();
    expect(outbox.map((e) => e.entityTable).toList(), ['homes', 'members']);
  });

  test('watchCurrentHome emits null before creation, home after', () async {
    expect(await repo.watchCurrentHome().first, isNull);

    await repo.createHome(name: 'My Home');

    final current = await repo.watchCurrentHome().first;
    expect(current?.name, 'My Home');
  });
}
