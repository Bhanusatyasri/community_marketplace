import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class ChatTile extends StatelessWidget {
  final String name;
  final String message;
  final String time;
  final String avatarUrl;
  final bool unread;
  final VoidCallback? onTap;

  const ChatTile({
    super.key,
    required this.name,
    required this.message,
    required this.time,
    this.avatarUrl = '',
    this.unread = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      leading: CircleAvatar(
        backgroundColor: AppColors.primaryLight,
        backgroundImage: avatarUrl.isEmpty ? null : NetworkImage(avatarUrl),
        child: avatarUrl.isEmpty
            ? const Icon(Icons.person, color: AppColors.primaryDark)
            : null,
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(message, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            time,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          if (unread)
            Container(
              margin: const EdgeInsets.only(top: 5),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
