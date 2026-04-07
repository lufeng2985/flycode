import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flycode/models/server_config.dart';
import 'package:flycode/providers/server_config_provider.dart';
import 'package:flycode/service/api/api_client.dart';

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient({
    Future<http.StreamedResponse> Function(http.BaseRequest request)? onSend,
  }) : _onSend = onSend;

  final Future<http.StreamedResponse> Function(http.BaseRequest request)?
  _onSend;

  int closeCount = 0;
  final List<http.BaseRequest> requests = <http.BaseRequest>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requests.add(request);
    if (_onSend != null) {
      return _onSend(request);
    }
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode('{}')),
      200,
      request: request,
    );
  }

  @override
  void close() {
    closeCount += 1;
  }
}

Future<void> _flushAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test(
    'apiClientProvider closes replaced client and closes active one on dispose',
    () async {
      final firstRawClient = _FakeHttpClient();
      final secondRawClient = _FakeHttpClient();
      final createdClients = Queue<_FakeHttpClient>.from(<_FakeHttpClient>[
        firstRawClient,
        secondRawClient,
      ]);
      final container = ProviderContainer(
        overrides: [
          apiHttpClientFactoryProvider.overrideWith(
            (ref) =>
                () => createdClients.removeFirst(),
          ),
        ],
      );

      await container
          .read(serverConfigProvider.notifier)
          .save(ServerConfig(baseUrl: 'http://server-one.test'));
      final firstApiClient = await container.read(apiClientProvider.future);

      await container
          .read(serverConfigProvider.notifier)
          .save(ServerConfig(baseUrl: 'http://server-two.test'));
      await _flushAsyncWork();
      final secondApiClient = await container.read(apiClientProvider.future);

      expect(firstApiClient.baseUrl, 'http://server-one.test');
      expect(secondApiClient.baseUrl, 'http://server-two.test');
      expect(identical(firstApiClient, secondApiClient), isFalse);
      expect(firstApiClient.isClosed, isTrue);
      expect(firstRawClient.closeCount, 1);
      expect(secondRawClient.closeCount, 0);

      container.dispose();

      expect(secondApiClient.isClosed, isTrue);
      expect(secondRawClient.closeCount, 1);
    },
  );

  test(
    'streamGet closes dedicated stream client when subscription is cancelled',
    () async {
      final baseClient = _FakeHttpClient();
      final responseController = StreamController<List<int>>();
      final streamClient = _FakeHttpClient(
        onSend: (request) async => http.StreamedResponse(
          responseController.stream,
          200,
          request: request,
        ),
      );
      final apiClient = ApiClient(
        baseUrl: 'http://localhost',
        client: baseClient,
        streamClientFactory: () => streamClient,
      );
      addTearDown(() async {
        await responseController.close();
      });

      final received = <String>[];
      final subscription = apiClient
          .streamGet('/global/event')
          .listen(received.add);

      await _flushAsyncWork();
      responseController.add(utf8.encode('data: hello\n\n'));
      await _flushAsyncWork();

      expect(received, <String>['hello']);
      expect(streamClient.closeCount, 0);

      await subscription.cancel();
      await _flushAsyncWork();

      expect(streamClient.closeCount, 1);
      expect(baseClient.closeCount, 0);
    },
  );

  test('streamGet calls onConnected after a successful SSE response', () async {
    final baseClient = _FakeHttpClient();
    final responseController = StreamController<List<int>>();
    final streamClient = _FakeHttpClient(
      onSend: (request) async => http.StreamedResponse(
        responseController.stream,
        200,
        request: request,
      ),
    );
    final apiClient = ApiClient(
      baseUrl: 'http://localhost',
      client: baseClient,
      streamClientFactory: () => streamClient,
    );
    addTearDown(() async {
      await responseController.close();
    });

    var connectedCount = 0;
    final subscription = apiClient
        .streamGet(
          '/global/event',
          onConnected: () {
            connectedCount += 1;
          },
        )
        .listen((_) {});

    await _flushAsyncWork();

    expect(connectedCount, 1);

    await subscription.cancel();
  });

  test('close shuts down active SSE clients immediately', () async {
    final baseClient = _FakeHttpClient();
    final responseController = StreamController<List<int>>();
    final streamClient = _FakeHttpClient(
      onSend: (request) async => http.StreamedResponse(
        responseController.stream,
        200,
        request: request,
      ),
    );
    final apiClient = ApiClient(
      baseUrl: 'http://localhost',
      client: baseClient,
      streamClientFactory: () => streamClient,
    );
    addTearDown(() async {
      await responseController.close();
    });

    final subscription = apiClient.streamGet('/global/event').listen((_) {});
    await _flushAsyncWork();

    apiClient.close();
    await _flushAsyncWork();

    expect(apiClient.isClosed, isTrue);
    expect(baseClient.closeCount, 1);
    expect(streamClient.closeCount, 1);

    await subscription.cancel();
  });
}
