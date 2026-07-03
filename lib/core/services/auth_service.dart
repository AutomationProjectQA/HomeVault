import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Identity boundary. [LocalDevAuthService] gives every install a stable
/// anonymous user id so the whole app works before Firebase exists; the
/// FirebaseAuth implementation (story 1.1) replaces it behind this interface
/// and existing local data is claimed by the signed-in account on first sync.
abstract interface class AuthService {
  Future<AppUser> currentUser();
}

class AppUser {
  const AppUser({required this.id, this.displayName});

  final String id;
  final String? displayName;
}

class LocalDevAuthService implements AuthService {
  static const _userIdKey = 'local_user_id';

  AppUser? _cached;

  @override
  Future<AppUser> currentUser() async {
    if (_cached != null) return _cached!;
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString(_userIdKey);
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(_userIdKey, id);
    }
    return _cached = AppUser(id: id);
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return LocalDevAuthService();
});
