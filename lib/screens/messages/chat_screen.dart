import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/conversation.dart';
import '../../models/product.dart';
import '../../repositories/message_repository.dart';
import '../../theme/app_colors.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/product_image.dart';

class ChatScreen extends StatefulWidget {
  final Product product;
  final ConversationModel? conversation;

  const ChatScreen({super.key, required this.product, this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final controller = TextEditingController();
  final scroll = ScrollController();
  final repository = MessageRepository();
  late final Future<ConversationModel> conversationFuture;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    conversationFuture = widget.conversation == null
        ? repository.openConversation(widget.product)
        : Future.value(widget.conversation);
  }

  @override
  void dispose() {
    controller.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> send(ConversationModel conversation) async {
    if (sending) return;
    final text = controller.text.trim();
    if (text.isEmpty) return;

    setState(() => sending = true);
    try {
      await repository.sendMessage(
        conversationId: conversation.id,
        text: text,
      );
      controller.clear();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Message could not be sent: $error')),
      );
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<ConversationModel>(
          future: conversationFuture,
          builder: (context, snapshot) {
            final conversation = snapshot.data;
            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primaryLight,
                  backgroundImage: conversation?.partnerAvatar(uid).isNotEmpty ==
                          true
                      ? NetworkImage(conversation!.partnerAvatar(uid))
                      : null,
                  child: conversation?.partnerAvatar(uid).isNotEmpty == true
                      ? null
                      : const Icon(
                          Icons.person,
                          color: AppColors.primaryDark,
                          size: 20,
                        ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    conversation?.partnerName(uid) ?? 'Chat with seller',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: FutureBuilder<ConversationModel>(
        future: conversationFuture,
        builder: (context, conversationSnapshot) {
          if (conversationSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to open this chat. Check your connection and Firestore permissions.\n${conversationSnapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!conversationSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final conversation = conversationSnapshot.data!;
          return Column(
            children: [
              Card(
                margin: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ProductImage(
                      source: widget.product.images.isEmpty
                          ? null
                          : widget.product.images.first,
                    ),
                  ),
                  title: Text(
                    widget.product.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '₹${widget.product.price.toStringAsFixed(0)}',
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder(
                  stream: repository.watchMessages(conversation.id),
                  builder: (context, messageSnapshot) {
                    if (messageSnapshot.hasError) {
                      return const Center(
                        child: Text('Could not load messages. Try again later.'),
                      );
                    }
                    if (messageSnapshot.connectionState ==
                            ConnectionState.waiting &&
                        !messageSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final messages = messageSnapshot.data ?? const [];
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (scroll.hasClients) {
                        scroll.jumpTo(scroll.position.maxScrollExtent);
                      }
                    });
                    if (messages.isEmpty) {
                      return const Center(
                        child: Text('Start the conversation with a message.'),
                      );
                    }
                    return ListView.builder(
                      controller: scroll,
                      padding: const EdgeInsets.all(14),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return MessageBubble(
                          text: message.text,
                          time: message.timestamp,
                          mine: message.senderId == uid,
                        );
                      },
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          maxLength: 1000,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => send(conversation),
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            prefixIcon: Icon(Icons.chat_bubble_outline),
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: IconButton(
                          onPressed: sending ? null : () => send(conversation),
                          tooltip: 'Send message',
                          icon: sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 19,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
