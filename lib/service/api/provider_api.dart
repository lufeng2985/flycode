import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'api_client.dart';
import 'models/provider.dart';

part 'provider_api.g.dart';

@riverpod
Future<ProviderApi> providerApi(Ref ref) async {
  final client = await ref.watch(apiClientProvider.future);
  return ProviderApi(client);
}

class ProviderApi {
  final ApiClient _client;

  ProviderApi(this._client);

  Future<ProviderListResponse> list({String? directory}) async {
    final json = await _client.get(
      '/provider',
      queryParameters: directory != null ? {'directory': directory} : null,
    );
    return ProviderListResponse.fromJson(json as Map<String, dynamic>);
  }
}
