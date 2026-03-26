import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/current_directory_provider.dart';
import '../../providers/question_provider.dart';
import '../../service/api/models/question.dart';

/// Displays all pending questions for the current session as a step-by-step
/// card overlay at the bottom of the chat view.
class QuestionOverlay extends ConsumerWidget {
  const QuestionOverlay({super.key, required this.sessionID});

  final String sessionID;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(pendingQuestionsProvider);

    return questionsAsync.when(
      data: (questions) {
        final sessionQuestions = questions
            .where((q) => q.sessionID == sessionID)
            .toList();
        if (sessionQuestions.isEmpty) return const SizedBox.shrink();

        return QuestionRequestCard(request: sessionQuestions.first);
      },
      loading: () => const SizedBox.shrink(),
      error: (err, st) => const SizedBox.shrink(),
    );
  }
}

/// Card that handles a single QuestionRequest (which may contain multiple
/// questions). Walks through each question one step at a time.
class QuestionRequestCard extends ConsumerStatefulWidget {
  const QuestionRequestCard({super.key, required this.request});

  final QuestionRequest request;

  @override
  ConsumerState<QuestionRequestCard> createState() =>
      _QuestionRequestCardState();
}

class _QuestionRequestCardState extends ConsumerState<QuestionRequestCard> {
  int _currentIndex = 0;

  // answers[i] = list of selected labels for question i
  late final List<List<String>> _answers;

  // custom text controllers, one per question
  late final List<TextEditingController> _customControllers;

  @override
  void initState() {
    super.initState();
    final count = widget.request.questions.length;
    _answers = List.generate(count, (_) => []);
    _customControllers = List.generate(count, (_) => TextEditingController());
  }

  @override
  void dispose() {
    for (final c in _customControllers) {
      c.dispose();
    }
    super.dispose();
  }

  QuestionInfo get _currentQuestion => widget.request.questions[_currentIndex];

  bool get _isLastQuestion =>
      _currentIndex == widget.request.questions.length - 1;

  bool get _canGoBack => _currentIndex > 0;

  bool get _canProceed {
    final selected = _answers[_currentIndex];
    final hasCustomInput = _customControllers[_currentIndex].text
        .trim()
        .isNotEmpty;
    return selected.isNotEmpty || hasCustomInput;
  }

  void _toggleOption(String label) {
    final current = _answers[_currentIndex];
    final question = _currentQuestion;
    final isMultiple = question.multiple ?? false;

    setState(() {
      if (isMultiple) {
        if (current.contains(label)) {
          _answers[_currentIndex] = current.where((l) => l != label).toList();
        } else {
          _answers[_currentIndex] = [...current, label];
        }
      } else {
        _answers[_currentIndex] = current.contains(label) ? [] : [label];
      }
    });
  }

  void _onPrevious() {
    if (_canGoBack) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  Future<void> _onNext() async {
    // Collect custom input if provided
    final customText = _customControllers[_currentIndex].text.trim();
    if (customText.isNotEmpty &&
        !_answers[_currentIndex].contains(customText)) {
      _answers[_currentIndex] = [..._answers[_currentIndex], customText];
    }

    if (_isLastQuestion) {
      await _submit();
    } else {
      setState(() {
        _currentIndex++;
      });
    }
  }

  Future<void> _submit() async {
    final directory = ref.read(currentDirectoryProvider);
    await ref
        .read(pendingQuestionsProvider.notifier)
        .reply(widget.request.id, answers: _answers, directory: directory);
  }

  Future<void> _reject() async {
    final directory = ref.read(currentDirectoryProvider);
    await ref
        .read(pendingQuestionsProvider.notifier)
        .reject(widget.request.id, directory: directory);
  }

  @override
  Widget build(BuildContext context) {
    final question = _currentQuestion;
    final total = widget.request.questions.length;
    final isMultiple = question.multiple ?? false;
    final hasCustom = question.custom ?? true; // default true per spec

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: step indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Text(
                  '${_currentIndex + 1} of $total question${total > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                _StepDots(total: total, current: _currentIndex),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Question text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              question.question,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              isMultiple ? '选择一个或多个答案' : '选择一个答案',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ),
          const SizedBox(height: 8),
          // Options list
          _OptionsList(
            question: question,
            selected: _answers[_currentIndex],
            customController: _customControllers[_currentIndex],
            onToggle: _toggleOption,
            hasCustom: hasCustom,
            onCustomChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          // Footer: ignore / previous / next
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              children: [
                TextButton(
                  onPressed: _reject,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('忽略', style: TextStyle(fontSize: 14)),
                ),
                if (_canGoBack) ...[
                  const Spacer(),
                  TextButton(
                    onPressed: _onPrevious,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[700],
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('上一步', style: TextStyle(fontSize: 14)),
                  ),
                ],
                const Spacer(),
                FilledButton(
                  onPressed: _canProceed ? _onNext : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black87,
                    disabledBackgroundColor: Colors.grey[300],
                    foregroundColor: Colors.white,
                    minimumSize: const Size(80, 36),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: Text(
                    _isLastQuestion ? '提交' : '下一步',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.total, required this.current});

  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final isActive = i == current;
        return Container(
          margin: const EdgeInsets.only(left: 4),
          width: isActive ? 20 : 8,
          height: 3,
          decoration: BoxDecoration(
            color: isActive ? Colors.black87 : Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}

class _OptionsList extends StatelessWidget {
  const _OptionsList({
    required this.question,
    required this.selected,
    required this.customController,
    required this.onToggle,
    required this.hasCustom,
    required this.onCustomChanged,
  });

  final QuestionInfo question;
  final List<String> selected;
  final TextEditingController customController;
  final void Function(String label) onToggle;
  final bool hasCustom;
  final void Function(String) onCustomChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          ...question.options.map(
            (opt) => _OptionTile(
              label: opt.label,
              description: opt.description,
              isSelected: selected.contains(opt.label),
              onTap: () => onToggle(opt.label),
            ),
          ),
          if (hasCustom)
            _CustomInputTile(
              controller: customController,
              onChanged: onCustomChanged,
            ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey[100] : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? Colors.grey[400]! : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.black87 : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.black87 : Colors.grey[400]!,
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.black : Colors.black87,
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 1),
                    Text(
                      description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomInputTile extends StatefulWidget {
  const _CustomInputTile({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final void Function(String) onChanged;

  @override
  State<_CustomInputTile> createState() => _CustomInputTileState();
}

class _CustomInputTileState extends State<_CustomInputTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _focused ? Colors.grey[400]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[400]!, width: 1.5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Focus(
              onFocusChange: (v) => setState(() => _focused = v),
              child: TextField(
                controller: widget.controller,
                onChanged: widget.onChanged,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
                decoration: InputDecoration(
                  hintText: '输入你的答案...',
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 6),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
