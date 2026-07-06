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
  ('Every 2 months', 'FREQ=MONTHLY;INTERVAL=2'), // gas/electricity in many states
  ('Quarterly', 'FREQ=MONTHLY;INTERVAL=3'),
  ('Yearly', 'FREQ=YEARLY'),
];

/// ≤5 taps for a recurring bill: type (cycle pre-fills) → due date → save.
class AddBillScreen extends ConsumerStatefulWidget {
  const AddBillScreen({super.key, this.billId});

  /// When set, the screen edits the existing open bill.
  final String? billId;

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

  bool get _isEdit => widget.billId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _prefill();
  }

  Future<void> _prefill() async {
    final bills = await ref.read(billRepositoryProvider).watchBills().first;
    final bill = bills.where((b) => b.id == widget.billId).firstOrNull;
    if (bill == null || !mounted) return;
    setState(() {
      _type = bill.type;
      _rrule = bill.recurrenceRule;
      _dueDate = bill.dueDate;
      _amount.text = bill.amount?.toStringAsFixed(0) ?? '';
      _provider.text = bill.provider ?? '';
    });
  }

  Future<void> _delete() async {
    await ref.read(billRepositoryProvider).deleteBill(widget.billId!);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Bill deleted.')));
      context.go(Routes.bills);
    }
  }

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
      final repo = ref.read(billRepositoryProvider);
      if (_isEdit) {
        await repo.updateBill(
          billId: widget.billId!,
          type: _type,
          provider: _provider.text,
          amount: double.tryParse(_amount.text.trim()),
          dueDate: _dueDate,
          recurrenceRule: _rrule,
        );
      } else {
        await repo.addBill(
          homeId: home.id,
          type: _type,
          provider: _provider.text,
          amount: double.tryParse(_amount.text.trim()),
          dueDate: _dueDate,
          recurrenceRule: _rrule,
        );
      }
      ref.read(analyticsProvider).logEvent(
          _isEdit ? 'bill_edited' : 'bill_added',
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
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit bill' : 'Add bill'),
        actions: [
          if (_isEdit)
            IconButton(
                icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
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
              key: ValueKey(_rrule),
              initialValue:
                  _repeatOptions.any((o) => o.$2 == _rrule) ? _rrule : null,
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
