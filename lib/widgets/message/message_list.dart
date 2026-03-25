import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/session_provider.dart';
import '../../service/api/models/message.dart';
import '../../service/api/models/parts.dart';
import '../../theme/app_tokens.dart';
import 'message_bubble.dart';

class MessageList extends ConsumerWidget {
  final void Function(String sessionId)? onNavigateToSubSession;

  const MessageList({super.key, this.onNavigateToSubSession});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(sessionMessagesProvider);

    return messagesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) {
        debugPrint('MessageList Error: $error\n$stack');
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Builder(
              builder: (context) {
                final theme = Theme.of(context);
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    SelectableText(
                      'Error: $error\n\nStack trace:\n$stack',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
      data: (messages) =>
          _buildList(messages, onNavigateToSubSession: onNavigateToSubSession),
    );
  }
}

/// 纯消息列表渲染（可复用于子 Session 页面）
class MessageListView extends StatelessWidget {
  final List<MessageWithParts> messages;
  final void Function(String sessionId)? onNavigateToSubSession;

  const MessageListView({
    super.key,
    required this.messages,
    this.onNavigateToSubSession,
  });

  @override
  Widget build(BuildContext context) =>
      _buildList(messages, onNavigateToSubSession: onNavigateToSubSession);
}

Widget _buildList(
  List<MessageWithParts> messages, {
  void Function(String sessionId)? onNavigateToSubSession,
}) {
  final visibleMessages = messages
      .where((message) => !_isSyntheticOnlyUserMessage(message))
      .toList();

  if (visibleMessages.isEmpty) {
    return Center(
      child: Builder(
        builder: (context) {
          final tokens = context.tokens;
          return Text(
            'No messages yet',
            style: TextStyle(color: tokens.mutedForeground),
          );
        },
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
      final prevMessage = prevIndex >= 0 ? visibleMessages[prevIndex] : null;
      final prevIsUser = prevMessage?.info is UserMessage;
      return MessageBubble(
        messageWithParts: messageWithParts,
        prevIsUser: prevIsUser,
        isLatestMessage: index == 0,
        onNavigateToSubSession: onNavigateToSubSession,
      );
    },
  );
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
