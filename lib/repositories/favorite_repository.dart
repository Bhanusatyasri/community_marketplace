import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';

class FavoriteRepository {
  FavoriteRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _favorites(String uid) =>
      _firestore.collection('users').doc(uid).collection('favorites');

  Stream<QuerySnapshot<Map<String, dynamic>>> watchFavoriteDocuments(
    String uid,
  ) {
    return _favorites(uid).snapshots();
  }

  Stream<List<Product>> watchFavorites(String uid) {
    return watchFavoriteDocuments(uid).asyncMap((favorites) async {
      final documents = await Future.wait(
        favorites.docs.map((favorite) {
          return _firestore.collection('products').doc(favorite.id).get();
        }),
      );
      final products = <Product>[];
      for (final document in documents) {
        final data = document.data();
        if (document.exists && data != null && data['status'] == 'Active') {
          products.add(Product.fromFirestore(document.id, data)..favorite = true);
        }
      }
      products.sort(
        (a, b) => (b.createdAtDate ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(
              a.createdAtDate ?? DateTime.fromMillisecondsSinceEpoch(0),
            ),
      );
      return products;
    });
  }

  Future<void> setFavorite({
    required String uid,
    required String productId,
    required bool selected,
  }) async {
    final reference = _favorites(uid).doc(productId);
    if (selected) {
      await reference.set({'createdAt': FieldValue.serverTimestamp()});
    } else {
      await reference.delete();
    }
  }
}
