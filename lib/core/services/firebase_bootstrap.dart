import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Guarded Firebase init (same approach as NovaPlay): the app runs fully
/// offline-local until the platform key files exist, then this lights up.
///
/// To activate:
///  - Android: drop `android/app/google-services.json` from the Firebase
///    console (project: homevault-dev), or run `flutterfire configure`.
///  - iOS: `ios/Runner/GoogleService-Info.plist`.
/// No code changes needed — initializeApp reads the native config.
Future<bool> tryInitFirebase() async {
  if (kIsWeb) return false; // web needs generated options; mobile-first
  try {
    await Firebase.initializeApp();
    return true;
  } catch (_) {
    return false; // keys not present yet — LocalDevAuth + Noop sync stay on
  }
}

/// Set once at startup in main() via override; providers switch on it.
final firebaseReadyProvider = Provider<bool>((ref) => false);
