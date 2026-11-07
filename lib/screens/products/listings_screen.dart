import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../repositories/product_repository.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/listing_card.dart';
import 'item_details_screen.dart';

class ListingsScreen extends StatelessWidget {
  const ListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = ProductRepository();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listings'),
      ),
      body: StreamBuilder<List<Product>>(
        stream: repository.watchProducts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Could not load listings. Check your connection and Firestore rules.',
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
              title: 'No listings yet',
              subtitle: 'New community listings will appear here.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final product = products[index];
              return ListingCard(
                product: product,
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
