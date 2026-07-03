import 'package:flutter/material.dart';

import '../../core/config/app_env.dart';
import '../../core/theme/tokens.dart';

/// Settings v0 — placeholders; real preferences land Sprint 1 & 6.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const ListTile(
            leading: Icon(Icons.notifications_outlined),
            title: Text('Notifications'),
            subtitle: Text('Reminder times, quiet hours'),
            trailing: Icon(Icons.chevron_right),
          ),
          const ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('App lock'),
            subtitle: Text('Biometric / PIN'),
            trailing: Icon(Icons.chevron_right),
          ),
          const ListTile(
            leading: Icon(Icons.privacy_tip_outlined),
            title: Text('Privacy & data'),
            subtitle: Text('Export or delete your data'),
            trailing: Icon(Icons.chevron_right),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            subtitle: Text('${AppConfig.appName} · Sprint 0 build'),
          ),
        ],
      ),
    );
  }
}
