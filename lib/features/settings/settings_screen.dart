import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_env.dart';
import '../../core/router/app_router.dart';
import '../../core/services/app_lock_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/theme/tokens.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _toggleAppLock(
      BuildContext context, WidgetRef ref, bool enable) async {
    final lock = ref.read(appLockServiceProvider);
    if (enable) {
      if (!await lock.isSupported()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'No screen lock is set up on this device. Set one in device settings first.')));
        }
        return;
      }
      // Verify the user can actually unlock before locking them out.
      if (!await lock.authenticate('Confirm to enable app lock')) return;
    }
    await ref.read(appLockEnabledProvider.notifier).set(enable);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLockOn = ref.watch(appLockEnabledProvider).value ?? false;
    final analyticsOn = ref.watch(analyticsEnabledProvider).value ?? true;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.lock_outline),
            title: const Text('App lock'),
            subtitle: const Text('Require fingerprint / face / PIN to open'),
            value: appLockOn,
            onChanged: (v) => _toggleAppLock(context, ref, v),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.insights_outlined),
            title: const Text('Anonymous usage analytics'),
            subtitle: const Text('Helps us improve. Never your data.'),
            value: analyticsOn,
            onChanged: (v) =>
                ref.read(analyticsEnabledProvider.notifier).set(v),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy'),
            subtitle: const Text('How your data is handled'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.privacy),
          ),
          const ListTile(
            leading: Icon(Icons.notifications_outlined),
            title: Text('Notifications'),
            subtitle: Text('Reminder times, quiet hours — coming in Sprint 3'),
            enabled: false,
          ),
          const ListTile(
            leading: Icon(Icons.download_outlined),
            title: Text('Export my data'),
            subtitle: Text('Coming with backup — Phase 3'),
            enabled: false,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: Text('${AppConfig.appName} · Sprint 2 build'),
          ),
        ],
      ),
    );
  }
}
