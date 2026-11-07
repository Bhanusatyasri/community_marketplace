import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/conversation.dart';
import '../models/message.dart';
import '../models/product.dart';
import 'profile_repository.dart';

class MessageRepository {
  MessageRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    ProfileRepository? profiles,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _profiles =
           profiles ?? ProfileRepository(firestore: firestore, auth: auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final ProfileRepository _profiles;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _firestore.collection('conversations');

  String? get currentUserId => _auth.currentUser?.uid;

  Future<ConversationModel> openConversation(Product product) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in before contacting a seller.');
    }
    if (product.seller.id.isEmpty) {
      throw StateError('This listing does not have a valid seller.');
    }
    if (user.uid == product.seller.id) {
      throw StateError('You cannot start a chat with yourself.');
    }

    final buyer = await _profiles.getProfile(user.uid);
    if (buyer == null) {
      throw StateError('Your profile is missing. Sign out and sign in again.');
    }
    final participants = [user.uid, product.seller.id]..sort();
    final conversationId = '${product.id}_${participants.join('_')}';
    final reference = _conversations.doc(conversationId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (snapshot.exists) return;

      transaction.set(reference, {
        'productId': product.id,
        'buyerId': user.uid,
        'sellerId': product.seller.id,
        'participantIds': [user.uid, product.seller.id],
        'buyerName': buyer.name,
        'sellerName': product.seller.name,
        'buyerAvatar': buyer.profileImage,
        'sellerAvatar': product.seller.profileImage,
        'productTitle': product.title,
        'productPrice': product.price,
        'productImage': product.images.isEmpty ? '' : product.images.first,
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    final snapshot = await reference.get();
    final data = snapshot.data();
    if (data == null) {
      throw StateError('The conversation could not be opened.');
    }
    return ConversationModel.fromFirestore(snapshot.id, data);
  }

  Stream<List<ConversationModel>> watchConversations(String uid) {
    return _conversations
        .where('participantIds', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
          final conversations = snapshot.docs
              .map(
                (document) =>
                    ConversationModel.fromFirestore(document.id, document.data()),
              )
              .toList();
          conversations.sort(
            (a, b) =>
                (b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                    .compareTo(
                      a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0),
                    ),
          );
          return conversations;
        });
  }

  Stream<List<MessageModel>> watchMessages(String conversationId) {
    return _conversations
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) =>
                    MessageModel.fromFirestore(document.id, document.data()),
              )
              .toList(growable: false),
        );
  }

  Future<void> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in before sending a message.');
    }
    final messageText = text.trim();
    if (messageText.isEmpty || messageText.length > 1000) {
      throw ArgumentError('Messages must contain 1 to 1,000 characters.');
    }

    final conversation = _conversations.doc(conversationId);
    final message = conversation.collection('messages').doc();
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(conversation);
      final data = snapshot.data();
      final participants = data?['participantIds'];
      if (data == null ||
          participants is! List ||
          !participants.contains(user.uid)) {
        throw StateError('You are not a participant in this conversation.');
      }

      final buyerId = data['buyerId'] as String? ?? '';
      final sellerId = data['sellerId'] as String? ?? '';
      final receiverId = user.uid == buyerId ? sellerId : buyerId;
      if (receiverId.isEmpty || receiverId == user.uid) {
        throw StateError('The conversation participants are invalid.');
      }
      final notification = _firestore
          .collection('users')
          .doc(receiverId)
          .collection('notifications')
          .doc();

      transaction.set(message, {
        'senderId': user.uid,
        'receiverId': receiverId,
        'text': messageText,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(conversation, {
        'lastMessage': messageText,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(notification, {
        'type': 'message',
        'title': 'New message',
        'description': messageText.length <= 120
            ? messageText
            : '${messageText.substring(0, 117)}...',
        'actorId': user.uid,
        'relatedId': conversationId,
        'eventId': message.id,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
