import 'package:firebase_auth/firebase_auth.dart';

import 'profile_repository.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    ProfileRepository? profiles,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _profiles = profiles ?? ProfileRepository(auth: auth);

  final FirebaseAuth _auth;
  final ProfileRepository _profiles;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get user => _auth.currentUser;

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String location,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase did not return the newly created user.');
    }
    await user.updateDisplayName(name.trim());
    await _profiles.createProfile(
      user: user,
      name: name,
      phone: phone,
      location: location,
    );
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> logout() => _auth.signOut();

  static String messageFor(FirebaseException error) {
    if (error.plugin == 'cloud_firestore') {
      return switch (error.code) {
        'permission-denied' =>
          'Firestore denied this request. Check the project security rules.',
        'unavailable' ||
        'deadline-exceeded' =>
          'Firestore is unavailable. Check your connection and try again.',
        _ => 'Could not save your profile. Please try again.',
      };
    }
    if (error.plugin == 'firebase_storage') {
      return switch (error.code) {
        'bucket-not-found' =>
          'Firebase Storage is not enabled for this project yet.',
        'unauthorized' ||
        'permission-denied' =>
          'Storage denied this upload. Check the Storage security rules.',
        'quota-exceeded' => 'Firebase Storage quota has been exceeded.',
        'upload-cleanup-failed' =>
          'The upload failed and some temporary images could not be removed.',
        'object-not-found' => 'A Firebase Storage image could not be found.',
        _ => 'Could not upload or remove the listing images. Please try again.',
      };
    }

    return switch (error.code) {
      'email-already-in-use' => 'An account already exists for this email.',
      'invalid-email' => 'Enter a valid email address.',
      'invalid-credential' ||
      'user-not-found' ||
      'wrong-password' =>
        'Email or password is incorrect.',
      'weak-password' => 'Choose a stronger password.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      'network-request-failed' =>
        'Could not connect. Check your internet connection and try again.',
      'operation-not-allowed' =>
        'Email/Password sign-in is disabled in Firebase Console.',
      _ => 'Authentication failed. Please try again.',
    };
  }
}
