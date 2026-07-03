import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/tokens.dart';
import '../../data/local/database.dart';
import '../../data/repositories/asset_repository.dart';
import '../../data/repositories/document_repository.dart';
import '../maintenance/log_service_sheet.dart';
import 'asset_categories.dart';
import 'warranty_status.dart';

class AssetDetailScreen extends ConsumerWidget {
  const AssetDetailScreen({super.key, required this.assetId});

  final String assetId;

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Asset asset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${asset.name}?'),
        content: const Text(
            'Its history stays in your records but pending reminders are cancelled.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(assetRepositoryProvider).deleteAsset(asset.id);
      if (context.mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = ref.watch(assetProvider(assetId)).value;
    if (asset == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final events = ref.watch(assetEventsProvider(assetId)).value ?? const [];
    final category = categoryByKey(asset.category);
    final status = warrantyStatusFor(asset.warrantyEndDate);
    final dateFormat = DateFormat('d MMM yyyy');
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(asset.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, ref, asset),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'log_service',
        onPressed: () => LogServiceSheet.show(context, asset),
        icon: const Icon(Icons.build_outlined),
        label: const Text('Log service'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Identity card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: AppRadius.card,
              boxShadow: AppElevation.soft,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: scheme.primary.withValues(alpha: 0.1),
                  child: Icon(category.icon, color: scheme.primary, size: 30),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(asset.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(
                        [
                          if (asset.brand != null) asset.brand!,
                          if (asset.model != null) asset.model!,
                          category.label,
                        ].join(' · '),
                        style:
                            const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Warranty card
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.08),
              borderRadius: AppRadius.card,
              border: Border.all(color: status.color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_outlined, color: status.color),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(status.label,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: status.color)),
                      if (asset.warrantyEndDate != null)
                        Text(
                          'Until ${dateFormat.format(asset.warrantyEndDate!)}',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Facts
          _FactRow('Serial number', asset.serialNumber),
          _FactRow('Bought from', asset.vendor),
          _FactRow(
              'Purchase date',
              asset.purchaseDate == null
                  ? null
                  : dateFormat.format(asset.purchaseDate!)),
          _FactRow(
              'Price',
              asset.purchasePrice == null
                  ? null
                  : '₹${asset.purchasePrice!.toStringAsFixed(0)}'),
          _FactRow('Notes', asset.notes),

          _DocumentsSection(assetId: assetId),

          const SizedBox(height: AppSpacing.lg),
          Text('Timeline',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          for (final event in events)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: scheme.primary.withValues(alpha: 0.1),
                child: Icon(
                  switch (event.type) {
                    'purchase' => Icons.shopping_bag_outlined,
                    'service' => Icons.build_outlined,
                    'repair' => Icons.handyman_outlined,
                    _ => Icons.notes_outlined,
                  },
                  size: 16,
                  color: scheme.primary,
                ),
              ),
              title: Text(event.title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(dateFormat.format(event.occurredAt)),
              trailing: event.cost == null
                  ? null
                  : Text('₹${event.cost!.toStringAsFixed(0)}'),
            ),
        ],
      ),
    );
  }
}

class _DocumentsSection extends ConsumerWidget {
  const _DocumentsSection({required this.assetId});

  final String assetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docs = ref.watch(assetDocumentsProvider(assetId)).value ?? const [];
    if (docs.isEmpty) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('d MMM yyyy');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text('Documents',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        for (final doc in docs)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 16,
              backgroundColor: scheme.primary.withValues(alpha: 0.1),
              child: Icon(Icons.description_outlined,
                  size: 16, color: scheme.primary),
            ),
            title: Text(doc.title,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(dateFormat.format(doc.createdAt)),
            trailing: doc.remotePath == null
                ? const Tooltip(
                    message: 'On this device — cloud backup after sync setup',
                    child: Icon(Icons.smartphone, size: 18))
                : const Icon(Icons.cloud_done_outlined, size: 18),
          ),
      ],
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow(this.label, this.value);

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value!,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
