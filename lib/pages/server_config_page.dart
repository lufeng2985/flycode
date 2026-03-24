import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../providers/onboarding_provider.dart';
import '../providers/server_config_provider.dart';
import '../providers/provider_list_provider.dart';
import '../service/api/project_api.dart';
import '../service/api/session_api.dart';
import '../service/api/api_client.dart';
import '../models/server_config.dart';

class ServerConfigPage extends ConsumerStatefulWidget {
  final ServerConfig? initialConfig;
  final bool onboardingMode;

  const ServerConfigPage({
    super.key,
    this.initialConfig,
    this.onboardingMode = false,
  });

  @override
  ConsumerState<ServerConfigPage> createState() => _ServerConfigPageState();
}

class _ServerConfigPageState extends ConsumerState<ServerConfigPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _baseUrlController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  bool _isTesting = false;
  bool _obscurePassword = true;
  bool _testPassed = false;

  @override
  void initState() {
    super.initState();
    final config = widget.initialConfig;
    _baseUrlController = TextEditingController(text: config?.baseUrl ?? '');
    _usernameController = TextEditingController(text: config?.username ?? '');
    _passwordController = TextEditingController(text: config?.password ?? '');
    _baseUrlController.addListener(_onConfigChanged);
    _usernameController.addListener(_onConfigChanged);
    _passwordController.addListener(_onConfigChanged);
  }

  void _onConfigChanged() {
    if (!_testPassed) return;
    setState(() => _testPassed = false);
  }

  @override
  void dispose() {
    _baseUrlController.removeListener(_onConfigChanged);
    _usernameController.removeListener(_onConfigChanged);
    _passwordController.removeListener(_onConfigChanged);
    _baseUrlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _humanizedConnectionError(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        return '认证失败，请检查用户名或密码';
      }
      if (error.statusCode >= 500) {
        return '服务器异常（${error.statusCode}），请稍后重试';
      }
      return '请求失败（${error.statusCode}）：${error.message}';
    }
    if (error is SocketException) {
      return '无法连接到服务器，请检查地址和网络';
    }
    if (error is http.ClientException) {
      return '网络请求失败，请检查服务器地址';
    }
    if (error is FormatException) {
      return '服务器地址格式不正确';
    }
    return '连接失败，请检查服务器配置';
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isTesting = true);

    try {
      final client = ApiClient(
        baseUrl: _baseUrlController.text.trim(),
        username: _usernameController.text.trim().isEmpty
            ? null
            : _usernameController.text.trim(),
        password: _passwordController.text.isEmpty
            ? null
            : _passwordController.text,
      );
      await client.get('/global/health');

      if (mounted) {
        setState(() => _testPassed = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('连接成功'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_humanizedConnectionError(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.onboardingMode && !_testPassed) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先测试连接并成功后再保存')));
      return;
    }

    final config = ServerConfig(
      baseUrl: _baseUrlController.text.trim(),
      username: _usernameController.text.trim().isEmpty
          ? null
          : _usernameController.text.trim(),
      password: _passwordController.text.isEmpty
          ? null
          : _passwordController.text,
    );

    await ref.read(serverConfigProvider.notifier).save(config);
    await ref.read(onboardingControllerProvider).markServerSetupCompleted();

    ref.invalidate(serverConfigProvider);
    ref.invalidate(projectsProvider);
    ref.invalidate(sessionsProvider);
    ref.invalidate(providerListProvider);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('保存成功')));
      if (widget.onboardingMode) {
        context.go('/');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.onboardingMode ? '连接服务器' : '服务器配置'),
        centerTitle: true,
        automaticallyImplyLeading: !widget.onboardingMode,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.onboardingMode) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 18, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '首次使用请先连接服务器。建议先点击“测试连接”，再保存进入首页。',
                        style: TextStyle(fontSize: 13, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextFormField(
              controller: _baseUrlController,
              decoration: const InputDecoration(
                labelText: '服务器地址',
                hintText: 'http://localhost:4096',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.dns_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入服务器地址';
                }
                final uri = Uri.tryParse(value.trim());
                if (uri == null || !uri.hasScheme) {
                  return '请输入有效的服务器地址';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: '用户名（可选）',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: '密码（可选）',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.wifi_find_outlined),
                    label: Text(_isTesting ? '测试中...' : '测试连接'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(widget.onboardingMode ? '保存并进入' : '保存'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
