import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import '../../service/api/session_api.dart';
import '../../service/api/command_api.dart';
import '../../service/api/file_api.dart';
import '../../service/api/models/prompt_input.dart';
import '../../service/api/models/command_input.dart';
import '../../service/api/models/command.dart';
import '../../providers/agent_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/chat_config_provider.dart';
import '../../providers/provider_list_provider.dart';
import '../../providers/project_provider.dart';
import '../../providers/session_status_provider.dart';
import '../../service/api/models/agent.dart';
import '../../service/api/models/provider.dart';
import '../../service/api/models/session_status.dart';
import 'at_mention_controller.dart';
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
  final AtMentionController _controller = AtMentionController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  bool _isLoading = false;

  /// True while an abort request has been sent and we are waiting for the
  /// backend to confirm the session is idle (via SSE session.status event).
  bool _isAborting = false;

  _InputMode _inputMode = _InputMode.chat;
  final List<_ImageAttachment> _attachments = [];
  OverlayEntry? _commandOverlay;
  List<Command> _filteredCommands = [];

  // ─── @ file mention state ─────────────────────────────────────────
  OverlayEntry? _atFileOverlay;
  String _atFilter = '';
  List<String> _atSearchResults = [];
  int _atHighlightIndex = 0;
  Timer? _atDebounceTimer;
  // Position of the `@` character that triggered the current search.
  int _atTriggerStart = -1;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    _focusNode.onKeyEvent = _handleKeyEvent;
  }

  // ─── 命令检测逻辑 ─────────────────────────────────────────────

  void _onTextChanged() {
    // Sync pills first — remove stale ones after any edit.
    _controller.syncPills();

    _syncInputModeByBangPrefix(_controller.text);

    if (_inputMode == _InputMode.shell) {
      _hideCommandOverlay();
      _hideAtFileOverlay();
      return;
    }

    final text = _controller.text;
    final sel = _controller.selection;
    final cursorPos = sel.isCollapsed ? sel.baseOffset : -1;

    // ── @ file mention detection ──
    if (cursorPos > 0) {
      final textBefore = text.substring(0, cursorPos);
      final atMatch = RegExp(r'@(\S*)$').firstMatch(textBefore);
      if (atMatch != null) {
        final filter = atMatch.group(1)!;
        final atStart = atMatch.start;
        // Only show overlay if we are not inside a pill.
        if (_controller.pillAt(atStart) == null) {
          _atTriggerStart = atStart;
          if (filter != _atFilter) {
            _atFilter = filter;
            _atHighlightIndex = 0;
            _triggerAtSearch(filter);
          }
          if (_atFileOverlay == null && _atSearchResults.isNotEmpty) {
            _showAtFileOverlay();
          }
          // ── @ overlay is active; skip command detection ──
          _hideCommandOverlay();
          return;
        }
      }
    }

    // No @ match — hide the file overlay.
    _hideAtFileOverlay();
    _atTriggerStart = -1;
    _atFilter = '';

    // ── Command autocomplete ──
    if (!text.startsWith('/') || text.contains(' ')) {
      _hideCommandOverlay();
      return;
    }

    final query = text.substring(1);
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

  /// Debounced search via GET /find/file.
  void _triggerAtSearch(String filter) {
    _atDebounceTimer?.cancel();
    _atDebounceTimer = Timer(const Duration(milliseconds: 200), () async {
      try {
        final fileApi = await ref.read(fileApiProvider.future);
        final results = await fileApi.findFile(filter, dirs: true, limit: 10);
        if (!mounted) return;
        setState(() {
          _atSearchResults = results;
          _atHighlightIndex = 0;
        });
        if (_atFileOverlay == null && results.isNotEmpty) {
          _showAtFileOverlay();
        } else {
          _atFileOverlay?.markNeedsBuild();
          // Hide overlay if no results.
          if (results.isEmpty) _hideAtFileOverlay();
        }
      } catch (_) {
        // Silently ignore search errors.
      }
    });
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

  // ─── Command Overlay ──────────────────────────────────────────────

  void _showCommandOverlay() {
    final overlay = Overlay.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    const horizontalPadding = 12.0;
    final overlayWidth = screenWidth - horizontalPadding * 2;
    final maxHeight = screenHeight * 0.5;

    final renderBox = context.findRenderObject() as RenderBox?;
    final boxOffset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
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
    _controller.value = TextEditingValue(
      text: '/${command.name} ',
      selection: TextSelection.collapsed(offset: 1 + command.name.length + 1),
    );
  }

  // ─── @ File Overlay ───────────────────────────────────────────────

  void _showAtFileOverlay() {
    if (_atFileOverlay != null) return;
    final overlay = Overlay.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    const horizontalPadding = 12.0;
    final overlayWidth = screenWidth - horizontalPadding * 2;
    final maxHeight = screenHeight * 0.4;

    final renderBox = context.findRenderObject() as RenderBox?;
    final boxOffset = renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final bottomY = boxOffset.dy - 4;

    _atFileOverlay = OverlayEntry(
      builder: (ctx) => Positioned(
        left: horizontalPadding,
        bottom: screenHeight - bottomY,
        width: overlayWidth,
        child: _AtFileSuggestionList(
          results: _atSearchResults,
          highlightIndex: _atHighlightIndex,
          maxHeight: maxHeight,
          onSelect: _onFileSelected,
        ),
      ),
    );
    overlay.insert(_atFileOverlay!);
  }

  void _hideAtFileOverlay() {
    _atFileOverlay?.remove();
    _atFileOverlay = null;
  }

  void _onFileSelected(String relativePath) {
    _hideAtFileOverlay();
    final sel = _controller.selection;
    final cursorPos = sel.isCollapsed
        ? sel.baseOffset
        : _controller.text.length;
    _controller.insertPill(relativePath, _atTriggerStart, cursorPos);
    _atTriggerStart = -1;
    _atFilter = '';
    _atSearchResults = [];
    _focusNode.requestFocus();
  }

  /// Move highlight up or down in the @ file overlay.
  void _moveAtHighlight(int delta) {
    if (_atSearchResults.isEmpty) return;
    setState(() {
      _atHighlightIndex = (_atHighlightIndex + delta).clamp(
        0,
        _atSearchResults.length - 1,
      );
    });
    _atFileOverlay?.markNeedsBuild();
  }

  /// Confirm the current highlight in the @ file overlay.
  void _confirmAtHighlight() {
    if (_atSearchResults.isEmpty) return;
    _onFileSelected(_atSearchResults[_atHighlightIndex]);
  }

  // ─── Keyboard handling ────────────────────────────────────────────

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    // @ file overlay navigation.
    if (_atFileOverlay != null) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _moveAtHighlight(-1);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _moveAtHighlight(1);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.tab) {
        _confirmAtHighlight();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        _hideAtFileOverlay();
        return KeyEventResult.handled;
      }
    }

    // Backspace: delete pill atomically.
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controller.tryDeletePillBeforeCursor()) {
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  void _syncInputModeByBangPrefix(String text) {
    final shouldShellMode = text.startsWith('!');
    final nextMode = shouldShellMode ? _InputMode.shell : _InputMode.chat;
    _setInputMode(nextMode);
  }

  String _normalizeShellCommand(String text) {
    final trimmed = text.trim();
    if (!trimmed.startsWith('!')) {
      return trimmed;
    }
    return trimmed.substring(1).trimLeft();
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
    final shellCommand = isShellMode ? _normalizeShellCommand(text) : text;
    if (isShellMode && shellCommand.isEmpty) return;
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
        await _dispatchShell(api, session, project, chatConfig, shellCommand);
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
          await _dispatchPrompt(api, session, project, chatConfig);
        }
      }

      setState(() {
        _controller.clear();
        _controller.pills.clear();
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
  Future<void> _handleAbort() async {
    if (_isAborting) return;
    final session = ref.read(selectedSessionProvider).session;
    if (session == null) return;

    setState(() => _isAborting = true);

    try {
      final api = await ref.read(sessionApiProvider.future);
      final project = await ref.read(selectedProjectProvider.future);
      await api.abortSession(session.id, directory: project?.worktree);
    } catch (e) {
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
  ) async {
    final text = _controller.text;
    final rootDir = (project?.worktree as String?) ?? '';

    // Build file parts from @ pills.
    final fileParts = _controller.pills.map((pill) {
      final rel = pill.path;
      final absPath = rootDir.isNotEmpty
          ? '$rootDir/$rel'.replaceAll('//', '/')
          : rel;
      return FilePartInput(
        mime: 'text/plain',
        url: 'file://$absPath',
        filename: rel.split('/').last,
        source: {
          'type': 'file',
          'path': absPath,
          'text': {
            'value': pill.displayText,
            'start': pill.start,
            'end': pill.end,
          },
        },
      );
    }).toList();

    final List<Object> parts = [
      if (text.isNotEmpty) TextPartInput(text: text),
      ...fileParts,
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

  /// Cycles through agents when there are ≤ 3, otherwise shows the selector.
  void _handleAgentTap(List<Agent> agents) {
    if (agents.isEmpty) return;
    if (agents.length <= 3) {
      _cycleAgent(agents);
    } else {
      _showAgentSelector(agents);
    }
  }

  /// Cycles to the next agent in the list (wraps around).
  void _cycleAgent(List<Agent> agents) {
    final current = ref.read(chatConfigProvider).agent;
    final idx = agents.indexWhere((a) => a.name == current);
    final nextIdx = (idx + 1) % agents.length;
    final next = agents[nextIdx];
    ref
        .read(chatConfigProvider.notifier)
        .setAgent(next.name, linkedModel: next.model);
  }

  /// Shows a bottom sheet for selecting an agent (used when > 3 agents).
  void _showAgentSelector(List<Agent> agents) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AgentSelectionSheet(
        agents: agents,
        currentAgent: ref.read(chatConfigProvider).agent,
        onSelect: (agent) {
          ref
              .read(chatConfigProvider.notifier)
              .setAgent(agent.name, linkedModel: agent.model);
          Navigator.of(context).pop();
        },
      ),
    );
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
    _hideAtFileOverlay();
  }

  // ─── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final chatConfig = ref.watch(chatConfigProvider);
    final theme = Theme.of(context);
    final isShellMode = _inputMode == _InputMode.shell;
    final providerList = ref.watch(providerListProvider).asData?.value;
    ref.watch(commandsProvider);

    final modelLabel = _resolveModelLabel(providerList, chatConfig);

    final sessionId = ref.watch(
      selectedSessionProvider.select((s) => s.session?.id),
    );
    final sessionStatuses = ref.watch(sessionStatusProvider);
    final isWorking =
        sessionId != null && (sessionStatuses[sessionId]?.isWorking ?? false);

    // Reconcile status snapshot on session switch to recover from missed SSE.
    ref.listen<String?>(selectedSessionProvider.select((s) => s.session?.id), (
      previous,
      next,
    ) {
      if (next == null || next == previous) return;
      unawaited(ref.read(sessionStatusProvider.notifier).refreshFromServer());
    });

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
            _ConfigToolBar(
              chatConfig: chatConfig,
              modelLabel: modelLabel,
              agents: ref.watch(agentsProvider).asData?.value ?? const [],
              onAgentTap: _handleAgentTap,
              onShowModelSelector: _showModelSelector,
            ),
            const SizedBox(height: 12),
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
                      focusNode: _focusNode,
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
          ],
        ),
      ),
    );
  }

  String _resolveModelLabel(
    ProviderListResponse? providerList,
    ChatConfig chatConfig,
  ) {
    if (providerList == null) {
      return chatConfig.model.modelID;
    }
    for (final provider in providerList.all) {
      if (provider.id != chatConfig.model.providerID) {
        continue;
      }
      final model = provider.models[chatConfig.model.modelID];
      if (model != null && model.name.isNotEmpty) {
        return model.name;
      }
    }
    return chatConfig.model.modelID;
  }

  @override
  void dispose() {
    _hideCommandOverlay();
    _hideAtFileOverlay();
    _atDebounceTimer?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
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
  final bool isWorking;
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
  final String modelLabel;
  final List<Agent> agents;
  final ValueChanged<List<Agent>> onAgentTap;
  final VoidCallback onShowModelSelector;

  const _ConfigToolBar({
    required this.chatConfig,
    required this.modelLabel,
    required this.agents,
    required this.onAgentTap,
    required this.onShowModelSelector,
  });

  String get _agentLabel {
    final name = chatConfig.agent;
    if (name.isEmpty) return 'Agent';
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SelectionChip(
          onTap: agents.isNotEmpty ? () => onAgentTap(agents) : null,
          label: _agentLabel,
        ),
        const SizedBox(width: 8),
        _SelectionChip(
          onTap: onShowModelSelector,
          label: modelLabel,
          icon: Icons.share_outlined,
        ),
        const SizedBox(width: 8),
        const _SelectionChip(label: '默认'),
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

// ─── Agent 选择底部弹窗（> 3 个 agent 时使用）────────────────────

class _AgentSelectionSheet extends StatelessWidget {
  final List<Agent> agents;
  final String currentAgent;
  final ValueChanged<Agent> onSelect;

  const _AgentSelectionSheet({
    required this.agents,
    required this.currentAgent,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖动指示条
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                '选择 Agent',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Divider(height: 1),
            ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: agents.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: Colors.grey[100]),
              itemBuilder: (ctx, i) {
                final agent = agents[i];
                final isSelected = agent.name == currentAgent;
                final label = agent.name.isNotEmpty
                    ? '${agent.name[0].toUpperCase()}${agent.name.substring(1)}'
                    : agent.name;
                return InkWell(
                  onTap: () => onSelect(agent),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        // 颜色圆点（如果有 color 字段）
                        if (agent.color != null) ...[
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _parseColor(agent.color!),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : Colors.black87,
                                ),
                              ),
                              if (agent.description != null &&
                                  agent.description!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    agent.description!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }
}

// ─── @ 文件建议列表 Widget ────────────────────────────────────────

class _AtFileSuggestionList extends StatelessWidget {
  final List<String> results;
  final int highlightIndex;
  final double maxHeight;
  final ValueChanged<String> onSelect;

  const _AtFileSuggestionList({
    required this.results,
    required this.highlightIndex,
    required this.maxHeight,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const SizedBox.shrink();

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(10),
      color: Colors.white,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemCount: results.length,
          separatorBuilder: (_, _) =>
              Divider(height: 1, color: Colors.grey[100]),
          itemBuilder: (ctx, i) {
            final path = results[i];
            final isHighlighted = i == highlightIndex;
            final filename = path.split('/').last;
            final dir = path.contains('/')
                ? path.substring(0, path.lastIndexOf('/'))
                : null;

            return GestureDetector(
              // Use onTapDown + onTap to avoid defocusing the text field.
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelect(path),
              child: Container(
                color: isHighlighted
                    ? const Color(0xFFEFF6FF)
                    : Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.insert_drive_file_outlined,
                      size: 16,
                      color: isHighlighted
                          ? const Color(0xFF2563EB)
                          : Colors.grey[500],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: filename,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isHighlighted
                                    ? const Color(0xFF1D4ED8)
                                    : Colors.black87,
                              ),
                            ),
                            if (dir != null)
                              TextSpan(
                                text: '  $dir',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
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
