import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../service/api/api_client.dart';
import '../../service/api/file_api.dart';
import '../../service/api/models/file_node.dart';
import '../../service/api/project_api.dart';
import '../../providers/project_provider.dart';

// ---------------------------------------------------------------------------
// 公开入口：显示打开项目底部 Sheet
// ---------------------------------------------------------------------------

Future<void> showOpenProjectSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _OpenProjectSheet(),
  );
}

// ---------------------------------------------------------------------------
// 内部 Sheet 实现
// ---------------------------------------------------------------------------

class _OpenProjectSheet extends ConsumerStatefulWidget {
  const _OpenProjectSheet();

  @override
  ConsumerState<_OpenProjectSheet> createState() => _OpenProjectSheetState();
}

class _OpenProjectSheetState extends ConsumerState<_OpenProjectSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  // 搜索结果：每一条都是一个绝对路径
  List<String> _results = [];
  bool _loading = false;
  String? _error;

  // 选中后正在确认（调用 /project/current）
  bool _confirming = false;

  Timer? _debounce;

  // 路径导航模式的目录缓存：directory -> List<FileNode>
  final Map<String, List<FileNode>> _dirCache = {};

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onInputChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // 输入处理
  // ---------------------------------------------------------------------------

  void _onInputChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _search);
  }

  Future<void> _search() async {
    final input = _controller.text.trim();
    if (input.isEmpty) {
      setState(() {
        _results = [];
        _error = null;
        _loading = false;
      });
      return;
    }

    final isPathMode = _isPathInput(input);

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = await ref.read(apiClientProvider.future);
      final fileApi = FileApi(client);

      List<String> results;
      if (isPathMode) {
        results = await _navigatePath(fileApi, input);
      } else {
        // 关键词搜索模式：不传 directory，服务端用 process.cwd()
        final relPaths = await fileApi.findDirectory(input);
        results = relPaths;
      }

      if (mounted) {
        setState(() {
          _results = results;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e is ApiException ? e.message : e.toString();
          _loading = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 判断是否为路径输入模式
  // ---------------------------------------------------------------------------

  bool _isPathInput(String input) {
    return input.startsWith('/') ||
        input.startsWith('~') ||
        input.contains('/');
  }

  // ---------------------------------------------------------------------------
  // 路径导航模式：逐段遍历，返回最终匹配的绝对路径列表
  // ---------------------------------------------------------------------------

  Future<List<String>> _navigatePath(FileApi fileApi, String input) async {
    // 展开 ~
    String expanded = input;
    if (expanded.startsWith('~/') || expanded == '~') {
      // home 目录暂时用空字符串占位，让服务端处理；
      // 实际上 listDirectory 传入 '~' 时服务端会报错，
      // 因此我们先取 home，再拼接。
      // 为简化，我们将 ~ 替换为 home（后面通过服务端 /path 获取，
      // 但这里选择直接调用 listDirectory('~') 来发现 home 子目录）。
      // 注意：下面的逻辑会 fallback 到逐段处理。
    }

    // 将输入按 / 分段
    final segments = _splitPath(expanded);
    if (segments.isEmpty) return [];

    // 如果输入以 / 开头，root 为 '/'
    // 如果以 ~ 开头，root 为 '~'（服务端需要能理解）
    final String rootDir;
    final List<String> remainingSegments;

    if (expanded.startsWith('/')) {
      rootDir = '/';
      // segments[0] 是空字符串（split '/' 开头）
      remainingSegments = segments.where((s) => s.isNotEmpty).toList();
    } else if (expanded.startsWith('~')) {
      rootDir = '~';
      remainingSegments = segments.skip(1).where((s) => s.isNotEmpty).toList();
    } else {
      // 含 / 但不以 / 或 ~ 开头（如 "src/comp"）
      rootDir = '.';
      remainingSegments = segments;
    }

    // 逐层深入
    String currentDir = rootDir;
    final allSegments = remainingSegments;

    // 如果输入以 / 或 ~ 结尾（用户刚输入了分隔符），
    // 则列出当前目录内容
    final endsWithSlash =
        expanded.endsWith('/') || expanded == '~' || expanded == '/';

    if (endsWithSlash) {
      // 逐段导航直到最后一段
      for (final seg in allSegments) {
        final children = await _cachedListDirectory(fileApi, currentDir);
        final dirs = children.where((n) => n.isDirectory).toList();
        final match = _fuzzyFirst(dirs, seg);
        if (match == null) return [];
        currentDir = match.absolute;
      }
      // 列出当前目录内容
      final children = await _cachedListDirectory(fileApi, currentDir);
      return children
          .where((n) => n.isDirectory)
          .map((n) => n.absolute)
          .toList();
    } else {
      // 最后一段是筛选词，前面的段用于导航
      if (allSegments.isEmpty) {
        final children = await _cachedListDirectory(fileApi, currentDir);
        return children
            .where((n) => n.isDirectory)
            .map((n) => n.absolute)
            .toList();
      }

      final navigationSegments = allSegments.sublist(0, allSegments.length - 1);
      final filterSegment = allSegments.last;

      for (final seg in navigationSegments) {
        final children = await _cachedListDirectory(fileApi, currentDir);
        final dirs = children.where((n) => n.isDirectory).toList();
        final match = _fuzzyFirst(dirs, seg);
        if (match == null) return [];
        currentDir = match.absolute;
      }

      // 在当前目录用最后一段做模糊过滤
      final children = await _cachedListDirectory(fileApi, currentDir);
      final dirs = children.where((n) => n.isDirectory).toList();
      final filtered = _fuzzyFilter(dirs, filterSegment);
      return filtered.map((n) => n.absolute).toList();
    }
  }

  // ---------------------------------------------------------------------------
  // 工具方法
  // ---------------------------------------------------------------------------

  List<String> _splitPath(String path) {
    return path.split('/');
  }

  Future<List<FileNode>> _cachedListDirectory(
    FileApi fileApi,
    String directory,
  ) async {
    if (_dirCache.containsKey(directory)) {
      return _dirCache[directory]!;
    }
    final nodes = await fileApi.listDirectory(directory);
    _dirCache[directory] = nodes;
    return nodes;
  }

  /// 简单模糊匹配：返回 name 包含 [query]（不区分大小写）的第一个结果
  FileNode? _fuzzyFirst(List<FileNode> nodes, String query) {
    if (query.isEmpty) return nodes.isNotEmpty ? nodes.first : null;
    final lower = query.toLowerCase();
    // 优先精确匹配，其次 startsWith，其次 contains
    FileNode? exact = nodes
        .where((n) => n.name.toLowerCase() == lower)
        .firstOrNull;
    if (exact != null) return exact;
    FileNode? starts = nodes
        .where((n) => n.name.toLowerCase().startsWith(lower))
        .firstOrNull;
    if (starts != null) return starts;
    return nodes.where((n) => n.name.toLowerCase().contains(lower)).firstOrNull;
  }

  /// 返回 name 包含 [query]（不区分大小写）的所有节点
  List<FileNode> _fuzzyFilter(List<FileNode> nodes, String query) {
    if (query.isEmpty) return nodes;
    final lower = query.toLowerCase();
    return nodes.where((n) => n.name.toLowerCase().contains(lower)).toList();
  }

  // ---------------------------------------------------------------------------
  // 确认选择目录
  // ---------------------------------------------------------------------------

  Future<void> _selectDirectory(String absolutePath) async {
    if (_confirming) return;
    setState(() => _confirming = true);

    try {
      final project = ref
          .read(projectsProvider.notifier)
          .addProjectByDirectory(absolutePath);

      if (!mounted) return;

      ref.read(selectedProjectProvider.notifier).select(project);

      // 关闭 Sheet，然后关闭 ProjectListPage
      Navigator.of(context).pop(); // 关闭 Sheet
      if (mounted) {
        Navigator.of(context).pop(); // 关闭 ProjectListPage
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _confirming = false);
      final msg = '打开项目失败：$e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部拖拽条
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // 标题
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    '打开项目',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  if (_confirming)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 搜索输入框
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                enabled: !_confirming,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: '输入目录名称或路径（如 ~/projects）',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            color: Colors.grey[400],
                            size: 18,
                          ),
                          onPressed: () {
                            _controller.clear();
                            setState(() {
                              _results = [];
                              _error = null;
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            // 进度条
            if (_loading)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                ),
              )
            else
              const SizedBox(height: 2),

            const SizedBox(height: 4),

            // 结果区域
            _buildResultArea(colorScheme),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildResultArea(ColorScheme colorScheme) {
    // 错误状态
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red[400], size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _error!,
                style: TextStyle(color: Colors.red[600], fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    // 空状态（未输入或无结果）
    if (_results.isEmpty && !_loading) {
      if (_controller.text.trim().isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Column(
            children: [
              Icon(
                Icons.folder_open_rounded,
                size: 40,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 12),
              Text(
                '输入目录名称进行搜索',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                '支持路径导航：~/projects/myapp',
                style: TextStyle(color: Colors.grey[350], fontSize: 12),
              ),
            ],
          ),
        );
      } else {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(
            '未找到匹配的目录',
            style: TextStyle(color: Colors.grey[400], fontSize: 13),
          ),
        );
      }
    }

    // 结果列表
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.45,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _results.length,
        itemBuilder: (context, index) {
          final path = _results[index];
          final parts = path.replaceAll('\\', '/').split('/');
          final name = parts.lastWhere((p) => p.isNotEmpty, orElse: () => path);

          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _confirming ? null : () => _selectDirectory(path),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.folder_rounded,
                        size: 20,
                        color: colorScheme.primary.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            path,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[450],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Colors.grey[350],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
