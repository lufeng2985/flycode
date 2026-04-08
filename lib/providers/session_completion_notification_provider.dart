import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flycode/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shared_preferences_provider.dart';

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
  bool _isRestoring = false;
  int _restoreGeneration = 0;
  SessionCompletionNotificationMode? _pendingMode;
  Completer<void>? _restoreCompleter;

  @override
  SessionCompletionNotificationMode build() {
    _startRestore();
    return SessionCompletionNotificationMode.backgroundOnly;
  }

  Future<void> setMode(SessionCompletionNotificationMode mode) async {
    if (state == mode && _pendingMode == null) return;
    state = mode;

    if (_isRestoring) {
      _pendingMode = mode;
      await _restoreCompleter?.future;
      return;
    }

    await _persist(mode);
    _pendingMode = null;
  }

  void _startRestore() {
    _isRestoring = true;
    final generation = ++_restoreGeneration;
    _restoreCompleter = Completer<void>();
    unawaited(_restore(generation));
  }

  Future<void> _restore(int generation) async {
    final restoreCompleter = _restoreCompleter;

    try {
      final restoredMode =
          await readSessionCompletionNotificationModeFromStorage(
            () => ref.read(sharedPreferencesProvider.future),
          );
      if (!ref.mounted || _restoreGeneration != generation) return;

      final nextMode = _pendingMode ?? restoredMode;
      _isRestoring = false;
      _restoreGeneration = 0;
      _pendingMode = null;

      if (state != nextMode) {
        state = nextMode;
      }

      await _persist(nextMode);
    } finally {
      if (identical(_restoreCompleter, restoreCompleter)) {
        _restoreCompleter = null;
      }
      if (restoreCompleter != null && !restoreCompleter.isCompleted) {
        restoreCompleter.complete();
      }
    }
  }

  Future<void> _persist(SessionCompletionNotificationMode mode) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(
      _kSessionCompletionNotificationModeKey,
      mode.storageValue,
    );
  }
}

Future<SessionCompletionNotificationMode>
readSessionCompletionNotificationModeFromStorage(
  Future<SharedPreferences> Function() preferencesLoader,
) async {
  final prefs = await preferencesLoader();
  final value = prefs.getString(_kSessionCompletionNotificationModeKey);
  return SessionCompletionNotificationModeX.fromStorageValue(value);
}
