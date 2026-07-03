import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/tokens.dart';
import '../../data/local/database.dart';
import '../../data/repositories/reminder_repository.dart';

/// Actionable task cards — the product's core surface. Tasks, not alerts:
/// every card is one tap from Done or a snooze that never loses the task.
class TodayTasksList extends ConsumerWidget {
  const TodayTasksList({super.key, required this.emptyState});

  final Widget emptyState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(todayTasksProvider).value ?? const <Reminder>[];
    if (tasks.isEmpty) return emptyState;

    return Column(
      children: [
        for (final task in tasks)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: TaskCard(task: task),
          ),
      ],
    );
  }
}

class TaskCard extends ConsumerWidget {
  const TaskCard({super.key, required this.task});

  final Reminder task;

  Color get _statusColor {
    final now = DateTime.now();
    if (task.dueAt.isBefore(DateTime(now.year, now.month, now.day))) {
      return AppColors.statusCritical; // overdue
    }
    if (task.priority == 'critical') return AppColors.statusWarning;
    return AppColors.statusUpcoming;
  }

  String get _dueLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(task.dueAt.year, task.dueAt.month, task.dueAt.day);
    final days = dueDay.difference(today).inDays;
    if (days < 0) return days == -1 ? 'Due yesterday' : '${-days} days overdue';
    if (days == 0) return 'Due today';
    return 'Due ${DateFormat('d MMM').format(task.dueAt)}';
  }

  Future<void> _complete(BuildContext context, WidgetRef ref) async {
    await ref.read(reminderRepositoryProvider).complete(task.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Done: ${task.title}'),
          duration: const Duration(seconds: 2)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final color = _statusColor;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        boxShadow: AppElevation.soft,
      ),
      child: Material(
        color: scheme.surface,
        borderRadius: AppRadius.card,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          child: Row(
            children: [
              IconButton(
                onPressed: () => _complete(context, ref),
                icon: Icon(Icons.radio_button_unchecked, color: color),
                tooltip: 'Mark done',
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(_dueLabel,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: color)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => SnoozeSheet.show(context, ref, task),
                icon: const Icon(Icons.snooze_outlined),
                tooltip: 'Snooze',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Smart snooze: Tomorrow / 3 days / Next week / Custom. Never dismiss-only.
class SnoozeSheet extends StatelessWidget {
  const SnoozeSheet({super.key, required this.task, required this.onSnooze});

  final Reminder task;
  final ValueChanged<DateTime> onSnooze;

  static Future<void> show(
      BuildContext context, WidgetRef ref, Reminder task) {
    final repo = ref.read(reminderRepositoryProvider);
    return showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SnoozeSheet(
        task: task,
        onSnooze: (until) {
          Navigator.pop(sheetContext);
          repo.snooze(task.id, until);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Snoozed until ${DateFormat('EEE, d MMM').format(until)}'),
              duration: const Duration(seconds: 2)));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    DateTime at9(DateTime d) => DateTime(d.year, d.month, d.day, 9);
    final options = [
      ('Tomorrow', at9(now.add(const Duration(days: 1)))),
      ('In 3 days', at9(now.add(const Duration(days: 3)))),
      ('Next week', at9(now.add(const Duration(days: 7)))),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Remind me again',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            for (final (label, until) in options)
              ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(label),
                subtitle: Text(DateFormat('EEEE, d MMM').format(until)),
                onTap: () => onSnooze(until),
              ),
            ListTile(
              leading: const Icon(Icons.edit_calendar_outlined),
              title: const Text('Pick a date'),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: now.add(const Duration(days: 1)),
                  firstDate: now,
                  lastDate: DateTime(now.year + 2),
                );
                if (picked != null) onSnooze(at9(picked));
              },
            ),
          ],
        ),
      ),
    );
  }
}
