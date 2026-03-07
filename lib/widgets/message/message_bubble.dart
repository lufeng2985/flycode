import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../service/api/models/message.dart';
import '../../service/api/models/parts.dart';
import 'message_header.dart';
import 'message_part.dart';

class MessageBubble extends StatefulWidget {
  final MessageWithParts messageWithParts;
  final bool prevIsUser;

  const MessageBubble({
    super.key,
    required this.messageWithParts,
    required this.prevIsUser,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _copied = false;

  String _extractText() {
    final buffer = StringBuffer();
    for (final part in widget.messageWithParts.parts) {
      if (part is TextPart) {
        if (buffer.isNotEmpty) buffer.write('\n');
        buffer.write(part.text);
      }
    }
    return buffer.toString();
  }

  Future<void> _copyMessage() async {
    final text = _extractText();
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.messageWithParts.info is UserMessage;
    final userMessage = isUser
        ? widget.messageWithParts.info as UserMessage
        : null;
    final assistantMessage = !isUser
        ? widget.messageWithParts.info as AssistantMessage
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
              Row(
                children: [
                  Expanded(
                    child: MessageHeader(
                      isUser: isUser,
                      userMessage: userMessage,
                      assistantMessage: assistantMessage,
                    ),
                  ),
                  GestureDetector(
                    onTap: _copyMessage,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _copied
                          ? Icon(
                              Icons.check,
                              key: const ValueKey('check'),
                              size: 14,
                              color: Colors.green[600],
                            )
                          : Icon(
                              Icons.copy,
                              key: const ValueKey('copy'),
                              size: 14,
                              color: Colors.grey[400],
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...widget.messageWithParts.parts.map(
                (part) => MessagePart(part: part, isUser: isUser),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
