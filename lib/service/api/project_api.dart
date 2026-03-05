import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'api_client.dart';
import 'models/project.dart';

part 'project_api.g.dart';

@riverpod
ProjectApi projectApi(Ref ref) {
  final client = ref.watch(apiClientProvider);
  return ProjectApi(client);
}

@riverpod
Future<List<Project>> projects(Ref ref) async {
  final api = ref.watch(projectApiProvider);
  return api.getProjects();
}

class ProjectApi {
  final ApiClient _client;

  ProjectApi(this._client);

  Future<List<Project>> getProjects({String? directory}) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    final List<dynamic> json = await _client.get(
      '/project',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    return json
        .map((e) => Project.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
