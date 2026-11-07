import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  const OrderModel({
    required this.id,
    required this.productId,
    required this.buyerId,
    required this.sellerId,
    required this.productTitle,
    required this.productImage,
    required this.sellerName,
    required this.price,
    required this.status,
    required this.fulfillmentMethod,
    required this.address,
    required this.paymentMethod,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String buyerId;
  final String sellerId;
  final String productTitle;
  final String productImage;
  final String sellerName;
  final double price;
  final String status;
  final String fulfillmentMethod;
  final String address;
  final String paymentMethod;
  final DateTime? createdAt;

  factory OrderModel.fromFirestore(String id, Map<String, dynamic> data) {
    final createdAt = data['createdAt'];
    return OrderModel(
      id: id,
      productId: data['productId'] as String? ?? '',
      buyerId: data['buyerId'] as String? ?? '',
      sellerId: data['sellerId'] as String? ?? '',
      productTitle: data['productTitle'] as String? ?? '',
      productImage: data['productImage'] as String? ?? '',
      sellerName: data['sellerName'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      status: data['status'] as String? ?? 'Pending',
      fulfillmentMethod: data['fulfillmentMethod'] as String? ?? 'Pickup',
      address: data['address'] as String? ?? '',
      paymentMethod: data['paymentMethod'] as String? ?? 'Pay in person',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }

  String get createdAtLabel {
    final date = createdAt;
    if (date == null) return 'Just now';
    return '${date.day}/${date.month}/${date.year}';
  }
}
