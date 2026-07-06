import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router/app_router.dart';
import '../../core/services/notifications/notification_scheduler.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories/home_repository.dart';
import '../../data/repositories/reminder_repository.dart';
import '../reminders/today_tasks.dart';
import 'dashboard_providers.dart';
import 'health_score.dart';

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
            _NotificationsMutedBanner(),
            _HealthCard(),
            SizedBox(height: AppSpacing.lg),
            _SectionTitle("Today's tasks"),
            SizedBox(height: AppSpacing.sm),
            TodayTasksList(emptyState: _EmptyTasksCard()),
            _SnoozedSection(),
            SizedBox(height: AppSpacing.lg),
            _UpcomingSection(),
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

/// Reminders that can't reach the user are the product failing silently —
/// surface it loudly with a one-tap fix.
class _NotificationsMutedBanner extends ConsumerWidget {
  const _NotificationsMutedBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(notificationsEnabledProvider).value ?? true;
    if (enabled) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.statusWarning.withValues(alpha: 0.1),
          borderRadius: AppRadius.card,
          border:
              Border.all(color: AppColors.statusWarning.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.notifications_off_outlined,
                color: AppColors.statusWarning),
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: Text(
                'Notifications are off — reminders can\'t reach you.',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () async {
                final granted = await ref
                    .read(notificationSchedulerProvider)
                    .requestPermissions();
                if (granted) {
                  await ref.read(reminderRepositoryProvider).rescheduleAll();
                }
                ref.invalidate(notificationsEnabledProvider);
                if (context.mounted && !granted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'Please allow HomeVault notifications in system settings.')));
                }
              },
              child: const Text('Enable'),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthCard extends ConsumerWidget {
  const _HealthCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(healthScoreProvider).value;
    final scheme = Theme.of(context).colorScheme;
    final score = health?.score ?? 100;
    final pending = health?.pendingCount ?? 0;
    final progress = score / 100;
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
                    '$score',
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Home health: ${health?.band ?? 'Excellent'}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                    pending == 0
                        ? 'Everything is on track'
                        : '$pending overdue ${pending == 1 ? 'task' : 'tasks'} — clear them to recover',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13)),
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

/// "Remind me later" must never mean "gone": snoozed tasks stay visible
/// here until they wake, with a one-tap way to bring them back now.
class _SnoozedSection extends ConsumerWidget {
  const _SnoozedSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snoozed = ref.watch(snoozedTasksProvider).value ?? const [];
    if (snoozed.isEmpty) return const SizedBox.shrink();

    final dateFormat = DateFormat('EEE, d MMM');
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final task in snoozed)
            Row(
              children: [
                const Icon(Icons.snooze,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${task.title} · back ${dateFormat.format(task.snoozedUntil!)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: () => ref
                      .read(reminderRepositoryProvider)
                      .unsnooze(task.id),
                  child: const Text('Wake now',
                      style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _UpcomingSection extends ConsumerWidget {
  const _UpcomingSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming = ref.watch(upcomingTasksProvider).value ?? const [];
    if (upcoming.isEmpty) return const SizedBox.shrink();

    final dateFormat = DateFormat('EEE, d MMM');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Next 7 days'),
        const SizedBox(height: AppSpacing.sm),
        for (final task in upcoming.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              children: [
                const Icon(Icons.circle,
                    size: 8, color: AppColors.statusUpcoming),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                    child: Text(task.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                Text(dateFormat.format(task.dueAt),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
        if (upcoming.length > 3)
          Text('+ ${upcoming.length - 3} more',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.lg),
      ],
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
