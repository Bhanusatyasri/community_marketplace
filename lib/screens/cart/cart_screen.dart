import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/cart_item.dart';
import '../../repositories/cart_repository.dart';
import '../../screens/orders/orders_screen.dart';
import '../../theme/app_colors.dart';
import '../../widgets/product_image.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _repository = CartRepository();
  bool _checkingOut = false;

  Future<void> _remove(CartItem item) async {
    try {
      await _repository.remove(item.productId);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not remove item: $error')),
      );
    }
  }

  Future<void> _checkout(List<CartItem> items) async {
    final formKey = GlobalKey<FormState>();
    final addressController = TextEditingController();
    var fulfillmentMethod = 'Pickup';
    final result = await showModalBottomSheet<({String method, String address})>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request these items',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'No online payment is taken. The seller must confirm your request; arrange payment directly when you meet or receive the item.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: fulfillmentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Fulfillment',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Pickup',
                      child: Text('Meet and pick up'),
                    ),
                    DropdownMenuItem(
                      value: 'Delivery',
                      child: Text('Ask seller about delivery'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setSheetState(() => fulfillmentMethod = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressController,
                  maxLength: 300,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Meetup or delivery location',
                    hintText: 'Enter an area or preferred location',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                      ? 'Enter a location to coordinate with the seller.'
                      : null,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      Navigator.pop(
                        context,
                        (
                          method: fulfillmentMethod,
                          address: addressController.text.trim(),
                        ),
                      );
                    },
                    child: const Text('Place order request'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    addressController.dispose();
    if (result == null || !mounted) return;

    setState(() => _checkingOut = true);
    try {
      await _repository.checkout(
        productIds: items.map((item) => item.productId).toList(),
        fulfillmentMethod: result.method,
        address: result.address,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${items.length} order request${items.length == 1 ? '' : 's'} sent. Payment is arranged in person.',
          ),
          action: SnackBarAction(
            label: 'Orders',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OrdersScreen()),
            ),
          ),
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order request failed: $error')),
      );
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view your cart.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: StreamBuilder<List<CartItem>>(
        stream: _repository.watchCart(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Could not load the cart. Check Firestore rules.'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 52,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 12),
                  Text('Your cart is empty.'),
                ],
              ),
            );
          }

          final total = items.fold<double>(0, (sum, item) => sum + item.price);
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(10),
                        leading: SizedBox(
                          width: 64,
                          height: 64,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: ProductImage(source: item.productImage),
                          ),
                        ),
                        title: Text(
                          item.productTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '₹${item.price.toStringAsFixed(0)} · ${item.sellerName}',
                        ),
                        trailing: IconButton(
                          tooltip: 'Remove from cart',
                          onPressed: () => _remove(item),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Listed total',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          Text(
                            '₹${total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _checkingOut ? null : () => _checkout(items),
                          child: _checkingOut
                              ? const CircularProgressIndicator()
                              : const Text('Continue · pay in person'),
                        ),
                      ),
                    ],
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
