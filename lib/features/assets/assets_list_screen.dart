import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/tokens.dart';
import '../../data/local/database.dart';
import '../../data/repositories/asset_repository.dart';
import 'asset_categories.dart';
import 'warranty_status.dart';

class AssetsListScreen extends ConsumerWidget {
  const AssetsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(activeAssetsProvider).value ?? const <Asset>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Assets')),
      body: assets.isEmpty
          ? const _EmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: assets.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => _AssetCard(asset: assets[index]),
            ),
    );
  }
}

class _AssetCard extends StatelessWidget {
  const _AssetCard({required this.asset});

  final Asset asset;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final category = categoryByKey(asset.category);
    final status = warrantyStatusFor(asset.warrantyEndDate);
    final subtitleParts = [
      if (asset.brand != null) asset.brand!,
      if (asset.model != null) asset.model!,
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppRadius.card,
        boxShadow: AppElevation.soft,
      ),
      child: Material(
        color: scheme.surface,
        borderRadius: AppRadius.card,
        child: ListTile(
          onTap: () => context.push(Routes.assetDetail(asset.id)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
          leading: CircleAvatar(
            backgroundColor: scheme.primary.withValues(alpha: 0.1),
            child: Icon(category.icon, color: scheme.primary),
          ),
          title: Text(
            asset.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: subtitleParts.isEmpty
              ? null
              : Text(
                  subtitleParts.join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
          trailing: status == WarrantyStatus.none
              ? const Icon(Icons.chevron_right)
              : _StatusChip(status: status),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final WarrantyStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: status.color,
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
            Icon(Icons.devices_other_outlined, size: 56, color: scheme.primary),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'No assets yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Add your appliances and HomeVault tracks their warranties, services, and papers.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: () => context.push(Routes.addAsset),
              icon: const Icon(Icons.add),
              label: const Text('Add an asset'),
            ),
          ],
        ),
      ),
    );
  }
}
