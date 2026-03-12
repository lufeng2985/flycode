import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../service/api/models/parts.dart';
import 'tool_meta.dart';

class ToolUseWidget extends StatefulWidget {
  final ToolPart toolPart;
  final void Function(String sessionId)? onNavigateToSubSession;

  const ToolUseWidget({
    super.key,
    required this.toolPart,
    this.onNavigateToSubSession,
  });

  @override
  State<ToolUseWidget> createState() => _ToolUseWidgetState();
}

class _ToolUseWidgetState extends State<ToolUseWidget> {
  bool _isExpanded = false;

  ToolPart get _part => widget.toolPart;

  bool get _isPending => _part.state is ToolStatePending;
  bool get _isRunning => _part.state is ToolStateRunning;
  bool get _isCompleted => _part.state is ToolStateCompleted;
  bool get _isError => _part.state is ToolStateError;
  bool get _isActive => _isPending || _isRunning;

  Map<String, dynamic> get _input {
    final state = _part.state;
    if (state is ToolStatePending) return state.input;
    if (state is ToolStateRunning) return state.input;
    if (state is ToolStateCompleted) return state.input;
    if (state is ToolStateError) return state.input;
    return {};
  }

  String? get _errorText {
    final state = _part.state;
    if (state is ToolStateError) {
      var err = state.error;
      if (err.startsWith('Error: ')) err = err.substring(7);
      return err;
    }
    return null;
  }

  String? get _output {
    final state = _part.state;
    if (state is ToolStateRunning) {
      return state.metadata?['output']?.toString();
    }
    if (state is ToolStateCompleted) {
      final metaOut = state.metadata['output']?.toString();
      return (metaOut != null && metaOut.isNotEmpty) ? metaOut : state.output;
    }
    return null;
  }

  String? get _subSessionId {
    // Check top-level ToolPart.metadata first
    final topLevel = _part.metadata?['sessionId'] as String?;
    if (topLevel != null) return topLevel;
    // Fall back to state-level metadata (server may put sessionId there)
    final state = _part.state;
    if (state is ToolStateCompleted) {
      return state.metadata['sessionId'] as String?;
    }
    if (state is ToolStateRunning) {
      return state.metadata?['sessionId'] as String?;
    }
    return null;
  }

  bool get _canNavigate =>
      _part.tool == 'task' &&
      _subSessionId != null &&
      widget.onNavigateToSubSession != null;

  // Determines if this tool should render at all
  // (question only shows when completed or dismissed-error)
  bool get _shouldRender {
    if (_part.tool == 'question') {
      if (_isCompleted) return true;
      if (_isError) {
        final err = _errorText ?? '';
        return err.toLowerCase().contains('dismissed');
      }
      return false;
    }
    return true;
  }

  bool get _hasExpandableContent {
    if (_isActive || _isError) return false;
    final meta = toolMetaOf(_part.tool);
    if (!meta.hasExpandableContent) return false;
    // bash needs output or command
    if (_part.tool == 'bash') return true;
    // edit/write always show file path
    if (_part.tool == 'edit' || _part.tool == 'write') return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldRender) return const SizedBox.shrink();

    // question dismissed
    if (_part.tool == 'question' && _isError) {
      return _buildQuestionDismissed(context);
    }

    return Container(
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          if (!_isActive && _isError) _buildErrorBody(context),
          if (_isExpanded && !_isError) _buildBody(context),
        ],
      ),
    );
  }

  Widget _buildQuestionDismissed(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        'Question dismissed',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[500],
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final meta = toolMetaOf(_part.tool);
    final input = _input;

    // Resolve display name (task uses subagent_type, skill uses name)
    String displayName = meta.displayName;
    if (_part.tool == 'task') {
      displayName = input['subagent_type']?.toString() ?? 'Task';
    } else if (_part.tool == 'skill') {
      displayName = input['name']?.toString() ?? 'Skill';
    }

    final subtitle = meta.getSubtitle(input);
    final args = _isActive ? <String>[] : meta.getArgs(input);

    return InkWell(
      onTap: _canNavigate
          ? () => widget.onNavigateToSubSession!(_subSessionId!)
          : _hasExpandableContent
          ? () => setState(() => _isExpanded = !_isExpanded)
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Display name — shimmer when active
            _isActive
                ? Shimmer.fromColors(
                    baseColor: Colors.grey[400]!,
                    highlightColor: Colors.grey[200]!,
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isError ? Colors.red[700] : Colors.black87,
                    ),
                  ),
            // Args chips (only when not active)
            if (args.isNotEmpty) ...[
              const SizedBox(width: 6),
              ...args.map((arg) => _ArgChip(label: arg)),
            ],
            // Subtitle
            if (!_isActive && subtitle != null && subtitle.isNotEmpty) ...[
              const SizedBox(width: 6),
              Expanded(
                child: _part.tool == 'webfetch'
                    ? GestureDetector(
                        onTap: () => _launchUrl(subtitle),
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      )
                    : Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
              ),
            ] else
              const Spacer(),
            // Right action
            if (_canNavigate)
              Icon(
                Icons.open_in_new,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              )
            else if (_hasExpandableContent && !_isActive)
              Icon(
                _isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 15,
                color: Colors.grey[500],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBody(BuildContext context) {
    final err = _errorText ?? '';
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Text(
        err,
        style: TextStyle(fontSize: 12, color: Colors.red[700], height: 1.4),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 1, color: Color(0xFFE5E5E5)),
        if (_part.tool == 'bash')
          _BashOutputPanel(
            command: _input['command']?.toString() ?? '',
            output: _output,
            running: _isRunning,
          )
        else if (_part.tool == 'edit' || _part.tool == 'write')
          _FilePathPanel(filePath: _input['filePath']?.toString() ?? '')
        else
          const SizedBox.shrink(),
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ─── Arg chip ────────────────────────────────────────────────────────────────

class _ArgChip extends StatelessWidget {
  final String label;

  const _ArgChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF666666),
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}

// ─── Bash output panel ────────────────────────────────────────────────────────

class _BashOutputPanel extends StatelessWidget {
  final String command;
  final String? output;
  final bool running;

  const _BashOutputPanel({
    required this.command,
    required this.output,
    required this.running,
  });

  @override
  Widget build(BuildContext context) {
    final displayOutput = (output?.isNotEmpty == true)
        ? output!
        : (running ? 'running...' : 'no output');

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: SelectableText(
          command.isNotEmpty ? '\$ $command\n\n$displayOutput' : displayOutput,
          style: const TextStyle(
            color: Color(0xFFE2E8F0),
            fontSize: 12,
            height: 1.45,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}

// ─── File path panel (edit / write) ──────────────────────────────────────────

class _FilePathPanel extends StatelessWidget {
  final String filePath;

  const _FilePathPanel({required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Text(
        filePath,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[700],
          fontFamily: 'monospace',
          height: 1.4,
        ),
      ),
    );
  }
}
