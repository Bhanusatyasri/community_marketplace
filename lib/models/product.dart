import 'package:cloud_firestore/cloud_firestore.dart';

import 'user.dart';

class Product {
  final String id;
  final String title;
  final String description;
  final String category;
  final String condition;
  final String location;
  final String status;
  final String createdAt;
  final DateTime? createdAtDate;
  final double price;
  final double distance;
  final List<String> images;
  final UserModel seller;
  final int views;
  bool favorite;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.condition,
    required this.images,
    required this.seller,
    required this.location,
    required this.distance,
    required this.views,
    required this.status,
    required this.createdAt,
    this.createdAtDate,
    this.favorite = false,
  });

  factory Product.fromFirestore(String id, Map<String, dynamic> data) {
    final sellerId = data['sellerId'] as String? ?? '';
    final rawImages = data['imageUrls'];
    final createdAt = data['createdAt'];

    return Product(
      id: id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      category: data['category'] as String? ?? '',
      condition: data['condition'] as String? ?? '',
      images: rawImages is List
          ? rawImages.whereType<String>().toList(growable: false)
          : const [],
      seller: UserModel(
        id: sellerId,
        name: data['sellerName'] as String? ?? '',
        email: '',
        phone: '',
        profileImage: data['sellerProfileImage'] as String? ?? '',
        location: data['sellerLocation'] as String? ?? '',
        rating: (data['sellerRating'] as num?)?.toDouble() ?? 0,
        reviewCount: data['sellerReviewCount'] as int? ?? 0,
      ),
      location: data['location'] as String? ?? '',
      distance: 0,
      views: data['views'] as int? ?? 0,
      status: data['status'] as String? ?? 'Active',
      createdAt: createdAt is Timestamp
          ? _formatDate(createdAt.toDate())
          : createdAt as String? ?? 'Recently',
      createdAtDate: createdAt is Timestamp ? createdAt.toDate() : null,
      favorite: false,
    );
  }

  static String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}
