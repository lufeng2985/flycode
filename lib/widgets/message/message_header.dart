import 'package:flutter/material.dart';
import '../../service/api/models/message.dart';

class MessageHeader extends StatelessWidget {
  final bool isUser;
  final UserMessage? userMessage;
  final AssistantMessage? assistantMessage;

  const MessageHeader({
    super.key,
    required this.isUser,
    this.userMessage,
    this.assistantMessage,
  });

  @override
  Widget build(BuildContext context) {
    final time = isUser
        ? userMessage?.time.created
        : assistantMessage?.time.created;
    final agent = isUser ? userMessage?.agent : assistantMessage?.modelID;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isUser ? Icons.person : Icons.smart_toy,
          size: 14,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          isUser ? 'You' : (agent ?? 'Assistant'),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        if (time != null) ...[
          const SizedBox(width: 8),
          Text(
            _formatTime(time),
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ],
    );
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
