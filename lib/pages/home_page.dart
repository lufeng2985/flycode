import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../service/api/models/session.dart';
import '../service/api/session_api.dart';
import '../widgets/message/message_list.dart';
import '../widgets/session/session_drawer.dart';

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
      drawer: SessionDrawer(
        sessionsAsync: sessionsAsync,
        selectedSession: selectedSession,
        onSessionSelected: (session) {
          ref.read(selectedSessionProvider.notifier).select(session);
          Navigator.pop(context);
        },
      ),
      body: selectedSession != null
          ? const MessageList()
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
