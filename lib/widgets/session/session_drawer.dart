import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../service/api/models/session.dart';
import '../../providers/project_provider.dart';

String _projectDisplayName(String worktree) {
  final parts = worktree.replaceAll('\\', '/').split('/');
  return parts.lastWhere((p) => p.isNotEmpty, orElse: () => worktree);
}

class SessionDrawer extends ConsumerWidget {
  final AsyncValue<List<Session>> sessionsAsync;
  final Session? selectedSession;
  final void Function(Session) onSessionSelected;
  final VoidCallback onNewSession;

  const SessionDrawer({
    super.key,
    required this.sessionsAsync,
    required this.selectedSession,
    required this.onSessionSelected,
    required this.onNewSession,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedProjectAsync = ref.watch(selectedProjectProvider);

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            _buildProjectHeader(context, selectedProjectAsync),
            const Divider(height: 1),
            Expanded(
              child: sessionsAsync.when(
                data: (sessions) => _buildSessionList(sessions),
                error: (error, stack) => Center(child: Text('$error')),
                loading: () => const Center(child: CircularProgressIndicator()),
              ),
            ),
            const Divider(height: 1),
            _buildBottomActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: onNewSession,
            tooltip: '新建会话',
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.pop(context);
              context.push('/settings');
            },
            tooltip: '设置',
          ),
        ],
      ),
    );
  }

  Widget _buildProjectHeader(
    BuildContext context,
    AsyncValue selectedProjectAsync,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/projects'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.folder_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: selectedProjectAsync.when(
                  loading: () => Text(
                    '加载中...',
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                  error: (error, stack) => Text(
                    '项目加载失败',
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  ),
                  data: (project) => project == null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '选择项目',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _projectDisplayName(project.worktree),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              project.worktree,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[450],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              Icon(
                Icons.unfold_more_rounded,
                color: Colors.grey[400],
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionList(List<Session> sessions) {
    final grouped = _groupSessionsByDate(sessions);
    final sortedDates = grouped.keys.toList();

    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final sessionsForDate = grouped[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                _formatDateHeader(date),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ),
            ...sessionsForDate.map(
              (session) => ListTile(
                leading: const Icon(Icons.chat_bubble_outline),
                title: Text(
                  session.title ?? session.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                selected: selectedSession?.id == session.id,
                onTap: () => onSessionSelected(session),
              ),
            ),
          ],
        );
      },
    );
  }

  Map<String, List<Session>> _groupSessionsByDate(List<Session> sessions) {
    final grouped = <String, List<Session>>{};
    final sortedSessions = List<Session>.from(sessions)
      ..sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0));

    for (final session in sortedSessions) {
      final dateKey = _getDateKey(session.updatedAt);
      grouped.putIfAbsent(dateKey, () => []).add(session);
    }
    return grouped;
  }

  String _getDateKey(int? timestamp) {
    if (timestamp == null || timestamp == 0) {
      final now = DateTime.now();
      return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    }
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateHeader(String dateKey) {
    if (dateKey == 'Unknown') return '未知';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    DateTime parseDate(String key) {
      final parts = key.split('-');
      if (parts.length < 3) return today;
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    }

    final date = parseDate(dateKey);

    if (date == today) return '今天';
    if (date == yesterday) return '昨天';

    final parts = dateKey.split('-');
    if (parts.length < 3) return dateKey;

    final month = int.tryParse(parts[1]) ?? 1;
    final day = int.tryParse(parts[2]) ?? 1;
    return '$month月$day日';
  }
}
