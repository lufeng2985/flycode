import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../providers/project_provider.dart';
import 'api_client.dart';
import 'models/file_content.dart';
import 'models/file_node.dart';

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

  /// 在 [searchRoot] 目录下关键词搜索子目录（[GET /find/file]）。
  ///
  /// 与 [findFile] 不同，此方法接受任意 [searchRoot] 作为搜索根目录，
  /// 用于目录选择器场景（搜索根固定，不依赖当前已选项目）。
  /// [searchRoot] 为 null 时不传 directory，服务端用 process.cwd()。
  /// 返回相对路径列表。
  Future<List<String>> findDirectory(
    String query, {
    String? searchRoot,
    int limit = 50,
  }) async {
    final params = <String, String>{
      'query': query,
      'type': 'directory',
      'limit': limit.toString(),
      'dirs': 'true',
    };
    if (searchRoot != null && searchRoot.isNotEmpty) {
      params['directory'] = searchRoot;
    }

    final result = await _client.get('/find/file', queryParameters: params);
    return List<String>.from(result as List);
  }

  /// 列出 [directory] 目录的直接子内容（[GET /file]）。
  ///
  /// 用于路径导航模式，每次导航一层目录。
  /// 只返回 [FileNode] 列表，客户端按需过滤目录。
  Future<List<FileNode>> listDirectory(String directory) async {
    final result = await _client.get(
      '/file',
      queryParameters: {'path': '', 'directory': directory},
    );
    if (result is! List) return [];
    return result
        .whereType<Map<String, dynamic>>()
        .map(FileNode.fromJson)
        .toList();
  }
}
