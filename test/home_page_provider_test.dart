import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flycode/models/chat_route_args.dart';
import 'package:flycode/providers/chat_view_state_provider.dart';
import 'package:flycode/providers/current_directory_provider.dart';
import 'package:flycode/providers/home_page_provider.dart';
import 'package:flycode/service/api/api_client.dart';
import 'package:flycode/service/api/models/permission.dart';
import 'package:flycode/service/api/models/question.dart';
import 'package:flycode/service/api/models/session.dart';
import 'package:flycode/service/api/session_api.dart';

class _FakeSessionApi extends SessionApi {
  _FakeSessionApi({required this.sessions, this.error})
    : super(ApiClient(baseUrl: 'http://localhost'));

  final List<Session> sessions;
  final Object? error;
  int getSessionsCallCount = 0;
  String? lastDirectory;
  bool? lastRoots;

  @override
  Future<List<Session>> getSessions({
    String? directory,
    bool? roots,
    int? start,
    String? search,
    int? limit,
  }) async {
    getSessionsCallCount += 1;
    lastDirectory = directory;
    lastRoots = roots;
    if (error != null) {
      throw error!;
    }
    return List<Session>.from(sessions);
  }
}

Session _session({
  required String id,
  required int updatedAt,
  String? parentId,
}) {
  return Session(
    id: id,
    slug: id,
    projectID: 'project-1',
    directory: '/tmp/project',
    parentID: parentId,
    version: '1',
    time: SessionTime(created: updatedAt - 1000, updated: updatedAt),
  );
}

QuestionRequest _question({String sessionId = 'session-1'}) {
  return QuestionRequest.fromJson({
    'id': 'question-1',
    'sessionID': sessionId,
    'questions': [
      {
        'header': 'Confirm',
        'question': 'Continue?',
        'options': [
          {'label': 'Yes', 'description': 'Continue'},
        ],
      },
    ],
  });
}

PermissionRequest _permission({String sessionId = 'session-1'}) {
  return PermissionRequest(
    id: 'permission-1',
    sessionID: sessionId,
    permission: 'write',
    patterns: const ['*.dart'],
    always: const [],
  );
}

void main() {
  group('HomePageBootstrapController', () {
    test('selects requested initial session when present', () async {
      final api = _FakeSessionApi(
        sessions: [
          _session(id: 'session-1', updatedAt: 10),
          _session(id: 'session-2', updatedAt: 20),
        ],
      );
      final container = ProviderContainer(
        overrides: [sessionApiProvider.overrideWith((ref) async => api)],
      );
      addTearDown(container.dispose);

      await container
          .read(homePageBootstrapControllerProvider.notifier)
          .bootstrap(
            const ChatRouteArgs(
              directory: '/tmp/project',
              initialSessionId: 'session-1',
            ),
          );

      expect(container.read(currentDirectoryProvider), '/tmp/project');
      expect(container.read(chatViewStateProvider), (
        sessionId: 'session-1',
        isPending: false,
      ));
      expect(api.getSessionsCallCount, 1);
      expect(api.lastDirectory, '/tmp/project');
      expect(api.lastRoots, isTrue);
    });

    test(
      'falls back to newest session and deduplicates repeated bootstrap',
      () async {
        final api = _FakeSessionApi(
          sessions: [
            _session(id: 'older', updatedAt: 10),
            _session(id: 'newer', updatedAt: 20),
          ],
        );
        final container = ProviderContainer(
          overrides: [sessionApiProvider.overrideWith((ref) async => api)],
        );
        addTearDown(container.dispose);
        final notifier = container.read(
          homePageBootstrapControllerProvider.notifier,
        );
        const args = ChatRouteArgs(directory: '/tmp/project');

        await notifier.bootstrap(args);
        await notifier.bootstrap(args);

        expect(container.read(chatViewStateProvider), (
          sessionId: 'newer',
          isPending: false,
        ));
        expect(api.getSessionsCallCount, 1);
      },
    );

    test('starts a new session when session load fails', () async {
      final api = _FakeSessionApi(
        sessions: const [],
        error: Exception('network down'),
      );
      final container = ProviderContainer(
        overrides: [sessionApiProvider.overrideWith((ref) async => api)],
      );
      addTearDown(container.dispose);

      await container
          .read(homePageBootstrapControllerProvider.notifier)
          .bootstrap(const ChatRouteArgs(directory: '/tmp/project'));

      expect(container.read(chatViewStateProvider), (
        sessionId: null,
        isPending: true,
      ));
    });
  });

  group('buildHomePagePresentationState', () {
    test(
      'suppresses input when the selected session is blocked by permission',
      () {
        final state = buildHomePagePresentationState(
          sessionsAsync: AsyncData([_session(id: 'session-1', updatedAt: 10)]),
          chatState: (sessionId: 'session-1', isPending: false),
          permissionRequest: _permission(),
          questionRequest: null,
        );

        expect(state.bodyMode, HomePageBodyMode.messageList);
        expect(state.showChatInput, isFalse);
        expect(state.showQuestionOverlay, isFalse);
        expect(state.canShowCommandPanel, isFalse);
        expect(state.permissionRequest?.id, 'permission-1');
      },
    );

    test(
      'shows question overlay and hides input when a question is pending',
      () {
        final state = buildHomePagePresentationState(
          sessionsAsync: AsyncData([_session(id: 'session-1', updatedAt: 10)]),
          chatState: (sessionId: 'session-1', isPending: false),
          permissionRequest: null,
          questionRequest: _question(),
        );

        expect(state.bodyMode, HomePageBodyMode.messageList);
        expect(state.showQuestionOverlay, isTrue);
        expect(state.showChatInput, isFalse);
        expect(state.questionRequest?.id, 'question-1');
      },
    );

    test('shows empty selection state when no session is active', () {
      final state = buildHomePagePresentationState(
        sessionsAsync: const AsyncData(<Session>[]),
        chatState: (sessionId: null, isPending: false),
        permissionRequest: null,
        questionRequest: null,
      );

      expect(state.bodyMode, HomePageBodyMode.sessionSelection);
      expect(state.hasAnySessions, isFalse);
      expect(state.showChatInput, isFalse);
    });
  });
}
