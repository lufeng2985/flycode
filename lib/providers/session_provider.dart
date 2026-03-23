import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../service/api/models/message.dart' hide FileDiff;
import '../service/api/models/parts.dart';
import '../service/api/models/session.dart';
import '../service/api/session_api.dart';
import 'project_provider.dart';

part 'session_provider.g.dart';

/// 当前选中会话的状态：
/// - session=null, isPending=false → 未选中任何会话
/// - session=null, isPending=true  → 用户点了"新建会话"，等待首次发送消息时再创建
/// - session!=null, isPending=false → 已选中一个真实会话
typedef SelectedSessionState = ({Session? session, bool isPending});

@riverpod
class SelectedSessionNotifier extends _$SelectedSessionNotifier {
  @override
  SelectedSessionState build() {
    ref.listen(selectedProjectProvider, (previous, next) {
      final prevProject = previous?.asData?.value;
      final nextProject = next.asData?.value;
      final changed = prevProject?.id != nextProject?.id;
      if (!changed) return;

      // 项目切换后清空当前会话，由用户在会话页主动选择。
      state = (session: null, isPending: false);
    });

    ref.listen(sessionsProvider, (previous, next) {
      next.whenData((sessions) {
        final current = state;

        // 用户手动进入“新建会话”态时，不自动变更选择。
        if (current.isPending) return;

        final selected = current.session;
        if (selected == null) return;

        if (sessions.isEmpty) {
          state = (session: null, isPending: false);
          return;
        }

        final stillExists = sessions.any((s) => s.id == selected.id);
        if (!stillExists) {
          state = (session: null, isPending: false);
        }
      });
    }, fireImmediately: true);

    return (session: null, isPending: false);
  }

  void select(Session? session) {
    state = (session: session, isPending: false);
  }

  void startNew() {
    state = (session: null, isPending: true);
  }
}

@riverpod
class SessionMessagesNotifier extends _$SessionMessagesNotifier {
  @override
  Future<List<MessageWithParts>> build() async {
    final selectedState = ref.watch(selectedSessionProvider);
    final session = selectedState.session;
    if (session == null) return [];

    final api = await ref.watch(sessionApiProvider.future);
    return api.getSessionMessages(session.id);
  }

  /// SSE: message.updated — 新增或更新一条消息（保留已有 parts）
  void updateMessage(String sessionID, MessageWithParts message) {
    final session = ref.read(selectedSessionProvider).session;
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
    final session = ref.read(selectedSessionProvider).session;
    if (session == null || session.id != sessionID) return;

    final current = state.asData?.value ?? [];
    final updated = current.where((m) => _messageId(m) != messageID).toList();
    state = AsyncData(updated);
  }

  /// SSE: message.part.updated — 新增或更新某条消息的一个 part
  void updatePart(String sessionID, String messageID, Object newPart) {
    final session = ref.read(selectedSessionProvider).session;
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
    final session = ref.read(selectedSessionProvider).session;
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
}
