import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router/app_router.dart';
import '../../core/services/analytics_service.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories/bill_repository.dart';
import '../../data/repositories/home_repository.dart';
import 'bill_types.dart';

const _repeatOptions = [
  ('No repeat', null),
  ('Monthly', 'FREQ=MONTHLY'),
  ('Every 30 days', 'FREQ=DAILY;INTERVAL=30'),
  ('Quarterly', 'FREQ=MONTHLY;INTERVAL=3'),
  ('Yearly', 'FREQ=YEARLY'),
];

/// ≤5 taps for a recurring bill: type (cycle pre-fills) → due date → save.
class AddBillScreen extends ConsumerStatefulWidget {
  const AddBillScreen({super.key});

  @override
  ConsumerState<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends ConsumerState<AddBillScreen> {
  final _provider = TextEditingController();
  final _amount = TextEditingController();

  String _type = 'electricity';
  String? _rrule = 'FREQ=MONTHLY';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _saving = false;

  @override
  void dispose() {
    _provider.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final home = ref.read(currentHomeProvider).value;
      if (home == null) return;
      await ref.read(billRepositoryProvider).addBill(
            homeId: home.id,
            type: _type,
            provider: _provider.text,
            amount: double.tryParse(_amount.text.trim()),
            dueDate: _dueDate,
            recurrenceRule: _rrule,
          );
      ref.read(analyticsProvider).logEvent('bill_added',
          {'type': _type, 'recurring': _rrule != null});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_rrule == null
                ? 'Bill added — we\'ll remind you before it\'s due.'
                : 'Recurring bill added — next cycles create themselves.')));
        context.go(Routes.bills);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, d MMM yyyy');
    return Scaffold(
      appBar: AppBar(title: const Text('Add bill')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                for (final t in billTypes)
                  ChoiceChip(
                    label: Text(t.label),
                    avatar: Icon(t.icon, size: 18),
                    selected: _type == t.key,
                    onSelected: (_) => setState(() {
                      _type = t.key;
                      _rrule = t.defaultRrule;
                    }),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Material(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm)),
                leading: const Icon(Icons.event_outlined),
                title: const Text('Due date', style: TextStyle(fontSize: 13)),
                subtitle: Text(dateFormat.format(_dueDate),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(DateTime.now().year + 5),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String?>(
              initialValue: _rrule,
              decoration: const InputDecoration(labelText: 'Repeats'),
              items: [
                for (final (label, rule) in _repeatOptions)
                  DropdownMenuItem(value: rule, child: Text(label)),
              ],
              onChanged: (v) => setState(() => _rrule = v),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Amount (optional)', prefixText: '₹ '),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _provider,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Provider (optional)',
                  hintText: 'e.g. Torrent Power, Jio'),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5))
                  : const Text('Save bill'),
            ),
          ],
        ),
      ),
    );
  }
}
