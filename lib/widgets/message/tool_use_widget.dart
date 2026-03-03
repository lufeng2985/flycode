import 'package:flutter/material.dart';
import '../../service/api/models/parts.dart';
import 'json_viewer.dart';

class ToolUseWidget extends StatefulWidget {
  final ToolPart toolPart;

  const ToolUseWidget({super.key, required this.toolPart});

  @override
  State<ToolUseWidget> createState() => _ToolUseWidgetState();
}

class _ToolUseWidgetState extends State<ToolUseWidget> {
  bool _isExpanded = false;

  String _getToolSummary() {
    final state = widget.toolPart.state;
    Map<String, dynamic>? input;
    if (state is ToolStateRunning) {
      input = state.input;
    } else if (state is ToolStateCompleted) {
      input = state.input;
    } else if (state is ToolStateError) {
      input = state.input;
    }

    if (input != null && input.containsKey('command')) {
      return input['command'].toString();
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final toolName = widget.toolPart.tool;
    final inputJson = _getToolInputJson();
    final output = _getToolOutput();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Text(
                    toolName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _getToolSummary(),
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
            if (inputJson != null) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(10),
                child: JsonViewer(jsonString: inputJson),
              ),
            ],
            if (output != null) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 14,
                          color: Colors.green[700],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Result',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    JsonViewer(jsonString: output),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String? _getToolInputJson() {
    final state = widget.toolPart.state;
    if (state is ToolStatePending) {
      return state.raw;
    } else if (state is ToolStateRunning) {
      return state.input.isNotEmpty ? _encodeJson(state.input) : null;
    } else if (state is ToolStateCompleted) {
      return state.input.isNotEmpty ? _encodeJson(state.input) : null;
    } else if (state is ToolStateError) {
      return state.input.isNotEmpty ? _encodeJson(state.input) : null;
    }
    return null;
  }

  String? _getToolOutput() {
    final state = widget.toolPart.state;
    if (state is ToolStateCompleted) {
      return state.output;
    } else if (state is ToolStateError) {
      return 'Error: ${state.error}';
    }
    return null;
  }

  String _encodeJson(Map<String, dynamic> json) {
    return json.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }
}
