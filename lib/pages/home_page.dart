import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../service/api/session_api.dart';
import '../providers/global_event_provider.dart';
import '../providers/session_provider.dart';
import '../widgets/message/message_list.dart';
import '../widgets/message/chat_input.dart';
import '../widgets/session/session_drawer.dart';

class MyHomePage extends ConsumerWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(globalEventListenerProvider);
    final sessionsAsync = ref.watch(sessionsProvider);
    final selectedSession = ref.watch(selectedSessionProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.grey),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  '状态',
                  style: TextStyle(color: Colors.black87, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey[300]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                backgroundColor: Colors.grey[100],
              ),
              child: const Text(
                '分享',
                style: TextStyle(color: Colors.black87, fontSize: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.black, width: 2),
                      ),
                    ),
                    child: const Text(
                      '会话',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    child: const Text(
                      '5 个文件变更',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: SessionDrawer(
        sessionsAsync: sessionsAsync,
        selectedSession: selectedSession,
        onSessionSelected: (session) {
          ref.read(selectedSessionProvider.notifier).select(session);
          Navigator.pop(context);
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: selectedSession != null
                ? const MessageList()
                : sessionsAsync.when(
                    data: (sessions) => sessions.isEmpty
                        ? const Center(child: Text('No sessions'))
                        : const Center(
                            child: Text('Select a session from drawer'),
                          ),
                    error: (error, stack) =>
                        Center(child: Text('$error, $stack')),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                  ),
          ),
          if (selectedSession != null) const ChatInput(),
        ],
      ),
    );
  }
}
