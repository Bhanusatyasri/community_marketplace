import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../repositories/product_repository.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/product_card.dart';
import '../products/item_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final controller = TextEditingController();
  final _products = ProductRepository();
  String _query = '';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  List<Product> _filterProducts(List<Product> products) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return products;
    return products.where((product) {
      return product.title.toLowerCase().contains(query) ||
          product.category.toLowerCase().contains(query) ||
          product.description.toLowerCase().contains(query) ||
          product.location.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: controller,
          autofocus: true,
          onChanged: (query) => setState(() => _query = query),
          decoration: const InputDecoration(
            hintText: 'Search products or categories...',
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              controller.clear();
              setState(() => _query = '');
            },
            icon: const Icon(Icons.clear),
            tooltip: 'Clear search',
          ),
        ],
      ),
      body: StreamBuilder<List<Product>>(
        stream: _products.watchProducts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Could not search listings. Check your connection and Firestore rules.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final filtered = _filterProducts(snapshot.data!);
          if (filtered.isEmpty) {
            return const EmptyState(
              title: 'No results found',
              subtitle: 'Try another product or category.',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: .76,
            ),
            itemBuilder: (context, index) {
              final product = filtered[index];
              return ProductCard(
                product: product,
                onFavoriteChanged: (selected) => _products.setFavorite(
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
