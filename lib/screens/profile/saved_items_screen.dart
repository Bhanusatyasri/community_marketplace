import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../repositories/product_repository.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/product_card.dart';
import '../products/item_details_screen.dart';

class SavedItemsScreen extends StatelessWidget {
  const SavedItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view saved items.')),
      );
    }

    final products = ProductRepository();
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Items')),
      body: StreamBuilder<List<Product>>(
        stream: products.watchFavorites(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Could not load saved items. Check your connection and Firestore rules.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final saved = snapshot.data!;
          if (saved.isEmpty) {
            return const EmptyState(
              title: 'No saved items yet',
              subtitle: 'Explore products and save your favorites.',
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: saved.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: .76,
            ),
            itemBuilder: (context, index) {
              final product = saved[index];
              return ProductCard(
                product: product,
                onFavoriteChanged: (selected) => products.setFavorite(
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
