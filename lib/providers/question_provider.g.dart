// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the list of pending QuestionRequests for the current project directory.
/// SSE events add/remove entries; initial load comes from GET /question.

@ProviderFor(PendingQuestionsNotifier)
final pendingQuestionsProvider = PendingQuestionsNotifierProvider._();

/// Holds the list of pending QuestionRequests for the current project directory.
/// SSE events add/remove entries; initial load comes from GET /question.
final class PendingQuestionsNotifierProvider
    extends
        $AsyncNotifierProvider<
          PendingQuestionsNotifier,
          List<QuestionRequest>
        > {
  /// Holds the list of pending QuestionRequests for the current project directory.
  /// SSE events add/remove entries; initial load comes from GET /question.
  PendingQuestionsNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingQuestionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingQuestionsNotifierHash();

  @$internal
  @override
  PendingQuestionsNotifier create() => PendingQuestionsNotifier();
}

String _$pendingQuestionsNotifierHash() =>
    r'76c58dfc5a48b68c2234e5c2865f88c05d4b3fa8';

/// Holds the list of pending QuestionRequests for the current project directory.
/// SSE events add/remove entries; initial load comes from GET /question.

abstract class _$PendingQuestionsNotifier
    extends $AsyncNotifier<List<QuestionRequest>> {
  FutureOr<List<QuestionRequest>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<QuestionRequest>>, List<QuestionRequest>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<QuestionRequest>>,
                List<QuestionRequest>
              >,
              AsyncValue<List<QuestionRequest>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
