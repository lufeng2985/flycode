import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

// ──────────────────────────────────────────────
// Diff 渲染器（从 session_diff_page.dart 提取）
// ──────────────────────────────────────────────

/// 单行展示数据
class DiffLine {
  const DiffLine({required this.op, required this.text});

  /// DIFF_DELETE=-1, DIFF_EQUAL=0, DIFF_INSERT=1
  final int op;
  final String text;
}

/// 折叠占位符
class CollapsedHint {
  const CollapsedHint(this.count);
  final int count;
}

class DiffView extends StatelessWidget {
  const DiffView({super.key, required this.before, required this.after});

  final String before;
  final String after;

  static const int _contextLines = 3;

  List<DiffLine> _computeDiffLines() {
    if (before.isEmpty && after.isEmpty) return [];

    final dmp = DiffMatchPatch();

    final lineArray = <String>[''];
    final lineHash = <String, int>{};

    String linesToChars(String text) {
      final lines = text.split('\n');
      final sb = StringBuffer();
      for (final line in lines) {
        if (lineHash.containsKey(line)) {
          sb.writeCharCode(lineHash[line]!);
        } else {
          lineArray.add(line);
          final code = lineArray.length - 1;
          lineHash[line] = code;
          sb.writeCharCode(code);
        }
      }
      return sb.toString();
    }

    final chars1 = linesToChars(before);
    final chars2 = linesToChars(after);

    final diffs = dmp.diff(chars1, chars2, false);
    dmp.diffCleanupSemantic(diffs);

    final result = <DiffLine>[];
    for (final d in diffs) {
      for (final charCode in d.text.codeUnits) {
        final line = charCode < lineArray.length ? lineArray[charCode] : '';
        result.add(DiffLine(op: d.operation, text: line));
      }
    }
    return result;
  }

  List<Object> _buildDisplayItems(List<DiffLine> lines) {
    if (lines.isEmpty) return [];

    final result = <Object>[];
    int i = 0;

    while (i < lines.length) {
      if (lines[i].op == DIFF_EQUAL) {
        final start = i;
        while (i < lines.length && lines[i].op == DIFF_EQUAL) {
          i++;
        }
        final equalCount = i - start;
        final keepBefore = result.isNotEmpty ? _contextLines : 0;
        final keepAfter = i < lines.length ? _contextLines : 0;
        final collapseCount = equalCount - keepBefore - keepAfter;

        if (collapseCount > 0) {
          for (int j = start; j < start + keepBefore; j++) {
            result.add(lines[j]);
          }
          result.add(CollapsedHint(collapseCount));
          for (int j = i - keepAfter; j < i; j++) {
            result.add(lines[j]);
          }
        } else {
          for (int j = start; j < i; j++) {
            result.add(lines[j]);
          }
        }
      } else {
        result.add(lines[i]);
        i++;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final lines = _computeDiffLines();

    if (lines.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tokens.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.border.withValues(alpha: 0.8)),
        ),
        child: Text(
          '(empty)',
          style: TextStyle(
            fontSize: 12,
            color: tokens.mutedForeground,
            fontFamily: 'monospace',
          ),
        ),
      );
    }

    final items = _buildDisplayItems(lines);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.border.withValues(alpha: 0.8)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: items.map((item) {
          if (item is CollapsedHint) {
            return CollapsedHintRow(count: item.count);
          }
          return DiffLineRow(line: item as DiffLine);
        }).toList(),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 折叠提示行
// ──────────────────────────────────────────────

class CollapsedHintRow extends StatelessWidget {
  const CollapsedHintRow({super.key, required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      color: tokens.card,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Text(
        '... $count lines unchanged',
        style: TextStyle(
          fontSize: 11,
          color: tokens.mutedForeground,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 单行渲染
// ──────────────────────────────────────────────

class DiffLineRow extends StatelessWidget {
  const DiffLineRow({super.key, required this.line});
  final DiffLine line;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.tokens;
    final Color bg;
    final Color textColor;
    final String prefix;

    switch (line.op) {
      case DIFF_INSERT:
        bg = tokens.success;
        textColor = tokens.successForeground;
        prefix = '+';
      case DIFF_DELETE:
        bg = tokens.errorSoft;
        textColor = tokens.errorSoftForeground;
        prefix = '-';
      default:
        bg = theme.colorScheme.surface;
        textColor = theme.colorScheme.onSurface;
        prefix = ' ';
    }

    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 12,
            child: Text(
              prefix,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              line.text,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
