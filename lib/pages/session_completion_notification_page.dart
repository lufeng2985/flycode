import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/session_completion_notification_provider.dart';

class SessionCompletionNotificationPage extends ConsumerWidget {
  const SessionCompletionNotificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(sessionCompletionNotificationModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('会话完成通知')),
      body: RadioGroup<SessionCompletionNotificationMode>(
        groupValue: selected,
        onChanged: (value) {
          if (value == null) return;
          ref
              .read(sessionCompletionNotificationModeProvider.notifier)
              .setMode(value);
        },
        child: ListView(
          children: [
            const SizedBox(height: 8),
            for (final mode in SessionCompletionNotificationMode.values)
              RadioListTile<SessionCompletionNotificationMode>(
                value: mode,
                title: Text(mode.label),
              ),
          ],
        ),
      ),
    );
  }
}
