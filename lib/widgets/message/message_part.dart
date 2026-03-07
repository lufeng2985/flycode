import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../service/api/models/parts.dart';
import 'code_block_widget.dart';
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
          builders: {'pre': CodeBlockBuilder()},
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(fontSize: 14, height: 1.5),
            code: TextStyle(
              backgroundColor: Colors.grey[200],
              fontFamily: 'monospace',
              fontSize: 13,
            ),
            codeblockDecoration: const BoxDecoration(),
          ),
        ),
      );
    } else if (part is ToolPart) {
      return ToolUseWidget(toolPart: part as ToolPart);
    } else if (part is ReasoningPart) {
      return ReasoningWidget(reasoning: part as ReasoningPart);
    } else if (part is FilePart) {
      final filePart = part as FilePart;
      if (filePart.mime.startsWith('image/')) {
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: _ImagePartWidget(url: filePart.url),
        );
      }
    }
    return const SizedBox.shrink();
  }
}

class _ImagePartWidget extends StatelessWidget {
  final String url;

  const _ImagePartWidget({required this.url});

  void _showFullscreen(BuildContext context, ImageProvider imageProvider) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image(image: imageProvider, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.of(ctx).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ImageProvider imageProvider;

    if (url.startsWith('data:')) {
      final base64Data = url.split(',').last;
      imageProvider = MemoryImage(base64Decode(base64Data));
    } else {
      imageProvider = NetworkImage(url);
    }

    return GestureDetector(
      onTap: () => _showFullscreen(context, imageProvider),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image(
          image: imageProvider,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 200,
            height: 200,
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
