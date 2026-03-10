import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../providers/server_config_provider.dart';

part 'api_client.g.dart';

class ApiException implements Exception {
  final int statusCode;
  final String? name;
  final dynamic data;
  final String message;

  ApiException({
    required this.statusCode,
    this.name,
    this.data,
    required this.message,
  });

  @override
  String toString() => 'ApiException: $statusCode $name - $message';
}

@riverpod
Future<ApiClient> apiClient(Ref ref) async {
  final config = await ref.watch(serverConfigProvider.future);
  return ApiClient(
    baseUrl: config.baseUrl,
    username: config.username,
    password: config.password,
  );
}

class ApiClient {
  final String _baseUrl;
  final String? _username;
  final String? _password;
  final http.Client _client;

  ApiClient({
    required String baseUrl,
    String? username,
    String? password,
    http.Client? client,
  }) : _baseUrl = baseUrl,
       _username = username,
       _password = password,
       _client = client ?? http.Client();

  Uri _getUri(String path, {Map<String, String>? queryParameters}) {
    return Uri.parse(
      '$_baseUrl$path',
    ).replace(queryParameters: queryParameters);
  }

  Map<String, String> _getHeaders() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_username != null && _username.isNotEmpty) {
      final credentials = base64Encode(utf8.encode('$_username:$_password'));
      headers['Authorization'] = 'Basic $credentials';
    }
    return headers;
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }

    String? errorName;
    dynamic errorData;
    String message = response.body;

    try {
      final body = jsonDecode(response.body);
      if (body is Map) {
        errorName = body['name']?.toString();
        errorData = body['data'];
        if (body.containsKey('message')) {
          message = body['message'].toString();
        }
      }
    } catch (_) {
      // Body 不是 JSON，保持原样
    }

    throw ApiException(
      statusCode: response.statusCode,
      name: errorName,
      data: errorData,
      message: message,
    );
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? extraHeaders,
  }) async {
    final headers = _getHeaders();
    if (extraHeaders != null) headers.addAll(extraHeaders);
    final response = await _client.get(
      _getUri(path, queryParameters: queryParameters),
      headers: headers,
    );
    return _handleResponse(response);
  }

  Future<dynamic> post(
    String path, {
    dynamic body,
    Map<String, String>? queryParameters,
    Map<String, String>? extraHeaders,
  }) async {
    final headers = _getHeaders();
    if (extraHeaders != null) headers.addAll(extraHeaders);
    final response = await _client.post(
      _getUri(path, queryParameters: queryParameters),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> patch(
    String path, {
    dynamic body,
    Map<String, String>? queryParameters,
    Map<String, String>? extraHeaders,
  }) async {
    final headers = _getHeaders();
    if (extraHeaders != null) headers.addAll(extraHeaders);
    final response = await _client.patch(
      _getUri(path, queryParameters: queryParameters),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? extraHeaders,
  }) async {
    final headers = _getHeaders();
    if (extraHeaders != null) headers.addAll(extraHeaders);
    final response = await _client.delete(
      _getUri(path, queryParameters: queryParameters),
      headers: headers,
    );
    return _handleResponse(response);
  }

  Stream<String> streamGet(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? extraHeaders,
  }) async* {
    final uri = _getUri(path, queryParameters: queryParameters);
    final request = http.Request('GET', uri);
    final headers = _getHeaders()..['Accept'] = 'text/event-stream';
    if (extraHeaders != null) headers.addAll(extraHeaders);
    request.headers.addAll(headers);

    final streamedResponse = await _client.send(request);

    if (streamedResponse.statusCode < 200 ||
        streamedResponse.statusCode >= 300) {
      throw ApiException(
        statusCode: streamedResponse.statusCode,
        message: 'Stream request failed',
      );
    }

    final buffer = StringBuffer();
    var lineBuffer = StringBuffer();

    await for (final chunk in streamedResponse.stream) {
      final text = utf8.decode(chunk);
      for (var i = 0; i < text.length; i++) {
        final char = text[i];
        if (char == '\n') {
          final line = lineBuffer.toString();
          lineBuffer.clear();

          if (line.startsWith('data:')) {
            buffer.write(line.substring(5).trim());
          } else if (line.isEmpty && buffer.isNotEmpty) {
            yield buffer.toString();
            buffer.clear();
          }
          // ignore 'event:' and other SSE fields
        } else {
          lineBuffer.write(char);
        }
      }
    }

    // Flush any remaining buffered data
    if (buffer.isNotEmpty) {
      yield buffer.toString();
    }
  }
}
