import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/profile_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/rating_widget.dart';
import '../../widgets/product_image.dart';
import '../messages/messages_screen.dart';
import '../messages/offers_screen.dart';
import '../orders/orders_screen.dart';
import '../sell/my_listings_screen.dart';
import 'edit_profile_screen.dart';
import 'help_support_screen.dart';
import 'saved_items_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Sign in to view your profile.'));
    }

    return StreamBuilder<UserModel?>(
      stream: ProfileRepository().watchProfile(user.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Could not load your profile. Check your connection and Firestore rules.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final profile = snapshot.data;
        if (profile == null) {
          return const Center(
            child: Text('Your profile has not been created yet.'),
          );
        }

        return SafeArea(
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 26),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor: Colors.white,
                      child: ClipOval(
                        child: profile.profileImage.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 36,
                                color: AppColors.primary,
                              )
                            : SizedBox(
                                width: 68,
                                height: 68,
                                child: ProductImage(
                                  source: profile.profileImage,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            profile.location,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 4),
                          RatingWidget(
                            rating: profile.rating,
                            reviews: profile.reviewCount,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _item(
                context,
                Icons.inventory_2_outlined,
                'My Listings',
                const MyListingsScreen(),
              ),
              _item(
                context,
                Icons.receipt_long_outlined,
                'My Orders',
                const OrdersScreen(),
              ),
              _item(
                context,
                Icons.chat_bubble_outline,
                'Messages',
                const MessagesScreen(),
              ),
              _item(
                context,
                Icons.favorite_border,
                'Saved Items',
                const SavedItemsScreen(),
              ),
              _item(
                context,
                Icons.local_offer_outlined,
                'My Offers',
                const OffersScreen(),
              ),
              _item(
                context,
                Icons.settings_outlined,
                'Settings',
                const SettingsScreen(),
              ),
              _item(
                context,
                Icons.help_outline,
                'Help & Support',
                const HelpSupportScreen(),
              ),
              _item(
                context,
                Icons.edit_outlined,
                'Edit Profile',
                const EditProfileScreen(),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.danger),
                title: const Text('Logout'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _logout(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _item(BuildContext context, IconData icon, String title, Widget page) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => page),
      ),
    );
  }
}

Future<void> _logout(BuildContext context) async {
  try {
    await AuthRepository().logout();
  } on FirebaseException catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AuthRepository.messageFor(error))),
      );
    }
  }
}
