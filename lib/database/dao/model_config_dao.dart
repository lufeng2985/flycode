import 'package:sqflite/sqflite.dart';

class ModelConfigDao {
  static const String tableName = 'model_configs';
  static const String columnProviderId = 'provider_id';
  static const String columnModelId = 'model_id';
  static const String columnEnabled = 'enabled';

  final Database db;

  ModelConfigDao(this.db);

  Future<bool> isModelEnabled(String providerId, String modelId) async {
    final result = await db.query(
      tableName,
      columns: [columnEnabled],
      where: '$columnProviderId = ? AND $columnModelId = ?',
      whereArgs: [providerId, modelId],
    );
    if (result.isEmpty) {
      return true;
    }
    return result.first[columnEnabled] == 1;
  }

  Future<void> upsertModelConfig(
    String providerId,
    String modelId,
    bool enabled,
  ) async {
    await db.insert(tableName, {
      columnProviderId: providerId,
      columnModelId: modelId,
      columnEnabled: enabled ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<Map<String, Map<String, bool>>> getAllModelConfigs() async {
    final result = await db.query(
      tableName,
      columns: [columnProviderId, columnModelId, columnEnabled],
    );

    final configs = <String, Map<String, bool>>{};

    for (final row in result) {
      final providerId = row[columnProviderId] as String;
      final modelId = row[columnModelId] as String;
      final isEnabled = row[columnEnabled] == 1;

      configs.putIfAbsent(providerId, () => {})[modelId] = isEnabled;
    }

    return configs;
  }
}
