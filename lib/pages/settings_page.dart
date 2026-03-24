import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/server_config_provider.dart';
import '../widgets/settings/settings_section_title.dart';
import '../widgets/settings/settings_item.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final asyncServerConfig = ref.watch(serverConfigProvider);
    final serverUrl =
        asyncServerConfig.value?.baseUrl ?? 'http://localhost:4096';

    return Scaffold(
      appBar: AppBar(title: const Text('设置'), centerTitle: true),
      body: ListView(
        children: [
          const SettingsSectionTitle(title: '通用'),
          SettingsItem(
            icon: Icons.language,
            iconColor: Colors.blue,
            title: '语言',
            onTap: () {},
          ),
          SettingsItem(
            icon: Icons.palette_outlined,
            iconColor: colorScheme.primary,
            title: '色彩主题',
            onTap: () {
              context.push('/settings/theme');
            },
          ),
          SettingsItem(
            icon: Icons.notifications_none,
            iconColor: Colors.green,
            title: '系统通知',
            onTap: () {},
          ),
          const Divider(),
          const SettingsSectionTitle(title: '业务配置'),
          SettingsItem(
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
          SettingsItem(
            icon: Icons.smart_toy_outlined,
            iconColor: Colors.purple,
            title: '模型',
            onTap: () {
              context.push('/settings/model');
            },
          ),
          const Divider(),
          const SettingsSectionTitle(title: '关于'),
          SettingsItem(
            icon: Icons.update,
            iconColor: Colors.blueGrey,
            title: '检查更新',
            onTap: () {},
          ),
          SettingsItem(
            icon: Icons.info_outline,
            iconColor: Colors.grey,
            title: '关于',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
