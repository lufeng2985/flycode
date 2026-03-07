import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../providers/project_provider.dart';
import 'api_client.dart';
import 'models/command.dart';

part 'command_api.g.dart';

@riverpod
Future<CommandApi> commandApi(Ref ref) async {
  final client = await ref.watch(apiClientProvider.future);
  return CommandApi(client);
}

@riverpod
Future<List<Command>> commands(Ref ref) async {
  final api = await ref.watch(commandApiProvider.future);
  final project = await ref.watch(selectedProjectProvider.future);
  return api.getCommands(directory: project?.worktree);
}

class CommandApi {
  final ApiClient _client;

  CommandApi(this._client);

  Future<List<Command>> getCommands({String? directory}) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    final List<dynamic> json = await _client.get(
      '/command',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    return json
        .map((e) => Command.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
