import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/product.dart';
import '../../models/user.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/product_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_image.dart';
import '../../widgets/section_title.dart';
import '../../models/category.dart';
import '../products/item_details_screen.dart';
import '../products/listings_screen.dart';
import '../categories/category_products_screen.dart';
import '../cart/cart_screen.dart';
import '../profile/edit_profile_screen.dart';
import 'notifications_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<UserModel?>(
                          stream: user == null
                              ? null
                              : ProfileRepository().watchProfile(user.uid),
                          builder: (context, snapshot) {
                            final fallbackName =
                                user?.displayName?.trim().split(' ').first ??
                                user?.email?.split('@').first ??
                                'there';
                            final firstName =
                                snapshot.data?.name.trim().split(' ').first;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  snapshot.hasError
                                      ? 'Profile unavailable'
                                      : 'Hello, ${firstName?.isNotEmpty == true ? firstName : fallbackName} 👋',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'What are you looking for today?',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationsScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.notifications_none),
                        tooltip: 'Notifications',
                      ),
                      IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CartScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.shopping_cart_outlined),
                        tooltip: 'Cart',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    readOnly: true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SearchScreen(),
                      ),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Search for items, categories...',
                      prefixIcon: Icon(Icons.search),
                      suffixIcon: Icon(Icons.tune),
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: StreamBuilder<UserModel?>(
                              stream: user == null
                                  ? null
                                  : ProfileRepository().watchProfile(user.uid),
                              builder: (context, snapshot) => Text(
                                snapshot.data?.location.isNotEmpty == true
                                    ? 'Your area: ${snapshot.data!.location}'
                                    : 'Add your area in your profile',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 5,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        const categories = [
                          CategoryModel(
                            id: 'all',
                            name: 'All',
                            icon: 'grid',
                            itemCount: 0,
                          ),
                          CategoryModel(
                            id: 'electronics',
                            name: 'Electronics',
                            icon: 'devices',
                            itemCount: 0,
                          ),
                          CategoryModel(
                            id: 'home',
                            name: 'Home & Garden',
                            icon: 'chair',
                            itemCount: 0,
                          ),
                          CategoryModel(
                            id: 'fashion',
                            name: 'Fashion',
                            icon: 'fashion',
                            itemCount: 0,
                          ),
                          CategoryModel(
                            id: 'books',
                            name: 'Books & Stationery',
                            icon: 'books',
                            itemCount: 0,
                          ),
                        ];
                        const icons = {
                          'All': Icons.grid_view,
                          'Electronics': Icons.devices,
                          'Home & Garden': Icons.chair,
                          'Fashion': Icons.checkroom,
                          'Books & Stationery': Icons.menu_book,
                        };

                        return SizedBox(
                          width: 62,
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => categories[index].name ==
                                            'All'
                                        ? const ListingsScreen()
                                        : CategoryProductsScreen(
                                            category: categories[index],
                                          ),
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(23),
                                child: CircleAvatar(
                                  radius: 23,
                                  backgroundColor: index == 0
                                      ? AppColors.primary
                                      : Colors.white,
                                  child: Icon(
                                    icons[categories[index].name],
                                    color: index == 0
                                        ? Colors.white
                                        : AppColors.primaryDark,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                categories[index].name == 'Home & Garden'
                                    ? 'Home'
                                    : categories[index].name ==
                                          'Books & Stationery'
                                    ? 'Books'
                                    : categories[index].name,
                                style: const TextStyle(fontSize: 10),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: StreamBuilder<List<Product>>(
              stream: ProductRepository().watchProducts(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Could not load community listings. Check your connection and Firestore rules.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final liveProducts = snapshot.data!;
                if (liveProducts.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                          'No community listings yet. Be the first to sell!'),
                    ),
                  );
                }
                final popularProducts = List<Product>.from(liveProducts)
                  ..sort((a, b) => b.views.compareTo(a.views));
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: SectionTitle(
                        title: 'Featured Listings',
                        action: 'See all',
                        onAction: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ListingsScreen(),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth >= 900
                              ? 4
                              : constraints.maxWidth >= 600
                                  ? 3
                                  : 2;
                          final featured = liveProducts.take(4).toList();
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: featured.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: .76,
                            ),
                            itemBuilder: (context, index) {
                              final product = featured[index];
                              return ProductCard(
                                product: product,
                                onFavoriteChanged: (selected) =>
                                    ProductRepository().setFavorite(
                                  productId: product.id,
                                  selected: selected,
                                ),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ItemDetailsScreen(product: product),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: SectionTitle(title: 'Popular Listings'),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 25),
                      child: Column(
                        children: popularProducts.take(5).map((product) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              tileColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              leading: Container(
                                width: 58,
                                height: 58,
                                clipBehavior: Clip.antiAlias,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ProductImage(
                                  source: product.images.isEmpty
                                      ? null
                                      : product.images.first,
                                ),
                              ),
                              title: Text(
                                product.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                '₹${product.price.toStringAsFixed(0)} • ${product.location}',
                              ),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ItemDetailsScreen(product: product),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
