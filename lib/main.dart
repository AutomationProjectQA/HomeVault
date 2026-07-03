import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_env.dart';
import 'core/router/app_router.dart';
import 'core/services/app_lock_service.dart';
import 'core/services/firebase_bootstrap.dart';
import 'core/services/settings_service.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/reminder_repository.dart';
import 'data/sync/sync_engine.dart';
import 'features/lock/lock_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final firebaseReady = await tryInitFirebase();
  runApp(ProviderScope(
    overrides: [
      firebaseReadyProvider.overrideWithValue(firebaseReady),
    ],
    child: const HomeVaultApp(),
  ));
}

class HomeVaultApp extends ConsumerWidget {
  const HomeVaultApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(reminderEngineBootstrapProvider);
    if (ref.watch(firebaseReadyProvider)) {
      ref.watch(syncEngineProvider); // start outbox drain once keys exist
    }
    final lockEnabled = ref.watch(appLockEnabledProvider).value ?? false;
    final unlocked = ref.watch(sessionUnlockedProvider);

    if (lockEnabled && !unlocked) {
      return MaterialApp(
        title: AppConfig.appName,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const LockScreen(),
        debugShowCheckedModeBanner: false,
      );
    }

    return MaterialApp.router(
      title: AppConfig.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: ref.watch(routerProvider),
      debugShowCheckedModeBanner: false,
    );
  }
}
