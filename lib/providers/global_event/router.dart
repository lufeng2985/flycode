import '../../service/api/models/global_event.dart';

enum GlobalEventRouteTarget {
  session,
  message,
  question,
  permission,
  todo,
  unread,
  notification,
  status,
}

bool shouldDispatchGlobalEventForDirectory(
  GlobalEvent event, {
  required String? currentDirectory,
}) {
  if (currentDirectory == null || currentDirectory.isEmpty) {
    return true;
  }

  return event.directory.isEmpty || event.directory == currentDirectory;
}

List<GlobalEventRouteTarget> routeGlobalEventPayload(Object payload) {
  if (payload is EventSessionCreated ||
      payload is EventSessionUpdated ||
      payload is EventSessionDeleted) {
    return const <GlobalEventRouteTarget>[GlobalEventRouteTarget.session];
  }

  if (payload is EventMessageUpdated ||
      payload is EventMessageRemoved ||
      payload is EventMessagePartUpdated ||
      payload is EventMessagePartDelta ||
      payload is EventMessagePartRemoved) {
    return const <GlobalEventRouteTarget>[GlobalEventRouteTarget.message];
  }

  if (payload is EventQuestionAsked ||
      payload is EventQuestionReplied ||
      payload is EventQuestionRejected) {
    return const <GlobalEventRouteTarget>[GlobalEventRouteTarget.question];
  }

  if (payload is EventPermissionAsked || payload is EventPermissionReplied) {
    return const <GlobalEventRouteTarget>[GlobalEventRouteTarget.permission];
  }

  if (payload is EventTodoUpdated) {
    return const <GlobalEventRouteTarget>[GlobalEventRouteTarget.todo];
  }

  if (payload is EventSessionStatus) {
    return const <GlobalEventRouteTarget>[GlobalEventRouteTarget.status];
  }

  if (payload is EventSessionIdle) {
    return const <GlobalEventRouteTarget>[
      GlobalEventRouteTarget.unread,
      GlobalEventRouteTarget.notification,
    ];
  }

  if (payload is EventSessionError) {
    return const <GlobalEventRouteTarget>[GlobalEventRouteTarget.unread];
  }

  return const <GlobalEventRouteTarget>[];
}
