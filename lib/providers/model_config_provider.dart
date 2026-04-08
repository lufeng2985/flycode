import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../database/database_helper.dart';
import '../database/dao/model_config_dao.dart';

part 'model_config_provider.g.dart';

@Riverpod(keepAlive: true)
DatabaseHelper databaseHelper(Ref ref) {
  return DatabaseHelper();
}

@Riverpod(keepAlive: true)
Future<ModelConfigDao> modelConfigDao(Ref ref) async {
  final dbHelper = ref.watch(databaseHelperProvider);
  final db = await dbHelper.database;
  return ModelConfigDao(db);
}

@riverpod
class ModelConfigNotifier extends _$ModelConfigNotifier {
  @override
  Future<Map<String, Map<String, bool>>> build() async {
    final dao = await ref.watch(modelConfigDaoProvider.future);
    return await dao.getAllModelConfigs();
  }

  Future<void> updateModelConfig(
    String providerId,
    String modelId,
    bool enabled,
  ) async {
    final dao = await ref.read(modelConfigDaoProvider.future);
    await dao.upsertModelConfig(providerId, modelId, enabled);
    ref.invalidateSelf();
  }

  Future<void> updateProviderModelsConfig(
    String providerId,
    Iterable<String> modelIds,
    bool enabled,
  ) async {
    final dao = await ref.read(modelConfigDaoProvider.future);
    await dao.upsertProviderConfigs(providerId, modelIds, enabled);
    ref.invalidateSelf();
  }
}
