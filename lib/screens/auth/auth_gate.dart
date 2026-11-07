import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../repositories/auth_repository.dart';
import '../home/main_navigation_screen.dart';
import 'welcome_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key, this.firebaseSupported = true});

  final bool firebaseSupported;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<User?> _authStateChanges;

  @override
  void initState() {
    super.initState();
    if (widget.firebaseSupported) {
      _authStateChanges = AuthRepository().authStateChanges;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.firebaseSupported) {
      return const WelcomeScreen(firebaseAvailable: false);
    }

    return StreamBuilder<User?>(
      stream: _authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Unable to check your sign-in status. Please restart the app.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return snapshot.data == null
            ? const WelcomeScreen()
            : const MainNavigationScreen();
      },
    );
  }
}
