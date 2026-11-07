import 'package:flutter/material.dart';

import '../models/category.dart';
import '../theme/app_colors.dart';

class CategoryCard extends StatelessWidget {
  final CategoryModel category;
  final int? itemCount;
  final VoidCallback? onTap;

  const CategoryCard({
    super.key,
    required this.category,
    this.itemCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primaryLight,
                child: Icon(
                  _icon(category.icon),
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                itemCount == null
                    ? 'Browse listings'
                    : '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _icon(String value) {
    return switch (value) {
      'devices' => Icons.devices,
      'chair' => Icons.chair,
      'checkroom' => Icons.checkroom,
      'menu_book' => Icons.menu_book,
      'toys' => Icons.toys,
      'sports' => Icons.sports,
      'directions_car' => Icons.directions_car,
      _ => Icons.category,
    };
  }
}
