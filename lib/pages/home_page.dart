import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/l10n.dart';
import '../models/chat_route_args.dart';
import '../providers/chat_view_state_provider.dart';
import '../providers/current_directory_provider.dart';
import '../service/api/models/session.dart';
import '../service/api/session_api.dart';
import '../providers/global_event_provider.dart';
import '../providers/permission_provider.dart';
import '../providers/question_provider.dart';
import '../theme/app_tokens.dart';
import '../widgets/message/message_list.dart';
import '../widgets/message/chat_input.dart';
import '../widgets/permission/session_permission_dock.dart';
import '../widgets/question/question_card.dart';
import '../widgets/session/todo_list_widget.dart';

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key, required this.title, this.args});

  final String title;
  final ChatRouteArgs? args;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  bool _didBootstrap = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didBootstrap) return;
    _didBootstrap = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapChatContext();
    });
  }

  Future<void> _bootstrapChatContext() async {
    final args = widget.args;
    final directory = args?.directory.trim();
    if (directory == null || directory.isEmpty) {
      return;
    }

    ref.read(currentDirectoryProvider.notifier).set(directory);

    final stateNotifier = ref.read(chatViewStateProvider.notifier);
    if (args?.startNew == true) {
      stateNotifier.startNew();
      return;
    }

    stateNotifier.clear();

    try {
      final sessions = await ref.refresh(sessionsProvider.future);
      if (!mounted) return;

      if (sessions.isEmpty) {
        stateNotifier.startNew();
        return;
      }

      final initialSessionId = args?.initialSessionId;
      if (initialSessionId != null && initialSessionId.isNotEmpty) {
        for (final session in sessions) {
          if (session.id == initialSessionId) {
            stateNotifier.selectSessionId(session.id);
            return;
          }
        }
      }

      final sortedSessions = List<Session>.from(sessions)
        ..sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0));
      stateNotifier.selectSessionId(sortedSessions.first.id);
    } catch (_) {
      if (!mounted) return;
      stateNotifier.startNew();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tokens = context.tokens;

    ref.watch(globalEventListenerProvider);
    final sessionsAsync = ref.watch(sessionsProvider);
    final chatState = ref.watch(chatViewStateProvider);
    final sessionId = chatState.sessionId;
    final isPending = chatState.isPending;
    final hasActiveOrPendingSession = sessionId != null || isPending;
    Session? selectedSession;
    final sessions = sessionsAsync.asData?.value;
    if (sessions != null && sessionId != null) {
      for (final session in sessions) {
        if (session.id == sessionId) {
          selectedSession = session;
          break;
        }
      }
    }
    final permissionRequest = sessionId == null
        ? null
        : ref.watch(currentSessionPermissionRequestProvider(sessionId));
    final hasPermissionBlock = permissionRequest != null;
    final hasQuestion = sessionId == null
        ? false
        : ref.watch(currentSessionHasQuestionProvider(sessionId));

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
              l10n.homeNewSessionTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: tokens.mutedForeground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.homeNewSessionSubtitle,
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
        ref.read(chatViewStateProvider.notifier).clear();
        ref.read(currentDirectoryProvider.notifier).clear();
      },
      child: Scaffold(
        appBar: AppBar(
          actions: [
            if (selectedSession != null) ...[
              _HeaderActionButton(
                icon: Icons.difference_outlined,
                tooltip: l10n.homeTooltipFileDiff,
                onTap: () => context.push('/diff', extra: selectedSession!.id),
              ),
              const SizedBox(width: 8),
              _HeaderActionButton(
                icon: Icons.info_outline,
                tooltip: l10n.homeTooltipContext,
                onTap: () => context.push(
                  '/session-context',
                  extra: selectedSession!.id,
                ),
              ),
              const SizedBox(width: 12),
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
                      sessionID: selectedSession.id,
                      onNavigateToSubSession: (sessionId) =>
                          context.push('/sub-session', extra: sessionId),
                    )
                  : isPending
                  ? buildNewSessionWelcome()
                  : sessionId != null
                  ? const Center(child: CircularProgressIndicator())
                  : sessionsAsync.when(
                      data: (sessions) {
                        final text = sessions.isEmpty
                            ? l10n.homeNoSession
                            : l10n.homeSelectSession;
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
            if (selectedSession != null && hasPermissionBlock)
              SessionPermissionDock(request: permissionRequest),
            if (hasActiveOrPendingSession && !hasPermissionBlock && hasQuestion)
              QuestionOverlay(sessionID: sessionId),
            if (hasActiveOrPendingSession &&
                !hasPermissionBlock &&
                !hasQuestion)
              const ChatInput(),
          ],
        ),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 20, color: tokens.mutedForeground),
        splashRadius: 20,
      ),
    );
  }
}
