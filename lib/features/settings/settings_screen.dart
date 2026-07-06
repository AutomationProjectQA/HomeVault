import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_env.dart';
import '../../core/router/app_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/app_lock_service.dart';
import '../../core/services/export_service.dart';
import '../../core/services/notifications/notification_scheduler.dart';
import '../../core/services/settings_service.dart';
import '../../data/repositories/reminder_repository.dart';
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
            leading: const Icon(Icons.family_restroom_outlined),
            title: const Text('Family'),
            subtitle: const Text('Who shares this home'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.family),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy'),
            subtitle: const Text('How your data is handled'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.privacy),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            subtitle: const Text('Allow reminders & exact alarms'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final granted = await ref
                  .read(notificationSchedulerProvider)
                  .requestPermissions();
              if (granted) {
                await ref.read(reminderRepositoryProvider).rescheduleAll();
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(granted
                        ? 'Notifications enabled — reminders re-armed.'
                        : 'Not enabled. Allow HomeVault notifications in system settings.')));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Export my data'),
            subtitle: const Text('Everything as JSON — yours to keep'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final json =
                  await ref.read(exportServiceProvider).buildExportJson();
              await SharePlus.instance.share(ShareParams(
                text: json,
                subject: 'HomeVault export',
              ));
            },
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
