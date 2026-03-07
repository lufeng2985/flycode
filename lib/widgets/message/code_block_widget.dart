import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

/// A custom [MarkdownElementBuilder] that renders fenced code blocks with
/// a language header bar and a copy-to-clipboard button.
class CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  bool isBlockElement() => true;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    if (element.tag != 'code') return null;

    final rawLanguage = element.attributes['class'] ?? '';
    // markdown encodes language as "language-dart", "language-python", etc.
    final language = rawLanguage.startsWith('language-')
        ? rawLanguage.substring('language-'.length)
        : rawLanguage;

    final code = element.textContent;

    return _CodeBlockWidget(language: language, code: code);
  }
}

class _CodeBlockWidget extends StatefulWidget {
  final String language;
  final String code;

  const _CodeBlockWidget({required this.language, required this.code});

  @override
  State<_CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<_CodeBlockWidget> {
  bool _copied = false;

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final hasLanguage = widget.language.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: const Color(0xFF2D2D2D),
            child: Row(
              children: [
                if (hasLanguage)
                  Text(
                    widget.language,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFAAAAAA),
                      letterSpacing: 0.5,
                    ),
                  )
                else
                  const Text(
                    'code',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF777777),
                      letterSpacing: 0.5,
                    ),
                  ),
                const Spacer(),
                GestureDetector(
                  onTap: _copyCode,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _copied
                        ? const Row(
                            key: ValueKey('copied'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check,
                                size: 14,
                                color: Color(0xFF4CAF50),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Copied',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF4CAF50),
                                ),
                              ),
                            ],
                          )
                        : const Row(
                            key: ValueKey('copy'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.copy,
                                size: 14,
                                color: Color(0xFF888888),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Copy',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF888888),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          // Code body
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              widget.code,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Color(0xFFD4D4D4),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
