import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'api_client.dart';
import 'models/project.dart';
import 'session_api.dart';

part 'project_api.g.dart';

@riverpod
Future<ProjectApi> projectApi(Ref ref) async {
  final client = await ref.watch(apiClientProvider.future);
  return ProjectApi(client);
}

@riverpod
class Projects extends _$Projects {
  @override
  Future<List<Project>> build() async {
    final api = await ref.watch(sessionApiProvider.future);
    final sessions = await api.getSessions(roots: true);

    final Map<String, int> dirMap = {};
    for (final s in sessions) {
      final dir = s.directory;
      final updated = s.time.updated;
      if (!dirMap.containsKey(dir) || updated > dirMap[dir]!) {
        dirMap[dir] = updated;
      }
    }

    return dirMap.entries
        .map((e) => Project.fromDirectory(e.key, updatedAt: e.value))
        .toList();
  }

  Project addProjectByDirectory(String directory) {
    final newProject = Project.fromDirectory(directory);
    final current = state.asData?.value ?? [];

    if (!current.any((p) => p.worktree == directory)) {
      state = AsyncData([...current, newProject]);
    }

    return newProject;
  }
}

class ProjectApi {
  final ApiClient _client;

  ProjectApi(this._client);
}
