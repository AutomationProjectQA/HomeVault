import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/router/app_router.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/attachment_service.dart';
import '../../core/services/ocr/invoice_parser.dart';
import '../../core/services/ocr/ocr_service.dart';
import '../../core/theme/tokens.dart';
import '../../data/repositories/asset_repository.dart';
import '../../data/repositories/document_repository.dart';
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
  PickedAttachment? _invoice;
  bool _scanning = false;

  Future<void> _scanInvoice({required bool fromCamera}) async {
    if (_scanning) return;
    setState(() => _scanning = true);
    try {
      final picked = await ref
          .read(attachmentPickerProvider)
          .pickImage(fromCamera: fromCamera);
      if (picked == null) return;
      setState(() => _invoice = picked);

      final ocr = ref.read(ocrServiceProvider);
      final text = await ocr.extractText(picked.path);
      if (text == null) {
        if (mounted && !ocr.isSupported) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content:
                  Text('Invoice attached. Auto-fill needs the mobile app.')));
        }
        return;
      }

      final scan = parseInvoiceText(text);
      if (!scan.hasAnyField) return;
      setState(() {
        if (scan.vendor != null && _vendor.text.isEmpty) {
          _vendor.text = scan.vendor!;
        }
        if (scan.amount != null && _price.text.isEmpty) {
          _price.text = scan.amount!.toStringAsFixed(0);
        }
        _purchaseDate ??= scan.purchaseDate;
        _showDetails = true;
      });
      ref.read(analyticsProvider).logEvent('invoice_scanned', {
        'vendor_found': scan.vendor != null,
        'amount_found': scan.amount != null,
        'date_found': scan.purchaseDate != null,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Details filled from your invoice — please verify.')));
      }
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

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

      final asset = await repo.addAsset(
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

      final invoice = _invoice;
      if (invoice != null) {
        await ref.read(documentRepositoryProvider).attach(
              homeId: home.id,
              sourceType: 'asset',
              sourceId: asset.id,
              title: 'Invoice',
              category: 'invoice',
              localPath: invoice.path,
              mimeType: invoice.mimeType,
            );
      }

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
            _InvoiceCard(
              invoice: _invoice,
              scanning: _scanning,
              onScan: () => _scanInvoice(fromCamera: true),
              onPick: () => _scanInvoice(fromCamera: false),
              onRemove: () => setState(() => _invoice = null),
            ),
            const SizedBox(height: AppSpacing.md),
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

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({
    required this.invoice,
    required this.scanning,
    required this.onScan,
    required this.onPick,
    required this.onRemove,
  });

  final PickedAttachment? invoice;
  final bool scanning;
  final VoidCallback onScan;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (invoice != null) {
      return Material(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: ListTile(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm)),
          leading: Icon(Icons.receipt_long, color: scheme.primary),
          title: const Text('Invoice attached',
              style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Saved with this asset'),
          trailing: IconButton(
              icon: const Icon(Icons.close), onPressed: onRemove),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Have the invoice? Skip the typing.',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: scanning ? null : onScan,
                  icon: scanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.photo_camera_outlined),
                  label: const Text('Scan invoice'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: scanning ? null : onPick,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('From gallery'),
                ),
              ),
            ],
          ),
        ],
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
