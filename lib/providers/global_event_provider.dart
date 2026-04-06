import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../service/api/global_api.dart';
import '../service/api/models/global_event.dart';
import '../service/api/models/message.dart';
import '../service/api/models/parts.dart';
import '../service/api/models/session.dart';
import '../service/notification/local_notification_service.dart';
import 'app_lifecycle_provider.dart';
import '../service/api/session_api.dart';
import 'session_completion_notification_provider.dart';
import 'question_provider.dart';
import 'permission_provider.dart';
import 'chat_view_state_provider.dart';
import 'current_directory_provider.dart';
import 'session_provider.dart';
import 'session_status_provider.dart';
import 'session_unread_provider.dart';
import 'todo_provider.dart';

part 'global_event_provider.g.dart';

bool shouldSendSessionCompletionNotification({
  required SessionCompletionNotificationMode mode,
  required AppLifecycleState lifecycleState,
}) {
  switch (mode) {
    case SessionCompletionNotificationMode.none:
      return false;
    case SessionCompletionNotificationMode.backgroundOnly:
      return !isAppInForeground(lifecycleState);
    case SessionCompletionNotificationMode.always:
      return true;
  }
}

@riverpod
class GlobalEventListener extends _$GlobalEventListener {
  @override
  Stream<GlobalEvent> build() async* {
    final api = await ref.watch(globalApiProvider.future);
    ref.read(sessionUnreadProvider);

    ref.listen<ChatViewState>(chatViewStateProvider, (previous, next) {
      final nextSessionID = next.sessionId;
      if (nextSessionID == null || nextSessionID == previous?.sessionId) {
        return;
      }
      unawaited(
        ref.read(sessionUnreadProvider.notifier).markViewed(nextSessionID),
      );
    });

    // Prime local status cache from snapshot so UI can recover if SSE dropped
    // previous status transitions (for example, busy -> idle).
    unawaited(ref.read(sessionStatusProvider.notifier).refreshFromServer());

    // 用 listenSelf 监听自身 stream state 来处理副作用，避免直接 stream.listen() 导致双重订阅
    listenSelf((_, next) {
      next.whenData(_handleEvent);
    });

    yield* api.subscribeToGlobalEvents();
  }

  void _handleEvent(GlobalEvent event) {
    final currentDirectory = ref.read(currentDirectoryProvider);
    if (currentDirectory != null &&
        currentDirectory.isNotEmpty &&
        event.directory.isNotEmpty &&
        event.directory != currentDirectory) {
      return;
    }

    final payload = event.payload;

    if (payload is EventSessionCreated ||
        payload is EventSessionUpdated ||
        payload is EventSessionDeleted) {
      ref.invalidate(sessionsProvider);
      ref.invalidate(allSessionsProvider);
      if (payload is EventSessionDeleted) {
        unawaited(
          ref
              .read(sessionUnreadProvider.notifier)
              .clearSession(payload.info.id),
        );
      }
      return;
    }

    if (payload is EventMessageUpdated) {
      _handleMessageUpdated(payload);
    } else if (payload is EventMessageRemoved) {
      _handleMessageRemoved(payload);
    } else if (payload is EventMessagePartUpdated) {
      _handleMessagePartUpdated(payload);
    } else if (payload is EventMessagePartDelta) {
      _handleMessagePartDelta(payload);
    } else if (payload is EventMessagePartRemoved) {
      _handleMessagePartRemoved(payload);
    } else if (payload is EventQuestionAsked) {
      ref
          .read(pendingQuestionsProvider.notifier)
          .addQuestion(payload.properties);
    } else if (payload is EventQuestionReplied) {
      ref
          .read(pendingQuestionsProvider.notifier)
          .removeQuestion(payload.requestID);
    } else if (payload is EventQuestionRejected) {
      ref
          .read(pendingQuestionsProvider.notifier)
          .removeQuestion(payload.requestID);
    } else if (payload is EventSessionStatus) {
      ref
          .read(sessionStatusProvider.notifier)
          .updateStatus(payload.sessionID, payload.status);
    } else if (payload is EventSessionIdle) {
      _markSessionUnread(payload.sessionID, isError: false);
      unawaited(_notifySessionCompleted(payload.sessionID));
    } else if (payload is EventSessionError) {
      final sessionID = payload.sessionID;
      if (sessionID == null || sessionID.isEmpty) return;
      _markSessionUnread(sessionID, isError: true);
    } else if (payload is EventPermissionAsked) {
      ref
          .read(pendingPermissionsProvider.notifier)
          .addPermission(payload.request);
    } else if (payload is EventPermissionReplied) {
      ref
          .read(pendingPermissionsProvider.notifier)
          .removePermission(payload.requestID);
    } else if (payload is EventTodoUpdated) {
      ref
          .read(sessionTodosProvider(payload.sessionID).notifier)
          .updateTodos(payload.todos);
    }
    // EventUnknown and other unhandled payloads are intentionally ignored.
  }

  void _markSessionUnread(String sessionID, {required bool isError}) {
    if (sessionID.isEmpty) return;
    final activeSessionID = ref.read(chatViewStateProvider).sessionId;
    if (activeSessionID == sessionID) {
      unawaited(ref.read(sessionUnreadProvider.notifier).markViewed(sessionID));
      return;
    }

    if (isError) {
      unawaited(ref.read(sessionUnreadProvider.notifier).addError(sessionID));
    } else {
      unawaited(
        ref.read(sessionUnreadProvider.notifier).addTurnComplete(sessionID),
      );
    }
  }

  Future<void> _notifySessionCompleted(String sessionID) async {
    if (sessionID.isEmpty) return;

    final mode = ref.read(sessionCompletionNotificationModeProvider);
    final lifecycleState = ref.read(appLifecycleStateProvider);
    final shouldSend = shouldSendSessionCompletionNotification(
      mode: mode,
      lifecycleState: lifecycleState,
    );
    if (!shouldSend) return;

    final session = await _sessionForNotification(sessionID);
    if (session == null || _isSubSession(session)) return;

    final sessionTitle = _normalizedSessionTitle(session.title);

    try {
      await ref
          .read(localNotificationServiceProvider)
          .showSessionCompleted(sessionTitle: sessionTitle);
    } catch (_) {
      // Ignore local notification failures to avoid affecting SSE handling.
    }
  }

  Future<Session?> _sessionForNotification(String sessionID) async {
    try {
      final api = await ref.read(sessionApiProvider.future);
      if (!ref.mounted) return null;
      final directory = ref.read(currentDirectoryProvider);
      if (!ref.mounted) return null;
      return await api.getSession(sessionID, directory: directory);
    } catch (_) {
      return null;
    }
  }

  bool _isSubSession(Session session) {
    final parentID = session.parentID;
    return parentID != null && parentID.isNotEmpty;
  }

  String? _normalizedSessionTitle(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  void _handleMessageUpdated(EventMessageUpdated event) {
    final info = event.info;
    final String sessionID;

    if (info is UserMessage) {
      sessionID = info.sessionID;
    } else if (info is AssistantMessage) {
      sessionID = info.sessionID;
    } else {
      return;
    }

    final message = MessageWithParts(info: info, parts: const []);

    ref
        .read(sessionMessagesProvider(sessionID).notifier)
        .updateMessage(sessionID, message);

    // 同时分发给子 Session provider（如果已订阅）
    _dispatchToSubSession(
      sessionID,
      (notifier) => notifier.updateMessage(sessionID, message),
    );
  }

  void _handleMessageRemoved(EventMessageRemoved event) {
    ref
        .read(sessionMessagesProvider(event.sessionID).notifier)
        .removeMessage(event.sessionID, event.messageID);

    _dispatchToSubSession(
      event.sessionID,
      (notifier) => notifier.removeMessage(event.sessionID, event.messageID),
    );
  }

  void _handleMessagePartUpdated(EventMessagePartUpdated event) {
    final newPart = event.part;
    final sessionID = newPart is ToolPart
        ? newPart.sessionID
        : (newPart is TextPart ? newPart.sessionID : null);
    if (sessionID == null) return;

    final partMsgId = newPart is ToolPart
        ? newPart.messageID
        : (newPart is TextPart ? newPart.messageID : null);
    if (partMsgId == null) return;

    ref
        .read(sessionMessagesProvider(sessionID).notifier)
        .updatePart(sessionID, partMsgId, newPart);

    _dispatchToSubSession(
      sessionID,
      (notifier) => notifier.updatePart(sessionID, partMsgId, newPart),
    );
  }

  void _handleMessagePartRemoved(EventMessagePartRemoved event) {
    ref
        .read(sessionMessagesProvider(event.sessionID).notifier)
        .removePart(event.sessionID, event.messageID, event.partID);

    _dispatchToSubSession(
      event.sessionID,
      (notifier) =>
          notifier.removePart(event.sessionID, event.messageID, event.partID),
    );
  }

  void _handleMessagePartDelta(EventMessagePartDelta event) {
    if (event.field != 'text' || event.delta.isEmpty) return;

    ref
        .read(sessionMessagesProvider(event.sessionID).notifier)
        .appendPartDelta(
          event.sessionID,
          event.messageID,
          event.partID,
          event.field,
          event.delta,
        );

    _dispatchToSubSession(
      event.sessionID,
      (notifier) => notifier.appendPartDelta(
        event.sessionID,
        event.messageID,
        event.partID,
        event.field,
        event.delta,
      ),
    );
  }

  /// 将消息事件分发给对应 sessionID 的子 Session provider（仅在已订阅时有效）
  void _dispatchToSubSession(
    String sessionID,
    void Function(SubSessionMessagesNotifier notifier) action,
  ) {
    try {
      final notifier = ref.read(subSessionMessagesProvider(sessionID).notifier);
      action(notifier);
    } catch (_) {
      // provider 未被订阅时 ref.read 会抛出，直接忽略
    }
  }
}
