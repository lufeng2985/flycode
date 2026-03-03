import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../service/api/models/message.dart';
import '../../service/api/session_api.dart';
import '../../pages/home_page.dart';
import '../../providers/message_cache_provider.dart';
import 'message_bubble.dart';

class MessageList extends ConsumerWidget {
  const MessageList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch sessionMessages to trigger initial fetch and refresh on session change
    final fetchAsync = ref.watch(sessionMessagesProvider);

    final selectedSession = ref.watch(selectedSessionProvider);
    final cache = ref.watch(messageCacheProvider);
    final messages = selectedSession != null
        ? (cache[selectedSession.id] ?? [])
        : [];

    if (fetchAsync is AsyncLoading && messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (fetchAsync is AsyncError && messages.isEmpty) {
      final error = (fetchAsync as AsyncError).error;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
          ],
        ),
      );
    }

    if (messages.isEmpty) {
      return const Center(
        child: Text('No messages yet', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final messageWithParts = messages[messages.length - 1 - index];
        final prevIndex = messages.length - 2 - index;
        final prevMessage = prevIndex >= 0 ? messages[prevIndex] : null;
        final prevIsUser = prevMessage?.info is UserMessage;
        return MessageBubble(
          messageWithParts: messageWithParts,
          prevIsUser: prevIsUser,
        );
      },
    );
  }
}
