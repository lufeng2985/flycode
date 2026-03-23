import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/project_provider.dart';
import '../providers/session_provider.dart';
import '../service/api/models/session.dart';
import '../service/api/session_api.dart';

String _projectDisplayName(String worktree) {
  final parts = worktree.replaceAll('\\', '/').split('/');
  return parts.lastWhere((p) => p.isNotEmpty, orElse: () => worktree);
}

class SessionListPage extends ConsumerWidget {
  const SessionListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsProvider);
    final selectedSession = ref.watch(selectedSessionProvider).session;
    final selectedProject = ref.watch(selectedProjectProvider).asData?.value;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
        ref.read(selectedSessionProvider.notifier).select(null);
        ref.read(selectedProjectProvider.notifier).clear();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            selectedProject == null
                ? '会话'
                : _projectDisplayName(selectedProject.worktree),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          actions: [
            IconButton(
              icon: const Icon(Icons.add_comment_outlined),
              tooltip: '新建会话',
              onPressed: () {
                ref.read(selectedSessionProvider.notifier).startNew();
                context.push('/chat');
              },
            ),
            const SizedBox(width: 4),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(color: Colors.grey[100], height: 1),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () => ref.refresh(sessionsProvider.future),
          child: sessionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('$error', style: TextStyle(color: Colors.grey[500])),
            ),
            data: (sessions) {
              if (sessions.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                    Center(
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
                              Icons.chat_bubble_outline_rounded,
                              size: 36,
                              color: Colors.grey[350],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '暂无会话',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '点击右上角新建会话',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              final grouped = _groupSessionsByDate(sessions);
              final sortedDates = grouped.keys.toList();

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 12),
                physics: const AlwaysScrollableScrollPhysics(),
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
                          subtitle: Text(
                            _formatUpdatedTime(session.updatedAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          selected: selectedSession?.id == session.id,
                          onTap: () {
                            ref
                                .read(selectedSessionProvider.notifier)
                                .select(session);
                            context.push('/chat');
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
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

String _formatUpdatedTime(int? timestampMs) {
  if (timestampMs == null || timestampMs == 0) return '刚刚';

  final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs);
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.inMinutes < 1) return '刚刚';
  if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
  if (diff.inHours < 24) return '${diff.inHours} 小时前';
  if (diff.inDays < 7) return '${diff.inDays} 天前';

  final y = dt.year;
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  if (dt.year == now.year) return '$m-$d';
  return '$y-$m-$d';
}
