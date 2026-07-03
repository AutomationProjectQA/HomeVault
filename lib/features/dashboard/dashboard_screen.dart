import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories/home_repository.dart';
import 'dashboard_providers.dart';

/// Dashboard v1 (Sprint 1): live home + stats from Drift streams.
/// Task cards become real with the Reminder Engine (Sprint 3).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: const [
            _Header(),
            SizedBox(height: AppSpacing.lg),
            _SetupProgressCard(progress: 0.15),
            SizedBox(height: AppSpacing.lg),
            _SectionTitle("Today's tasks"),
            SizedBox(height: AppSpacing.sm),
            _EmptyTasksCard(),
            SizedBox(height: AppSpacing.lg),
            _SectionTitle('Your home'),
            SizedBox(height: AppSpacing.sm),
            _StatsStrip(),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final home = ref.watch(currentHomeProvider).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(home?.name ?? 'My Home',
            style: textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.xs),
        Text('Everything about your home, in one place',
            style: textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}

class _SetupProgressCard extends StatelessWidget {
  const _SetupProgressCard({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: AppRadius.card,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 5,
                  backgroundColor: Colors.white24,
                  color: AppColors.accent,
                ),
                Center(
                  child: Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Home setup',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                SizedBox(height: 2),
                Text('Add your first appliance to secure your home',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _EmptyTasksCard extends StatelessWidget {
  const _EmptyTasksCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.card,
        boxShadow: AppElevation.soft,
      ),
      child: Column(
        children: [
          Icon(Icons.task_alt, size: 40, color: scheme.primary),
          const SizedBox(height: AppSpacing.sm),
          const Text('Nothing due today',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.xs),
          const Text(
            'Add an appliance or a bill and HomeVault will remind you before anything is due.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: () => context.push(Routes.addAsset),
            icon: const Icon(Icons.add),
            label: const Text('Add your first appliance'),
          ),
        ],
      ),
    );
  }
}

class _StatsStrip extends ConsumerWidget {
  const _StatsStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(dashboardStatsProvider);
    return Row(
      children: [
        Expanded(
            child: _StatCard(value: '${stats.assetCount}', label: 'Assets')),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: _StatCard(
                value: '₹${stats.billsThisMonth.toStringAsFixed(0)}',
                label: 'Bills this month')),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
            child: _StatCard(
                value: '${stats.pendingTasks}', label: 'Pending tasks')),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: AppRadius.card,
        boxShadow: AppElevation.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
