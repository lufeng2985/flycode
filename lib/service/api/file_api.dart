import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'api_client.dart';
import 'models/file_content.dart';

part 'file_api.g.dart';

@riverpod
Future<FileApi> fileApi(Ref ref) async {
  final client = await ref.watch(apiClientProvider.future);
  return FileApi(client);
}

class FileApi {
  final ApiClient _client;

  FileApi(this._client);

  Future<FileContent> getFileContent(String path) async {
    final Map<String, dynamic> json = await _client.get(
      '/file/content',
      queryParameters: {'path': path},
    );
    return FileContent.fromJson(json);
  }
}
