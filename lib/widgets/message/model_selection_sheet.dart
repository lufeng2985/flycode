import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../service/api/provider_api.dart';
import '../../service/api/models/provider.dart';
import '../../service/api/models/message.dart';
import '../../providers/model_config_provider.dart';
import '../../providers/chat_config_provider.dart';

class ModelSelectionSheet extends ConsumerWidget {
  const ModelSelectionSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We recreate the future provider here to fetch the list fresh each time the sheet opens
    final providerListAsync = ref.watch(_providerListFutureProvider);
    final configsAsync = ref.watch(modelConfigProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text(
                  '选择模型',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // List
          Expanded(
            child: providerListAsync.when(
              data: (providerList) {
                return configsAsync.when(
                  data: (configs) =>
                      _buildList(context, ref, providerList, configs),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, s) =>
                      Center(child: Text('Error loading configs: $e')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) =>
                  Center(child: Text('Error loading providers: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    ProviderListResponse providerList,
    Map<String, Map<String, bool>> configs,
  ) {
    final connectedProviders = providerList.all
        .where((p) => providerList.connected.contains(p.id))
        .toList();

    if (connectedProviders.isEmpty) {
      return const Center(child: Text('没有连接的模型提供商'));
    }

    final List<Widget> listItems = [];

    for (final provider in connectedProviders) {
      final providerConfigs = configs[provider.id] ?? {};

      // Filter models
      final availableModels = provider.models.entries.where((entry) {
        final modelId = entry.key;
        final model = entry.value;

        // Check if enabled in config
        if (providerConfigs.containsKey(modelId)) {
          return providerConfigs[modelId]!;
        }

        // Fallback to recently released
        return _isRecentlyReleased(model.releaseDate);
      }).toList();

      if (availableModels.isEmpty) continue;

      // Add Header
      listItems.add(
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          color: Colors.grey[50],
          width: double.infinity,
          child: Text(
            provider.name,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      );

      // Add Models
      for (final entry in availableModels) {
        listItems.add(
          _ModelTile(providerId: provider.id, modelInfo: entry.value),
        );
      }
    }

    if (listItems.isEmpty) {
      return const Center(child: Text('没有可用的模型'));
    }

    return ListView.builder(
      itemCount: listItems.length,
      itemBuilder: (context, index) => listItems[index],
    );
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
}

class _ModelTile extends ConsumerWidget {
  final String providerId;
  final ModelInfo modelInfo;

  const _ModelTile({required this.providerId, required this.modelInfo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentConfig = ref.watch(chatConfigProvider).asData?.value;
    final isSelected =
        currentConfig?.model.providerID == providerId &&
        currentConfig?.model.modelID == modelInfo.id;

    return InkWell(
      onTap: () {
        ref
            .read(chatConfigProvider.notifier)
            .setModel(
              MessageModel(providerID: providerId, modelID: modelInfo.id),
            );
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withValues(alpha: 0.05) : null,
          border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    modelInfo.name,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 16,
                      color: isSelected ? Colors.blue : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    modelInfo.id,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: Colors.blue, size: 20),
          ],
        ),
      ),
    );
  }
}

final _providerListFutureProvider = FutureProvider<ProviderListResponse>((
  ref,
) async {
  final api = ref.watch(providerApiProvider);
  return await api.list();
});
