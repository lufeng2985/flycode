import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../service/api/models/project.dart';
import '../service/api/project_api.dart';
import 'server_config_provider.dart';

part 'project_provider.g.dart';

@riverpod
class SelectedProjectNotifier extends _$SelectedProjectNotifier {
  @override
  Future<Project?> build() async {
    // 监听服务器配置变化，配置变化时自动重置
    await ref.watch(serverConfigProvider.future);

    final projects = await ref.read(projectsProvider.future);
    if (projects.isEmpty) return null;
    final sorted = List<Project>.from(projects.where((p) => p.id != 'global'))
      ..sort((a, b) => b.time.updated.compareTo(a.time.updated));
    if (sorted.isEmpty) return null;
    return sorted.first;
  }

  void select(Project project) {
    state = AsyncData(project);
  }
}
