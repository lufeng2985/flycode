import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../service/api/global_api.dart';
import '../service/api/models/global_event.dart';
import '../service/api/models/message.dart';
import '../service/api/models/parts.dart';
import '../service/api/session_api.dart';
import 'question_provider.dart';
import 'session_provider.dart';
import 'session_status_provider.dart';

part 'global_event_provider.g.dart';

@riverpod
class GlobalEventListener extends _$GlobalEventListener {
  @override
  Stream<GlobalEvent> build() async* {
    final api = await ref.watch(globalApiProvider.future);

    // 用 listenSelf 监听自身 stream state 来处理副作用，避免直接 stream.listen() 导致双重订阅
    listenSelf((_, next) {
      next.whenData(_handleEvent);
    });

    yield* api.subscribeToGlobalEvents();
  }

  void _handleEvent(GlobalEvent event) {
    final payload = event.payload;

    if (payload is EventSessionCreated ||
        payload is EventSessionUpdated ||
        payload is EventSessionDeleted) {
      ref.invalidate(sessionsProvider);
      return;
    }

    if (payload is EventMessageUpdated) {
      _handleMessageUpdated(payload);
    } else if (payload is EventMessageRemoved) {
      _handleMessageRemoved(payload);
    } else if (payload is EventMessagePartUpdated) {
      _handleMessagePartUpdated(payload);
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
    }
    // EventUnknown and other unhandled payloads are intentionally ignored.
  }

  void _handleMessageUpdated(EventMessageUpdated event) {
    final info = event.info;
    final String sessionID;
    final String messageID;

    if (info is UserMessage) {
      sessionID = info.sessionID;
      messageID = info.id;
    } else if (info is AssistantMessage) {
      sessionID = info.sessionID;
      messageID = info.id;
    } else {
      return;
    }

    // 保留已有的 parts，只更新消息 info
    final current = ref.read(sessionMessagesProvider).asData?.value ?? [];
    final existing = current.firstWhere(
      (m) => _messageId(m) == messageID,
      orElse: () => MessageWithParts(info: info, parts: []),
    );
    final message = MessageWithParts(info: info, parts: existing.parts);

    ref
        .read(sessionMessagesProvider.notifier)
        .updateMessage(sessionID, message);
  }

  void _handleMessageRemoved(EventMessageRemoved event) {
    ref
        .read(sessionMessagesProvider.notifier)
        .removeMessage(event.sessionID, event.messageID);
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
        .read(sessionMessagesProvider.notifier)
        .updatePart(sessionID, partMsgId, newPart);
  }

  void _handleMessagePartRemoved(EventMessagePartRemoved event) {
    ref
        .read(sessionMessagesProvider.notifier)
        .removePart(event.sessionID, event.messageID, event.partID);
  }
}

String _messageId(MessageWithParts m) {
  final info = m.info;
  if (info is UserMessage) return info.id;
  if (info is AssistantMessage) return info.id;
  return '';
}
