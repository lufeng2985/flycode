import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:flycode/service/api/api_client.dart';
import 'package:flycode/service/api/global_api.dart';
import 'package:flycode/service/api/models/global_event.dart';

class _FakeApiClient extends ApiClient {
  _FakeApiClient(Queue<Stream<String>> streams)
    : _streams = streams,
      super(baseUrl: 'http://localhost');

  final Queue<Stream<String>> _streams;
  int streamGetCount = 0;

  @override
  Stream<String> streamGet(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? extraHeaders,
  }) {
    streamGetCount += 1;
    if (_streams.isEmpty) {
      throw StateError('No SSE stream queued for $path');
    }
    return _streams.removeFirst();
  }
}

class _ControlledDelay {
  final List<Duration> durations = <Duration>[];
  final Queue<Completer<void>> _pending = Queue<Completer<void>>();

  Future<void> call(Duration duration) {
    durations.add(duration);
    final completer = Completer<void>();
    _pending.add(completer);
    return completer.future;
  }

  void completeNext() {
    if (_pending.isEmpty) {
      throw StateError('No pending reconnect delay');
    }
    _pending.removeFirst().complete();
  }
}

String _eventJson(String sessionID) {
  return jsonEncode(<String, dynamic>{
    'directory': '',
    'payload': <String, dynamic>{
      'type': 'session.idle',
      'properties': <String, dynamic>{'sessionID': sessionID},
    },
  });
}

Future<void> _flushAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  test('reconnects after server closes SSE stream', () async {
    final firstController = StreamController<String>();
    final secondController = StreamController<String>();
    final delay = _ControlledDelay();
    final api = GlobalApi(
      _FakeApiClient(
        Queue<Stream<String>>.from(<Stream<String>>[
          firstController.stream,
          secondController.stream,
        ]),
      ),
      reconnectDelay: delay.call,
    );
    final states = <GlobalEventConnectionState>[];
    final events = <GlobalEvent>[];

    final subscription = api
        .subscribeToGlobalEvents(onConnectionStateChanged: states.add)
        .listen(events.add);

    await _flushAsyncWork();
    expect(states.last.phase, GlobalEventConnectionPhase.connected);
    expect(states.last.attempt, 0);

    firstController.add(_eventJson('sess-1'));
    await _flushAsyncWork();

    expect(events, hasLength(1));
    expect(events.single.payload, isA<EventSessionIdle>());

    await firstController.close();
    await _flushAsyncWork();

    expect(states.last.phase, GlobalEventConnectionPhase.reconnecting);
    expect(states.last.attempt, 1);
    expect(delay.durations, <Duration>[const Duration(seconds: 1)]);

    delay.completeNext();
    await _flushAsyncWork();

    expect(states.last.phase, GlobalEventConnectionPhase.connected);
    expect(states.last.attempt, 0);

    secondController.add(_eventJson('sess-2'));
    await _flushAsyncWork();

    expect(events, hasLength(2));
    expect((events.last.payload as EventSessionIdle).sessionID, 'sess-2');

    await subscription.cancel();
    await secondController.close();
  });

  test('reconnects after stream error and exposes last error', () async {
    final secondController = StreamController<String>();
    final delay = _ControlledDelay();
    final api = GlobalApi(
      _FakeApiClient(
        Queue<Stream<String>>.from(<Stream<String>>[
          Stream<String>.error(StateError('network down')),
          secondController.stream,
        ]),
      ),
      reconnectDelay: delay.call,
    );
    final states = <GlobalEventConnectionState>[];

    final subscription = api
        .subscribeToGlobalEvents(onConnectionStateChanged: states.add)
        .listen((_) {});

    await _flushAsyncWork();

    expect(states.last.phase, GlobalEventConnectionPhase.reconnecting);
    expect(states.last.attempt, 1);
    expect(states.last.lastError, isA<StateError>());
    expect(delay.durations, <Duration>[const Duration(seconds: 1)]);

    delay.completeNext();
    await _flushAsyncWork();

    expect(states.last.phase, GlobalEventConnectionPhase.connected);
    expect(states.last.attempt, 0);
    expect(states.last.lastError, isNull);

    await subscription.cancel();
    await secondController.close();
  });
}
