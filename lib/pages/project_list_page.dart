import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../service/api/models/project.dart';
import '../service/api/api_client.dart';
import '../providers/project_pin_provider.dart';
import '../providers/server_config_provider.dart';
import '../service/api/project_api.dart';
import '../providers/project_provider.dart';
import '../providers/session_provider.dart';
import '../service/api/models/session.dart';
import '../service/api/session_api.dart';
import '../widgets/project/open_project_sheet.dart';

String _projectDisplayName(Project project) {
  if (project.name != null && project.name!.isNotEmpty) return project.name!;
  final worktree = project.worktree;
  final parts = worktree.replaceAll('\\', '/').split('/');
  return parts.lastWhere((p) => p.isNotEmpty, orElse: () => worktree);
}

Color? _parseColor(String? colorStr) {
  if (colorStr == null || colorStr.isEmpty) return null;
  if (colorStr.startsWith('#')) {
    final hex = colorStr.substring(1);
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    } else if (hex.length == 8) {
      return Color(int.parse(hex, radix: 16));
    }
  }
  return null;
}

String _formatUpdatedTime(int timestampMs) {
  final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs);
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.inMinutes < 1) return '刚刚';
  if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
  if (diff.inHours < 24) return '${diff.inHours} 小时前';
  if (diff.inDays < 7) return '${diff.inDays} 天前';

  final y = dt.year;
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  if (dt.year == now.year) return '$m-$d';
  return '$y-$m-$d';
}

List<Project> _sortProjects(
  List<Project> projects,
  Map<String, int> pinnedProjects,
) {
  final sorted = List<Project>.from(projects);

  sorted.sort((a, b) {
    final aPinnedAt = pinnedProjects[a.worktree];
    final bPinnedAt = pinnedProjects[b.worktree];

    final aPinned = aPinnedAt != null;
    final bPinned = bPinnedAt != null;

    if (aPinned != bPinned) {
      return aPinned ? -1 : 1;
    }

    if (aPinned && bPinned) {
      final pinCompare = bPinnedAt.compareTo(aPinnedAt);
      if (pinCompare != 0) return pinCompare;
    }

    return b.time.updated.compareTo(a.time.updated);
  });

  return sorted;
}

String _connectionErrorText(Object error) {
  if (error is ApiException) {
    if (error.statusCode == 401 || error.statusCode == 403) {
      return '认证失败，请检查服务器账号和密码。';
    }
    if (error.statusCode >= 500) {
      return '服务器暂时不可用（${error.statusCode}）。';
    }
    return '请求失败（${error.statusCode}）：${error.message}';
  }
  final text = error.toString();
  if (text.contains('SocketException') || text.contains('ClientException')) {
    return '无法连接到服务器，请检查地址或网络。';
  }
  return '加载项目失败，请检查服务器配置。';
}

Future<void> _showProjectActionMenu(
  BuildContext context,
  WidgetRef ref,
  Project project,
  bool isPinned,
) async {
  HapticFeedback.lightImpact();

  final action = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                isPinned ? Icons.push_pin_outlined : Icons.push_pin,
              ),
              title: Text(isPinned ? '取消置顶' : '置顶'),
              onTap: () => Navigator.of(context).pop('toggle_pin'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );

  if (action != 'toggle_pin') return;

  await ref.read(projectPinsProvider.notifier).togglePin(project);
}

Future<void> _openProjectChat(
  BuildContext context,
  WidgetRef ref,
  Project project,
) async {
  ref.read(selectedProjectProvider.notifier).select(project);

  try {
    final sessions = await ref.refresh(sessionsProvider.future);
    if (!context.mounted) return;

    if (sessions.isEmpty) {
      ref.read(selectedSessionProvider.notifier).startNew();
    } else {
      final sortedSessions = List<Session>.from(sessions)
        ..sort((a, b) => (b.updatedAt ?? 0).compareTo(a.updatedAt ?? 0));
      ref.read(selectedSessionProvider.notifier).select(sortedSessions.first);
    }
  } catch (_) {
    if (!context.mounted) return;
    ref.read(selectedSessionProvider.notifier).startNew();
  }

  if (!context.mounted) return;
  context.push('/chat');
}

class ProjectListPage extends ConsumerWidget {
  const ProjectListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);
    final asyncServerConfig = ref.watch(serverConfigProvider);
    final pinnedProjectsAsync = ref.watch(projectPinsProvider);

    void openServerConfigPage() {
      final config = asyncServerConfig.value;
      if (config != null) {
        context.push('/settings/server', extra: config);
      } else {
        context.push('/settings/server');
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          '项目',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, size: 24),
            tooltip: '打开项目',
            onPressed: () => showOpenProjectSheet(context),
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey[100], height: 1),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.refresh(projectsProvider.future),
            ref.refresh(projectPinsProvider.future),
          ]);
        },
        child: projectsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.18),
              Icon(Icons.cloud_off_outlined, size: 44, color: Colors.grey[350]),
              const SizedBox(height: 12),
              const Text(
                '暂时无法加载项目',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                _connectionErrorText(error),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: openServerConfigPage,
                icon: const Icon(Icons.settings_ethernet),
                label: const Text('去配置服务器'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  ref.invalidate(projectsProvider);
                  ref.invalidate(projectPinsProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('重试加载'),
              ),
            ],
          ),
          data: (projects) {
            return pinnedProjectsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  '$error',
                  style: TextStyle(color: Colors.grey[500]),
                ),
              ),
              data: (pinnedProjects) {
                final sortedProjects = _sortProjects(projects, pinnedProjects);

                if (sortedProjects.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.2,
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Icon(
                                Icons.folder_off_rounded,
                                size: 36,
                                color: Colors.grey[350],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '暂无项目',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '请先添加一个项目',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 14),
                            OutlinedButton.icon(
                              onPressed: openServerConfigPage,
                              icon: const Icon(
                                Icons.settings_ethernet_outlined,
                              ),
                              label: const Text('检查服务器配置'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  itemCount: sortedProjects.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final project = sortedProjects[index];
                    final isPinned = pinnedProjects.containsKey(
                      project.worktree,
                    );
                    final displayName = _projectDisplayName(project);
                    final updatedText = _formatUpdatedTime(
                      project.time.updated,
                    );
                    final iconColor = _parseColor(project.icon?.color);

                    return Material(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _openProjectChat(context, ref, project),
                        onLongPress: () => _showProjectActionMenu(
                          context,
                          ref,
                          project,
                          isPinned,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Icon(
                                  Icons.folder_rounded,
                                  size: 22,
                                  color: iconColor ?? Colors.grey[400],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      project.worktree,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isPinned) ...[
                                    Icon(
                                      Icons.push_pin_rounded,
                                      size: 14,
                                      color: Colors.grey[500],
                                    ),
                                    const SizedBox(height: 4),
                                  ],
                                  Text(
                                    updatedText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
