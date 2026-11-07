import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../repositories/order_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/product_image.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final _orders = OrderRepository();
  bool _updating = false;
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.order.status;
  }

  Future<void> _update(String status) async {
    if (_updating) return;
    setState(() => _updating = true);
    try {
      await _orders.updateStatus(orderId: widget.order.id, status: status);
      if (mounted) {
        setState(() => _status = status);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order marked $status.')),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order could not be updated: $error')),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isSeller = uid == order.sellerId;
    final isBuyer = uid == order.buyerId;
    final actions = _actionsFor(_status, isSeller, isBuyer);

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          SizedBox(
            height: 190,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: ProductImage(
                source: order.productImage,
                iconSize: 70,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            order.productTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          Text(
            '₹${order.price.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 18),
          _detail('Order date', order.createdAtLabel),
          _detail('Seller', order.sellerName),
          _detail('Fulfillment', order.fulfillmentMethod),
          _detail('Meetup / delivery area', order.address),
          _detail('Payment', order.paymentMethod),
          _detail('Status', _status),
          const SizedBox(height: 22),
          const Text(
            'Order progress',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          for (final stage in const [
            'Pending',
            'Confirmed',
            'Ready for pickup',
            'Completed',
          ])
            ListTile(
              leading: CircleAvatar(
                radius: 13,
                backgroundColor: _isStageComplete(_status, stage)
                    ? AppColors.primaryLight
                    : Colors.black12,
                child: Icon(
                  _isStageComplete(_status, stage)
                      ? Icons.check
                      : Icons.circle_outlined,
                  size: 15,
                  color: _isStageComplete(order.status, stage)
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
              title: Text(stage, style: const TextStyle(fontSize: 14)),
              dense: true,
            ),
          if (_status == 'Cancelled')
            const ListTile(
              leading: Icon(Icons.cancel_outlined, color: AppColors.danger),
              title: Text('This order was cancelled.'),
            ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (final action in actions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: action.status == 'Cancelled'
                      ? OutlinedButton(
                          onPressed: _updating
                              ? null
                              : () => _update(action.status),
                          child: Text(action.label),
                        )
                      : ElevatedButton(
                          onPressed: _updating
                              ? null
                              : () => _update(action.status),
                          child: _updating
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(action.label),
                        ),
                ),
              ),
          ],
          const SizedBox(height: 18),
          const Text(
            'Community order requests do not process online payments. Confirm the meetup or delivery details directly with the other participant.',
            style: TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 145,
          child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );

  List<({String label, String status})> _actionsFor(
    String status,
    bool isSeller,
    bool isBuyer,
  ) {
    if (status == 'Pending' && isSeller) {
      return const [
        (label: 'Confirm order request', status: 'Confirmed'),
        (label: 'Decline request', status: 'Cancelled'),
      ];
    }
    if (status == 'Pending' && isBuyer) {
      return const [(label: 'Cancel request', status: 'Cancelled')];
    }
    if (status == 'Confirmed' && isSeller) {
      return const [(label: 'Mark ready for pickup', status: 'Ready for pickup')];
    }
    if (status == 'Ready for pickup' && isSeller) {
      return const [(label: 'Mark completed', status: 'Completed')];
    }
    return const [];
  }

  bool _isStageComplete(String status, String stage) {
    const stages = ['Pending', 'Confirmed', 'Ready for pickup', 'Completed'];
    if (status == 'Cancelled') return stage == 'Pending';
    return stages.indexOf(stage) <= stages.indexOf(status);
  }
}
