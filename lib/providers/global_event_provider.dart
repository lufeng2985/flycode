import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../service/api/global_api.dart';
import '../service/api/models/global_event.dart';
import '../service/api/models/message.dart';
import '../service/api/models/parts.dart';
import '../service/api/session_api.dart';
import 'message_cache_provider.dart';

part 'global_event_provider.g.dart';

@riverpod
class GlobalEventListener extends _$GlobalEventListener {
  @override
  Stream<GlobalEvent> build() {
    final api = ref.watch(globalApiProvider);
    final stream = api.subscribeToGlobalEvents();

    stream.listen((event) {
      _handleEvent(event);
    });

    return stream;
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
    }
  }

  void _handleMessageUpdated(EventMessageUpdated event) {
    // event.info is UserMessage | AssistantMessage (not MessageWithParts)
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

    // Preserve existing parts if the message already exists in cache
    final currentCache = ref.read(messageCacheProvider);
    final existing = currentCache[sessionID]?.where((m) {
      final id = m.info is UserMessage
          ? (m.info as UserMessage).id
          : (m.info as AssistantMessage).id;
      return id == messageID;
    }).firstOrNull;

    final message = MessageWithParts(info: info, parts: existing?.parts ?? []);

    ref.read(messageCacheProvider.notifier).updateMessage(sessionID, message);
  }

  void _handleMessageRemoved(EventMessageRemoved event) {
    final currentCache = ref.read(messageCacheProvider);
    final list = currentCache[event.sessionID];

    if (list != null) {
      ref
          .read(messageCacheProvider.notifier)
          .removeMessage(event.sessionID, event.messageID);
    }

    _scheduleRefresh();
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

    if (partMsgId == null) {
      _scheduleRefresh();
      return;
    }

    final currentCache = ref.read(messageCacheProvider);
    final list = currentCache[sessionID];

    if (list != null) {
      final targetIndex = list.indexWhere((m) {
        final msgId = m.info is UserMessage
            ? (m.info as UserMessage).id
            : (m.info as AssistantMessage).id;
        return msgId == partMsgId;
      });

      if (targetIndex >= 0) {
        final m = list[targetIndex];
        final existingIndex = m.parts.indexWhere((p) {
          if (p is ToolPart && newPart is ToolPart) {
            return p.id == newPart.id;
          }
          if (p is TextPart && newPart is TextPart) {
            return p.id == newPart.id;
          }
          return false;
        });

        final newParts = List<Object>.from(m.parts);
        if (existingIndex >= 0) {
          newParts[existingIndex] = newPart;
        } else {
          newParts.add(newPart);
        }

        ref
            .read(messageCacheProvider.notifier)
            .updateMessage(
              sessionID,
              MessageWithParts(info: m.info, parts: newParts),
            );
      }
    }

    _scheduleRefresh();
  }

  void _handleMessagePartRemoved(EventMessagePartRemoved event) {
    final currentCache = ref.read(messageCacheProvider);
    final list = currentCache[event.sessionID];
    if (list == null) return;

    final targetIndex = list.indexWhere((m) {
      final msgId = m.info is UserMessage
          ? (m.info as UserMessage).id
          : (m.info as AssistantMessage).id;
      return msgId == event.messageID;
    });

    if (targetIndex >= 0) {
      final m = list[targetIndex];
      final newParts = m.parts.where((p) {
        if (p is ToolPart) {
          return p.id != event.partID;
        }
        return true;
      }).toList();

      ref
          .read(messageCacheProvider.notifier)
          .updateMessage(
            event.sessionID,
            MessageWithParts(info: m.info, parts: newParts),
          );
    }

    _scheduleRefresh();
  }

  void _scheduleRefresh() {
    // sessionMessagesProvider watches messageCacheProvider and will
    // automatically rebuild when the cache is updated; no explicit
    // invalidation needed.
  }
}
