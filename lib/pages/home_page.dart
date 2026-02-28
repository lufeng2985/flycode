import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../service/api/models/session.dart';
import '../service/api/models/message.dart';
import '../service/api/models/parts.dart';
import '../service/api/session_api.dart';

part 'home_page.g.dart';

@riverpod
class SelectedSessionNotifier extends _$SelectedSessionNotifier {
  @override
  Session? build() => null;

  void select(Session? session) {
    state = session;
  }
}

class MyHomePage extends ConsumerWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsProvider);
    final selectedSession = ref.watch(selectedSessionProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(selectedSession?.title ?? title),
        centerTitle: true,
      ),
      drawer: _SessionDrawer(
        sessionsAsync: sessionsAsync,
        selectedSession: selectedSession,
        onSessionSelected: (session) {
          ref.read(selectedSessionProvider.notifier).select(session);
          Navigator.pop(context);
        },
      ),
      body: selectedSession != null
          ? const _MessageList()
          : sessionsAsync.when(
              data: (sessions) => sessions.isEmpty
                  ? const Center(child: Text('No sessions'))
                  : const Center(child: Text('Select a session from drawer')),
              error: (error, stack) => Center(child: Text('$error, $stack')),
              loading: () => const Center(child: CircularProgressIndicator()),
            ),
    );
  }
}

class _MessageList extends ConsumerWidget {
  const _MessageList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(sessionMessagesProvider);

    return messagesAsync.when(
      data: (messages) {
        if (messages.isEmpty) {
          return const Center(
            child: Text(
              'No messages yet',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final messageWithParts = messages[messages.length - 1 - index];
            final prevIndex = messages.length - 2 - index;
            final prevMessage = prevIndex >= 0 ? messages[prevIndex] : null;
            final prevIsUser = prevMessage?.info is UserMessage;
            return _MessageBubble(
              messageWithParts: messageWithParts,
              prevIsUser: prevIsUser,
            );
          },
        );
      },
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $error'),
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageWithParts messageWithParts;
  final bool prevIsUser;

  const _MessageBubble({
    required this.messageWithParts,
    required this.prevIsUser,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = messageWithParts.info is UserMessage;
    final userMessage = isUser ? messageWithParts.info as UserMessage : null;
    final assistantMessage = !isUser
        ? messageWithParts.info as AssistantMessage
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: isUser
                ? MediaQuery.of(context).size.width * 0.75
                : MediaQuery.of(context).size.width,
          ),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isUser
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MessageHeader(
                isUser: isUser,
                userMessage: userMessage,
                assistantMessage: assistantMessage,
              ),
              const SizedBox(height: 8),
              ...messageWithParts.parts.map(
                (part) => _MessagePart(part: part, isUser: isUser),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageHeader extends StatelessWidget {
  final bool isUser;
  final UserMessage? userMessage;
  final AssistantMessage? assistantMessage;

  const _MessageHeader({
    required this.isUser,
    this.userMessage,
    this.assistantMessage,
  });

  @override
  Widget build(BuildContext context) {
    final time = isUser
        ? userMessage?.time.created
        : assistantMessage?.time.created;
    final agent = isUser ? userMessage?.agent : assistantMessage?.modelID;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isUser ? Icons.person : Icons.smart_toy,
          size: 14,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          isUser ? 'You' : (agent ?? 'Assistant'),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        if (time != null) ...[
          const SizedBox(width: 8),
          Text(
            _formatTime(time),
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ],
    );
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _MessagePart extends StatelessWidget {
  final Object part;
  final bool isUser;

  const _MessagePart({required this.part, required this.isUser});

  @override
  Widget build(BuildContext context) {
    if (part is TextPart) {
      final textPart = part as TextPart;
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: SelectableText(
          textPart.text,
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
      );
    } else if (part is ToolPart) {
      return _ToolUseWidget(toolPart: part as ToolPart);
    } else if (part is ReasoningPart) {
      return _ReasoningWidget(reasoning: part as ReasoningPart);
    }
    return const SizedBox.shrink();
  }
}

class _ToolUseWidget extends StatefulWidget {
  final ToolPart toolPart;

  const _ToolUseWidget({required this.toolPart});

  @override
  State<_ToolUseWidget> createState() => _ToolUseWidgetState();
}

class _ToolUseWidgetState extends State<_ToolUseWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final toolName = widget.toolPart.tool;
    final inputJson = _getToolInputJson();
    final output = _getToolOutput();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Icon(Icons.build, size: 14, color: Colors.orange[700]),
                  const SizedBox(width: 6),
                  Text(
                    toolName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.orange[700],
                      fontFamily: 'monospace',
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            if (inputJson != null) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(10),
                child: _JsonViewer(jsonString: inputJson),
              ),
            ],
            if (output != null) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 14,
                          color: Colors.green[700],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Result',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _JsonViewer(jsonString: output),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String? _getToolInputJson() {
    final state = widget.toolPart.state;
    if (state is ToolStatePending) {
      return state.raw;
    } else if (state is ToolStateRunning) {
      return state.input.isNotEmpty ? _encodeJson(state.input) : null;
    } else if (state is ToolStateCompleted) {
      return state.input.isNotEmpty ? _encodeJson(state.input) : null;
    } else if (state is ToolStateError) {
      return state.input.isNotEmpty ? _encodeJson(state.input) : null;
    }
    return null;
  }

  String? _getToolOutput() {
    final state = widget.toolPart.state;
    if (state is ToolStateCompleted) {
      return state.output;
    } else if (state is ToolStateError) {
      return 'Error: ${state.error}';
    }
    return null;
  }

  String _encodeJson(Map<String, dynamic> json) {
    return json.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }
}

class _ReasoningWidget extends StatelessWidget {
  final ReasoningPart reasoning;

  const _ReasoningWidget({required this.reasoning});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, size: 14, color: Colors.purple[700]),
              const SizedBox(width: 6),
              Text(
                'Reasoning',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            reasoning.text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.purple[900],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _JsonViewer extends StatelessWidget {
  final String? jsonString;

  const _JsonViewer({this.jsonString});

  @override
  Widget build(BuildContext context) {
    if (jsonString == null || jsonString!.isEmpty) {
      return Text(
        'null',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
          fontFamily: 'monospace',
        ),
      );
    }

    return Text(
      jsonString!,
      style: TextStyle(
        fontSize: 12,
        color: Colors.grey[800],
        fontFamily: 'monospace',
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final bool isAssistant;

  const _Avatar({required this.isAssistant});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: isAssistant
          ? Theme.of(context).colorScheme.primary
          : Colors.grey[400],
      child: Icon(
        isAssistant ? Icons.smart_toy : Icons.person,
        size: 16,
        color: Colors.white,
      ),
    );
  }
}

class _SessionDrawer extends StatelessWidget {
  final AsyncValue<List<Session>> sessionsAsync;
  final Session? selectedSession;
  final void Function(Session) onSessionSelected;

  const _SessionDrawer({
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
