import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../service/api/models/message.dart' hide FileDiff;
import '../service/api/models/parts.dart';
import '../service/api/session_api.dart';
import '../service/api/models/session.dart';

part 'session_provider.g.dart';

@riverpod
class SessionMessagesNotifier extends _$SessionMessagesNotifier {
  @override
  Future<List<MessageWithParts>> build(String sessionID) async {
    final api = await ref.watch(sessionApiProvider.future);
    return api.getSessionMessages(sessionID);
  }

  /// SSE: message.updated — 新增或更新一条消息（保留已有 parts）
  void updateMessage(String sessionID, MessageWithParts message) {
    if (this.sessionID != sessionID) return;

    final current = state.asData?.value ?? [];
    final index = current.indexWhere(
      (m) => _messageId(m) == _messageId(message),
    );

    final updated = List<MessageWithParts>.from(current);
    if (index >= 0) {
      updated[index] = message;
    } else {
      updated.add(message);
    }
    state = AsyncData(updated);
  }

  /// SSE: message.removed — 删除一条消息
  void removeMessage(String sessionID, String messageID) {
    if (this.sessionID != sessionID) return;

    final current = state.asData?.value ?? [];
    final updated = current.where((m) => _messageId(m) != messageID).toList();
    state = AsyncData(updated);
  }

  /// SSE: message.part.updated — 新增或更新某条消息的一个 part
  void updatePart(String sessionID, String messageID, Object newPart) {
    if (this.sessionID != sessionID) return;

    final current = state.asData?.value ?? [];
    final msgIndex = current.indexWhere((m) => _messageId(m) == messageID);
    if (msgIndex < 0) return;

    final msg = current[msgIndex];
    final existingIndex = msg.parts.indexWhere(
      (p) => _partId(p) == _partId(newPart),
    );

    final newParts = List<Object>.from(msg.parts);
    if (existingIndex >= 0) {
      newParts[existingIndex] = newPart;
    } else {
      newParts.add(newPart);
    }

    final updated = List<MessageWithParts>.from(current);
    updated[msgIndex] = MessageWithParts(info: msg.info, parts: newParts);
    state = AsyncData(updated);
  }

  /// SSE: message.part.removed — 删除某条消息的一个 part
  void removePart(String sessionID, String messageID, String partID) {
    if (this.sessionID != sessionID) return;

    final current = state.asData?.value ?? [];
    final msgIndex = current.indexWhere((m) => _messageId(m) == messageID);
    if (msgIndex < 0) return;

    final msg = current[msgIndex];
    final newParts = msg.parts.where((p) => _partId(p) != partID).toList();

    final updated = List<MessageWithParts>.from(current);
    updated[msgIndex] = MessageWithParts(info: msg.info, parts: newParts);
    state = AsyncData(updated);
  }

  /// SSE: message.part.delta — 增量追加某个 part 的文本内容
  void appendPartDelta(
    String sessionID,
    String messageID,
    String partID,
    String field,
    String delta,
  ) {
    if (this.sessionID != sessionID) return;
    if (field != 'text' || delta.isEmpty) return;

    final current = state.asData?.value ?? [];
    final msgIndex = current.indexWhere((m) => _messageId(m) == messageID);
    if (msgIndex < 0) return;

    final msg = current[msgIndex];
    final partIndex = msg.parts.indexWhere((p) => _partId(p) == partID);

    final newParts = List<Object>.from(msg.parts);
    if (partIndex >= 0) {
      final part = msg.parts[partIndex];
      if (part is! TextPart) return;
      newParts[partIndex] = TextPart(
        id: part.id,
        sessionID: part.sessionID,
        messageID: part.messageID,
        type: part.type,
        text: '${part.text}$delta',
        synthetic: part.synthetic,
        ignored: part.ignored,
        time: part.time,
        metadata: part.metadata,
      );
    } else {
      newParts.add(
        TextPart(
          id: partID,
          sessionID: sessionID,
          messageID: messageID,
          type: 'text',
          text: delta,
        ),
      );
    }

    final updated = List<MessageWithParts>.from(current);
    updated[msgIndex] = MessageWithParts(info: msg.info, parts: newParts);
    state = AsyncData(updated);
  }
}

String _messageId(MessageWithParts m) {
  final info = m.info;
  if (info is UserMessage) return info.id;
  if (info is AssistantMessage) return info.id;
  return '';
}

String? _partId(Object part) {
  if (part is ToolPart) return part.id;
  if (part is TextPart) return part.id;
  return null;
}

@riverpod
Future<List<FileDiff>> sessionDiff(Ref ref, String sessionID) async {
  final api = await ref.watch(sessionApiProvider.future);
  return api.getSessionDiff(sessionID);
}

/// 子 Session 消息列表（只读，支持 SSE 实时更新）
@riverpod
class SubSessionMessagesNotifier extends _$SubSessionMessagesNotifier {
  @override
  Future<List<MessageWithParts>> build(String sessionID) async {
    final api = await ref.watch(sessionApiProvider.future);
    return api.getSessionMessages(sessionID);
  }

  void updateMessage(String msgSessionID, MessageWithParts message) {
    if (msgSessionID != sessionID) return;
    final current = state.asData?.value ?? [];
    final index = current.indexWhere(
      (m) => _messageId(m) == _messageId(message),
    );
    final updated = List<MessageWithParts>.from(current);
    if (index >= 0) {
      updated[index] = message;
    } else {
      updated.add(message);
    }
    state = AsyncData(updated);
  }

  void removeMessage(String msgSessionID, String messageID) {
    if (msgSessionID != sessionID) return;
    final current = state.asData?.value ?? [];
    final updated = current.where((m) => _messageId(m) != messageID).toList();
    state = AsyncData(updated);
  }

  void updatePart(String msgSessionID, String messageID, Object newPart) {
    if (msgSessionID != sessionID) return;
    final current = state.asData?.value ?? [];
    final msgIndex = current.indexWhere((m) => _messageId(m) == messageID);
    if (msgIndex < 0) return;

    final msg = current[msgIndex];
    final existingIndex = msg.parts.indexWhere(
      (p) => _partId(p) == _partId(newPart),
    );
    final newParts = List<Object>.from(msg.parts);
    if (existingIndex >= 0) {
      newParts[existingIndex] = newPart;
    } else {
      newParts.add(newPart);
    }
    final updated = List<MessageWithParts>.from(current);
    updated[msgIndex] = MessageWithParts(info: msg.info, parts: newParts);
    state = AsyncData(updated);
  }

  void removePart(String msgSessionID, String messageID, String partID) {
    if (msgSessionID != sessionID) return;
    final current = state.asData?.value ?? [];
    final msgIndex = current.indexWhere((m) => _messageId(m) == messageID);
    if (msgIndex < 0) return;

    final msg = current[msgIndex];
    final newParts = msg.parts.where((p) => _partId(p) != partID).toList();
    final updated = List<MessageWithParts>.from(current);
    updated[msgIndex] = MessageWithParts(info: msg.info, parts: newParts);
    state = AsyncData(updated);
  }

  void appendPartDelta(
    String msgSessionID,
    String messageID,
    String partID,
    String field,
    String delta,
  ) {
    if (msgSessionID != sessionID) return;
    if (field != 'text' || delta.isEmpty) return;

    final current = state.asData?.value ?? [];
    final msgIndex = current.indexWhere((m) => _messageId(m) == messageID);
    if (msgIndex < 0) return;

    final msg = current[msgIndex];
    final partIndex = msg.parts.indexWhere((p) => _partId(p) == partID);
    final newParts = List<Object>.from(msg.parts);
    if (partIndex >= 0) {
      final part = msg.parts[partIndex];
      if (part is! TextPart) return;
      newParts[partIndex] = TextPart(
        id: part.id,
        sessionID: part.sessionID,
        messageID: part.messageID,
        type: part.type,
        text: '${part.text}$delta',
        synthetic: part.synthetic,
        ignored: part.ignored,
        time: part.time,
        metadata: part.metadata,
      );
    } else {
      newParts.add(
        TextPart(
          id: partID,
          sessionID: msgSessionID,
          messageID: messageID,
          type: 'text',
          text: delta,
        ),
      );
    }

    final updated = List<MessageWithParts>.from(current);
    updated[msgIndex] = MessageWithParts(info: msg.info, parts: newParts);
    state = AsyncData(updated);
  }
}
