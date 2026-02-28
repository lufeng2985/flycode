import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/server_config_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncServerConfig = ref.watch(serverConfigProvider);
    final serverUrl =
        asyncServerConfig.value?.baseUrl ?? 'http://localhost:4096';

    return Scaffold(
      appBar: AppBar(title: const Text('设置'), centerTitle: true),
      body: ListView(
        children: [
          _buildSectionTitle('通用'),
          _buildSettingsItem(
            icon: Icons.language,
            iconColor: Colors.blue,
            title: '语言',
            onTap: () {},
          ),
          _buildSettingsItem(
            icon: Icons.palette_outlined,
            iconColor: Colors.orange,
            title: '色彩主题',
            onTap: () {},
          ),
          _buildSettingsItem(
            icon: Icons.notifications_none,
            iconColor: Colors.green,
            title: '系统通知',
            onTap: () {},
          ),
          const Divider(),
          _buildSectionTitle('业务配置'),
          _buildSettingsItem(
            icon: Icons.dns_outlined,
            iconColor: Colors.cyan,
            title: '服务器',
            subtitle: serverUrl,
            onTap: () {
              final config = asyncServerConfig.value;
              if (config != null) {
                context.push('/settings/server', extra: config);
              } else {
                context.push('/settings/server');
              }
            },
          ),
          _buildSettingsItem(
            icon: Icons.business,
            iconColor: Colors.indigo,
            title: '模型提供商',
            onTap: () {},
          ),
          _buildSettingsItem(
            icon: Icons.smart_toy_outlined,
            iconColor: Colors.purple,
            title: '模型',
            onTap: () {},
          ),
          const Divider(),
          _buildSectionTitle('关于'),
          _buildSettingsItem(
            icon: Icons.update,
            iconColor: Colors.blueGrey,
            title: '检查更新',
            onTap: () {},
          ),
          _buildSettingsItem(
            icon: Icons.info_outline,
            iconColor: Colors.grey,
            title: '关于',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
