import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../providers/project_provider.dart';
import 'api_client.dart';
import 'models/file_content.dart';

part 'file_api.g.dart';

@riverpod
Future<FileApi> fileApi(Ref ref) async {
  final client = await ref.watch(apiClientProvider.future);
  final project = await ref.watch(selectedProjectProvider.future);
  return FileApi(client, directory: project?.worktree);
}

class FileApi {
  final ApiClient _client;
  final String? _directory;

  FileApi(this._client, {String? directory}) : _directory = directory;

  Map<String, String> get _extraHeaders {
    final headers = <String, String>{};
    final dir = _directory;
    if (dir != null) {
      headers['x-opencode-directory'] = dir;
    }
    return headers;
  }

  Future<FileContent> getFileContent(String path) async {
    final Map<String, dynamic> json = await _client.get(
      '/file/content',
      queryParameters: {'path': path},
      extraHeaders: _extraHeaders,
    );
    return FileContent.fromJson(json);
  }

  /// Search for files matching [query] in the project.
  ///
  /// Returns a list of relative paths from the project root.
  /// Pass [dirs] = true to include directories in results.
  /// Pass [limit] to cap the result count.
  Future<List<String>> findFile(
    String query, {
    bool dirs = true,
    int? limit,
  }) async {
    final params = <String, String>{
      'query': query,
      'dirs': dirs ? 'true' : 'false',
    };
    if (limit != null) params['limit'] = limit.toString();

    final result = await _client.get(
      '/find/file',
      queryParameters: params,
      extraHeaders: _extraHeaders,
    );
    return List<String>.from(result as List);
  }
}
