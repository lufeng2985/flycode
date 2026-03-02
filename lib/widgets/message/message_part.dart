import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../service/api/models/parts.dart';
import 'tool_use_widget.dart';
import 'reasoning_widget.dart';

class MessagePart extends StatelessWidget {
  final Object part;
  final bool isUser;

  const MessagePart({super.key, required this.part, required this.isUser});

  @override
  Widget build(BuildContext context) {
    if (part is TextPart) {
      final textPart = part as TextPart;
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: MarkdownBody(
          data: textPart.text,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(fontSize: 14, height: 1.5),
            code: TextStyle(
              backgroundColor: Colors.grey[200],
              fontFamily: 'monospace',
              fontSize: 13,
            ),
            codeblockDecoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      );
    } else if (part is ToolPart) {
      return ToolUseWidget(toolPart: part as ToolPart);
    } else if (part is ReasoningPart) {
      return ReasoningWidget(reasoning: part as ReasoningPart);
    }
    return const SizedBox.shrink();
  }
}
