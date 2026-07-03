import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/firebase_bootstrap.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories/home_repository.dart';

/// Family module (Sprint 5). Member list works fully offline; the invite
/// flow needs the cloud (invite redemption + cross-device sync), so it
/// activates with the Firebase keys and explains itself until then.
class FamilyScreen extends ConsumerWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(currentHomeProvider).value;
    final members = home == null
        ? const []
        : ref.watch(membersProvider(home.id)).value ?? const [];
    final firebaseReady = ref.watch(firebaseReadyProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Family')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('${home?.name ?? 'Your home'} · ${members.length} '
              '${members.length == 1 ? 'member' : 'members'}',
              style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          for (final m in members)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: scheme.primary.withValues(alpha: 0.1),
                child: Text(m.displayName.isEmpty
                    ? '?'
                    : m.displayName[0].toUpperCase()),
              ),
              title: Text(m.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(m.role == 'owner' ? 'Owner' : 'Member'),
            ),
          const SizedBox(height: AppSpacing.lg),
          if (firebaseReady)
            FilledButton.icon(
              onPressed: () {
                // Invite-link generation + Cloud Function redemption land
                // with the first keyed build (Sprint 5 stories 5.1–5.3).
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Invite links arrive in the next build.')));
              },
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Invite family'),
            )
          else
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.06),
                borderRadius: AppRadius.card,
                border:
                    Border.all(color: scheme.primary.withValues(alpha: 0.2)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Family sharing is almost ready',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'Inviting family needs the cloud connection so everyone '
                    'sees the same home. It switches on with the next build.',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
