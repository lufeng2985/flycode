import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../service/api/models/session.dart';

class SessionDrawer extends StatelessWidget {
  final AsyncValue<List<Session>> sessionsAsync;
  final Session? selectedSession;
  final void Function(Session) onSessionSelected;

  const SessionDrawer({
    super.key,
    required this.sessionsAsync,
    required this.selectedSession,
    required this.onSessionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: sessionsAsync.when(
          data: (sessions) => _buildSessionList(sessions),
          error: (error, stack) => Center(child: Text('$error')),
          loading: () => const Center(child: CircularProgressIndicator()),
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
