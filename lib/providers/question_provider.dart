import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../service/api/models/question.dart';
import '../service/api/question_api.dart';
import '../providers/project_provider.dart';
import 'session_provider.dart';

part 'question_provider.g.dart';

/// Holds the list of pending QuestionRequests for the current project directory.
/// SSE events add/remove entries; initial load comes from GET /question.
@Riverpod(keepAlive: true)
class PendingQuestionsNotifier extends _$PendingQuestionsNotifier {
  @override
  Future<List<QuestionRequest>> build() async {
    final project = await ref.watch(selectedProjectProvider.future);
    final api = await ref.watch(questionApiProvider.future);
    return api.getQuestions(directory: project?.worktree);
  }

  /// SSE: question.asked — add a new question to the list.
  void addQuestion(QuestionRequest request) {
    final current = state.asData?.value ?? [];
    // Avoid duplicates
    if (current.any((q) => q.id == request.id)) return;
    state = AsyncData([...current, request]);
  }

  /// SSE: question.replied or question.rejected — remove question from list.
  void removeQuestion(String requestID) {
    final current = state.asData?.value ?? [];
    state = AsyncData(current.where((q) => q.id != requestID).toList());
  }

  /// Submit answers for a question and remove it from the list.
  Future<void> reply(
    String requestID, {
    required List<List<String>> answers,
    String? directory,
  }) async {
    final api = await ref.read(questionApiProvider.future);
    await api.replyQuestion(requestID, answers: answers, directory: directory);
    removeQuestion(requestID);
  }

  /// Reject a question and remove it from the list.
  Future<void> reject(String requestID, {String? directory}) async {
    final api = await ref.read(questionApiProvider.future);
    await api.rejectQuestion(requestID, directory: directory);
    removeQuestion(requestID);
  }
}

@Riverpod(keepAlive: true)
bool currentSessionHasQuestion(Ref ref) {
  final selectedState = ref.watch(selectedSessionProvider);
  final sessionId = selectedState.session?.id;
  if (sessionId == null) return false;

  final questions = ref.watch(pendingQuestionsProvider);
  return questions.asData?.value?.any((q) => q.sessionID == sessionId) ?? false;
}
