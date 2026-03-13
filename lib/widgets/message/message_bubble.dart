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
import 'message_part.dart';

class MessageBubble extends StatefulWidget {
  final MessageWithParts messageWithParts;
  final bool prevIsUser;
  final void Function(String sessionId)? onNavigateToSubSession;

  const MessageBubble({
    super.key,
    required this.messageWithParts,
    required this.prevIsUser,
    this.onNavigateToSubSession,
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

  bool get _hasTextContent {
    for (final part in widget.messageWithParts.parts) {
      if (part is TextPart && part.synthetic != true && part.text.isNotEmpty) {
        return true;
      }
    }
    return false;
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

    if (isUser) {
      return _buildUserBubble(context, userMessage!);
    }

    return _buildAssistantContent(context, assistantMessage!);
  }

  // ─── Error ────────────────────────────────────────────────────────────────

  Widget _buildErrorWidget(BuildContext context, Object error) {
    final errorMessage = _getErrorMessage(error);
    final errorName = _getErrorName(error);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, size: 14, color: Colors.red[600]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    errorName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red[700],
                    ),
                  ),
                ),
              ],
            ),
            if (errorMessage.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                errorMessage,
                style: TextStyle(fontSize: 12, color: Colors.red[700]),
              ),
            ],
          ],
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

  // ─── User bubble ──────────────────────────────────────────────────────────

  Widget _buildUserBubble(BuildContext context, UserMessage userMessage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...widget.messageWithParts.parts.map(
                (part) => MessagePart(
                  part: part,
                  isUser: true,
                  onNavigateToSubSession: widget.onNavigateToSubSession,
                ),
              ),
              if (_hasTextContent) ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: _CopyButton(copied: _copied, onCopy: _copyMessage),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ─── Assistant content (no bubble) ────────────────────────────────────────

  Widget _buildAssistantContent(
    BuildContext context,
    AssistantMessage assistantMessage,
  ) {
    final parts = widget.messageWithParts.parts;
    final lastTextPartIndex = parts.lastIndexWhere(
      (p) => p is TextPart && p.synthetic != true && p.text.isNotEmpty,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < parts.length; i++) ...[
            MessagePart(
              part: parts[i],
              isUser: false,
              onNavigateToSubSession: widget.onNavigateToSubSession,
            ),
            if (i == lastTextPartIndex) ...[
              const SizedBox(height: 6),
              _AssistantFooter(
                message: assistantMessage,
                copied: _copied,
                onCopy: _copyMessage,
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ─── Assistant footer & Copy Button ──────────────────────────────────────────

class _CopyButton extends StatelessWidget {
  final bool copied;
  final VoidCallback onCopy;

  const _CopyButton({required this.copied, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCopy,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: copied
            ? const Row(
                key: ValueKey('copied'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check, size: 14, color: Colors.green),
                  SizedBox(width: 4),
                  Text(
                    'Copied',
                    style: TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
              )
            : Row(
                key: const ValueKey('copy'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  const Text(
                    'Copy',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }
}

class _AssistantFooter extends StatelessWidget {
  final AssistantMessage message;
  final bool copied;
  final VoidCallback onCopy;

  const _AssistantFooter({
    required this.message,
    required this.copied,
    required this.onCopy,
  });

  String _formatDuration(int start, int? end) {
    if (end == null) return '';
    final seconds = end - start;
    if (seconds < 0) return '';
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final durationStr = _formatDuration(
      message.time.created,
      message.time.completed,
    );

    return DefaultTextStyle(
      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
      child: Row(
        children: [
          _CopyButton(copied: copied, onCopy: onCopy),
          const SizedBox(width: 12),
          Text('${message.providerID} · ${message.modelID}'),
          if (durationStr.isNotEmpty) ...[const Text(' · '), Text(durationStr)],
        ],
      ),
    );
  }
}
