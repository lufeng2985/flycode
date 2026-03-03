import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'api_client.dart';
import 'models/config.dart';
import 'models/global_event.dart';
import 'models/health.dart';

part 'global_api.g.dart';

@riverpod
GlobalApi globalApi(Ref ref) {
  final client = ref.watch(apiClientProvider);
  return GlobalApi(client);
}

class GlobalApi {
  final ApiClient _client;

  GlobalApi(this._client);

  Future<Health> getHealth() async {
    final json = await _client.get('/global/health');
    return Health.fromJson(json);
  }

  Future<Config> getConfig() async {
    final json = await _client.get('/global/config');
    return Config.fromJson(json);
  }

  Future<Config> updateConfig(Config config) async {
    final json = await _client.patch('/global/config', body: config.toJson());
    return Config.fromJson(json);
  }

  Stream<GlobalEvent> subscribeToGlobalEvents() async* {
    final stream = _client.streamGet('/global/event');
    await for (final data in stream) {
      if (data.trim().isEmpty) continue;
      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
        yield parseGlobalEvent(json);
      } catch (e) {
        // Skip invalid JSON
        continue;
      }
    }
  }
}
