import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import '../../service/api/session_api.dart';
import '../../service/api/models/prompt_input.dart';
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
  bool _isLoading = false;
  final List<_ImageAttachment> _attachments = [];

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

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _attachments.isEmpty) return;
    if (_isLoading) return;

    final selectedState = ref.read(selectedSessionProvider);
    if (selectedState.session == null && !selectedState.isPending) return;

    setState(() {
      _isLoading = true;
    });

    final chatConfig = ref.read(chatConfigProvider).asData?.value;

    try {
      final api = await ref.read(sessionApiProvider.future);

      var session = selectedState.session;
      if (session == null && selectedState.isPending) {
        final project = await ref.read(selectedProjectProvider.future);
        session = await api.createSession(directory: project?.worktree);
        ref.read(selectedSessionProvider.notifier).select(session);
      }

      // 构造 parts：先文字（若有），再图片附件
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
        session!.id,
        data: PromptAsyncInput(
          agent: chatConfig?.agent,
          model: chatConfig?.model,
          parts: parts,
        ),
      );

      _controller.clear();
      setState(() {
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 图片预览区（仅在有附件时显示）
                  if (_attachments.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(_attachments.length, (i) {
                            final att = _attachments[i];
                            final bytes = base64Decode(
                              att.dataUrl.split(',').last,
                            );
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  GestureDetector(
                                    onTap: () =>
                                        _showImagePreview(context, att),
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
                                      onTap: () => _removeAttachment(i),
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
                    ),
                  TextField(
                    controller: _controller,
                    autofocus: false,
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
                          onPressed: _isLoading ? null : _pickImage,
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
