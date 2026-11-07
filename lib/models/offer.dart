import 'package:cloud_firestore/cloud_firestore.dart';

class OfferModel {
  const OfferModel({
    required this.id,
    required this.productId,
    required this.buyerId,
    required this.sellerId,
    required this.listedPrice,
    required this.offeredPrice,
    required this.message,
    required this.status,
    required this.productTitle,
    required this.productImage,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String buyerId;
  final String sellerId;
  final double listedPrice;
  final double offeredPrice;
  final String message;
  final String status;
  final String productTitle;
  final String productImage;
  final DateTime? createdAt;

  factory OfferModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final createdAt = data['createdAt'];
    return OfferModel(
      id: id,
      productId: data['productId'] as String? ?? '',
      buyerId: data['buyerId'] as String? ?? '',
      sellerId: data['sellerId'] as String? ?? '',
      listedPrice: (data['listedPrice'] as num?)?.toDouble() ?? 0,
      offeredPrice: (data['offeredPrice'] as num?)?.toDouble() ?? 0,
      message: data['message'] as String? ?? '',
      status: data['status'] as String? ?? 'Pending',
      productTitle: data['productTitle'] as String? ?? '',
      productImage: data['productImage'] as String? ?? '',
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }
}
