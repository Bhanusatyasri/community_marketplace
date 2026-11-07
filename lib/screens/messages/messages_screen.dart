import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/conversation.dart';
import '../../repositories/message_repository.dart';
import '../../widgets/chat_tile.dart';
import 'chat_screen.dart';
import 'offers_screen.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return DefaultTabController(
      length: 2,
      initialIndex: initialTab.clamp(0, 1),
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 18, 18, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Messages',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const TabBar(
              tabs: [
                Tab(text: 'Chats'),
                Tab(text: 'Offers'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  if (uid == null)
                    const Center(child: Text('Sign in to view your chats.'))
                  else
                    StreamBuilder<List<ConversationModel>>(
                      stream: MessageRepository().watchConversations(uid),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Could not load chats. Check your connection and Firestore permissions.',
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            !snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final conversations = snapshot.data ?? const [];
                        if (conversations.isEmpty) {
                          return const Center(
                            child: Text(
                              'No conversations yet. Contact a seller to start chatting.',
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: conversations.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final conversation = conversations[index];
                            return ChatTile(
                              name: conversation.partnerName(uid),
                              avatarUrl: conversation.partnerAvatar(uid),
                              message: conversation.lastMessage.isEmpty
                                  ? 'Conversation started'
                                  : conversation.lastMessage,
                              time: _timeLabel(conversation.lastMessageAt),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatScreen(
                                    product: conversation.toProduct(),
                                    conversation: conversation,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  const OffersScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeLabel(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    if (time.year == now.year &&
        time.month == now.month &&
        time.day == now.day) {
      final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
      return '$hour:${time.minute.toString().padLeft(2, '0')}';
    }
    final yesterday = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    if (time.year == yesterday.year &&
        time.month == yesterday.month &&
        time.day == yesterday.day) {
      return 'Yesterday';
    }
    return '${time.day}/${time.month}/${time.year}';
  }
}
