import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/product_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/listing_card.dart';
import '../products/edit_listing_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  final _products = ProductRepository();
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view your listings.')),
      );
    }

    final statuses = ['Active', 'Sold', 'Inactive'];
    final status = statuses[_tab];

    return Scaffold(
      appBar: AppBar(title: const Text('My Listings')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Active')),
                ButtonSegment(value: 1, label: Text('Sold')),
                ButtonSegment(value: 2, label: Text('Inactive')),
              ],
              selected: {_tab},
              onSelectionChanged: (value) => setState(() => _tab = value.first),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _products.watchMyListings(user.uid),
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

                final listings = snapshot.data!
                    .where((product) => product.status == status)
                    .toList();
                if (listings.isEmpty) {
                  return Center(child: Text('No $status listings yet.'));
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  itemCount: listings.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final product = listings[index];
                    return ListingCard(
                      product: product,
                      onTap: () => _showActions(product),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showActions(Product product) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit listing'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            if (product.status != 'Sold')
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Mark as sold'),
                onTap: () => Navigator.pop(context, 'sold'),
              ),
            ListTile(
              leading: const Icon(Icons.pause_circle_outline),
              title: const Text('Deactivate listing'),
              onTap: () => Navigator.pop(context, 'inactive'),
            ),
            if (product.status == 'Inactive')
              ListTile(
                leading: const Icon(Icons.play_circle_outline),
                title: const Text('Reactivate listing'),
                onTap: () => Navigator.pop(context, 'active'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.danger),
              title: const Text('Delete listing'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;

    if (action == 'edit') {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => EditListingScreen(product: product),
        ),
      );
      return;
    }

    try {
      if (action == 'delete') {
        final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete listing?'),
            content: const Text('This will permanently remove this listing.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (shouldDelete != true) return;
        await _products.deleteProduct(product.id);
      } else {
        final newStatus = switch (action) {
          'sold' => 'Sold',
          'inactive' => 'Inactive',
          'active' => 'Active',
          _ => throw StateError('Unsupported listing action.'),
        };
        await _products.updateStatus(product.id, newStatus);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'delete' ? 'Listing deleted.' : 'Listing updated.',
            ),
          ),
        );
      }
    } on FirebaseException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthRepository.messageFor(error))),
      );
    } on ArgumentError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message?.toString() ?? 'Invalid action.')),
      );
    }
  }
}
