import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../service/api/models/global_event.dart';
import '../current_directory_provider.dart';
import 'handlers.dart';
import 'router.dart';

final globalEventDispatcherProvider = Provider<GlobalEventDispatcher>((ref) {
  return GlobalEventDispatcher(ref);
});

class GlobalEventDispatcher {
  const GlobalEventDispatcher(this.ref);

  final Ref ref;

  void dispatch(GlobalEvent event) {
    final currentDirectory = ref.read(currentDirectoryProvider);
    if (!shouldDispatchGlobalEventForDirectory(
      event,
      currentDirectory: currentDirectory,
    )) {
      return;
    }

    for (final target in routeGlobalEventPayload(event.payload)) {
      _handlerFor(target).handle(event.payload);
    }
  }

  GlobalEventHandler _handlerFor(GlobalEventRouteTarget target) {
    return switch (target) {
      GlobalEventRouteTarget.session => ref.read(
        globalEventSessionHandlerProvider,
      ),
      GlobalEventRouteTarget.message => ref.read(
        globalEventMessageHandlerProvider,
      ),
      GlobalEventRouteTarget.question => ref.read(
        globalEventQuestionHandlerProvider,
      ),
      GlobalEventRouteTarget.permission => ref.read(
        globalEventPermissionHandlerProvider,
      ),
      GlobalEventRouteTarget.todo => ref.read(globalEventTodoHandlerProvider),
      GlobalEventRouteTarget.unread => ref.read(
        globalEventUnreadHandlerProvider,
      ),
      GlobalEventRouteTarget.notification => ref.read(
        globalEventNotificationHandlerProvider,
      ),
      GlobalEventRouteTarget.status => ref.read(
        globalEventStatusHandlerProvider,
      ),
    };
  }
}
