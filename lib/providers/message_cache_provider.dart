import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../service/api/models/message.dart';

part 'message_cache_provider.g.dart';

@riverpod
class MessageCache extends _$MessageCache {
  @override
  Map<String, List<MessageWithParts>> build() => {};

  void updateMessage(String sessionID, MessageWithParts message) {
    final list = List<MessageWithParts>.from(state[sessionID] ?? []);
    final index = list.indexWhere((m) {
      final currentId = m.info is UserMessage
          ? (m.info as UserMessage).id
          : (m.info as AssistantMessage).id;
      final newId = message.info is UserMessage
          ? (message.info as UserMessage).id
          : (message.info as AssistantMessage).id;
      return currentId == newId;
    });

    if (index >= 0) {
      list[index] = message;
    } else {
      list.add(message);
    }

    state = {...state, sessionID: list};
  }

  void removeMessage(String sessionID, String messageID) {
    final list = List<MessageWithParts>.from(state[sessionID] ?? []);
    list.removeWhere((m) {
      final id = m.info is UserMessage
          ? (m.info as UserMessage).id
          : (m.info as AssistantMessage).id;
      return id == messageID;
    });
    state = {...state, sessionID: list};
  }

  void clearSession(String sessionID) {
    final newState = Map<String, List<MessageWithParts>>.from(state);
    newState.remove(sessionID);
    state = newState;
  }

  void clearAll() {
    state = {};
  }
}
