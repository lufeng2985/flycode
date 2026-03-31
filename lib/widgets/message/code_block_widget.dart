import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:markdown/markdown.dart' as md;

import 'message_markdown_theme.dart';

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
    if (element.tag != 'pre') return null;

    // Fenced code blocks are <pre><code class="language-xxx">...</code></pre>
    final codeElement = element.children
        ?.whereType<md.Element>()
        .where((e) => e.tag == 'code')
        .firstOrNull;

    final rawLanguage = codeElement?.attributes['class'] ?? '';
    // markdown encodes language as "language-dart", "language-python", etc.
    final language = rawLanguage.startsWith('language-')
        ? rawLanguage.substring('language-'.length)
        : rawLanguage;

    final code = (codeElement?.textContent ?? element.textContent).trimRight();

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
    const borderRadius = BorderRadius.all(Radius.circular(12));
    const headerRadius = BorderRadius.vertical(top: Radius.circular(12));
    const bodyRadius = BorderRadius.vertical(bottom: Radius.circular(12));
    final hasLanguage = widget.language.isNotEmpty;
    final theme = Theme.of(context);
    final codeTheme = buildMessageCodeBlockTheme(context);
    final codeTextStyle = theme.textTheme.bodyMedium!.copyWith(
      fontFamily: 'monospace',
      fontSize: 13,
      height: 1.5,
      color: codeTheme.codeColor,
    );
    final commentPattern = RegExp(r'^\s*(//|#)');

    return Container(
      key: messageMarkdownCodeBlockKey,
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: codeTheme.backgroundColor,
        borderRadius: borderRadius,
        border: Border.all(color: codeTheme.borderColor),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: codeTheme.headerColor,
              borderRadius: headerRadius,
              border: Border(bottom: BorderSide(color: codeTheme.borderColor)),
            ),
            child: Row(
              children: [
                Text(
                  hasLanguage ? widget.language : 'code',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: codeTheme.languageColor,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _copyCode,
                  borderRadius: BorderRadius.circular(999),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _copied
                        ? Row(
                            key: ValueKey('copied'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check,
                                size: 14,
                                color: codeTheme.successColor,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Copied',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: codeTheme.successColor,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            key: ValueKey('copy'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.copy_outlined,
                                size: 14,
                                color: codeTheme.iconColor,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Copy',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: codeTheme.iconColor,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: codeTheme.backgroundColor,
              borderRadius: bodyRadius,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: SelectableText.rich(
                TextSpan(
                  children: [
                    for (final line in widget.code.split('\n')) ...[
                      TextSpan(
                        text: line,
                        style: commentPattern.hasMatch(line)
                            ? codeTextStyle.copyWith(
                                color: codeTheme.commentColor,
                              )
                            : codeTextStyle,
                      ),
                      const TextSpan(text: '\n'),
                    ],
                  ]..removeLast(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
