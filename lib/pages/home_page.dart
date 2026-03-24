import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../service/api/session_api.dart';
import '../providers/global_event_provider.dart';
import '../providers/permission_provider.dart';
import '../providers/session_provider.dart';
import '../providers/question_provider.dart';
import '../theme/app_tokens.dart';
import '../widgets/message/message_list.dart';
import '../widgets/message/chat_input.dart';
import '../widgets/permission/session_permission_dock.dart';
import '../widgets/question/question_card.dart';
import '../widgets/session/todo_list_widget.dart';

class MyHomePage extends ConsumerWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;

    ref.watch(globalEventListenerProvider);
    final sessionsAsync = ref.watch(sessionsProvider);
    final selectedState = ref.watch(selectedSessionProvider);
    final selectedSession = selectedState.session;
    final isPending = selectedState.isPending;
    final permissionRequest = ref.watch(
      currentSessionPermissionRequestProvider,
    );
    final hasPermissionBlock = permissionRequest != null;
    final hasQuestion = ref.watch(currentSessionHasQuestionProvider);

    Widget buildNewSessionWelcome() {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: tokens.mutedForeground.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              '开始一段新会话',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: tokens.mutedForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '在下方输入消息，发送后将自动创建会话',
              style: TextStyle(
                fontSize: 13,
                color: tokens.mutedForeground.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      );
    }

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) return;
        ref.read(selectedSessionProvider.notifier).select(null);
      },
      child: Scaffold(
        appBar: AppBar(
          actions: [
            if (selectedSession != null) ...[
              IconButton(
                icon: Icon(
                  Icons.difference_outlined,
                  color: tokens.mutedForeground,
                ),
                tooltip: '文件变更',
                onPressed: () =>
                    context.push('/diff', extra: selectedSession.id),
              ),
              IconButton(
                icon: Icon(Icons.info_outline, color: tokens.mutedForeground),
                tooltip: '上下文',
                onPressed: () => context.push('/session-context'),
              ),
            ],
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: tokens.border.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            if (selectedSession != null)
              TodoListWidget(sessionID: selectedSession.id),
            Expanded(
              child: selectedSession != null
                  ? MessageList(
                      onNavigateToSubSession: (sessionId) =>
                          context.push('/sub-session', extra: sessionId),
                    )
                  : isPending
                  ? buildNewSessionWelcome()
                  : sessionsAsync.when(
                      data: (sessions) {
                        final text = sessions.isEmpty ? '暂无会话' : '请选择一个会话';
                        return Center(
                          child: Text(
                            text,
                            style: TextStyle(color: tokens.mutedForeground),
                          ),
                        );
                      },
                      error: (error, stack) =>
                          Center(child: Text('$error, $stack')),
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                    ),
            ),
            if ((selectedSession != null || isPending) &&
                selectedSession != null &&
                hasPermissionBlock)
              SessionPermissionDock(request: permissionRequest),
            if ((selectedSession != null || isPending) &&
                !hasPermissionBlock &&
                hasQuestion)
              const QuestionOverlay(),
            if ((selectedSession != null || isPending) &&
                !hasPermissionBlock &&
                !hasQuestion)
              const ChatInput(),
          ],
        ),
      ),
    );
  }
}
