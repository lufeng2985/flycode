import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/server_config.dart';
import 'shared_preferences_provider.dart';

part 'server_config_provider.g.dart';

const String _serverConfigKey = 'server_config';

@Riverpod(keepAlive: true)
class ServerConfigNotifier extends _$ServerConfigNotifier {
  @override
  Future<ServerConfig> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final jsonString = prefs.getString(_serverConfigKey);
    if (jsonString != null) {
      try {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        return ServerConfig.fromJson(json);
      } catch (_) {}
    }
    return ServerConfig.defaultValue();
  }

  Future<void> save(ServerConfig config) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_serverConfigKey, jsonEncode(config.toJson()));
    state = AsyncData(config);
  }

  Future<void> clear() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.remove(_serverConfigKey);
    state = AsyncData(ServerConfig.defaultValue());
  }
}
