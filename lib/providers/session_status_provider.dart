import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../service/api/models/session_status.dart';

part 'session_status_provider.g.dart';

/// Tracks the backend-reported status for each session.
///
/// The map only contains entries for sessions that are non-idle.
/// A missing key is equivalent to [SessionStatusIdle].
@riverpod
class SessionStatusNotifier extends _$SessionStatusNotifier {
  @override
  Map<String, SessionStatus> build() => const {};

  void updateStatus(String sessionID, SessionStatus status) {
    if (status is SessionStatusIdle) {
      // Remove idle entries to keep the map small.
      if (state.containsKey(sessionID)) {
        state = Map.unmodifiable({
          for (final entry in state.entries)
            if (entry.key != sessionID) entry.key: entry.value,
        });
      }
    } else {
      state = Map.unmodifiable({...state, sessionID: status});
    }
  }

  /// Returns true when the given session is busy or retrying.
  bool isWorking(String sessionID) {
    final s = state[sessionID];
    return s != null && s.isWorking;
  }

  /// Returns the status for a given session, defaulting to [SessionStatusIdle].
  SessionStatus statusFor(String sessionID) {
    return state[sessionID] ?? const SessionStatusIdle();
  }
}
