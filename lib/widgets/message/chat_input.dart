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
import '../../providers/session_status_provider.dart';
import '../../service/api/models/session_status.dart';
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

enum _InputMode { chat, shell }

class ChatInput extends ConsumerStatefulWidget {
  const ChatInput({super.key});

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  bool _isLoading = false;

  /// True while an abort request has been sent and we are waiting for the
  /// backend to confirm the session is idle (via SSE session.status event).
  bool _isAborting = false;

  _InputMode _inputMode = _InputMode.chat;
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
    if (_inputMode == _InputMode.shell) {
      _hideCommandOverlay();
      return;
    }

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
    final isShellMode = _inputMode == _InputMode.shell;
    if (isShellMode && text.isEmpty) return;
    if (!isShellMode && text.isEmpty && _attachments.isEmpty) return;
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

      if (isShellMode) {
        await _dispatchShell(api, session, project, chatConfig, text);
      } else {
        final matchedCommand = _parseCommand(text);
        if (matchedCommand != null) {
          await _dispatchCommand(
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

  /// Sends an abort request to the backend for the current session.
  ///
  /// Sets [_isAborting] immediately to prevent duplicate requests.
  /// The flag is cleared when the SSE stream delivers a `session.status`
  /// event with `{ type: "idle" }` (see [build] listener).
  Future<void> _handleAbort() async {
    if (_isAborting) return;
    final session = ref.read(selectedSessionProvider).session;
    if (session == null) return;

    setState(() => _isAborting = true);

    try {
      final api = await ref.read(sessionApiProvider.future);
      final project = await ref.read(selectedProjectProvider.future);
      await api.abortSession(session.id, directory: project?.worktree);
      // Do NOT clear _isAborting here — wait for SSE idle confirmation.
    } catch (e) {
      // Abort request failed — restore state so the user can retry.
      if (mounted) {
        setState(() => _isAborting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('中断失败: $e')));
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

  Future<void> _dispatchShell(
    SessionApi api,
    String sessionId,
    dynamic project,
    ChatConfig chatConfig,
    String command,
  ) async {
    await api.runShell(
      sessionId,
      directory: project?.worktree,
      data: {
        'agent': chatConfig.agent,
        'command': command,
        'model': {
          'providerID': chatConfig.model.providerID,
          'modelID': chatConfig.model.modelID,
        },
      },
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

  void _setInputMode(_InputMode mode) {
    if (_inputMode == mode) return;
    setState(() {
      _inputMode = mode;
      if (mode == _InputMode.shell) {
        _attachments.clear();
      }
    });
    _hideCommandOverlay();
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final chatConfig = ref.watch(chatConfigProvider);
    final theme = Theme.of(context);
    final isShellMode = _inputMode == _InputMode.shell;
    // 预加载命令列表，确保 _onTextChanged 里 ref.read 时数据已就绪
    ref.watch(commandsProvider);

    // Derive whether the backend is currently processing for this session.
    final sessionId = ref.watch(
      selectedSessionProvider.select((s) => s.session?.id),
    );
    final sessionStatuses = ref.watch(sessionStatusProvider);
    final isWorking =
        sessionId != null && (sessionStatuses[sessionId]?.isWorking ?? false);

    // Clear _isAborting once the backend confirms idle via SSE.
    ref.listen<Map<String, SessionStatus>>(sessionStatusProvider, (
      _,
      statuses,
    ) {
      if (!_isAborting) return;
      final sid = sessionId;
      if (sid == null) return;
      final status = statuses[sid];
      if (status == null || status is SessionStatusIdle) {
        setState(() => _isAborting = false);
      }
    });

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
                    if (!isShellMode && _attachments.isNotEmpty)
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
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: isShellMode ? 'monospace' : null,
                      ),
                      decoration: InputDecoration(
                        hintText: isShellMode ? '输入 shell 命令...' : '随便问点什么...',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontFamily: isShellMode ? 'monospace' : null,
                        ),
                        contentPadding: const EdgeInsets.all(12),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                    _InputToolBar(
                      isLoading: _isLoading,
                      isWorking: isWorking,
                      isAborting: _isAborting,
                      isShellMode: isShellMode,
                      onPickImage: _pickImage,
                      onSend: _handleSend,
                      onAbort: _handleAbort,
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
              inputMode: _inputMode,
              onModeChange: _setInputMode,
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
  /// True while the send HTTP request is in-flight (near-instant, but guards
  /// against double-tap).
  final bool isLoading;

  /// True when the backend is actively processing (busy or retry state).
  /// When true, the action button switches to a Stop icon.
  final bool isWorking;

  /// True while an abort request has been sent and we are awaiting the SSE
  /// idle confirmation. Disables the button to prevent duplicate requests.
  final bool isAborting;

  final bool isShellMode;
  final VoidCallback onPickImage;
  final VoidCallback onSend;
  final VoidCallback onAbort;

  const _InputToolBar({
    required this.isLoading,
    required this.isWorking,
    required this.isAborting,
    required this.isShellMode,
    required this.onPickImage,
    required this.onSend,
    required this.onAbort,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the current action-button configuration.
    // Priority: aborting > working > sending > idle.
    final bool showStop = isWorking || isAborting;
    final bool actionDisabled = isAborting || isLoading;
    final Color buttonColor;
    if (showStop) {
      buttonColor = actionDisabled
          ? Colors.red.withValues(alpha: 0.5)
          : Colors.red;
    } else {
      buttonColor = actionDisabled ? Colors.grey : Colors.grey[600]!;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Text(
            isShellMode ? r'$' : '>>',
            style: TextStyle(
              color: isShellMode ? const Color(0xFF0F766E) : Colors.green,
              fontWeight: FontWeight.bold,
              fontFamily: isShellMode ? 'monospace' : null,
            ),
          ),
          const Spacer(),
          if (!isShellMode)
            IconButton(
              onPressed: (isLoading || isWorking) ? null : onPickImage,
              icon: const Icon(Icons.add, size: 20, color: Colors.grey),
              visualDensity: VisualDensity.compact,
            ),
          Container(
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              color: buttonColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Show a subtle spinner overlay while loading or aborting.
                if (isLoading || isAborting)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                    ),
                  ),
                IconButton(
                  onPressed: actionDisabled
                      ? null
                      : (showStop ? onAbort : onSend),
                  icon: Icon(
                    showStop ? Icons.stop_rounded : Icons.arrow_upward,
                    size: 20,
                    color: Colors.white,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
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
  final _InputMode inputMode;
  final ValueChanged<_InputMode> onModeChange;

  const _ConfigToolBar({
    required this.chatConfig,
    required this.onToggleAgent,
    required this.onShowModelSelector,
    required this.inputMode,
    required this.onModeChange,
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
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _ModeIconButton(
                icon: Icons.terminal,
                selected: inputMode == _InputMode.shell,
                onTap: () => onModeChange(_InputMode.shell),
              ),
              _ModeIconButton(
                icon: Icons.chat_bubble_outline,
                selected: inputMode == _InputMode.chat,
                onTap: () => onModeChange(_InputMode.chat),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ModeIconButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ModeIconButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF1F5F9) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: selected
              ? Border.all(color: const Color(0xFFD7E1EC))
              : Border.all(color: Colors.transparent),
        ),
        child: Icon(
          icon,
          size: 18,
          color: selected ? const Color(0xFF0F172A) : Colors.grey,
        ),
      ),
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
