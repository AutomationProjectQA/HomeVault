import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/tokens.dart';
import '../../data/local/database.dart';
import '../../data/repositories/asset_repository.dart';

const _nextDueOptions = [
  ('No reminder', null, null),
  ('In 6 months', 180, 'FREQ=MONTHLY;INTERVAL=6'),
  ('In 1 year', 365, 'FREQ=YEARLY'),
];

/// Log a completed service in ≤4 taps; optionally arms the next-due
/// recurring reminder (medium policy).
class LogServiceSheet extends ConsumerStatefulWidget {
  const LogServiceSheet({super.key, required this.asset});

  final Asset asset;

  static Future<void> show(BuildContext context, Asset asset) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: LogServiceSheet(asset: asset),
      ),
    );
  }

  @override
  ConsumerState<LogServiceSheet> createState() => _LogServiceSheetState();
}

class _LogServiceSheetState extends ConsumerState<LogServiceSheet> {
  final _cost = TextEditingController();
  final _providerName = TextEditingController();
  int _nextDueIndex = 2; // yearly by default — most appliances
  bool _saving = false;

  @override
  void dispose() {
    _cost.dispose();
    _providerName.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final (_, days, rrule) = _nextDueOptions[_nextDueIndex];
      await ref.read(assetRepositoryProvider).logService(
            homeId: widget.asset.homeId,
            assetId: widget.asset.id,
            assetName: widget.asset.name,
            title: 'Serviced',
            serviceDate: DateTime.now(),
            cost: double.tryParse(_cost.text.trim()),
            providerName: _providerName.text,
            nextDue:
                days == null ? null : DateTime.now().add(Duration(days: days)),
            recurrenceRule: rrule,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(days == null
                ? 'Service logged.'
                : 'Service logged. Next reminder ${DateFormat('MMM yyyy').format(DateTime.now().add(Duration(days: days)))}.')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
            Text('Log service — ${widget.asset.name}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _cost,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Cost (optional)', prefixText: '₹ '),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _providerName,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Technician / company (optional)'),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (var i = 0; i < _nextDueOptions.length; i++)
                  ChoiceChip(
                    label: Text('Next: ${_nextDueOptions[i].$1}'),
                    selected: _nextDueIndex == i,
                    onSelected: (_) => setState(() => _nextDueIndex = i),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: const Text('Save service'),
            ),
          ],
        ),
      ),
    );
  }
}
