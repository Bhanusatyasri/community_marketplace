import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  const CartItem({
    required this.id,
    required this.productId,
    required this.sellerId,
    required this.sellerName,
    required this.productTitle,
    required this.productImage,
    required this.price,
    required this.addedAt,
  });

  final String id;
  final String productId;
  final String sellerId;
  final String sellerName;
  final String productTitle;
  final String productImage;
  final double price;
  final DateTime? addedAt;

  factory CartItem.fromFirestore(String id, Map<String, dynamic> data) {
    final addedAt = data['addedAt'];
    return CartItem(
      id: id,
      productId: data['productId'] as String? ?? id,
      sellerId: data['sellerId'] as String? ?? '',
      sellerName: data['sellerName'] as String? ?? '',
      productTitle: data['productTitle'] as String? ?? '',
      productImage: data['productImage'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      addedAt: addedAt is Timestamp ? addedAt.toDate() : null,
    );
  }
}
