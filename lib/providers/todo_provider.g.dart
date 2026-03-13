// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 按 sessionID 管理 todo 列表的 family provider。
///
/// - build(sessionID): 通过 REST GET /session/{id}/todo 初始化加载
/// - updateTodos(todos): 由 SSE todo.updated 事件调用，全量替换列表
///
/// 使用 keepAlive: true，确保即使 TodoListWidget 未挂载（如切换路由），
/// SSE 通过 ref.read 写入的 updateTodos 数据不会因 provider 销毁而丢失。

@ProviderFor(SessionTodosNotifier)
final sessionTodosProvider = SessionTodosNotifierFamily._();

/// 按 sessionID 管理 todo 列表的 family provider。
///
/// - build(sessionID): 通过 REST GET /session/{id}/todo 初始化加载
/// - updateTodos(todos): 由 SSE todo.updated 事件调用，全量替换列表
///
/// 使用 keepAlive: true，确保即使 TodoListWidget 未挂载（如切换路由），
/// SSE 通过 ref.read 写入的 updateTodos 数据不会因 provider 销毁而丢失。
final class SessionTodosNotifierProvider
    extends $AsyncNotifierProvider<SessionTodosNotifier, List<Todo>> {
  /// 按 sessionID 管理 todo 列表的 family provider。
  ///
  /// - build(sessionID): 通过 REST GET /session/{id}/todo 初始化加载
  /// - updateTodos(todos): 由 SSE todo.updated 事件调用，全量替换列表
  ///
  /// 使用 keepAlive: true，确保即使 TodoListWidget 未挂载（如切换路由），
  /// SSE 通过 ref.read 写入的 updateTodos 数据不会因 provider 销毁而丢失。
  SessionTodosNotifierProvider._({
    required SessionTodosNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'sessionTodosProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$sessionTodosNotifierHash();

  @override
  String toString() {
    return r'sessionTodosProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SessionTodosNotifier create() => SessionTodosNotifier();

  @override
  bool operator ==(Object other) {
    return other is SessionTodosNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$sessionTodosNotifierHash() =>
    r'62ea7de9d0d94678b2b6dd712d5dd26bc047ffef';

/// 按 sessionID 管理 todo 列表的 family provider。
///
/// - build(sessionID): 通过 REST GET /session/{id}/todo 初始化加载
/// - updateTodos(todos): 由 SSE todo.updated 事件调用，全量替换列表
///
/// 使用 keepAlive: true，确保即使 TodoListWidget 未挂载（如切换路由），
/// SSE 通过 ref.read 写入的 updateTodos 数据不会因 provider 销毁而丢失。

final class SessionTodosNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          SessionTodosNotifier,
          AsyncValue<List<Todo>>,
          List<Todo>,
          FutureOr<List<Todo>>,
          String
        > {
  SessionTodosNotifierFamily._()
    : super(
        retry: null,
        name: r'sessionTodosProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// 按 sessionID 管理 todo 列表的 family provider。
  ///
  /// - build(sessionID): 通过 REST GET /session/{id}/todo 初始化加载
  /// - updateTodos(todos): 由 SSE todo.updated 事件调用，全量替换列表
  ///
  /// 使用 keepAlive: true，确保即使 TodoListWidget 未挂载（如切换路由），
  /// SSE 通过 ref.read 写入的 updateTodos 数据不会因 provider 销毁而丢失。

  SessionTodosNotifierProvider call(String sessionID) =>
      SessionTodosNotifierProvider._(argument: sessionID, from: this);

  @override
  String toString() => r'sessionTodosProvider';
}

/// 按 sessionID 管理 todo 列表的 family provider。
///
/// - build(sessionID): 通过 REST GET /session/{id}/todo 初始化加载
/// - updateTodos(todos): 由 SSE todo.updated 事件调用，全量替换列表
///
/// 使用 keepAlive: true，确保即使 TodoListWidget 未挂载（如切换路由），
/// SSE 通过 ref.read 写入的 updateTodos 数据不会因 provider 销毁而丢失。

abstract class _$SessionTodosNotifier extends $AsyncNotifier<List<Todo>> {
  late final _$args = ref.$arg as String;
  String get sessionID => _$args;

  FutureOr<List<Todo>> build(String sessionID);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Todo>>, List<Todo>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Todo>>, List<Todo>>,
              AsyncValue<List<Todo>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
