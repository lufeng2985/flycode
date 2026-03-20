import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../service/api/models/parts.dart';
import 'code_block_widget.dart';
import 'tool_use_widget.dart';

class MessagePart extends StatelessWidget {
  final Object part;
  final bool isUser;
  final bool isStreaming;
  final void Function(String sessionId)? onNavigateToSubSession;

  const MessagePart({
    super.key,
    required this.part,
    required this.isUser,
    this.isStreaming = false,
    this.onNavigateToSubSession,
  });

  @override
  Widget build(BuildContext context) {
    if (part is CompactionPart) {
      return const _CompactionDivider();
    }
    if (part is TextPart) {
      final textPart = part as TextPart;
      if (textPart.synthetic == true) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: _TypewriterMarkdownText(
          key: ValueKey(textPart.id),
          text: textPart.text,
          animate: !isUser && isStreaming,
        ),
      );
    } else if (part is ToolPart) {
      return ToolUseWidget(
        toolPart: part as ToolPart,
        onNavigateToSubSession: onNavigateToSubSession,
      );
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

class _TypewriterMarkdownText extends StatefulWidget {
  final String text;
  final bool animate;

  const _TypewriterMarkdownText({
    super.key,
    required this.text,
    required this.animate,
  });

  @override
  State<_TypewriterMarkdownText> createState() =>
      _TypewriterMarkdownTextState();
}

class _TypewriterMarkdownTextState extends State<_TypewriterMarkdownText> {
  static const Duration _tick = Duration(milliseconds: 24);

  Timer? _timer;
  List<String> _chars = const [];
  int _visibleCount = 0;

  @override
  void initState() {
    super.initState();
    _chars = widget.text.characters.toList();
    _visibleCount = widget.animate ? 0 : _chars.length;
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _TypewriterMarkdownText oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldLength = _chars.length;
    _chars = widget.text.characters.toList();
    final newLength = _chars.length;

    if (!widget.animate) {
      _timer?.cancel();
      _timer = null;
      if (_visibleCount != newLength) {
        setState(() {
          _visibleCount = newLength;
        });
      }
      return;
    }

    if (newLength < oldLength && _visibleCount > newLength) {
      setState(() {
        _visibleCount = newLength;
      });
    }

    _syncAnimation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _syncAnimation() {
    if (!widget.animate || _visibleCount >= _chars.length) {
      _timer?.cancel();
      _timer = null;
      return;
    }

    _timer ??= Timer.periodic(_tick, (_) {
      if (!mounted) return;

      final remaining = _chars.length - _visibleCount;
      if (remaining <= 0) {
        _timer?.cancel();
        _timer = null;
        return;
      }

      final step = remaining >= 120
          ? 4
          : remaining >= 60
          ? 3
          : remaining >= 20
          ? 2
          : 1;

      setState(() {
        _visibleCount = (_visibleCount + step).clamp(0, _chars.length);
      });

      if (_visibleCount >= _chars.length) {
        _timer?.cancel();
        _timer = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = _chars.take(_visibleCount).join();
    return MarkdownBody(
      data: text,
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
    );
  }
}

class _CompactionDivider extends StatelessWidget {
  const _CompactionDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.grey[300], height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'Context compacted',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                letterSpacing: 0.2,
              ),
            ),
          ),
          Expanded(child: Divider(color: Colors.grey[300], height: 1)),
        ],
      ),
    );
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
