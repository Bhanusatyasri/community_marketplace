import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/product.dart';
import '../repositories/auth_repository.dart';
import '../theme/app_colors.dart';
import 'product_image.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;
  final Future<void> Function(bool selected)? onFavoriteChanged;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onFavoriteChanged,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _updatingFavorite = false;

  Future<void> _toggleFavorite(Product product) async {
    if (_updatingFavorite) return;
    final previous = product.favorite;
    final selected = !previous;
    setState(() {
      _updatingFavorite = true;
      product.favorite = selected;
    });

    try {
      await widget.onFavoriteChanged?.call(selected);
    } on FirebaseException catch (error) {
      product.favorite = previous;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AuthRepository.messageFor(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingFavorite = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(14),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'product-image-${product.id}',
                    child: ProductImage(
                      source:
                          product.images.isEmpty ? null : product.images.first,
                      icon: _iconFor(product.category),
                      iconSize: 50,
                    ),
                  ),
                  Positioned(
                    right: 7,
                    top: 7,
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 16,
                        onPressed: _updatingFavorite
                            ? null
                            : () => _toggleFavorite(product),
                        icon: Icon(
                          product.favorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: product.favorite
                              ? Colors.red
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          product.distance > 0
                              ? '${product.distance.toStringAsFixed(1)} km'
                              : product.location.isEmpty
                              ? 'Community listing'
                              : product.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static IconData _iconFor(String category) {
    switch (category) {
      case 'Electronics':
        return Icons.devices_other;
      case 'Home & Garden':
        return Icons.chair_outlined;
      case 'Fashion':
        return Icons.checkroom_outlined;
      case 'Books & Stationery':
        return Icons.menu_book_outlined;
      case 'Kids & Toys':
        return Icons.toys_outlined;
      case 'Sports & Fitness':
        return Icons.sports_soccer_outlined;
      case 'Vehicles':
        return Icons.directions_car_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}
