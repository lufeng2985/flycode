import 'dart:async';
import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'current_directory_provider.dart';

part 'session_unread_provider.g.dart';

const String _kSessionUnreadCacheKeyPrefix = 'session_unread_v1:';

String sessionUnreadCacheKeyForDirectory(String directory) {
  return '$_kSessionUnreadCacheKeyPrefix${Uri.encodeComponent(directory)}';
}

class SessionUnreadState {
  final Map<String, int> unseenCountBySession;
  final Set<String> errorSessionIDs;

  const SessionUnreadState({
    required this.unseenCountBySession,
    required this.errorSessionIDs,
  });

  const SessionUnreadState.empty()
    : unseenCountBySession = const <String, int>{},
      errorSessionIDs = const <String>{};

  int unseenCount(String sessionID) => unseenCountBySession[sessionID] ?? 0;

  bool hasError(String sessionID) => errorSessionIDs.contains(sessionID);

  SessionUnreadState copyWith({
    Map<String, int>? unseenCountBySession,
    Set<String>? errorSessionIDs,
  }) {
    return SessionUnreadState(
      unseenCountBySession: unseenCountBySession ?? this.unseenCountBySession,
      errorSessionIDs: errorSessionIDs ?? this.errorSessionIDs,
    );
  }
}

@Riverpod(keepAlive: true)
class SessionUnreadNotifier extends _$SessionUnreadNotifier {
  @override
  SessionUnreadState build() {
    final directory = ref.watch(currentDirectoryProvider);
    if (directory == null || directory.isEmpty) {
      return const SessionUnreadState.empty();
    }

    unawaited(_restore(directory));
    return const SessionUnreadState.empty();
  }

  Future<void> addTurnComplete(String sessionID) async {
    if (sessionID.isEmpty) return;

    final current = state.unseenCountBySession;
    state = state.copyWith(
      unseenCountBySession: <String, int>{
        ...current,
        sessionID: (current[sessionID] ?? 0) + 1,
      },
    );
    await _persist();
  }

  Future<void> addError(String sessionID) async {
    if (sessionID.isEmpty) return;

    final current = state.unseenCountBySession;
    state = state.copyWith(
      unseenCountBySession: <String, int>{
        ...current,
        sessionID: (current[sessionID] ?? 0) + 1,
      },
      errorSessionIDs: <String>{...state.errorSessionIDs, sessionID},
    );
    await _persist();
  }

  Future<void> markViewed(String sessionID) async {
    if (sessionID.isEmpty) return;

    if (!state.unseenCountBySession.containsKey(sessionID) &&
        !state.errorSessionIDs.contains(sessionID)) {
      return;
    }

    state = state.copyWith(
      unseenCountBySession: <String, int>{
        for (final entry in state.unseenCountBySession.entries)
          if (entry.key != sessionID) entry.key: entry.value,
      },
      errorSessionIDs: <String>{
        for (final id in state.errorSessionIDs)
          if (id != sessionID) id,
      },
    );
    await _persist();
  }

  Future<void> clearSession(String sessionID) => markViewed(sessionID);

  Future<void> _restore(String directory) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = sessionUnreadCacheKeyForDirectory(directory);
      final raw = prefs.getString(key);
      if (raw == null || raw.trim().isEmpty) {
        if (!ref.mounted) return;
        if (ref.read(currentDirectoryProvider) != directory) return;
        state = const SessionUnreadState.empty();
        return;
      }

      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return;

      final unseenJson = json['unseen'];
      final errorsJson = json['errors'];

      final unseen = <String, int>{};
      if (unseenJson is Map<String, dynamic>) {
        for (final entry in unseenJson.entries) {
          final count = (entry.value as num?)?.toInt() ?? 0;
          if (entry.key.isNotEmpty && count > 0) {
            unseen[entry.key] = count;
          }
        }
      }

      final errors = <String>{};
      if (errorsJson is List<dynamic>) {
        for (final item in errorsJson) {
          if (item is String && item.isNotEmpty) {
            errors.add(item);
          }
        }
      }

      if (!ref.mounted) return;
      if (ref.read(currentDirectoryProvider) != directory) return;

      state = SessionUnreadState(
        unseenCountBySession: Map.unmodifiable(unseen),
        errorSessionIDs: Set.unmodifiable(errors),
      );
    } catch (_) {
      // Keep current state when local cache is invalid.
    }
  }

  Future<void> _persist() async {
    final directory = ref.read(currentDirectoryProvider);
    if (directory == null || directory.isEmpty) return;

    final payload = <String, dynamic>{
      'unseen': state.unseenCountBySession,
      'errors': state.errorSessionIDs.toList(),
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      sessionUnreadCacheKeyForDirectory(directory),
      jsonEncode(payload),
    );
  }
}

@riverpod
int sessionUnseenCount(Ref ref, String sessionID) {
  return ref.watch(sessionUnreadProvider).unseenCount(sessionID);
}

@riverpod
bool sessionHasUnreadError(Ref ref, String sessionID) {
  return ref.watch(sessionUnreadProvider).hasError(sessionID);
}
