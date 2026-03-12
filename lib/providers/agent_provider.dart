import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../service/api/global_api.dart';
import '../service/api/models/agent.dart';
import 'project_provider.dart';

part 'agent_provider.g.dart';

/// Fetches the list of available agents from the server, filtered to only
/// include agents that are visible in the switcher (mode != 'subagent' and
/// not hidden).
@riverpod
Future<List<Agent>> agents(Ref ref) async {
  final api = await ref.watch(globalApiProvider.future);
  final project = await ref.watch(selectedProjectProvider.future);

  final all = await api.getAgents(directory: project?.worktree);
  return all.where((a) => a.mode != 'subagent' && !a.hidden).toList();
}
