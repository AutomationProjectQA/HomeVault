import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/tokens.dart';

/// Quick-add bottom sheet: Asset / Bill / Service.
/// Entries navigate to their flows as those modules land (Sprints 2–4).
class QuickAddSheet extends StatelessWidget {
  const QuickAddSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      builder: (_) => const QuickAddSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Add to your home',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            _AddOption(
              icon: Icons.tv_outlined,
              title: 'Appliance / Asset',
              subtitle: 'Track warranty, services, and papers',
              onTap: () {
                Navigator.pop(context);
                context.push(Routes.addAsset);
              },
            ),
            _AddOption(
              icon: Icons.receipt_long_outlined,
              title: 'Bill',
              subtitle: 'Electricity, gas, internet, society…',
              onTap: () {
                Navigator.pop(context);
                context.push(Routes.addBill);
              },
            ),
            _AddOption(
              icon: Icons.build_outlined,
              title: 'Service / Maintenance',
              subtitle: 'Log a service from the asset\'s page',
              onTap: () {
                Navigator.pop(context);
                context.go(Routes.assets);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content:
                        Text('Open an asset and tap "Log service".')));
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AddOption extends StatelessWidget {
  const _AddOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: scheme.primary.withValues(alpha: 0.1),
        child: Icon(icon, color: scheme.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
