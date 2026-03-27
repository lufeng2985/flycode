import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/session_completion_notification_provider.dart';
import '../service/notification/local_notification_service.dart';

class SessionCompletionNotificationPage extends ConsumerWidget {
  const SessionCompletionNotificationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(sessionCompletionNotificationModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('会话完成通知')),
      body: RadioGroup<SessionCompletionNotificationMode>(
        groupValue: selected,
        onChanged: (value) async {
          if (value == null) return;
          await ref
              .read(sessionCompletionNotificationModeProvider.notifier)
              .setMode(value);
          if (value == SessionCompletionNotificationMode.none) return;
          await ref
              .read(localNotificationServiceProvider)
              .ensurePermissionPrompted();
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
