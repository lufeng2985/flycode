import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flycode/l10n/app_localizations.dart';

const _kSessionCompletionNotificationModeKey =
    'session_completion_notification_mode_v1';

enum SessionCompletionNotificationMode { none, backgroundOnly, always }

extension SessionCompletionNotificationModeX
    on SessionCompletionNotificationMode {
  String label(AppLocalizations l10n) {
    switch (this) {
      case SessionCompletionNotificationMode.none:
        return l10n.sessionCompletionNotificationModeNone;
      case SessionCompletionNotificationMode.backgroundOnly:
        return l10n.sessionCompletionNotificationModeBackgroundOnly;
      case SessionCompletionNotificationMode.always:
        return l10n.sessionCompletionNotificationModeAlways;
    }
  }

  String get storageValue {
    switch (this) {
      case SessionCompletionNotificationMode.none:
        return 'none';
      case SessionCompletionNotificationMode.backgroundOnly:
        return 'backgroundOnly';
      case SessionCompletionNotificationMode.always:
        return 'always';
    }
  }

  static SessionCompletionNotificationMode fromStorageValue(String? value) {
    switch (value) {
      case 'none':
        return SessionCompletionNotificationMode.none;
      case 'always':
        return SessionCompletionNotificationMode.always;
      default:
        return SessionCompletionNotificationMode.backgroundOnly;
    }
  }
}

final sessionCompletionNotificationModeProvider =
    NotifierProvider<
      SessionCompletionNotificationModeNotifier,
      SessionCompletionNotificationMode
    >(SessionCompletionNotificationModeNotifier.new);

class SessionCompletionNotificationModeNotifier
    extends Notifier<SessionCompletionNotificationMode> {
  @override
  SessionCompletionNotificationMode build() {
    unawaited(_restore());
    return SessionCompletionNotificationMode.backgroundOnly;
  }

  Future<void> setMode(SessionCompletionNotificationMode mode) async {
    if (state == mode) return;
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kSessionCompletionNotificationModeKey,
      mode.storageValue,
    );
  }

  Future<void> _restore() async {
    final mode = await readSessionCompletionNotificationModeFromStorage();
    if (!ref.mounted) return;
    state = mode;
  }
}

Future<SessionCompletionNotificationMode>
readSessionCompletionNotificationModeFromStorage() async {
  final prefs = await SharedPreferences.getInstance();
  final value = prefs.getString(_kSessionCompletionNotificationModeKey);
  return SessionCompletionNotificationModeX.fromStorageValue(value);
}
