import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../service/api/models/permission.dart';
import '../service/api/models/session.dart';
import '../service/api/permission_api.dart';
import '../service/api/session_api.dart';
import 'project_provider.dart';
import 'session_provider.dart';

final pendingPermissionsProvider =
    AsyncNotifierProvider<PendingPermissionsNotifier, List<PermissionRequest>>(
      PendingPermissionsNotifier.new,
    );

class PendingPermissionsNotifier
    extends AsyncNotifier<List<PermissionRequest>> {
  final Set<String> _responding = <String>{};

  @override
  Future<List<PermissionRequest>> build() async {
    final project = await ref.watch(selectedProjectProvider.future);
    final api = await ref.watch(permissionApiProvider.future);
    return api.getPermissions(directory: project?.worktree);
  }

  bool isResponding(String requestID) => _responding.contains(requestID);

  void addPermission(PermissionRequest request) {
    final current = state.asData?.value ?? [];
    if (current.any((p) => p.id == request.id)) return;
    state = AsyncData([...current, request]);
  }

  void removePermission(String requestID) {
    final current = state.asData?.value ?? [];
    state = AsyncData(current.where((p) => p.id != requestID).toList());
    _responding.remove(requestID);
  }

  Future<void> respond(
    PermissionRequest request, {
    required PermissionReplyAction reply,
  }) async {
    if (_responding.contains(request.id)) return;

    _responding.add(request.id);
    state = AsyncData(List<PermissionRequest>.from(state.asData?.value ?? []));

    try {
      final project = await ref.read(selectedProjectProvider.future);
      final api = await ref.read(permissionApiProvider.future);
      await api.replyPermission(
        request.id,
        sessionID: request.sessionID,
        reply: reply,
        directory: project?.worktree,
      );
    } finally {
      _responding.remove(request.id);
      state = AsyncData(
        List<PermissionRequest>.from(state.asData?.value ?? []),
      );
    }
  }
}

final allSessionsProvider = FutureProvider<List<Session>>((ref) async {
  final api = await ref.watch(sessionApiProvider.future);
  final project = await ref.watch(selectedProjectProvider.future);
  return api.getSessions(directory: project?.worktree, roots: false);
});

final currentSessionPermissionRequestProvider = Provider<PermissionRequest?>((
  ref,
) {
  final selectedState = ref.watch(selectedSessionProvider);
  final sessionID = selectedState.session?.id;
  if (sessionID == null) return null;

  final pending = ref.watch(pendingPermissionsProvider).asData?.value ?? [];
  if (pending.isEmpty) return null;

  final allSessions = ref.watch(allSessionsProvider).asData?.value ?? [];
  final subtree = collectSessionTree(sessionID, allSessions);
  for (final request in pending) {
    if (subtree.contains(request.sessionID)) return request;
  }
  return null;
});

final currentSessionHasPermissionBlockProvider = Provider<bool>((ref) {
  return ref.watch(currentSessionPermissionRequestProvider) != null;
});

Set<String> collectSessionTree(String rootID, List<Session> allSessions) {
  final childrenByParent = <String, List<String>>{};
  for (final session in allSessions) {
    final parentID = session.parentID;
    if (parentID == null || parentID.isEmpty) continue;
    childrenByParent.putIfAbsent(parentID, () => <String>[]).add(session.id);
  }

  final visited = <String>{};
  final queue = <String>[rootID];
  while (queue.isNotEmpty) {
    final id = queue.removeAt(0);
    if (!visited.add(id)) continue;
    final children = childrenByParent[id] ?? const <String>[];
    queue.addAll(children);
  }
  return visited;
}
