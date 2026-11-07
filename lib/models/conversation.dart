import 'package:cloud_firestore/cloud_firestore.dart';

import 'product.dart';
import 'user.dart';

class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.productId,
    required this.buyerId,
    required this.sellerId,
    required this.buyerName,
    required this.sellerName,
    required this.buyerAvatar,
    required this.sellerAvatar,
    required this.productTitle,
    required this.productPrice,
    required this.productImage,
    required this.lastMessage,
    required this.lastMessageAt,
  });

  final String id;
  final String productId;
  final String buyerId;
  final String sellerId;
  final String buyerName;
  final String sellerName;
  final String buyerAvatar;
  final String sellerAvatar;
  final String productTitle;
  final double productPrice;
  final String productImage;
  final String lastMessage;
  final DateTime? lastMessageAt;

  String partnerName(String uid) => uid == sellerId ? buyerName : sellerName;

  String partnerAvatar(String uid) =>
      uid == sellerId ? buyerAvatar : sellerAvatar;

  factory ConversationModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final lastMessageAt = data['lastMessageAt'];
    return ConversationModel(
      id: id,
      productId: data['productId'] as String? ?? '',
      buyerId: data['buyerId'] as String? ?? '',
      sellerId: data['sellerId'] as String? ?? '',
      buyerName: data['buyerName'] as String? ?? 'Buyer',
      sellerName: data['sellerName'] as String? ?? 'Seller',
      buyerAvatar: data['buyerAvatar'] as String? ?? '',
      sellerAvatar: data['sellerAvatar'] as String? ?? '',
      productTitle: data['productTitle'] as String? ?? '',
      productPrice: (data['productPrice'] as num?)?.toDouble() ?? 0,
      productImage: data['productImage'] as String? ?? '',
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageAt: lastMessageAt is Timestamp
          ? lastMessageAt.toDate()
          : null,
    );
  }

  Product toProduct() {
    return Product(
      id: productId,
      title: productTitle,
      description: '',
      price: productPrice,
      category: '',
      condition: '',
      images: productImage.isEmpty ? const [] : [productImage],
      seller: UserModel(
        id: sellerId,
        name: sellerName,
        email: '',
        phone: '',
        profileImage: sellerAvatar,
        location: '',
        rating: 0,
        reviewCount: 0,
      ),
      location: '',
      distance: 0,
      views: 0,
      status: 'Active',
      createdAt: '',
    );
  }
}
