import 'package:flutter/material.dart';

class AssetCategory {
  const AssetCategory(this.key, this.label, this.icon);

  final String key;
  final String label;
  final IconData icon;
}

const assetCategories = [
  AssetCategory('electronics', 'Electronics', Icons.tv_outlined),
  AssetCategory('kitchen', 'Kitchen', Icons.kitchen_outlined),
  AssetCategory('furniture', 'Furniture', Icons.chair_outlined),
  AssetCategory('vehicle', 'Vehicle', Icons.directions_car_outlined),
  AssetCategory('bathroom', 'Bathroom', Icons.bathtub_outlined),
  AssetCategory('other', 'Other', Icons.category_outlined),
];

AssetCategory categoryByKey(String key) => assetCategories.firstWhere(
      (c) => c.key == key,
      orElse: () => assetCategories.last,
    );
