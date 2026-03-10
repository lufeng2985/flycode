import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../service/api/models/message.dart';
import '../../service/api/models/parts.dart'
    hide
        ProviderAuthError,
        UnknownError,
        MessageOutputLengthError,
        MessageAbortedError,
        ApiError;
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

    final error = assistantMessage?.error;
    if (error != null) {
      return _buildErrorWidget(context, error);
    }

    return _buildNormalContent(context, isUser, userMessage, assistantMessage);
  }

  Widget _buildErrorWidget(BuildContext context, Object error) {
    final errorMessage = _getErrorMessage(error);
    final errorName = _getErrorName(error);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.error_outline, size: 16, color: Colors.red[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      errorName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[700],
                      ),
                    ),
                  ),
                ],
              ),
              if (errorMessage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  errorMessage,
                  style: TextStyle(fontSize: 13, color: Colors.red[700]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getErrorMessage(Object error) {
    if (error is ProviderAuthError) return error.message;
    if (error is UnknownError) return error.message;
    if (error is MessageOutputLengthError) {
      return error.data['message'] as String? ?? '';
    }
    if (error is MessageAbortedError) return error.message;
    if (error is ApiError) return error.message;
    return '';
  }

  String _getErrorName(Object error) {
    if (error is ProviderAuthError) return 'Authentication Failed';
    if (error is UnknownError) return 'Error';
    if (error is MessageOutputLengthError) return 'Output Limit Exceeded';
    if (error is MessageAbortedError) return 'Message Aborted';
    if (error is ApiError) return 'API Error';
    return 'Unknown Error';
  }

  Widget _buildNormalContent(
    BuildContext context,
    bool isUser,
    UserMessage? userMessage,
    AssistantMessage? assistantMessage,
  ) {
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
