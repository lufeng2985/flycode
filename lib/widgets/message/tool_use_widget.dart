import 'package:flutter/material.dart';
import '../../service/api/models/parts.dart';
import 'json_viewer.dart';

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
  bool _isExpanded = true;

  String? _subSessionId() {
    final metadata = widget.toolPart.metadata;
    if (metadata == null) return null;
    return metadata['sessionId'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    final isBash = widget.toolPart.tool == 'bash';
    final isTask = widget.toolPart.tool == 'task';
    final subSessionId = isTask ? _subSessionId() : null;
    final canNavigate =
        isTask && subSessionId != null && widget.onNavigateToSubSession != null;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: isBash ? const Color(0xFFF8FAFC) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isBash ? const Color(0xFFD5DDE8) : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              child: Row(
                children: [
                  Icon(
                    isBash ? Icons.terminal : Icons.build_outlined,
                    size: 14,
                    color: Colors.blueGrey[700],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.toolPart.tool,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(state: widget.toolPart.state),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _summary(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ),
                  if (canNavigate)
                    GestureDetector(
                      onTap: () => widget.onNavigateToSubSession!(subSessionId),
                      child: Tooltip(
                        message: '查看子 Session',
                        child: Icon(
                          Icons.open_in_new,
                          size: 15,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                  else
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            if (isBash)
              _BashOutputPanel(
                command: _command(),
                output: _output(),
                running: _isRunning(),
              )
            else
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_inputJson() != null) ...[
                      JsonViewer(jsonString: _inputJson()),
                      const SizedBox(height: 8),
                    ],
                    if (_output() != null)
                      JsonViewer(jsonString: _output())
                    else
                      Text(
                        _isRunning() ? 'Running...' : 'No output',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _summary() {
    final command = _command();
    if (command.isNotEmpty) return command;
    return _isRunning() ? 'Running...' : 'Tool result';
  }

  String _command() {
    final state = widget.toolPart.state;
    if (state is ToolStateRunning) {
      return state.input['command']?.toString() ?? '';
    }
    if (state is ToolStateCompleted) {
      return state.input['command']?.toString() ?? '';
    }
    if (state is ToolStateError) {
      return state.input['command']?.toString() ?? '';
    }
    return '';
  }

  String? _inputJson() {
    final state = widget.toolPart.state;
    if (state is ToolStatePending) {
      return state.raw;
    }
    if (state is ToolStateRunning) {
      return _toLines(state.input);
    }
    if (state is ToolStateCompleted) {
      return _toLines(state.input);
    }
    if (state is ToolStateError) {
      return _toLines(state.input);
    }
    return null;
  }

  String? _output() {
    final state = widget.toolPart.state;
    if (state is ToolStateRunning) {
      return state.metadata?['output']?.toString();
    }
    if (state is ToolStateCompleted) {
      final metadataOutput = state.metadata['output']?.toString();
      return (metadataOutput != null && metadataOutput.isNotEmpty)
          ? metadataOutput
          : state.output;
    }
    if (state is ToolStateError) {
      return state.error;
    }
    return null;
  }

  bool _isRunning() => widget.toolPart.state is ToolStateRunning;

  String _toLines(Map<String, dynamic> json) {
    if (json.isEmpty) return '';
    return json.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }
}

class _StatusBadge extends StatelessWidget {
  final Object state;

  const _StatusBadge({required this.state});

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg) = _statusStyle();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w700),
      ),
    );
  }

  (String, Color, Color) _statusStyle() {
    if (state is ToolStateRunning) {
      return ('RUNNING', const Color(0xFF8A6200), const Color(0xFFFFF4CC));
    }
    if (state is ToolStateCompleted) {
      return ('DONE', const Color(0xFF256029), const Color(0xFFD9F2DD));
    }
    if (state is ToolStateError) {
      return ('ERROR', const Color(0xFF8B1E1E), const Color(0xFFFFE1E1));
    }
    return ('PENDING', const Color(0xFF475569), const Color(0xFFE2E8F0));
  }
}

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
    final displayOutput = output?.isNotEmpty == true
        ? output!
        : (running ? 'running...' : 'no output');

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(8),
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
