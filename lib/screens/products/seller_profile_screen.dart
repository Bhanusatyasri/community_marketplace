import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../models/user.dart';
import '../../repositories/product_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_image.dart';
import '../../widgets/rating_widget.dart';
import 'item_details_screen.dart';

class SellerProfileScreen extends StatelessWidget {
  final UserModel user;

  const SellerProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final products = ProductRepository();
    return Scaffold(
      appBar: AppBar(title: const Text('Seller Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 42,
              backgroundColor: AppColors.primaryLight,
              child: ClipOval(
                child: user.profileImage.isEmpty
                    ? const Icon(
                        Icons.person,
                        size: 44,
                        color: AppColors.primaryDark,
                      )
                    : SizedBox(
                        width: 84,
                        height: 84,
                        child: ProductImage(source: user.profileImage),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              user.name,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 5),
          Center(
              child:
                  RatingWidget(rating: user.rating, reviews: user.reviewCount)),
          const SizedBox(height: 5),
          Center(
            child: Text(
              user.location,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            'About Seller',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            user.reviewCount == 0
                ? 'Community marketplace member.'
                : 'Community marketplace member with ${user.reviewCount} reviews.',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 22),
          const Text(
            'Active Listings',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<Product>>(
            stream: products.watchSellerListings(user.id),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Could not load this seller’s listings.'),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final listings = snapshot.data ?? const [];
              if (listings.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'This seller has no active listings right now.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: listings.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: .76,
                ),
                itemBuilder: (context, index) {
                  final product = listings[index];
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
        ],
      ),
    );
  }
}
