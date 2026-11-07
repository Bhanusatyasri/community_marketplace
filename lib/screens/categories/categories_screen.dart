import 'package:flutter/material.dart';

import '../../data/mock_data.dart';
import '../../repositories/product_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/category_card.dart';
import 'category_products_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = ProductRepository();
    return SafeArea(
      child: StreamBuilder<Map<String, int>>(
        stream: repository.watchCategoryCounts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Could not load categories. Check your connection and Firestore rules.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final counts = snapshot.data ?? const <String, int>{};
          return CustomScrollView(
            slivers: [
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(18, 18, 18, 10),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Categories',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                sliver: SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final category = categories[index];
                    return CategoryCard(
                      category: category,
                      itemCount: counts[category.name] ?? 0,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CategoryProductsScreen(category: category),
                        ),
                      ),
                    );
                  }, childCount: categories.length),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.02,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 18)),
              if (snapshot.hasData && categories.every(
                (category) => (counts[category.name] ?? 0) == 0,
              ))
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'No active listings yet. Check back soon or be the first to sell.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
