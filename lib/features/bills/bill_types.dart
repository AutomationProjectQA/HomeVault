import 'package:flutter/material.dart';

/// Indian biller templates: label, icon, and the typical cycle pre-filled
/// so a recurring bill takes ≤5 taps to create.
class BillType {
  const BillType(this.key, this.label, this.icon, this.defaultRrule);

  final String key;
  final String label;
  final IconData icon;
  final String? defaultRrule;
}

const billTypes = [
  BillType('electricity', 'Electricity', Icons.bolt_outlined, 'FREQ=MONTHLY'),
  BillType('water', 'Water', Icons.water_drop_outlined, 'FREQ=MONTHLY'),
  BillType('gas', 'Gas', Icons.local_fire_department_outlined, null),
  BillType('internet', 'Internet', Icons.wifi_outlined, 'FREQ=MONTHLY'),
  BillType('mobile', 'Mobile', Icons.smartphone_outlined, 'FREQ=MONTHLY'),
  BillType('society', 'Society', Icons.apartment_outlined, 'FREQ=MONTHLY'),
  BillType('insurance', 'Insurance', Icons.shield_outlined, 'FREQ=YEARLY'),
  BillType('property_tax', 'Property tax', Icons.account_balance_outlined,
      'FREQ=YEARLY'),
  BillType('rent', 'Rent', Icons.home_work_outlined, 'FREQ=MONTHLY'),
  BillType('other', 'Other', Icons.receipt_long_outlined, null),
];

BillType billTypeByKey(String key) =>
    billTypes.firstWhere((t) => t.key == key, orElse: () => billTypes.last);
