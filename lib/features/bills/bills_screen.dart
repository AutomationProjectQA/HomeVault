import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/tokens.dart';
import '../../data/local/database.dart';
import '../../data/repositories/bill_repository.dart';
import 'bill_types.dart';

final typeDeltasProvider = FutureProvider<List<TypeDelta>>((ref) {
  ref.watch(billsProvider); // recompute when bills change
  return ref.watch(billRepositoryProvider).typeDeltas();
});

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(billsProvider).value ?? const <Bill>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Bills')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_bill',
        onPressed: () => context.push(Routes.addBill),
        icon: const Icon(Icons.add),
        label: const Text('Add bill'),
      ),
      body: bills.isEmpty
          ? const _EmptyState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
              children: [
                const _TrendsHeader(),
                for (final bill in bills)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _BillCard(bill: bill),
                  ),
              ],
            ),
    );
  }
}

/// "Electricity up 24% vs last month" — simple arithmetic, high perceived value.
class _TrendsHeader extends ConsumerWidget {
  const _TrendsHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deltas = ref.watch(typeDeltasProvider).value ?? const <TypeDelta>[];
    final notable = deltas
        .where((d) => d.percentChange != null && d.percentChange != 0)
        .take(2)
        .toList();
    if (notable.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        children: [
          for (final d in notable)
            Row(
              children: [
                Icon(
                  d.percentChange! > 0
                      ? Icons.trending_up
                      : Icons.trending_down,
                  size: 18,
                  color: d.percentChange! > 0
                      ? AppColors.statusWarning
                      : AppColors.statusDone,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '${billTypeByKey(d.type).label} ${d.percentChange! > 0 ? 'up' : 'down'} '
                    '${d.percentChange!.abs()}% vs last month',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _BillCard extends ConsumerWidget {
  const _BillCard({required this.bill});

  final Bill bill;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final type = billTypeByKey(bill.type);
    final paid = bill.status == 'paid';
    final overdue = !paid && bill.dueDate.isBefore(DateTime.now());
    final dateFormat = DateFormat('d MMM');

    return DecoratedBox(
      decoration: BoxDecoration(
          borderRadius: AppRadius.card, boxShadow: AppElevation.soft),
      child: Material(
        color: scheme.surface,
        borderRadius: AppRadius.card,
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
          leading: CircleAvatar(
            backgroundColor: (paid
                    ? AppColors.statusDone
                    : overdue
                        ? AppColors.statusCritical
                        : scheme.primary)
                .withValues(alpha: 0.1),
            child: Icon(type.icon,
                color: paid
                    ? AppColors.statusDone
                    : overdue
                        ? AppColors.statusCritical
                        : scheme.primary),
          ),
          title: Text(
            bill.provider == null
                ? type.label
                : '${type.label} · ${bill.provider}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              decoration: paid ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Text(
            paid
                ? 'Paid ${dateFormat.format(bill.paidDate ?? bill.dueDate)}'
                : (overdue ? 'Overdue since ' : 'Due ') +
                    dateFormat.format(bill.dueDate),
            style: TextStyle(
              color: overdue ? AppColors.statusCritical : null,
              fontWeight: overdue ? FontWeight.w600 : null,
            ),
          ),
          trailing: paid
              ? Text(
                  bill.amount == null
                      ? ''
                      : '₹${bill.amount!.toStringAsFixed(0)}',
                  style: const TextStyle(color: AppColors.textSecondary))
              : FilledButton.tonal(
                  onPressed: () async {
                    final next =
                        await ref.read(billRepositoryProvider).markPaid(bill.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(next == null
                            ? 'Marked paid'
                            : 'Paid. Next bill created for ${DateFormat('d MMM').format(next.dueDate)}.'),
                        duration: const Duration(seconds: 2),
                      ));
                    }
                  },
                  child: Text(bill.amount == null
                      ? 'Paid'
                      : 'Paid ₹${bill.amount!.toStringAsFixed(0)}'),
                ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 56, color: scheme.primary),
            const SizedBox(height: AppSpacing.md),
            const Text('No bills yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Add a bill once — HomeVault reminds you every cycle and keeps the history.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
