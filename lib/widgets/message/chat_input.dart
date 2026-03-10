import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import '../../service/api/session_api.dart';
import '../../service/api/command_api.dart';
import '../../service/api/models/prompt_input.dart';
import '../../service/api/models/command_input.dart';
import '../../service/api/models/command.dart';
import '../../providers/session_provider.dart';
import '../../providers/chat_config_provider.dart';
import '../../providers/project_provider.dart';
import 'model_selection_sheet.dart';

class _ImageAttachment {
  final String filename;
  final String mime;
  final String dataUrl; // "data:image/jpeg;base64,..."

  _ImageAttachment({
    required this.filename,
    required this.mime,
    required this.dataUrl,
  });
}

class ChatInput extends ConsumerStatefulWidget {
  const ChatInput({super.key});

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  bool _isLoading = false;
  final List<_ImageAttachment> _attachments = [];
  OverlayEntry? _commandOverlay;
  List<Command> _filteredCommands = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  // ─── 命令检测逻辑 ─────────────────────────────────────────────

  void _onTextChanged() {
    final text = _controller.text;

    // 含空格或不以 "/" 开头，立即关闭 Overlay
    if (!text.startsWith('/') || text.contains(' ')) {
      _hideCommandOverlay();
      return;
    }

    final query = text.substring(1); // "/" 后的内容（可为空字符串）
    final commands = ref.read(commandsProvider).asData?.value ?? [];
    final filtered = commands.where((c) => c.name.startsWith(query)).toList();

    if (filtered.isEmpty) {
      _hideCommandOverlay();
    } else {
      _filteredCommands = filtered;
      if (_commandOverlay == null) {
        _showCommandOverlay();
      } else {
        _commandOverlay!.markNeedsBuild();
      }
    }
  }

  /// 从输入文本解析匹配的命令，返回 null 表示非命令或命令不存在。
  Command? _parseCommand(String text) {
    if (!text.startsWith('/')) return null;
    final afterSlash = text.substring(1);
    final spaceIdx = afterSlash.indexOf(' ');
    final cmdName = spaceIdx == -1
        ? afterSlash
        : afterSlash.substring(0, spaceIdx);
    if (cmdName.isEmpty) return null;
    final commands = ref.read(commandsProvider).asData?.value ?? [];
    try {
      return commands.firstWhere((c) => c.name == cmdName);
    } on StateError {
      return null;
    }
  }

  // ─── Overlay ─────────────────────────────────────────────────

  void _showCommandOverlay() {
    final overlay = Overlay.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    const horizontalPadding = 12.0;
    final overlayWidth = screenWidth - horizontalPadding * 2;
    // 最大高度：屏幕高度的 35%
    final maxHeight = screenHeight * 0.5;

    // 通过 RenderBox 获取输入框容器在屏幕中的绝对位置
    final renderBox = context.findRenderObject() as RenderBox?;
    final boxOffset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    // overlay 底部紧贴输入框顶部，再上移 4px 间距
    final bottomY = boxOffset.dy - 4;

    _commandOverlay = OverlayEntry(
      builder: (ctx) => Positioned(
        left: horizontalPadding,
        bottom: screenHeight - bottomY,
        width: overlayWidth,
        child: _CommandSuggestionList(
          commands: _filteredCommands,
          onSelect: _onCommandSelected,
          maxHeight: maxHeight,
        ),
      ),
    );
    overlay.insert(_commandOverlay!);
  }

  void _hideCommandOverlay() {
    _commandOverlay?.remove();
    _commandOverlay = null;
  }

  void _onCommandSelected(Command command) {
    _hideCommandOverlay();
    // 末尾始终加空格：关闭 overlay 并提示用户继续输入参数
    _controller.value = TextEditingValue(
      text: '/${command.name} ',
      selection: TextSelection.collapsed(offset: 1 + command.name.length + 1),
    );
  }

  // ─── 图片附件 ─────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final List<XFile> files = await picker.pickMultiImage();
    if (files.isEmpty) return;

    for (final file in files) {
      final bytes = await file.readAsBytes();
      final base64Str = base64Encode(bytes);
      final mimeType =
          lookupMimeType(file.name, headerBytes: bytes) ?? 'image/jpeg';
      final dataUrl = 'data:$mimeType;base64,$base64Str';
      if (mounted) {
        setState(() {
          _attachments.add(
            _ImageAttachment(
              filename: file.name,
              mime: mimeType,
              dataUrl: dataUrl,
            ),
          );
        });
      }
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  void _showImagePreview(BuildContext context, _ImageAttachment attachment) {
    final bytes = base64Decode(attachment.dataUrl.split(',').last);
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.memory(bytes, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                onPressed: () => Navigator.of(ctx).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── 发送逻辑 ─────────────────────────────────────────────────

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _attachments.isEmpty) return;
    if (_isLoading) return;

    final selectedState = ref.read(selectedSessionProvider);
    if (selectedState.session == null && !selectedState.isPending) return;

    setState(() => _isLoading = true);

    try {
      final api = await ref.read(sessionApiProvider.future);
      final project = await ref.read(selectedProjectProvider.future);
      final chatConfig = ref.read(chatConfigProvider);

      final session = await _ensureSession(api, project, selectedState);
      if (session == null) return;

      final matchedCommand = _parseCommand(text);
      if (matchedCommand != null) {
        _dispatchCommand(
          api,
          session,
          project,
          chatConfig,
          matchedCommand,
          text,
        );
      } else {
        await _dispatchPrompt(api, session, project, chatConfig, text);
      }

      setState(() {
        _controller.clear();
        _attachments.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String?> _ensureSession(
    SessionApi api,
    dynamic project,
    SelectedSessionState selectedState,
  ) async {
    var session = selectedState.session;
    if (session == null && selectedState.isPending) {
      session = await api.createSession(directory: project?.worktree);
      ref.read(selectedSessionProvider.notifier).select(session);
    }
    return session?.id;
  }

  Future<void> _dispatchCommand(
    SessionApi api,
    String sessionId,
    dynamic project,
    ChatConfig chatConfig,
    Command matchedCommand,
    String text,
  ) async {
    final afterSlash = text.substring(1);
    final spaceIdx = afterSlash.indexOf(' ');
    final arguments = spaceIdx == -1
        ? ''
        : afterSlash.substring(spaceIdx + 1).trim();

    final modelStr =
        '${chatConfig.model.providerID}/${chatConfig.model.modelID}';

    await api.sendCommand(
      sessionId,
      directory: project?.worktree,
      data: CommandInput(
        command: matchedCommand.name,
        arguments: arguments,
        model: modelStr,
        agent: chatConfig.agent,
      ),
    );
  }

  Future<void> _dispatchPrompt(
    SessionApi api,
    String sessionId,
    dynamic project,
    ChatConfig chatConfig,
    String text,
  ) async {
    final List<Object> parts = [
      if (text.isNotEmpty) TextPartInput(text: text),
      ..._attachments.map(
        (att) => FilePartInput(
          mime: att.mime,
          filename: att.filename,
          url: att.dataUrl,
        ),
      ),
    ];

    await api.sendPromptAsync(
      sessionId,
      directory: project?.worktree,
      data: PromptAsyncInput(
        agent: chatConfig.agent,
        model: chatConfig.model,
        parts: parts,
      ),
    );
  }

  // ─── Agent / Model 切换 ───────────────────────────────────────

  void _toggleAgent() {
    final config = ref.read(chatConfigProvider);

    final newAgent = config.agent == 'build' ? 'plan' : 'build';
    ref.read(chatConfigProvider.notifier).setAgent(newAgent);
  }

  void _showModelSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ModelSelectionSheet(),
    );
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final chatConfig = ref.watch(chatConfigProvider);
    final theme = Theme.of(context);
    // 预加载命令列表，确保 _onTextChanged 里 ref.read 时数据已就绪
    ref.watch(commandsProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CompositedTransformTarget(
              link: _layerLink,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_attachments.isNotEmpty)
                      _AttachmentList(
                        attachments: _attachments,
                        onRemove: _removeAttachment,
                        onPreview: (att) => _showImagePreview(context, att),
                      ),
                    TextField(
                      controller: _controller,
                      autofocus: false,
                      maxLines: 5,
                      minLines: 1,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: '随便问点什么...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        contentPadding: EdgeInsets.all(12),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                    _InputToolBar(
                      isLoading: _isLoading,
                      onPickImage: _pickImage,
                      onSend: _handleSend,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _ConfigToolBar(
              chatConfig: chatConfig,
              onToggleAgent: _toggleAgent,
              onShowModelSelector: _showModelSelector,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hideCommandOverlay();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }
}

// ─── UI 子组件 ─────────────────────────────────────────────────────

class _AttachmentList extends StatelessWidget {
  final List<_ImageAttachment> attachments;
  final ValueChanged<int> onRemove;
  final ValueChanged<_ImageAttachment> onPreview;

  const _AttachmentList({
    required this.attachments,
    required this.onRemove,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(attachments.length, (i) {
            final att = attachments[i];
            final bytes = base64Decode(att.dataUrl.split(',').last);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: () => onPreview(att),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.memory(
                        bytes,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: GestureDetector(
                      onTap: () => onRemove(i),
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _InputToolBar extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPickImage;
  final VoidCallback onSend;

  const _InputToolBar({
    required this.isLoading,
    required this.onPickImage,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          const Text(
            '>>',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          IconButton(
            onPressed: isLoading ? null : onPickImage,
            icon: const Icon(Icons.add, size: 20, color: Colors.grey),
            visualDensity: VisualDensity.compact,
          ),
          Container(
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color: isLoading ? Colors.grey : Colors.grey[400],
              borderRadius: BorderRadius.circular(4),
            ),
            child: IconButton(
              onPressed: isLoading ? null : onSend,
              icon: const Icon(
                Icons.arrow_upward,
                size: 20,
                color: Colors.white,
              ),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigToolBar extends StatelessWidget {
  final ChatConfig chatConfig;
  final VoidCallback onToggleAgent;
  final VoidCallback onShowModelSelector;

  const _ConfigToolBar({
    required this.chatConfig,
    required this.onToggleAgent,
    required this.onShowModelSelector,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SelectionChip(
          onTap: onToggleAgent,
          label:
              '${chatConfig.agent[0].toUpperCase()}${chatConfig.agent.substring(1)}',
        ),
        const SizedBox(width: 8),
        _SelectionChip(
          onTap: onShowModelSelector,
          label: chatConfig.model.modelID,
          icon: Icons.share_outlined,
        ),
        const SizedBox(width: 8),
        const _SelectionChip(label: '默认'),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(
            Icons.terminal_outlined,
            size: 20,
            color: Colors.grey,
          ),
          visualDensity: VisualDensity.compact,
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(
            Icons.chat_bubble_outline,
            size: 20,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

class _SelectionChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  const _SelectionChip({required this.label, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// ─── 命令建议列表 Widget ───────────────────────────────────────────

class _CommandSuggestionList extends StatelessWidget {
  final List<Command> commands;
  final ValueChanged<Command> onSelect;
  final double maxHeight;

  const _CommandSuggestionList({
    required this.commands,
    required this.onSelect,
    required this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(10),
      color: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemCount: commands.length,
          separatorBuilder: (_, _) =>
              Divider(height: 1, color: Colors.grey[100]),
          itemBuilder: (ctx, i) {
            final cmd = commands[i];
            return InkWell(
              onTap: () => onSelect(cmd),
              borderRadius: i == 0
                  ? const BorderRadius.vertical(top: Radius.circular(10))
                  : i == commands.length - 1
                  ? const BorderRadius.vertical(bottom: Radius.circular(10))
                  : BorderRadius.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Text(
                      '/${cmd.name}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (cmd.description != null &&
                        cmd.description!.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          cmd.description!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
