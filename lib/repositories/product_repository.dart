import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

import '../models/product.dart';
import 'favorite_repository.dart';
import 'profile_repository.dart';
import 'storage_repository.dart';

class ProductRepository {
  ProductRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    ProfileRepository? profiles,
    StorageRepository? storage,
    FavoriteRepository? favorites,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _profiles =
            profiles ?? ProfileRepository(firestore: firestore, auth: auth),
        _storage = storage ?? StorageRepository(),
        _favorites = favorites ?? FavoriteRepository(firestore: firestore);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final ProfileRepository _profiles;
  final StorageRepository _storage;
  final FavoriteRepository _favorites;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');

  String? get currentUserId => _auth.currentUser?.uid;

  void _validateProductFields({
    required String title,
    required String description,
    required double price,
    required String category,
    required String condition,
    required String location,
  }) {
    if (title.trim().isEmpty || title.trim().length > 120) {
      throw ArgumentError('Title must contain 1 to 120 characters.');
    }
    if (description.trim().isEmpty || description.trim().length > 4000) {
      throw ArgumentError('Description must contain 1 to 4,000 characters.');
    }
    if (!price.isFinite || price <= 0 || price > 100000000) {
      throw ArgumentError(
        'Price must be greater than zero and at most ₹10 crore.',
      );
    }
    if (category.trim().isEmpty || category.trim().length > 60) {
      throw ArgumentError('Choose a valid category.');
    }
    if (condition.trim().isEmpty || condition.trim().length > 40) {
      throw ArgumentError('Choose a valid item condition.');
    }
    if (location.trim().length > 120) {
      throw ArgumentError('Location must be no more than 120 characters.');
    }
  }

  Future<void> setFavorite({
    required String productId,
    required bool selected,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in to save marketplace listings.');
    }
    await _favorites.setFavorite(
      uid: user.uid,
      productId: productId,
      selected: selected,
    );
  }

  Future<void> recordView(String productId) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Sign in to view marketplace listings.');
    final reference = _products.doc(productId);
    final snapshot = await reference.get();
    if (!snapshot.exists) {
      throw StateError('This listing is no longer available.');
    }
    if (snapshot.data()?['sellerId'] == user.uid) {
      return;
    }
    await reference.update({'views': FieldValue.increment(1)});
  }

  Stream<Map<String, int>> watchCategoryCounts() {
    if (_auth.currentUser == null) {
      return Stream.error(
        StateError('Sign in to browse marketplace categories.'),
      );
    }
    return _products.where('status', isEqualTo: 'Active').snapshots().map((
      snapshot,
    ) {
      final counts = <String, int>{};
      for (final document in snapshot.docs) {
        final category = document.data()['category'];
        if (category is String && category.isNotEmpty) {
          counts.update(category, (total) => total + 1, ifAbsent: () => 1);
        }
      }
      return counts;
    });
  }

  Stream<List<Product>> watchProducts({String? category}) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.error(
          StateError('Sign in to browse marketplace listings.'));
    }
    return _combineProductsAndFavorites(
      _products.where('status', isEqualTo: 'Active').snapshots(),
      _favorites.watchFavoriteDocuments(user.uid),
      category: category,
    );
  }

  Stream<List<Product>> watchFavorites(String uid) =>
      _favorites.watchFavorites(uid);

  Stream<List<Product>> watchMyListings(String uid) {
    return _products
        .where('sellerId', isEqualTo: uid)
        .snapshots()
        .map(_productsFromSnapshot);
  }

  Stream<List<Product>> watchSellerListings(String uid) {
    return _products.where('sellerId', isEqualTo: uid).snapshots().map(
          (snapshot) => _productsFromSnapshot(snapshot)
              .where((product) => product.status == 'Active')
              .toList(growable: false),
        );
  }

  Future<String> createProduct({
    required String title,
    required String description,
    required double price,
    required String category,
    required String condition,
    required String location,
    List<XFile> images = const [],
    void Function(double progress)? onUploadProgress,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in before creating a listing.');
    }
    _validateProductFields(
      title: title,
      description: description,
      price: price,
      category: category,
      condition: condition,
      location: location,
    );

    final profile = await _profiles.getProfile(user.uid);
    if (profile == null) {
      throw StateError('Your profile is missing. Sign out and sign in again.');
    }

    if (images.length > 5) {
      throw ArgumentError('Choose no more than five product images.');
    }

    final document = _products.doc();
    final imageUrls = <String>[];
    var totalEncodedBytes = 0;
    for (final image in images) {
      final bytes = await image.readAsBytes();
      if (bytes.isEmpty || bytes.length > 600 * 1024) {
        throw ArgumentError(
          'Each photo must be no larger than 600 KB when saving on the free plan.',
        );
      }
      final extension = image.name.split('.').last.toLowerCase();
      final contentType = switch (extension) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => throw ArgumentError('Use JPEG, PNG, or WebP images.'),
      };
      final dataUrl = 'data:$contentType;base64,${base64Encode(bytes)}';
      totalEncodedBytes += utf8.encode(dataUrl).length;
      if (totalEncodedBytes > 850 * 1024) {
        throw ArgumentError(
          'The combined photos for one listing must be smaller than 850 KB.',
        );
      }
      imageUrls.add(dataUrl);
      onUploadProgress?.call(imageUrls.length / images.length);
    }

    await document.set({
      'sellerId': user.uid,
      'sellerName': profile.name,
      'sellerLocation': profile.location,
      'sellerProfileImage': profile.profileImage,
      'sellerRating': profile.rating,
      'sellerReviewCount': profile.reviewCount,
      'title': title.trim(),
      'description': description.trim(),
      'price': price,
      'category': category.trim(),
      'condition': condition.trim(),
      'location': location.trim(),
      'imageUrls': imageUrls,
      'status': 'Active',
      'views': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return document.id;
  }

  Future<void> updateProduct({
    required String productId,
    required String title,
    required String description,
    required double price,
    required String category,
    required String condition,
    required String location,
  }) async {
    if (_auth.currentUser == null) {
      throw StateError('Sign in before editing a listing.');
    }
    _validateProductFields(
      title: title,
      description: description,
      price: price,
      category: category,
      condition: condition,
      location: location,
    );

    await _products.doc(productId).update({
      'title': title.trim(),
      'description': description.trim(),
      'price': price,
      'category': category.trim(),
      'condition': condition.trim(),
      'location': location.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateStatus(String productId, String status) {
    if (status != 'Active' && status != 'Sold' && status != 'Inactive') {
      throw ArgumentError.value(
          status, 'status', 'Unsupported listing status.');
    }
    return _products.doc(productId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteProduct(String productId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in before deleting a listing.');
    }
    final reference = _products.doc(productId);
    final snapshot = await reference.get();
    final imageUrls = snapshot.data()?['imageUrls'];
    await reference.delete();
    final hasStorageImages = imageUrls is List &&
        imageUrls.whereType<String>().any((image) {
          final scheme = Uri.tryParse(image)?.scheme;
          return scheme == 'http' || scheme == 'https';
        });
    if (hasStorageImages) {
      await _storage.deleteProductImages(uid: user.uid, productId: productId);
    }
  }

  List<Product> _productsFromSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final products = snapshot.docs
        .map((document) => Product.fromFirestore(document.id, document.data()))
        .toList();
    products.sort(
      (a, b) => (b.createdAtDate ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.createdAtDate ?? DateTime.fromMillisecondsSinceEpoch(0)),
    );
    return products;
  }

  Stream<List<Product>> _combineProductsAndFavorites(
      Stream<QuerySnapshot<Map<String, dynamic>>> productSnapshots,
      Stream<QuerySnapshot<Map<String, dynamic>>> favoriteSnapshots,
      {String? category}) {
    return Stream<List<Product>>.multi((controller) {
      QuerySnapshot<Map<String, dynamic>>? latestProducts;
      Set<String> favoriteIds = {};
      var receivedProducts = false;
      var receivedFavorites = false;

      void emitIfReady() {
        if (!receivedProducts || !receivedFavorites) return;
        final products = _productsFromSnapshot(latestProducts!).where(
          (product) => category == null || product.category == category,
        );
        controller.add(
          products
              .map(
                (product) =>
                    product..favorite = favoriteIds.contains(product.id),
              )
              .toList(growable: false),
        );
      }

      final productSubscription = productSnapshots.listen(
        (snapshot) {
          latestProducts = snapshot;
          receivedProducts = true;
          emitIfReady();
        },
        onError: (Object error, StackTrace stackTrace) {
          controller.addError(error, stackTrace);
        },
      );
      final favoritesSubscription = favoriteSnapshots.listen(
        (snapshot) {
          favoriteIds = snapshot.docs.map((document) => document.id).toSet();
          receivedFavorites = true;
          emitIfReady();
        },
        onError: (Object error, StackTrace stackTrace) {
          controller.addError(error, stackTrace);
        },
      );

      controller.onCancel = () async {
        await productSubscription.cancel();
        await favoritesSubscription.cancel();
      };
    });
  }
}
