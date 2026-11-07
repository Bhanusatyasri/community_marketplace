import 'package:flutter/material.dart';

import '../../models/category.dart';
import '../../models/product.dart';
import '../../repositories/product_repository.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/product_card.dart';
import '../products/item_details_screen.dart';

class CategoryProductsScreen extends StatelessWidget {
  const CategoryProductsScreen({super.key, required this.category});

  final CategoryModel category;

  @override
  Widget build(BuildContext context) {
    final repository = ProductRepository();
    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: StreamBuilder<List<Product>>(
        stream: repository.watchProducts(category: category.name),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Could not load this category. Check your connection and Firestore rules.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final products = snapshot.data!;
          if (products.isEmpty) {
            return const EmptyState(
              title: 'No products in this category',
              subtitle: 'Try another category or check back later.',
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: .76,
            ),
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(
                product: product,
                onFavoriteChanged: (selected) => repository.setFavorite(
                  productId: product.id,
                  selected: selected,
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ItemDetailsScreen(product: product),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
