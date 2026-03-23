import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../service/api/models/project.dart';
import '../service/api/project_api.dart';
import '../providers/project_provider.dart';
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

class ProjectListPage extends ConsumerWidget {
  const ProjectListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);
    final selectedProjectAsync = ref.watch(selectedProjectProvider);
    final selectedProject = selectedProjectAsync.asData?.value;
    final colorScheme = Theme.of(context).colorScheme;

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
        onRefresh: () => ref.refresh(projectsProvider.future),
        child: projectsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('$error', style: TextStyle(color: Colors.grey[500])),
          ),
          data: (projects) {
            if (projects.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.2),
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
                      ],
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              itemCount: projects.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final project = projects[index];
                final isSelected = selectedProject?.id == project.id;
                final displayName = _projectDisplayName(project);
                final updatedText = _formatUpdatedTime(project.time.updated);
                final iconColor = _parseColor(project.icon?.color);

                return Material(
                  color: isSelected
                      ? (iconColor ?? colorScheme.primary).withValues(
                          alpha: 0.06,
                        )
                      : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      ref
                          .read(selectedProjectProvider.notifier)
                          .select(project);
                      context.push('/sessions');
                    },
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
                              color: isSelected
                                  ? (iconColor ?? colorScheme.primary)
                                        .withValues(alpha: 0.12)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: !isSelected
                                  ? Border.all(color: Colors.grey[200]!)
                                  : null,
                            ),
                            child: Icon(
                              Icons.folder_rounded,
                              size: 22,
                              color: isSelected
                                  ? (iconColor ?? colorScheme.primary)
                                  : Colors.grey[400],
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
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? (iconColor ?? colorScheme.primary)
                                        : Colors.black87,
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
                              if (isSelected) ...[
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 16,
                                  color: iconColor ?? colorScheme.primary,
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
        ),
      ),
    );
  }
}
