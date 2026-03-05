import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../service/api/session_api.dart';
import '../../service/api/models/prompt_input.dart';
import '../../providers/session_provider.dart';
import '../../providers/chat_config_provider.dart';
import 'model_selection_sheet.dart';

class ChatInput extends ConsumerStatefulWidget {
  const ChatInput({super.key});

  @override
  ConsumerState<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends ConsumerState<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    final selectedSession = ref.read(selectedSessionProvider);
    if (selectedSession == null) return;

    setState(() {
      _isLoading = true;
    });

    final chatConfig = ref.read(chatConfigProvider).asData?.value;

    try {
      final api = await ref.read(sessionApiProvider.future);
      await api.sendPromptAsync(
        selectedSession.id,
        data: PromptAsyncInput(
          agent: chatConfig?.agent,
          model: chatConfig?.model,
          parts: [TextPartInput(text: text)],
        ),
      );
      _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleAgent() {
    final config = ref.read(chatConfigProvider).asData?.value;
    if (config == null) return;

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

  @override
  Widget build(BuildContext context) {
    final chatConfig = ref.watch(chatConfigProvider).asData?.value;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _controller,
                    maxLines: 5,
                    minLines: 1,
                    decoration: const InputDecoration(
                      hintText: '随便问点什么...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                      contentPadding: EdgeInsets.all(12),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _handleSend(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        const Text(
                          '>>',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.add,
                            size: 20,
                            color: Colors.grey,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          decoration: BoxDecoration(
                            color: _isLoading ? Colors.grey : Colors.grey[400],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: IconButton(
                            onPressed: _isLoading ? null : _handleSend,
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
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                GestureDetector(
                  onTap: _toggleAgent,
                  child: _buildDropdown(
                    chatConfig != null
                        ? '${chatConfig.agent[0].toUpperCase()}'
                              '${chatConfig.agent.substring(1)}'
                        : '...',
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showModelSelector,
                  child: _buildDropdown(
                    chatConfig?.model.modelID ?? '...',
                    icon: Icons.share_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                _buildDropdown('默认'),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, {IconData? icon}) {
    return Container(
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
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
