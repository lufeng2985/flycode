import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../service/api/models/project.dart';
import 'server_config_provider.dart';

part 'project_provider.g.dart';

@riverpod
class SelectedProjectNotifier extends _$SelectedProjectNotifier {
  @override
  Future<Project?> build() async {
    // 监听服务器配置变化，配置变化时自动重置。
    await ref.watch(serverConfigProvider.future);

    // 默认不自动选择项目，只有用户进入流程后手动选择。
    return null;
  }

  void select(Project project) {
    state = AsyncData(project);
  }

  void clear() {
    state = const AsyncData(null);
  }
}
