import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../service/api/models/message.dart';
import '../service/api/models/parts.dart';
import '../service/api/models/session.dart';
import '../service/api/session_api.dart';

part 'session_provider.g.dart';

@riverpod
class SelectedSessionNotifier extends _$SelectedSessionNotifier {
  @override
  Session? build() => null;

  void select(Session? session) {
    state = session;
  }
}

@riverpod
class SessionMessagesNotifier extends _$SessionMessagesNotifier {
  @override
  Future<List<MessageWithParts>> build() async {
    final session = ref.watch(selectedSessionProvider);
    if (session == null) return [];

    final api = ref.watch(sessionApiProvider);
    return api.getSessionMessages(session.id);
  }

  /// SSE: message.updated — 新增或更新一条消息（保留已有 parts）
  void updateMessage(String sessionID, MessageWithParts message) {
    final session = ref.read(selectedSessionProvider);
    if (session == null || session.id != sessionID) return;

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
    final session = ref.read(selectedSessionProvider);
    if (session == null || session.id != sessionID) return;

    final current = state.asData?.value ?? [];
    final updated = current.where((m) => _messageId(m) != messageID).toList();
    state = AsyncData(updated);
  }

  /// SSE: message.part.updated — 新增或更新某条消息的一个 part
  void updatePart(String sessionID, String messageID, Object newPart) {
    final session = ref.read(selectedSessionProvider);
    if (session == null || session.id != sessionID) return;

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
    final session = ref.read(selectedSessionProvider);
    if (session == null || session.id != sessionID) return;

    final current = state.asData?.value ?? [];
    final msgIndex = current.indexWhere((m) => _messageId(m) == messageID);
    if (msgIndex < 0) return;

    final msg = current[msgIndex];
    final newParts = msg.parts.where((p) => _partId(p) != partID).toList();

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
