import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/server_config.dart';

part 'server_config_provider.g.dart';

const String _serverConfigKey = 'server_config';

@riverpod
class ServerConfigNotifier extends _$ServerConfigNotifier {
  @override
  Future<ServerConfig> build() async {
    final prefs = await SharedPreferences.getInstance();
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_serverConfigKey, jsonEncode(config.toJson()));
    state = AsyncData(config);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_serverConfigKey);
    state = AsyncData(ServerConfig.defaultValue());
  }
}
