import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user.dart';

class ProfileRepository {
  ProfileRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  Stream<UserModel?> watchProfile(String uid) {
    return _users.doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      return data == null ? null : UserModel.fromFirestore(snapshot.id, data);
    });
  }

  Future<UserModel?> getProfile(String uid) async {
    final snapshot = await _users.doc(uid).get();
    final data = snapshot.data();
    return data == null ? null : UserModel.fromFirestore(snapshot.id, data);
  }

  Future<void> createProfile({
    required User user,
    required String phone,
    required String location,
    String? name,
  }) async {
    final reference = _users.doc(user.uid);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (snapshot.exists) return;

      transaction.set(reference, {
        'name': name?.trim().isNotEmpty == true
            ? name!.trim()
            : user.displayName ?? '',
        'email': user.email ?? '',
        'phone': phone.trim(),
        'location': location.trim(),
        'profileImage': user.photoURL ?? '',
        'rating': 0,
        'reviewCount': 0,
        'online': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> ensureCurrentProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await createProfile(user: user, phone: '', location: '');
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    required String location,
    String? profileImage,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('A signed-in user is required to update a profile.');
    }

    final updates = <String, dynamic>{
      'name': name.trim(),
      'email': user.email ?? '',
      'phone': phone.trim(),
      'location': location.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (profileImage != null) updates['profileImage'] = profileImage;
    await _users.doc(user.uid).set(updates, SetOptions(merge: true));
    await user.updateDisplayName(name.trim());
  }
}
