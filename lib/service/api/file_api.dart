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

  Future<FileContent> getFileContent(String path) async {
    final extraHeaders = <String, String>{};
    if (_directory != null) {
      extraHeaders['x-opencode-directory'] = _directory;
    }

    final Map<String, dynamic> json = await _client.get(
      '/file/content',
      queryParameters: {'path': path},
      extraHeaders: extraHeaders,
    );
    return FileContent.fromJson(json);
  }
}
