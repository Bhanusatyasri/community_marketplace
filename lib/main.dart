import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'theme/app_theme.dart';
import 'screens/auth/auth_gate.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final platform = defaultTargetPlatform;
  const useFirebaseEmulators = bool.fromEnvironment(
    'USE_FIREBASE_EMULATORS',
  );
  const emulatorProjectId = 'demo-community-marketplace';
  final firebaseSupported = kIsWeb ||
      platform == TargetPlatform.android ||
      platform == TargetPlatform.iOS ||
      platform == TargetPlatform.macOS;
  if (firebaseSupported) {
    await Firebase.initializeApp(
      options: useFirebaseEmulators
          ? DefaultFirebaseOptions.currentPlatform.copyWith(
              projectId: emulatorProjectId,
            )
          : DefaultFirebaseOptions.currentPlatform,
    );
    if (useFirebaseEmulators) {
      FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
      FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
      FirebaseStorage.instance.useStorageEmulator('127.0.0.1', 9199);
    }
  }
  runApp(CommunityMarketplaceApp(firebaseSupported: firebaseSupported));
}

class CommunityMarketplaceApp extends StatelessWidget {
  const CommunityMarketplaceApp({
    super.key,
    required this.firebaseSupported,
  });

  final bool firebaseSupported;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Community Marketplace',
        theme: AppTheme.light(),
        home: AuthGate(firebaseSupported: firebaseSupported),
      );
}
