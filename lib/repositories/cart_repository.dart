import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

class CartRepository {
  CartRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _cart(String uid) =>
      _firestore.collection('users').doc(uid).collection('cartItems');

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  String? get currentUserId => _auth.currentUser?.uid;

  Stream<List<CartItem>> watchCart(String uid) {
    return _cart(uid).snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => CartItem.fromFirestore(doc.id, doc.data()))
          .toList();
      items.sort(
        (a, b) => (b.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );
      return items;
    });
  }

  Future<void> add(Product product) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to add items to your cart.');
    if (product.seller.id == user.uid) {
      throw StateError('You cannot add your own listing to your cart.');
    }
    await _cart(user.uid).doc(product.id).set({
      'productId': product.id,
      'sellerId': product.seller.id,
      'sellerName': product.seller.name,
      'productTitle': product.title,
      'productImage': product.images.isEmpty ? '' : product.images.first,
      'price': product.price,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> remove(String productId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sign in to update your cart.');
    await _cart(uid).doc(productId).delete();
  }

  Future<List<String>> checkout({
    required List<String> productIds,
    required String fulfillmentMethod,
    required String address,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in before placing an order.');
    if (productIds.isEmpty || productIds.length > 10) {
      throw ArgumentError('Checkout supports 1 to 10 unique cart items.');
    }
    if (productIds.toSet().length != productIds.length) {
      throw ArgumentError('The cart contains duplicate listings.');
    }
    if (fulfillmentMethod != 'Pickup' && fulfillmentMethod != 'Delivery') {
      throw ArgumentError('Choose pickup or delivery.');
    }
    final trimmedAddress = address.trim();
    if (trimmedAddress.isEmpty || trimmedAddress.length > 300) {
      throw ArgumentError(
          'Enter a meetup or delivery location (up to 300 characters).');
    }

    final cartRefs = productIds.map((id) => _cart(user.uid).doc(id)).toList();
    final productRefs = productIds.map(_products.doc).toList();
    final orderRefs = productIds.map((_) => _orders.doc()).toList();

    await _firestore.runTransaction((transaction) async {
      final cartSnapshots = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final reference in cartRefs) {
        cartSnapshots.add(await transaction.get(reference));
      }
      final productSnapshots = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final reference in productRefs) {
        productSnapshots.add(await transaction.get(reference));
      }

      final orderData = <Map<String, dynamic>>[];
      for (var index = 0; index < productIds.length; index++) {
        final cartData = cartSnapshots[index].data();
        final productData = productSnapshots[index].data();
        if (cartData == null || productData == null) {
          throw StateError(
              'A cart item or its listing is no longer available.');
        }
        if (productData['status'] != 'Active') {
          throw StateError(
            '"${productData['title'] ?? 'This listing'}" is no longer available.',
          );
        }
        if (productData['sellerId'] == user.uid) {
          throw StateError('You cannot buy your own listing.');
        }
        if (cartData['sellerId'] != productData['sellerId'] ||
            cartData['price'] != productData['price']) {
          throw StateError(
            '"${productData['title'] ?? 'A listing'}" changed since it was added. Remove it and add it again.',
          );
        }
        orderData.add({
          'productId': productIds[index],
          'buyerId': user.uid,
          'sellerId': productData['sellerId'],
          'participantIds': [user.uid, productData['sellerId']],
          'productTitle': productData['title'],
          'productImage': productData['imageUrls'] is List &&
                  (productData['imageUrls'] as List).isNotEmpty
              ? (productData['imageUrls'] as List).first
              : '',
          'sellerName': productData['sellerName'],
          'price': productData['price'],
          'status': 'Pending',
          'fulfillmentMethod': fulfillmentMethod,
          'address': trimmedAddress,
          'paymentMethod': 'Pay in person',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      for (var index = 0; index < productIds.length; index++) {
        final sellerId = orderData[index]['sellerId'] as String;
        final notification = _firestore
            .collection('users')
            .doc(sellerId)
            .collection('notifications')
            .doc();
        transaction.set(orderRefs[index], orderData[index]);
        transaction.delete(cartRefs[index]);
        transaction.set(notification, {
          'type': 'order',
          'title': 'New order request',
          'description':
              'A buyer requested ${orderData[index]['productTitle']}.',
          'actorId': user.uid,
          'relatedId': orderRefs[index].id,
          'eventId': orderRefs[index].id,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });

    return orderRefs.map((reference) => reference.id).toList(growable: false);
  }
}
