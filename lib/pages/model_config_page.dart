import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../service/api/models/provider.dart';
import '../providers/model_config_provider.dart';
import '../providers/provider_list_provider.dart';

class ModelConfigPage extends ConsumerWidget {
  const ModelConfigPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerListAsync = ref.watch(providerListProvider);
    final isRefreshing = providerListAsync.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('模型配置'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: '刷新模型列表',
            onPressed: isRefreshing
                ? null
                : () async {
                    try {
                      await ref.read(providerListProvider.notifier).refresh();
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('模型列表已刷新')));
                    } catch (error) {
                      if (!context.mounted) {
                        return;
                      }
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('刷新失败: $error')));
                    }
                  },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: providerListAsync.when(
        data: (providerList) => _buildModelList(context, ref, providerList),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('加载失败: $error, $stack'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModelList(
    BuildContext context,
    WidgetRef ref,
    ProviderListResponse providerList,
  ) {
    final configsAsync = ref.watch(modelConfigProvider);

    return configsAsync.when(
      data: (configs) {
        final connectedProviders = providerList.all
            .where((p) => providerList.connected.contains(p.id))
            .toList();
        return ListView.builder(
          itemCount: connectedProviders.length,
          itemBuilder: (context, index) {
            final provider = connectedProviders[index];
            return _ProviderExpansionTile(provider: provider, configs: configs);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('加载配置失败: $error, $stack')),
    );
  }
}

bool _isRecentlyReleased(String releaseDate) {
  if (releaseDate.isEmpty) {
    return true;
  }
  try {
    final release = DateTime.parse(releaseDate);
    final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
    return release.isAfter(sixMonthsAgo);
  } catch (e) {
    return true;
  }
}

class _ProviderExpansionTile extends ConsumerWidget {
  final ProviderModel provider;
  final Map<String, Map<String, bool>> configs;

  const _ProviderExpansionTile({required this.provider, required this.configs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerConfigs = configs[provider.id] ?? {};
    final modelCount = provider.models.length;

    return ExpansionTile(
      leading: const Icon(Icons.cloud_outlined),
      title: Text(provider.name),
      subtitle: Text('$modelCount 个模型'),
      children: provider.models.entries.map((entry) {
        final modelId = entry.key;
        final model = entry.value;

        final bool isEnabled;
        if (providerConfigs.containsKey(modelId)) {
          isEnabled = providerConfigs[modelId]!;
        } else {
          isEnabled = _isRecentlyReleased(model.releaseDate);
        }

        return _ModelSwitchTile(
          providerId: provider.id,
          modelId: modelId,
          modelName: model.name,
          isEnabled: isEnabled,
        );
      }).toList(),
    );
  }
}

class _ModelSwitchTile extends ConsumerWidget {
  final String providerId;
  final String modelId;
  final String modelName;
  final bool isEnabled;

  const _ModelSwitchTile({
    required this.providerId,
    required this.modelId,
    required this.modelName,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwitchListTile(
      title: Text(modelName),
      subtitle: Text(
        modelId,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      value: isEnabled,
      onChanged: (value) {
        ref
            .read(modelConfigProvider.notifier)
            .updateModelConfig(providerId, modelId, value);
      },
    );
  }
}
