import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/todo_provider.dart';
import '../../service/api/models/global_event.dart' show Todo;

/// 展示当前 session 的 AI Todo 任务列表。
///
/// 展示规则：
/// - 只有存在非 completed 的 todo 时才显示整个区域
/// - 所有 todo 均展示，排序：in_progress → pending → completed
/// - 支持折叠/展开
class TodoListWidget extends ConsumerStatefulWidget {
  const TodoListWidget({super.key, required this.sessionID});

  final String sessionID;

  @override
  ConsumerState<TodoListWidget> createState() => _TodoListWidgetState();
}

class _TodoListWidgetState extends ConsumerState<TodoListWidget> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final todosAsync = ref.watch(sessionTodosProvider(widget.sessionID));

    return todosAsync.when(
      data: (todos) => _buildContent(context, todos),
      loading: () => const SizedBox.shrink(),
      error: (err, st) => const SizedBox.shrink(),
    );
  }

  Widget _buildContent(BuildContext context, List<Todo> todos) {
    // 只有存在非 completed 的 todo 时才显示
    final hasActive = todos.any((t) => t.status != 'completed');
    if (!hasActive) return const SizedBox.shrink();

    // 排序：in_progress → pending → completed
    final sorted = List<Todo>.from(
      todos,
    )..sort((a, b) => _statusOrder(a.status).compareTo(_statusOrder(b.status)));

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        border: Border.all(color: const Color(0xFFE8EAED)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context, sorted),
          if (_expanded) ...[
            const Divider(height: 1, color: Color(0xFFE8EAED)),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 4),
              itemCount: sorted.length,
              separatorBuilder: (_, idx) => const Divider(
                height: 1,
                indent: 40,
                color: Color(0xFFEEEEEE),
              ),
              itemBuilder: (context, index) => _buildTodoItem(sorted[index]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, List<Todo> todos) {
    final inProgressCount = todos
        .where((t) => t.status == 'in_progress')
        .length;
    final pendingCount = todos.where((t) => t.status == 'pending').length;
    final completedCount = todos.where((t) => t.status == 'completed').length;

    return InkWell(
      borderRadius: _expanded
          ? const BorderRadius.vertical(top: Radius.circular(10))
          : BorderRadius.circular(10),
      onTap: () => setState(() => _expanded = !_expanded),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(
              Icons.checklist_rounded,
              size: 16,
              color: Color(0xFF5F6368),
            ),
            const SizedBox(width: 6),
            Text(
              'AI 任务规划',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3C4043),
              ),
            ),
            const SizedBox(width: 8),
            if (inProgressCount > 0)
              _buildBadge('$inProgressCount 进行中', const Color(0xFF1A73E8)),
            if (pendingCount > 0)
              _buildBadge('$pendingCount 待处理', const Color(0xFF80868B)),
            if (completedCount > 0)
              _buildBadge('$completedCount 已完成', const Color(0xFF34A853)),
            const Spacer(),
            Icon(
              _expanded ? Icons.expand_less : Icons.expand_more,
              size: 18,
              color: const Color(0xFF80868B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTodoItem(Todo todo) {
    final statusInfo = _statusInfo(todo.status);
    final isCompleted = todo.status == 'completed';
    final priorityInfo = _priorityInfo(todo.priority);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 状态图标
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(statusInfo.icon, size: 16, color: statusInfo.color),
          ),
          const SizedBox(width: 10),
          // 任务内容
          Expanded(
            child: Text(
              todo.content,
              style: TextStyle(
                fontSize: 13,
                color: isCompleted
                    ? const Color(0xFFADADAD)
                    : const Color(0xFF3C4043),
                decoration: isCompleted ? TextDecoration.lineThrough : null,
                decorationColor: const Color(0xFFADADAD),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 优先级标签
          if (todo.priority != 'low')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: priorityInfo.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: priorityInfo.color.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Text(
                priorityInfo.label,
                style: TextStyle(
                  fontSize: 10,
                  color: priorityInfo.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  int _statusOrder(String status) {
    switch (status) {
      case 'in_progress':
        return 0;
      case 'pending':
        return 1;
      case 'completed':
        return 2;
      case 'cancelled':
        return 3;
      default:
        return 4;
    }
  }

  _StatusInfo _statusInfo(String status) {
    switch (status) {
      case 'in_progress':
        return _StatusInfo(
          icon: Icons.radio_button_checked,
          color: const Color(0xFF1A73E8),
        );
      case 'completed':
        return _StatusInfo(
          icon: Icons.check_circle,
          color: const Color(0xFF34A853),
        );
      case 'cancelled':
        return _StatusInfo(icon: Icons.cancel, color: const Color(0xFFEA4335));
      default: // pending
        return _StatusInfo(
          icon: Icons.radio_button_unchecked,
          color: const Color(0xFF80868B),
        );
    }
  }

  _PriorityInfo _priorityInfo(String priority) {
    switch (priority) {
      case 'high':
        return _PriorityInfo(label: '高优', color: const Color(0xFFEA4335));
      case 'medium':
        return _PriorityInfo(label: '中', color: const Color(0xFFFB8C00));
      default: // low
        return _PriorityInfo(label: '低', color: const Color(0xFF80868B));
    }
  }
}

class _StatusInfo {
  const _StatusInfo({required this.icon, required this.color});
  final IconData icon;
  final Color color;
}

class _PriorityInfo {
  const _PriorityInfo({required this.label, required this.color});
  final String label;
  final Color color;
}
