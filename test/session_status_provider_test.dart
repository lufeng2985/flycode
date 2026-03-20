import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flycode/providers/project_provider.dart';
import 'package:flycode/providers/session_status_provider.dart';
import 'package:flycode/service/api/api_client.dart';
import 'package:flycode/service/api/models/project.dart';
import 'package:flycode/service/api/models/session_status.dart';
import 'package:flycode/service/api/session_api.dart';

class _FakeSelectedProjectNotifier extends SelectedProjectNotifier {
  @override
  Future<Project?> build() async {
    return Project.fromDirectory('/tmp/worktree');
  }
}

class _FakeSessionApi extends SessionApi {
  _FakeSessionApi(this.snapshot)
    : super(ApiClient(baseUrl: 'http://localhost'));

  Map<String, dynamic> snapshot;
  String? lastDirectory;

  @override
  Future<Map<String, dynamic>> getSessionStatus({String? directory}) async {
    lastDirectory = directory;
    return snapshot;
  }
}

void main() {
  test('refreshFromServer clears stale busy state from snapshot', () async {
    final fakeApi = _FakeSessionApi(<String, dynamic>{});
    final container = ProviderContainer(
      overrides: [
        selectedProjectProvider.overrideWith(_FakeSelectedProjectNotifier.new),
        sessionApiProvider.overrideWith((ref) async => fakeApi),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(sessionStatusProvider.notifier);
    notifier.updateStatus('sess-1', const SessionStatusBusy());

    expect(container.read(sessionStatusProvider).containsKey('sess-1'), isTrue);

    await notifier.refreshFromServer();

    expect(container.read(sessionStatusProvider), isEmpty);
    expect(fakeApi.lastDirectory, '/tmp/worktree');
  });

  test('refreshFromServer parses mixed snapshot shapes', () async {
    final fakeApi = _FakeSessionApi({
      'sessions': {
        'sess-busy': {'type': 'busy'},
        'sess-idle': {'type': 'idle'},
      },
      'items': [
        {
          'sessionID': 'sess-retry',
          'status': {'type': 'retry', 'attempt': 2, 'message': 'x', 'next': 1},
        },
      ],
    });

    final container = ProviderContainer(
      overrides: [
        selectedProjectProvider.overrideWith(_FakeSelectedProjectNotifier.new),
        sessionApiProvider.overrideWith((ref) async => fakeApi),
      ],
    );
    addTearDown(container.dispose);

    await container.read(sessionStatusProvider.notifier).refreshFromServer();
    final state = container.read(sessionStatusProvider);

    expect(state.keys, contains('sess-busy'));
    expect(state.keys, contains('sess-retry'));
    expect(state.keys, isNot(contains('sess-idle')));
  });
}
