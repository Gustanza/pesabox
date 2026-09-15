import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;

/// Resolves the base URL of the PesaBox Go backend for the current platform.
///
///   - `--dart-define=API_BASE_URL=...` always wins (e.g. a device pointing
///     at the dev machine's LAN IP: `flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8181`).
///   - Android emulator defaults to `10.0.2.2` (the host machine).
///   - Everywhere else (iOS simulator, desktop, web) defaults to `localhost`.
String resolveApiBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8181';
  }
  return 'http://localhost:8181';
}

/// Thin HTTP client for the PesaBox Go backend (`/api/v1`).
class ApiClient {
  ApiClient({String? baseUrl}) : baseUrl = baseUrl ?? resolveApiBaseUrl();

  final String baseUrl;

  Uri _uri(String path, [Map<String, String>? query]) => Uri.parse(
        '$baseUrl/api/v1$path',
      ).replace(queryParameters: query);

  /// GET and decode the JSON response (object payloads).
  Future<Map<String, dynamic>> get(String path,
      [Map<String, String>? query]) async {
    final res = await http.get(_uri(path, query));
    return _decode(res) as Map<String, dynamic>;
  }

  /// GET and decode a JSON list response.
  Future<List<dynamic>> getList(String path,
      [Map<String, String>? query]) async {
    final res = await http.get(_uri(path, query));
    final data = _decode(res);
    return data is List ? data : <dynamic>[];
  }

  /// POST a JSON body and decode the JSON response.
  Future<Map<String, dynamic>> post(
    String path, [
    Map<String, dynamic>? body,
    Map<String, String>? query,
  ]) async {
    final res = await http.post(
      _uri(path, query),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body ?? const {}),
    );
    return _decode(res) as Map<String, dynamic>;
  }

  /// PATCH a JSON body and decode the JSON response.
  Future<Map<String, dynamic>> patch(
    String path, [
    Map<String, dynamic>? body,
    Map<String, String>? query,
  ]) async {
    final res = await http.patch(
      _uri(path, query),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(body ?? const {}),
    );
    return _decode(res) as Map<String, dynamic>;
  }

  /// Pings the backend health endpoint.
  Future<bool> health() async {
    try {
      final res = await http
          .get(_uri('/health'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return false;
      final data = _decode(res);
      return data is Map<String, dynamic> && data['status'] == 'ok';
    } on Exception {
      return false;
    }
  }

  dynamic _decode(http.Response res) {
    Map<String, dynamic> decoded = const {};
    try {
      decoded = jsonDecode(res.body) as Map<String, dynamic>;
    } on FormatException {
      decoded = {'error': 'invalid response', 'status': res.statusCode};
    }
    if (res.statusCode >= 400) {
      final message = decoded['error'] ?? 'Request failed';
      throw ApiException(res.statusCode, message as String);
    }
    // The API wraps successful payloads in { data: ... }.
    return decoded.containsKey('data') ? decoded['data'] : decoded;
  }
}

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

final ApiClient api = ApiClient();