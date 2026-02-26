import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'api_constants.dart';
import 'models/session.dart';
import 'models/message.dart';

part 'session_api.g.dart';

@riverpod
SessionApi sessionApi(Ref ref) {
  return SessionApi();
}

class SessionApi {
  final String _baseUrl = ApiConstants.baseUrl;

  Uri _getUri(String path, {Map<String, String>? queryParameters}) {
    return Uri.parse(
      '$_baseUrl$path',
    ).replace(queryParameters: queryParameters);
  }

  Future<List<Session>> getSessions({
    String? directory,
    bool? roots,
    int? start,
    String? search,
    int? limit,
  }) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;
    if (roots != null) queryParams['roots'] = roots.toString();
    if (start != null) queryParams['start'] = start.toString();
    if (search != null) queryParams['search'] = search;
    if (limit != null) queryParams['limit'] = limit.toString();

    final response = await http.get(
      _getUri('/session', queryParameters: queryParams),
    );

    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body);
      return json.map((e) => Session.fromJson(e)).toList();
    } else {
      throw Exception(
        'Failed to list sessions: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<Session> createSession({
    String? directory,
    Map<String, dynamic>? data,
  }) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    final response = await http.post(
      _getUri('/session', queryParameters: queryParams),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data ?? {}),
    );

    if (response.statusCode == 200) {
      return Session.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Failed to create session: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<Session> getSession(String id, {String? directory}) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    final response = await http.get(
      _getUri('/session/$id', queryParameters: queryParams),
    );

    if (response.statusCode == 200) {
      return Session.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Failed to get session: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> deleteSession(String id, {String? directory}) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    final response = await http.delete(
      _getUri('/session/$id', queryParameters: queryParams),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to delete session: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<Session> updateSession(
    String id, {
    String? directory,
    Map<String, dynamic>? data,
  }) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    final response = await http.patch(
      _getUri('/session/$id', queryParameters: queryParams),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data ?? {}),
    );

    if (response.statusCode == 200) {
      return Session.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Failed to update session: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> abortSession(String id, {String? directory}) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    final response = await http.post(
      _getUri('/session/$id/abort', queryParameters: queryParams),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to abort session: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<List<Session>> getSessionChildren(
    String id, {
    String? directory,
  }) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    final response = await http.get(
      _getUri('/session/$id/children', queryParameters: queryParams),
    );

    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body);
      return json.map((e) => Session.fromJson(e)).toList();
    } else {
      throw Exception(
        'Failed to get session children: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<List<Message>> getSessionMessages(
    String id, {
    String? directory,
    int? limit,
  }) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;
    if (limit != null) queryParams['limit'] = limit.toString();

    final response = await http.get(
      _getUri('/session/$id/message', queryParameters: queryParams),
    );

    if (response.statusCode == 200) {
      final List<dynamic> json = jsonDecode(response.body);
      return json.map((e) => Message.fromJson(e)).toList();
    } else {
      throw Exception(
        'Failed to get session messages: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> sendMessage(
    String id, {
    String? directory,
    Map<String, dynamic>? data,
  }) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    final response = await http.post(
      _getUri('/session/$id/message', queryParameters: queryParams),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data ?? {}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to send message: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> sendCommand(
    String id, {
    String? directory,
    Map<String, dynamic>? data,
  }) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    final response = await http.post(
      _getUri('/session/$id/command', queryParameters: queryParams),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data ?? {}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to send command: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> summarizeSession(
    String id, {
    String? directory,
    Map<String, dynamic>? data,
  }) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    final response = await http.post(
      _getUri('/session/$id/summarize', queryParameters: queryParams),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data ?? {}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to summarize session: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<Map<String, dynamic>> getMessageDiff(
    String id, {
    String? directory,
    String? messageID,
  }) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;
    if (messageID != null) queryParams['messageID'] = messageID;

    final response = await http.get(
      _getUri('/session/$id/diff', queryParameters: queryParams),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Failed to get message diff: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> forkSession(
    String id, {
    String? directory,
    Map<String, dynamic>? data,
  }) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    final response = await http.post(
      _getUri('/session/$id/fork', queryParameters: queryParams),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data ?? {}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fork session: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> initSession(
    String id, {
    String? directory,
    Map<String, dynamic>? data,
  }) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    final response = await http.post(
      _getUri('/session/$id/init', queryParameters: queryParams),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data ?? {}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to init session: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<Message> getMessage(
    String id,
    String messageID, {
    String? directory,
  }) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    final response = await http.get(
      _getUri('/session/$id/message/$messageID', queryParameters: queryParams),
    );

    if (response.statusCode == 200) {
      return Message.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Failed to get message: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> revertMessage(
    String id, {
    String? directory,
    Map<String, dynamic>? data,
  }) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    final response = await http.post(
      _getUri('/session/$id/revert', queryParameters: queryParams),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data ?? {}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to revert message: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> shareSession(String id, {String? directory}) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    final response = await http.post(
      _getUri('/session/$id/share', queryParameters: queryParams),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to share session: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> unshareSession(String id, {String? directory}) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    final response = await http.delete(
      _getUri('/session/$id/share', queryParameters: queryParams),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to unshare session: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<Map<String, dynamic>> getSessionTodos(
    String id, {
    String? directory,
  }) async {
    final queryParams = <String, String>{};
    if (directory != null) queryParams['directory'] = directory;

    final response = await http.get(
      _getUri('/session/$id/todo', queryParameters: queryParams),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
        'Failed to get session todos: ${response.statusCode} - ${response.body}',
      );
    }
  }
}
