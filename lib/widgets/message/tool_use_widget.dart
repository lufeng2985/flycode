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

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
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
    final rightAction = _canNavigate
        ? Icon(
            Icons.open_in_new,
            size: 14,
            color: Theme.of(context).colorScheme.primary,
          )
        : _hasExpandableContent && !_isActive
        ? Icon(
            _isExpanded ? Icons.expand_less : Icons.expand_more,
            size: 16,
            color: Colors.grey[500],
          )
        : null;

    return GestureDetector(
      onTap: _canNavigate
          ? () => widget.onNavigateToSubSession!(_subSessionId!)
          : _hasExpandableContent
          ? () => setState(() => _isExpanded = !_isExpanded)
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Display name — shimmer when active
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _isActive
                          ? Shimmer.fromColors(
                              baseColor: Colors.grey[400]!,
                              highlightColor: Colors.grey[200]!,
                              child: Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _isError
                                    ? Colors.red[700]
                                    : Colors.black87,
                              ),
                            ),
                      SizedBox(width: 8),
                      if (!_isActive &&
                          !_isError &&
                          subtitle != null &&
                          subtitle.isNotEmpty)
                        Expanded(
                          child: _part.tool == 'webfetch'
                              ? GestureDetector(
                                  onTap: () => _launchUrl(subtitle),
                                  child: Text(
                                    subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                )
                              : Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                  ),
                                ),
                        ),
                    ],
                  ),
                  // Args chips (only when not active)
                  if (args.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(
                        top:
                            (!_isActive &&
                                !_isError &&
                                subtitle != null &&
                                subtitle.isNotEmpty)
                            ? 6
                            : 4,
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final maxWidth = constraints.maxWidth.isFinite
                              ? constraints.maxWidth
                              : 280.0;
                          return Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: args
                                .map(
                                  (arg) =>
                                      _ArgChip(label: arg, maxWidth: maxWidth),
                                )
                                .toList(),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            if (rightAction != null) ...[const SizedBox(width: 8), rightAction],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBody(BuildContext context) {
    final err = _errorText ?? '';
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 8),
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
  final double maxWidth;

  const _ArgChip({required this.label, required this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F1F1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF555555),
            fontFamily: 'monospace',
          ),
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
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F8FA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SelectableText(
            command.isNotEmpty
                ? '\$ $command\n\n$displayOutput'
                : displayOutput,
            style: const TextStyle(
              color: Color(0xFF1F2328),
              fontSize: 13,
              height: 1.5,
              fontFamily: 'monospace',
            ),
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
      padding: const EdgeInsets.only(top: 4, bottom: 8),
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
