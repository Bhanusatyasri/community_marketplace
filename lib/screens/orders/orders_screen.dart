import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../repositories/order_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/product_image.dart';
import 'order_details_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view your orders.')),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: StreamBuilder<List<OrderModel>>(
          stream: OrderRepository().watchOrders(uid),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Could not load orders. Check your connection and Firestore rules.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final orders = snapshot.data ?? const [];
            return TabBarView(
              children: [
                _list(context, orders, const {
                  'Pending',
                  'Confirmed',
                  'Ready for pickup',
                }),
                _list(context, orders, const {'Completed'}),
                _list(context, orders, const {'Cancelled'}),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _list(
    BuildContext context,
    List<OrderModel> orders,
    Set<String> statuses,
  ) {
    final filtered = orders.where((order) => statuses.contains(order.status)).toList();
    if (filtered.isEmpty) {
      return const Center(child: Text('No orders in this section.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final order = filtered[index];
        return Card(
          child: ListTile(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailsScreen(order: order),
              ),
            ),
            leading: SizedBox(
              width: 58,
              height: 58,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: ProductImage(source: order.productImage),
              ),
            ),
            title: Text(
              order.productTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              '₹${order.price.toStringAsFixed(0)} · ${order.createdAtLabel}',
            ),
            trailing: Text(
              order.status,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        );
      },
    );
  }
}
