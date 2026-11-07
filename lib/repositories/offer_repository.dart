import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/offer.dart';
import '../models/product.dart';

class OfferRepository {
  OfferRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _offers =>
      _firestore.collection('offers');

  Stream<List<OfferModel>> watchOffers(String uid) {
    return _offers
        .where('participantIds', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
          final offers = snapshot.docs
              .map((doc) => OfferModel.fromFirestore(doc.id, doc.data()))
              .toList();
          offers.sort(
            (a, b) =>
                (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                    .compareTo(
                      a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
                    ),
          );
          return offers;
        });
  }

  Future<void> createOffer({
    required Product product,
    required double amount,
    required String message,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in before making an offer.');
    if (user.uid == product.seller.id) {
      throw StateError('You cannot make an offer on your own listing.');
    }
    if (!amount.isFinite || amount <= 0 || amount > product.price) {
      throw ArgumentError(
        'Offer must be greater than zero and no more than the listed price.',
      );
    }
    final trimmedMessage = message.trim();
    if (trimmedMessage.length > 500) {
      throw ArgumentError('Offer messages must be 500 characters or fewer.');
    }

    final offerReference = _offers.doc();
    final productReference = _firestore
        .collection('products')
        .doc(product.id);
    final notificationReference = _firestore
        .collection('users')
        .doc(product.seller.id)
        .collection('notifications')
        .doc();
    await _firestore.runTransaction((transaction) async {
      final productSnapshot = await transaction.get(productReference);
      final listing = productSnapshot.data();
      if (listing == null ||
          listing['status'] != 'Active' ||
          listing['sellerId'] != product.seller.id ||
          listing['price'] != product.price) {
        throw StateError('This listing is no longer available at that price.');
      }

      transaction.set(offerReference, {
        'productId': product.id,
        'buyerId': user.uid,
        'sellerId': product.seller.id,
        'participantIds': [user.uid, product.seller.id],
        'listedPrice': product.price,
        'offeredPrice': amount,
        'message': trimmedMessage,
        'productTitle': product.title,
        'productImage': product.images.isEmpty ? '' : product.images.first,
        'status': 'Pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(notificationReference, {
        'type': 'offer',
        'title': 'New offer',
        'description':
            '₹${amount.toStringAsFixed(0)} offered for ${product.title}',
        'actorId': user.uid,
        'relatedId': offerReference.id,
        'eventId': offerReference.id,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateOfferStatus({
    required String offerId,
    required String status,
  }) async {
    if (status != 'Accepted' && status != 'Rejected') {
      throw ArgumentError.value(status, 'status', 'Unsupported offer status.');
    }
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to update offers.');
    final reference = _offers.doc(offerId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final offer = snapshot.data();
      if (offer == null) throw StateError('This offer no longer exists.');
      final buyerId = offer['buyerId'] as String? ?? '';
      final sellerId = offer['sellerId'] as String? ?? '';
      if (sellerId != user.uid || offer['status'] != 'Pending') {
        throw StateError('Only the seller can respond to a pending offer.');
      }
      final notification = _firestore
          .collection('users')
          .doc(buyerId)
          .collection('notifications')
          .doc();
      transaction.update(reference, {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(notification, {
        'type': 'offer',
        'title': 'Offer $status',
        'description': 'The seller $status your offer for ${offer['productTitle']}.',
        'actorId': user.uid,
        'relatedId': offerId,
        'eventId': offerId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
