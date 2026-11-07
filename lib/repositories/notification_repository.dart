import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/notification_model.dart';

class NotificationRepository {
  NotificationRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> _notifications(String uid) =>
      _firestore.collection('users').doc(uid).collection('notifications');

  Stream<List<NotificationModel>> watchNotifications(String uid) {
    return _notifications(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => NotificationModel.fromFirestore(doc.id, doc.data()),
              )
              .toList(growable: false),
        );
  }

  Future<void> markRead(String notificationId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sign in to update notifications.');
    await _notifications(uid).doc(notificationId).update({'isRead': true});
  }

  Future<void> markAllRead(List<NotificationModel> notifications) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Sign in to update notifications.');
    final unread = notifications
        .where((notification) => !notification.isRead)
        .toList(growable: false);
    for (var start = 0; start < unread.length; start += 450) {
      final batch = _firestore.batch();
      final end = (start + 450).clamp(0, unread.length);
      for (final notification in unread.sublist(start, end)) {
        batch.update(
          _notifications(uid).doc(notification.id),
          {'isRead': true},
        );
      }
      await batch.commit();
    }
  }
}
