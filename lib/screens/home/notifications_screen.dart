import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/notification_model.dart';
import '../../repositories/notification_repository.dart';
import '../../theme/app_colors.dart';
import '../messages/messages_screen.dart';
import '../orders/orders_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Sign in to view notifications.')),
      );
    }
    final notifications = NotificationRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          StreamBuilder<List<NotificationModel>>(
            stream: notifications.watchNotifications(uid),
            builder: (context, snapshot) {
              final items = snapshot.data;
              if (items == null ||
                  items.every((notification) => notification.isRead)) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: () async {
                  try {
                    await notifications.markAllRead(items);
                  } catch (error) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not update notifications: $error')),
                    );
                  }
                },
                child: const Text('Mark all read'),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: notifications.watchNotifications(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Could not load notifications. Check your connection and Firestore rules.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 52,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 12),
                  Text('You are all caught up.'),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final notification = items[index];
              return Card(
                color: notification.isRead
                    ? Colors.white
                    : AppColors.primaryLight,
                child: ListTile(
                  onTap: () => _open(context, notifications, notification),
                  leading: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      _icon(notification.type),
                      color: AppColors.primaryDark,
                    ),
                  ),
                  title: Text(
                    notification.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(notification.description),
                  trailing: Text(
                    notification.timestampLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    NotificationRepository repository,
    NotificationModel notification,
  ) async {
    if (!notification.isRead) {
      try {
        await repository.markRead(notification.id);
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update notification: $error')),
        );
      }
    }
    if (!context.mounted) return;
    final page = switch (notification.type) {
      'order' => const OrdersScreen(),
      'offer' => const MessagesScreen(initialTab: 1),
      _ => const MessagesScreen(),
    };
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  IconData _icon(String type) => switch (type) {
    'message' => Icons.chat_bubble_outline,
    'offer' => Icons.local_offer_outlined,
    'order' => Icons.receipt_long_outlined,
    _ => Icons.notifications_none,
  };
}
