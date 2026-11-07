import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/order.dart';

class OrderRepository {
  OrderRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<List<OrderModel>> watchOrders(String uid) {
    return _orders
        .where('participantIds', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
          final orders = snapshot.docs
              .map((doc) => OrderModel.fromFirestore(doc.id, doc.data()))
              .toList();
          orders.sort(
            (a, b) =>
                (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                    .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
          );
          return orders;
        });
  }

  Future<void> updateStatus({
    required String orderId,
    required String status,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to update this order.');
    const allowed = {
      'Confirmed',
      'Ready for pickup',
      'Completed',
      'Cancelled',
    };
    if (!allowed.contains(status)) {
      throw ArgumentError.value(status, 'status', 'Unsupported order status.');
    }
    final orderReference = _orders.doc(orderId);
    await _firestore.runTransaction((transaction) async {
      final orderSnapshot = await transaction.get(orderReference);
      final order = orderSnapshot.data();
      if (order == null) throw StateError('This order no longer exists.');
      final buyerId = order['buyerId'] as String? ?? '';
      final sellerId = order['sellerId'] as String? ?? '';
      if (user.uid != buyerId && user.uid != sellerId) {
        throw StateError('You are not a participant in this order.');
      }
      final productReference = _firestore
          .collection('products')
          .doc(order['productId'] as String? ?? '');
      final shouldSetListingStatus =
          status == 'Confirmed' || status == 'Completed';
      final productSnapshot = shouldSetListingStatus
          ? await transaction.get(productReference)
          : null;

      if (shouldSetListingStatus) {
        final product = productSnapshot?.data();
        final expectedStatus = status == 'Confirmed' ? 'Active' : 'Inactive';
        final targetStatus = status == 'Confirmed' ? 'Inactive' : 'Sold';
        if (product == null ||
            product['sellerId'] != order['sellerId'] ||
            product['status'] != expectedStatus) {
          throw StateError(
            'The listing is no longer available for this order update.',
          );
        }
        transaction.update(productReference, {
          'status': targetStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      transaction.update(orderReference, {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final recipientId = user.uid == buyerId ? sellerId : buyerId;
      final notification = _firestore
          .collection('users')
          .doc(recipientId)
          .collection('notifications')
          .doc();
      transaction.set(notification, {
        'type': 'order',
        'title': 'Order $status',
        'description':
            'The other participant marked ${order['productTitle']} as $status.',
        'actorId': user.uid,
        'relatedId': orderId,
        'eventId': orderId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
