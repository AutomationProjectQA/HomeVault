import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router/app_router.dart';
import '../../core/services/analytics_service.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories/asset_repository.dart';
import '../../data/repositories/home_repository.dart';
import 'asset_categories.dart';

/// Quick-add first: name + category is enough to save. Details expand below.
/// Camera-first OCR capture lands with story 2.3.
class AddAssetScreen extends ConsumerStatefulWidget {
  const AddAssetScreen({super.key});

  @override
  ConsumerState<AddAssetScreen> createState() => _AddAssetScreenState();
}

class _AddAssetScreenState extends ConsumerState<AddAssetScreen> {
  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _serial = TextEditingController();
  final _vendor = TextEditingController();
  final _price = TextEditingController();
  final _notes = TextEditingController();

  String _category = 'electronics';
  DateTime? _purchaseDate;
  DateTime? _warrantyEnd;
  bool _showDetails = false;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _brand, _model, _serial, _vendor, _price, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate({required bool warranty}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: warranty ? now.add(const Duration(days: 365)) : now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 15),
    );
    if (picked != null) {
      setState(() => warranty ? _warrantyEnd = picked : _purchaseDate = picked);
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      // Home is guaranteed loaded once this screen is reachable.
      final home = ref.read(currentHomeProvider).value;
      if (home == null) return;

      final repo = ref.read(assetRepositoryProvider);
      final hadAssets = await repo.countActiveAssets() > 0;

      await repo.addAsset(
            AssetDraft(
              name: name,
              category: _category,
              brand: _brand.text,
              model: _model.text,
              serialNumber: _serial.text,
              vendor: _vendor.text,
              purchaseDate: _purchaseDate,
              purchasePrice: double.tryParse(_price.text.trim()),
              warrantyEndDate: _warrantyEnd,
              notes: _notes.text,
            ),
            homeId: home.id,
          );

      final analytics = ref.read(analyticsProvider);
      analytics.logEvent('asset_added', {'category': _category});
      if (!hadAssets) {
        analytics.logEvent(AnalyticsEvents.firstAssetAdded);
      }
      if (_warrantyEnd != null) {
        analytics.logEvent(AnalyticsEvents.firstReminderScheduled, {
          'source': 'asset_warranty',
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _warrantyEnd != null
                  ? '$name saved. We\'ll remind you before the warranty ends.'
                  : '$name saved.',
            ),
          ),
        );
        // Land on the assets list: the user sees their vault grow.
        context.go(Routes.assets);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy');
    return Scaffold(
      appBar: AppBar(title: const Text('Add asset')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Samsung 55" TV',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final c in assetCategories)
                  ChoiceChip(
                    label: Text(c.label),
                    avatar: Icon(c.icon, size: 18),
                    selected: _category == c.key,
                    onSelected: (_) => setState(() => _category = c.key),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _DateTile(
              icon: Icons.verified_outlined,
              label: 'Warranty ends',
              value: _warrantyEnd == null
                  ? 'Set date — we\'ll remind you'
                  : dateFormat.format(_warrantyEnd!),
              onTap: () => _pickDate(warranty: true),
              onClear: _warrantyEnd == null
                  ? null
                  : () => setState(() => _warrantyEnd = null),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: () => setState(() => _showDetails = !_showDetails),
              icon: Icon(_showDetails ? Icons.expand_less : Icons.expand_more),
              label: Text(_showDetails ? 'Fewer details' : 'More details'),
            ),
            if (_showDetails) ...[
              TextField(
                controller: _brand,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Brand'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _model,
                decoration: const InputDecoration(labelText: 'Model'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _serial,
                decoration: const InputDecoration(labelText: 'Serial number'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _vendor,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Bought from',
                  hintText: 'e.g. Croma, Amazon',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  prefixText: '₹ ',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _DateTile(
                icon: Icons.calendar_today_outlined,
                label: 'Purchase date',
                value: _purchaseDate == null
                    ? 'Set date'
                    : dateFormat.format(_purchaseDate!),
                onTap: () => _pickDate(warranty: false),
                onClear: _purchaseDate == null
                    ? null
                    : () => setState(() => _purchaseDate = null),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _notes,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Save asset'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        leading: Icon(icon, color: scheme.primary),
        title: Text(label, style: const TextStyle(fontSize: 13)),
        subtitle: Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: onClear == null
            ? const Icon(Icons.chevron_right)
            : IconButton(icon: const Icon(Icons.close), onPressed: onClear),
      ),
    );
  }
}
