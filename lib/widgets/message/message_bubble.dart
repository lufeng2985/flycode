import 'package:flutter/material.dart';
import '../../service/api/models/message.dart';
import 'message_header.dart';
import 'message_part.dart';

class MessageBubble extends StatelessWidget {
  final MessageWithParts messageWithParts;
  final bool prevIsUser;

  const MessageBubble({
    super.key,
    required this.messageWithParts,
    required this.prevIsUser,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = messageWithParts.info is UserMessage;
    final userMessage = isUser ? messageWithParts.info as UserMessage : null;
    final assistantMessage = !isUser
        ? messageWithParts.info as AssistantMessage
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isUser
                ? MediaQuery.of(context).size.width * 0.75
                : MediaQuery.of(context).size.width,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isUser
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MessageHeader(
                isUser: isUser,
                userMessage: userMessage,
                assistantMessage: assistantMessage,
              ),
              const SizedBox(height: 8),
              ...messageWithParts.parts.map(
                (part) => MessagePart(part: part, isUser: isUser),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
