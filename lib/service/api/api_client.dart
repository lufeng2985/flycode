import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'api_constants.dart';

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
ApiClient apiClient(Ref ref) {
  return ApiClient();
}

class ApiClient {
  final String _baseUrl = ApiConstants.baseUrl;
  final http.Client _client = http.Client();

  Uri _getUri(String path, {Map<String, String>? queryParameters}) {
    return Uri.parse(
      '$_baseUrl$path',
    ).replace(queryParameters: queryParameters);
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      // 后续可以在这里添加鉴权 Headers
    };
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
  }) async {
    final response = await _client.get(
      _getUri(path, queryParameters: queryParameters),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }

  Future<dynamic> post(
    String path, {
    dynamic body,
    Map<String, String>? queryParameters,
  }) async {
    final response = await _client.post(
      _getUri(path, queryParameters: queryParameters),
      headers: _getHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> patch(
    String path, {
    dynamic body,
    Map<String, String>? queryParameters,
  }) async {
    final response = await _client.patch(
      _getUri(path, queryParameters: queryParameters),
      headers: _getHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final response = await _client.delete(
      _getUri(path, queryParameters: queryParameters),
      headers: _getHeaders(),
    );
    return _handleResponse(response);
  }
}
