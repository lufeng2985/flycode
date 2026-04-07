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
    final messages = await api.getSessionMessages(sessionID);
    return _normalizeMessages(messages);
  }

  /// SSE: message.updated — 新增或更新一条消息（保留已有 parts）
  void updateMessage(String sessionID, MessageWithParts message) {
    if (this.sessionID != sessionID) return;

    final current = state.asData?.value ?? [];
    state = AsyncData(_upsertMessage(current, message));
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
    updated[msgIndex] = _messageWithNormalizedParts(msg.info, newParts);
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
    updated[msgIndex] = _messageWithNormalizedParts(msg.info, newParts);
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
    updated[msgIndex] = _messageWithNormalizedParts(msg.info, newParts);
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
  return switch (part) {
    TextPart value => value.id,
    FilePart value => value.id,
    ToolPart value => value.id,
    ReasoningPart value => value.id,
    StepStartPart value => value.id,
    StepFinishPart value => value.id,
    SnapshotPart value => value.id,
    PatchPart value => value.id,
    AgentPart value => value.id,
    RetryPart value => value.id,
    CompactionPart value => value.id,
    SubtaskPart value => value.id,
    _ => null,
  };
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
    final messages = await api.getSessionMessages(sessionID);
    return _normalizeMessages(messages);
  }

  void updateMessage(String msgSessionID, MessageWithParts message) {
    if (msgSessionID != sessionID) return;
    final current = state.asData?.value ?? [];
    state = AsyncData(_upsertMessage(current, message));
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
    updated[msgIndex] = _messageWithNormalizedParts(msg.info, newParts);
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
    updated[msgIndex] = _messageWithNormalizedParts(msg.info, newParts);
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
    updated[msgIndex] = _messageWithNormalizedParts(msg.info, newParts);
    state = AsyncData(updated);
  }
}

List<MessageWithParts> _upsertMessage(
  List<MessageWithParts> current,
  MessageWithParts incoming,
) {
  final index = current.indexWhere(
    (m) => _messageId(m) == _messageId(incoming),
  );
  final updated = List<MessageWithParts>.from(current);
  if (index >= 0) {
    updated[index] = _mergeMessagePreservingParts(updated[index], incoming);
  } else {
    updated.add(_messageWithNormalizedParts(incoming.info, incoming.parts));
  }
  return updated;
}

MessageWithParts _mergeMessagePreservingParts(
  MessageWithParts current,
  MessageWithParts incoming,
) {
  if (incoming.parts.isNotEmpty) {
    return _messageWithNormalizedParts(incoming.info, incoming.parts);
  }
  return _messageWithNormalizedParts(incoming.info, current.parts);
}

List<MessageWithParts> _normalizeMessages(List<MessageWithParts> messages) {
  return messages
      .map(
        (message) => _messageWithNormalizedParts(message.info, message.parts),
      )
      .toList();
}

MessageWithParts _messageWithNormalizedParts(Object info, List<Object> parts) {
  return MessageWithParts(info: info, parts: _normalizeParts(parts));
}

List<Object> _normalizeParts(List<Object> parts) {
  final normalized = List<Object>.from(parts);
  final seenByPartId = <String, int>{};

  for (var i = 0; i < normalized.length; i++) {
    final partId = _partId(normalized[i]);
    if (partId == null) continue;

    final existingIndex = seenByPartId[partId];
    if (existingIndex == null) {
      seenByPartId[partId] = i;
      continue;
    }

    normalized[existingIndex] = normalized[i];
    normalized.removeAt(i);
    i -= 1;
  }

  return normalized;
}
