import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../theme/app_colors.dart';
import '../home/notifications_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _sendPasswordReset(BuildContext context, String email) async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your account has no email address.')),
      );
      return;
    }
    try {
      await AuthRepository().sendPasswordResetEmail(email);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('If the account exists, a password reset email was sent.'),
        ),
      );
    } on FirebaseException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthRepository.messageFor(error))),
      );
    }
  }

  void _showPrivacySummary(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy and data'),
        content: const Text(
          'Your account profile, listings, saved items, cart, orders, conversations, offers, and in-app notifications are stored in this project’s Firebase services. Do not include sensitive payment details in chat or order notes. This app does not process online payments.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view account settings.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: StreamBuilder<UserModel?>(
        stream: ProfileRepository().watchProfile(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                  'Could not load account settings. Check Firestore rules.'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = snapshot.data;

          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 18, 18, 5),
                child: Text(
                  'Account',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              ListTile(
                title: const Text('Email'),
                subtitle: Text(user.email ?? 'No email on this account'),
              ),
              ListTile(
                title: const Text('Phone'),
                subtitle: Text(
                  profile?.phone.isNotEmpty == true
                      ? profile!.phone
                      : 'Not added',
                ),
              ),
              ListTile(
                title: const Text('Location'),
                subtitle: Text(
                  profile?.location.isNotEmpty == true
                      ? profile!.location
                      : 'Not added',
                ),
              ),
              ListTile(
                leading: const Icon(Icons.lock_reset),
                title: const Text('Reset password'),
                subtitle: const Text('Send a reset link to your account email'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _sendPasswordReset(context, user.email ?? ''),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 18, 18, 5),
                child: Text(
                  'App',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Notifications'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                ),
              ),
              const ListTile(
                title: Text('Appearance'),
                subtitle: Text('Light theme'),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 18, 18, 5),
                child: Text(
                  'Privacy',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy and data'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showPrivacySummary(context),
              ),
            ],
          );
        },
      ),
    );
  }
}
