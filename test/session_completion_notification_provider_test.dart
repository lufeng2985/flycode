import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flycode/providers/session_completion_notification_provider.dart';

Future<void> _flushAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('defaults to background-only mode', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(sessionCompletionNotificationModeProvider);
    await _flushAsyncWork();

    expect(
      container.read(sessionCompletionNotificationModeProvider),
      SessionCompletionNotificationMode.backgroundOnly,
    );
  });

  test('restores persisted mode from shared preferences', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'session_completion_notification_mode_v1': 'always',
    });

    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(sessionCompletionNotificationModeProvider);
    await _flushAsyncWork();

    expect(
      container.read(sessionCompletionNotificationModeProvider),
      SessionCompletionNotificationMode.always,
    );
  });

  test('setMode persists selected value', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(sessionCompletionNotificationModeProvider.notifier)
        .setMode(SessionCompletionNotificationMode.none);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('session_completion_notification_mode_v1'), 'none');
  });
}
