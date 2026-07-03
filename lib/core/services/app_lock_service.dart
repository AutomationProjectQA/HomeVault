import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// Biometric/PIN gate. Wraps local_auth so the rest of the app (and tests,
/// and the web preview where biometrics don't exist) sees a simple interface.
abstract interface class AppLockService {
  Future<bool> isSupported();
  Future<bool> authenticate(String reason);
}

class LocalAuthAppLockService implements AppLockService {
  final _auth = LocalAuthentication();

  @override
  Future<bool> isSupported() async {
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false; // web / unsupported platform
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(localizedReason: reason);
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}

final appLockServiceProvider = Provider<AppLockService>((ref) {
  return LocalAuthAppLockService();
});

/// Session unlock state: starts locked; the lock screen flips it after a
/// successful biometric/PIN check. Only consulted when app lock is enabled.
class SessionUnlocked extends Notifier<bool> {
  @override
  bool build() => false;

  void unlock() => state = true;
}

final sessionUnlockedProvider =
    NotifierProvider<SessionUnlocked, bool>(SessionUnlocked.new);
