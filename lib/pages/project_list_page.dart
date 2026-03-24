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
import '../theme/app_tokens.dart';
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
  final colorScheme = Theme.of(context).colorScheme;
  final tokens = context.tokens;

  HapticFeedback.lightImpact();

  final action = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: colorScheme.surface,
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
                color: colorScheme.onSurface,
              ),
              title: Text(
                isPinned ? '取消置顶' : '置顶',
                style: TextStyle(color: colorScheme.onSurface),
              ),
              onTap: () => Navigator.of(context).pop('toggle_pin'),
            ),
            SizedBox(height: tokens.radiusXs / 2),
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
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final projectsAsync = ref.watch(projectsProvider);
    final asyncServerConfig = ref.watch(serverConfigProvider);
    final pinnedProjectsAsync = ref.watch(projectPinsProvider);
    final contentBottomPadding = MediaQuery.paddingOf(context).bottom + 16;

    Future<void> refreshProjects() async {
      await Future.wait([
        ref.refresh(projectsProvider.future),
        ref.refresh(projectPinsProvider.future),
      ]);
    }

    void openServerConfigPage() {
      final config = asyncServerConfig.value;
      if (config != null) {
        context.push('/settings/server', extra: config);
      } else {
        context.push('/settings/server');
      }
    }

    Widget buildHeader() {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Projects',
                  style: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => showOpenProjectSheet(context),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '+ New',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget buildPageLayout(Widget body) {
      return Column(
        children: [
          buildHeader(),
          Container(height: 1, color: tokens.border.withValues(alpha: 0.45)),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: projectsAsync.when(
          loading: () =>
              buildPageLayout(const Center(child: CircularProgressIndicator())),
          error: (error, stack) => buildPageLayout(
            RefreshIndicator(
              onRefresh: refreshProjects,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(24, 0, 24, contentBottomPadding),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.12),
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 44,
                    color: tokens.mutedForeground.withValues(alpha: 0.55),
                  ),
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
                    style: TextStyle(
                      fontSize: 13,
                      color: tokens.mutedForeground,
                    ),
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
            ),
          ),
          data: (projects) {
            return pinnedProjectsAsync.when(
              loading: () => buildPageLayout(
                const Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => buildPageLayout(
                Center(
                  child: Text(
                    '$error',
                    style: TextStyle(color: tokens.mutedForeground),
                  ),
                ),
              ),
              data: (pinnedProjects) {
                final sortedProjects = _sortProjects(projects, pinnedProjects);

                if (sortedProjects.isEmpty) {
                  return buildPageLayout(
                    RefreshIndicator(
                      onRefresh: refreshProjects,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.only(bottom: contentBottomPadding),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.16,
                          ),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: tokens.card,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Icon(
                                    Icons.folder_off_rounded,
                                    size: 36,
                                    color: tokens.mutedForeground.withValues(
                                      alpha: 0.55,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '暂无项目',
                                  style: TextStyle(
                                    color: tokens.mutedForeground,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '请先添加一个项目',
                                  style: TextStyle(
                                    color: tokens.mutedForeground.withValues(
                                      alpha: 0.8,
                                    ),
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
                      ),
                    ),
                  );
                }

                return buildPageLayout(
                  RefreshIndicator(
                    onRefresh: refreshProjects,
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        24,
                        20,
                        24,
                        contentBottomPadding,
                      ),
                      itemCount: sortedProjects.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final project = sortedProjects[index];
                        final isPinned = pinnedProjects.containsKey(
                          project.worktree,
                        );
                        final displayName = _projectDisplayName(project);
                        final updatedText = _formatUpdatedTime(
                          project.time.updated,
                        );
                        final iconColor =
                            _parseColor(project.icon?.color) ??
                            colorScheme.primary;
                        final iconText = displayName.trim().isEmpty
                            ? '?'
                            : displayName.trim().substring(0, 1).toUpperCase();

                        return Material(
                          color: tokens.card,
                          borderRadius: BorderRadius.circular(tokens.radiusM),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(tokens.radiusM),
                            onTap: () =>
                                _openProjectChat(context, ref, project),
                            onLongPress: () => _showProjectActionMenu(
                              context,
                              ref,
                              project,
                              isPinned,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 18,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: iconColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      iconText,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: iconColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          displayName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          project.worktree,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: tokens.mutedForeground,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (isPinned) ...[
                                        Icon(
                                          Icons.push_pin,
                                          size: 14,
                                          color: colorScheme.primary,
                                        ),
                                        const SizedBox(height: 4),
                                      ],
                                      Text(
                                        updatedText,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: tokens.mutedForeground
                                              .withValues(alpha: 0.8),
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
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
