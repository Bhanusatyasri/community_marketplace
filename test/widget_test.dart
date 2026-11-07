import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:community_marketplace/data/mock_data.dart';
import 'package:community_marketplace/screens/auth/welcome_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:community_marketplace/models/product.dart';
import 'package:community_marketplace/models/user.dart';
import 'package:community_marketplace/models/conversation.dart';
import 'package:community_marketplace/models/message.dart';
import 'package:community_marketplace/models/offer.dart';
import 'package:community_marketplace/models/cart_item.dart';
import 'package:community_marketplace/models/order.dart';
import 'package:community_marketplace/models/notification_model.dart';
import 'package:community_marketplace/widgets/product_image.dart';

void main() {
  test('sample marketplace listings cover each category with unique assets',
      () async {
    final imagePaths = <String>{};

    expect(products, hasLength(28));
    for (final category in categories) {
      expect(
        products.where((product) => product.category == category.name).length,
        greaterThanOrEqualTo(2),
        reason: '${category.name} should have sample listings.',
      );
    }

    for (final product in products) {
      expect(product.title, isNotEmpty);
      expect(product.description, isNotEmpty);
      expect(product.price, greaterThan(0));
      expect(
        product.location,
        anyOf(contains('Hyderabad'), contains('Telangana')),
      );
      expect(product.condition, anyOf('New', 'Used'));
      expect(product.status, 'Active');
      expect(product.images, hasLength(1));
      expect(imagePaths.add(product.images.single), isTrue);
      await rootBundle.load(product.images.single);
    }
  });

  testWidgets('Welcome screen loads', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: WelcomeScreen()),
    );
    expect(find.text('Community\nMarketplace'), findsOneWidget);
  });

  testWidgets('ProductImage renders inline Firestore photo data',
      (tester) async {
    const imageData =
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/l1sAAAAASUVORK5CYII=';
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 20,
          height: 20,
          child: ProductImage(source: imageData),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<MemoryImage>());
  });

  test('UserModel parses a Firestore profile document', () {
    final user = UserModel.fromFirestore('user-123', {
      'name': 'Alex Morgan',
      'email': 'alex@example.com',
      'phone': '1234567890',
      'location': 'Hyderabad',
      'profileImage': '',
      'rating': 4.5,
      'reviewCount': 3,
      'online': true,
    });

    expect(user.id, 'user-123');
    expect(user.name, 'Alex Morgan');
    expect(user.rating, 4.5);
    expect(user.reviewCount, 3);
    expect(user.online, isTrue);
  });

  test('Product parses a Firestore listing document', () {
    final createdAt = Timestamp.fromDate(DateTime(2026, 10, 10));
    final product = Product.fromFirestore('listing-123', {
      'sellerId': 'user-123',
      'sellerName': 'Alex Morgan',
      'sellerLocation': 'Hyderabad',
      'sellerProfileImage': '',
      'sellerRating': 4.5,
      'sellerReviewCount': 3,
      'title': 'Desk lamp',
      'description': 'A working desk lamp.',
      'price': 450,
      'category': 'Home & Garden',
      'condition': 'Good',
      'location': 'Hyderabad',
      'imageUrls': <String>[],
      'status': 'Active',
      'views': 2,
      'createdAt': createdAt,
    });

    expect(product.id, 'listing-123');
    expect(product.seller.id, 'user-123');
    expect(product.title, 'Desk lamp');
    expect(product.price, 450);
    expect(product.createdAtDate, DateTime(2026, 10, 10));
  });

  test('Conversation and message models parse Firestore documents', () {
    final sentAt = Timestamp.fromDate(DateTime(2026, 10, 10, 14, 5));
    final conversation = ConversationModel.fromFirestore('chat-123', {
      'productId': 'listing-123',
      'buyerId': 'buyer-1',
      'sellerId': 'seller-1',
      'buyerName': 'Buyer',
      'sellerName': 'Seller',
      'buyerAvatar': '',
      'sellerAvatar': '',
      'productTitle': 'Desk lamp',
      'productPrice': 450,
      'productImage': '',
      'lastMessage': 'Is this available?',
      'lastMessageAt': sentAt,
    });
    final message = MessageModel.fromFirestore('message-123', {
      'senderId': 'buyer-1',
      'receiverId': 'seller-1',
      'text': 'Is this available?',
      'createdAt': sentAt,
    });

    expect(conversation.partnerName('seller-1'), 'Buyer');
    expect(conversation.partnerName('buyer-1'), 'Seller');
    expect(conversation.toProduct().title, 'Desk lamp');
    expect(message.senderId, 'buyer-1');
    expect(message.timestamp, '2:05 PM');
  });

  test('OfferModel parses a Firestore offer document', () {
    final createdAt = Timestamp.fromDate(DateTime(2026, 10, 10));
    final offer = OfferModel.fromFirestore('offer-123', {
      'productId': 'listing-123',
      'buyerId': 'buyer-1',
      'sellerId': 'seller-1',
      'listedPrice': 1000,
      'offeredPrice': 850,
      'message': 'Can you accept this price?',
      'status': 'Pending',
      'productTitle': 'Desk lamp',
      'productImage': '',
      'createdAt': createdAt,
    });

    expect(offer.id, 'offer-123');
    expect(offer.buyerId, 'buyer-1');
    expect(offer.sellerId, 'seller-1');
    expect(offer.offeredPrice, 850);
    expect(offer.status, 'Pending');
    expect(offer.createdAt, DateTime(2026, 10, 10));
  });

  test('CartItem and OrderModel parse Firestore documents', () {
    final createdAt = Timestamp.fromDate(DateTime(2026, 10, 10));
    final cartItem = CartItem.fromFirestore('listing-123', {
      'productId': 'listing-123',
      'sellerId': 'seller-1',
      'sellerName': 'Seller',
      'productTitle': 'Desk lamp',
      'productImage': '',
      'price': 450,
      'addedAt': createdAt,
    });
    final order = OrderModel.fromFirestore('order-123', {
      'productId': 'listing-123',
      'buyerId': 'buyer-1',
      'sellerId': 'seller-1',
      'productTitle': 'Desk lamp',
      'productImage': '',
      'sellerName': 'Seller',
      'price': 450,
      'status': 'Pending',
      'fulfillmentMethod': 'Pickup',
      'address': 'Hyderabad',
      'paymentMethod': 'Pay in person',
      'createdAt': createdAt,
    });

    expect(cartItem.productId, 'listing-123');
    expect(cartItem.price, 450);
    expect(cartItem.addedAt, DateTime(2026, 10, 10));
    expect(order.id, 'order-123');
    expect(order.status, 'Pending');
    expect(order.paymentMethod, 'Pay in person');
    expect(order.createdAtLabel, '10/10/2026');
  });

  test('NotificationModel parses an unread Firestore notification', () {
    final createdAt = Timestamp.fromDate(DateTime(2026, 10, 10, 9, 30));
    final notification = NotificationModel.fromFirestore('notice-123', {
      'title': 'New message',
      'description': 'Are you still interested?',
      'type': 'message',
      'createdAt': createdAt,
      'isRead': false,
      'relatedId': 'conversation-123',
    });

    expect(notification.id, 'notice-123');
    expect(notification.title, 'New message');
    expect(notification.type, 'message');
    expect(notification.isRead, isFalse);
    expect(notification.relatedId, 'conversation-123');
  });
}
