import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

enum WarrantyStatus { none, active, expiringSoon, expired }

const _expiringSoonWindow = Duration(days: 30);

WarrantyStatus warrantyStatusFor(DateTime? warrantyEnd, {DateTime? now}) {
  if (warrantyEnd == null) return WarrantyStatus.none;
  final today = now ?? DateTime.now();
  if (warrantyEnd.isBefore(today)) return WarrantyStatus.expired;
  if (warrantyEnd.difference(today) <= _expiringSoonWindow) {
    return WarrantyStatus.expiringSoon;
  }
  return WarrantyStatus.active;
}

extension WarrantyStatusUi on WarrantyStatus {
  String get label => switch (this) {
        WarrantyStatus.none => 'No warranty',
        WarrantyStatus.active => 'In warranty',
        WarrantyStatus.expiringSoon => 'Expiring soon',
        WarrantyStatus.expired => 'Expired',
      };

  Color get color => switch (this) {
        WarrantyStatus.none => AppColors.textSecondary,
        WarrantyStatus.active => AppColors.statusDone,
        WarrantyStatus.expiringSoon => AppColors.statusWarning,
        WarrantyStatus.expired => AppColors.statusCritical,
      };
}
