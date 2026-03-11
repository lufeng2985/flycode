import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/session_provider.dart';
import '../../service/api/models/message.dart';
import '../../service/api/models/parts.dart';
import 'message_bubble.dart';

class MessageList extends ConsumerWidget {
  const MessageList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(sessionMessagesProvider);

    return messagesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
          ],
        ),
      ),
      data: (messages) {
        final visibleMessages = messages
            .where((message) => !_isSyntheticOnlyUserMessage(message))
            .toList();

        if (visibleMessages.isEmpty) {
          return const Center(
            child: Text(
              'No messages yet',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          itemCount: visibleMessages.length,
          itemBuilder: (context, index) {
            final messageWithParts =
                visibleMessages[visibleMessages.length - 1 - index];
            final prevIndex = visibleMessages.length - 2 - index;
            final prevMessage = prevIndex >= 0
                ? visibleMessages[prevIndex]
                : null;
            final prevIsUser = prevMessage?.info is UserMessage;
            return MessageBubble(
              messageWithParts: messageWithParts,
              prevIsUser: prevIsUser,
            );
          },
        );
      },
    );
  }
}

bool _isSyntheticOnlyUserMessage(MessageWithParts message) {
  if (message.info is! UserMessage) return false;
  if (message.parts.isEmpty) return false;

  for (final part in message.parts) {
    if (part is TextPart) {
      if (part.synthetic != true) return false;
      continue;
    }
    return false;
  }
  return true;
}
