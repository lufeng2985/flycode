import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'current_directory_provider.dart';

part 'session_unread_provider.g.dart';

const String _kSessionUnreadCacheKeyPrefix = 'session_unread_v1:';

typedef SessionUnreadPreferencesLoader = Future<SharedPreferences> Function();

@visibleForTesting
SessionUnreadPreferencesLoader debugSessionUnreadPreferencesLoader =
    SharedPreferences.getInstance;

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

enum _SessionUnreadMutationType { addTurnComplete, addError, markViewed }

class _SessionUnreadMutation {
  const _SessionUnreadMutation._(this.type, this.sessionID);

  final _SessionUnreadMutationType type;
  final String sessionID;

  const _SessionUnreadMutation.addTurnComplete(String sessionID)
    : this._(_SessionUnreadMutationType.addTurnComplete, sessionID);

  const _SessionUnreadMutation.addError(String sessionID)
    : this._(_SessionUnreadMutationType.addError, sessionID);

  const _SessionUnreadMutation.markViewed(String sessionID)
    : this._(_SessionUnreadMutationType.markViewed, sessionID);

  SessionUnreadState apply(SessionUnreadState current) {
    switch (type) {
      case _SessionUnreadMutationType.addTurnComplete:
        return current.copyWith(
          unseenCountBySession: <String, int>{
            ...current.unseenCountBySession,
            sessionID: (current.unseenCountBySession[sessionID] ?? 0) + 1,
          },
        );
      case _SessionUnreadMutationType.addError:
        return current.copyWith(
          unseenCountBySession: <String, int>{
            ...current.unseenCountBySession,
            sessionID: (current.unseenCountBySession[sessionID] ?? 0) + 1,
          },
          errorSessionIDs: <String>{...current.errorSessionIDs, sessionID},
        );
      case _SessionUnreadMutationType.markViewed:
        return current.copyWith(
          unseenCountBySession: <String, int>{
            for (final entry in current.unseenCountBySession.entries)
              if (entry.key != sessionID) entry.key: entry.value,
          },
          errorSessionIDs: <String>{
            for (final id in current.errorSessionIDs)
              if (id != sessionID) id,
          },
        );
    }
  }
}

@Riverpod(keepAlive: true)
class SessionUnreadNotifier extends _$SessionUnreadNotifier {
  int _restoreGeneration = 0;
  String? _hydratingDirectory;
  final List<_SessionUnreadMutation> _pendingMutations =
      <_SessionUnreadMutation>[];

  @override
  SessionUnreadState build() {
    final directory = ref.watch(currentDirectoryProvider);
    if (directory == null || directory.isEmpty) {
      _cancelRestore();
      return const SessionUnreadState.empty();
    }

    _startRestore(directory);
    return const SessionUnreadState.empty();
  }

  Future<void> addTurnComplete(String sessionID) async {
    if (sessionID.isEmpty) return;
    await _applyMutation(_SessionUnreadMutation.addTurnComplete(sessionID));
  }

  Future<void> addError(String sessionID) async {
    if (sessionID.isEmpty) return;
    await _applyMutation(_SessionUnreadMutation.addError(sessionID));
  }

  Future<void> markViewed(String sessionID) async {
    if (sessionID.isEmpty) return;
    if (!_isHydrating &&
        !state.unseenCountBySession.containsKey(sessionID) &&
        !state.errorSessionIDs.contains(sessionID)) {
      return;
    }

    await _applyMutation(_SessionUnreadMutation.markViewed(sessionID));
  }

  Future<void> clearSession(String sessionID) => markViewed(sessionID);

  bool get _isHydrating =>
      _restoreGeneration > 0 && _hydratingDirectory != null;

  void _startRestore(String directory) {
    _restoreGeneration += 1;
    _hydratingDirectory = directory;
    _pendingMutations.clear();
    final generation = _restoreGeneration;
    unawaited(_restore(directory, generation));
  }

  void _cancelRestore() {
    _restoreGeneration += 1;
    _hydratingDirectory = null;
    _pendingMutations.clear();
  }

  Future<void> _restore(String directory, int generation) async {
    SessionUnreadState restoredState = const SessionUnreadState.empty();

    try {
      final prefs = await debugSessionUnreadPreferencesLoader();
      final key = sessionUnreadCacheKeyForDirectory(directory);
      final raw = prefs.getString(key);
      restoredState = _parseRestoredState(raw);
    } catch (_) {
      // Keep current state when local cache is invalid.
    }

    if (!ref.mounted) return;
    if (_restoreGeneration != generation) return;
    if (ref.read(currentDirectoryProvider) != directory) return;

    var nextState = restoredState;
    for (final mutation in _pendingMutations) {
      nextState = mutation.apply(nextState);
    }

    _pendingMutations.clear();
    _restoreGeneration = 0;
    _hydratingDirectory = null;
    state = _freezeState(nextState);

    await _persistState(directory, state);
  }

  Future<void> _persist() async {
    final directory = ref.read(currentDirectoryProvider);
    if (directory == null || directory.isEmpty) return;

    await _persistState(directory, state);
  }

  Future<void> _applyMutation(_SessionUnreadMutation mutation) async {
    if (_isHydrating) {
      _pendingMutations.add(mutation);
      state = _freezeState(mutation.apply(state));
      return;
    }

    state = _freezeState(mutation.apply(state));
    await _persist();
  }

  SessionUnreadState _parseRestoredState(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return const SessionUnreadState.empty();
    }

    final json = jsonDecode(raw);
    if (json is! Map<String, dynamic>) {
      return const SessionUnreadState.empty();
    }

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

    return SessionUnreadState(
      unseenCountBySession: Map.unmodifiable(unseen),
      errorSessionIDs: Set.unmodifiable(errors),
    );
  }

  SessionUnreadState _freezeState(SessionUnreadState source) {
    return SessionUnreadState(
      unseenCountBySession: Map.unmodifiable(source.unseenCountBySession),
      errorSessionIDs: Set.unmodifiable(source.errorSessionIDs),
    );
  }

  Future<void> _persistState(
    String directory,
    SessionUnreadState snapshot,
  ) async {
    final payload = <String, dynamic>{
      'unseen': snapshot.unseenCountBySession,
      'errors': snapshot.errorSessionIDs.toList(),
    };

    final prefs = await debugSessionUnreadPreferencesLoader();
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
