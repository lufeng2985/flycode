import 'package:diff_match_patch/diff_match_patch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/session_provider.dart';
import '../service/api/models/session.dart';

// ──────────────────────────────────────────────
// 页面入口
// ──────────────────────────────────────────────

class SessionDiffPage extends ConsumerWidget {
  const SessionDiffPage({super.key, required this.sessionID});

  final String sessionID;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diffsAsync = ref.watch(sessionDiffProvider(sessionID));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '文件变更',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[100], height: 1),
        ),
      ),
      body: diffsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Colors.grey[350],
                ),
                const SizedBox(height: 12),
                Text(
                  '加载失败',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$error',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                ),
              ],
            ),
          ),
        ),
        data: (diffs) {
          if (diffs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      size: 36,
                      color: Colors.grey[350],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无文件变更',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '本次会话未产生任何文件改动',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ],
              ),
            );
          }

          // 汇总统计
          final totalAdditions = diffs.fold(0, (s, d) => s + d.additions);
          final totalDeletions = diffs.fold(0, (s, d) => s + d.deletions);

          return Column(
            children: [
              _SummaryBar(
                fileCount: diffs.length,
                additions: totalAdditions,
                deletions: totalDeletions,
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 0,
                  ),
                  itemCount: diffs.length,
                  separatorBuilder: (context, index) =>
                      Divider(height: 1, color: Colors.grey[100]),
                  itemBuilder: (context, index) =>
                      _FileDiffTile(diff: diffs[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 顶部汇总栏
// ──────────────────────────────────────────────

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.fileCount,
    required this.additions,
    required this.deletions,
  });

  final int fileCount;
  final int additions;
  final int deletions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.description_outlined, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Text(
            '$fileCount 个文件',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(width: 12),
          Text(
            '+$additions',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF2E7D32),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '-$deletions',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFC62828),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 单文件 diff 展开块
// ──────────────────────────────────────────────

class _FileDiffTile extends StatelessWidget {
  const _FileDiffTile({required this.diff});

  final FileDiff diff;

  String _fileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    final parts = normalized.split('/');
    return parts.lastWhere((p) => p.isNotEmpty, orElse: () => path);
  }

  @override
  Widget build(BuildContext context) {
    final fileName = _fileName(diff.file);
    final isNewFile = diff.before.isEmpty && diff.after.isNotEmpty;
    final isDeletedFile = diff.before.isNotEmpty && diff.after.isEmpty;

    return Theme(
      // 移除 ExpansionTile 默认顶部分隔线
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: EdgeInsets.zero,
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _iconBgColor(isNewFile, isDeletedFile),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _fileIcon(isNewFile, isDeletedFile),
            size: 16,
            color: _iconColor(isNewFile, isDeletedFile),
          ),
        ),
        title: Text(
          fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        subtitle: diff.file != fileName
            ? Text(
                diff.file,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.grey[450]),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (diff.additions > 0)
              Text(
                '+${diff.additions}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (diff.additions > 0 && diff.deletions > 0)
              const SizedBox(width: 4),
            if (diff.deletions > 0)
              Text(
                '-${diff.deletions}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFC62828),
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more_rounded, size: 18, color: Colors.grey[400]),
          ],
        ),
        expandedAlignment: Alignment.topLeft,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 12,
              top: 4,
            ),
            child: _DiffView(before: diff.before, after: diff.after),
          ),
        ],
      ),
    );
  }

  Color _iconBgColor(bool isNew, bool isDeleted) {
    if (isNew) return const Color(0xFFE8F5E9);
    if (isDeleted) return const Color(0xFFFFEBEE);
    return Colors.grey[100]!;
  }

  IconData _fileIcon(bool isNew, bool isDeleted) {
    if (isNew) return Icons.add_circle_outline_rounded;
    if (isDeleted) return Icons.remove_circle_outline_rounded;
    return Icons.insert_drive_file_outlined;
  }

  Color _iconColor(bool isNew, bool isDeleted) {
    if (isNew) return const Color(0xFF2E7D32);
    if (isDeleted) return const Color(0xFFC62828);
    return Colors.grey[500]!;
  }
}

// ──────────────────────────────────────────────
// Diff 渲染器
// ──────────────────────────────────────────────

/// 单行展示数据
class _DiffLine {
  const _DiffLine({required this.op, required this.text});

  /// DIFF_DELETE=-1, DIFF_EQUAL=0, DIFF_INSERT=1
  final int op;
  final String text;
}

/// 折叠占位符
class _CollapsedHint {
  const _CollapsedHint(this.count);
  final int count;
}

class _DiffView extends StatelessWidget {
  const _DiffView({required this.before, required this.after});

  final String before;
  final String after;

  static const int _contextLines = 3;

  /// 将 before/after 全文做行级 diff，返回 [_DiffLine] 列表
  List<_DiffLine> _computeDiffLines() {
    if (before.isEmpty && after.isEmpty) return [];

    // 对纯文本做字符级 diff，但这里文件可能很大，所以先将每行映射为单字符
    // 手动实现行级 diff：
    //   1. 按行拆分 before / after
    //   2. 对行数组用 diff_match_patch 做逐行 diff
    //      — 将每行映射为 Unicode 私有区字符，做字符级 diff
    //      — 再把字符还原回行
    final dmp = DiffMatchPatch();

    // 构建 before 和 after 的逐行表示
    final lineArray = <String>['']; // 下标 0 留空
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

    final result = <_DiffLine>[];
    for (final d in diffs) {
      for (final charCode in d.text.codeUnits) {
        final line = charCode < lineArray.length ? lineArray[charCode] : '';
        result.add(_DiffLine(op: d.operation, text: line));
      }
    }
    return result;
  }

  /// 将连续 equal 段折叠，仅保留变更前后各 [_contextLines] 行
  List<Object> _buildDisplayItems(List<_DiffLine> lines) {
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
          result.add(_CollapsedHint(collapseCount));
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
    final lines = _computeDiffLines();

    if (lines.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Text(
          '（空文件）',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[400],
            fontFamily: 'monospace',
          ),
        ),
      );
    }

    final items = _buildDisplayItems(lines);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: items.map((item) {
          if (item is _CollapsedHint) {
            return _CollapsedHintRow(count: item.count);
          }
          return _DiffLineRow(line: item as _DiffLine);
        }).toList(),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 折叠提示行
// ──────────────────────────────────────────────

class _CollapsedHintRow extends StatelessWidget {
  const _CollapsedHintRow({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Text(
        '── $count 行未变更 ──',
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[400],
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// 单行渲染
// ──────────────────────────────────────────────

class _DiffLineRow extends StatelessWidget {
  const _DiffLineRow({required this.line});
  final _DiffLine line;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color textColor;
    final String prefix;

    switch (line.op) {
      case DIFF_INSERT:
        bg = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF1B5E20);
        prefix = '+';
      case DIFF_DELETE:
        bg = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFB71C1C);
        prefix = '-';
      default:
        bg = Colors.white;
        textColor = Colors.black87;
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
