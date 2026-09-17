import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_data.dart';

/// Resolves the base URL of the PesaBox Go backend.
///
/// Defaults to the live VPS deployment so the app talks to the real backend
/// on every platform without extra setup. `--dart-define=API_BASE_URL=...`
/// still overrides this (e.g. for pointing back at a local dev server:
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8090`).
String resolveApiBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  return 'http://161.97.99.40:8090';
}

/// Thin GraphQL client for the real PesaBox Go backend. Sessions are carried
/// as `Authorization: Bearer <accessToken>` rather than cookies — cookies
/// work fine for a browser but a native/mobile client has no shared cookie
/// jar the way a browser does, so the backend's login/verifyOtp responses
/// also hand back the token directly for exactly this case.
class GraphQLClient {
  GraphQLClient({String? baseUrl, this.authEndpoint = false})
      : baseUrl = baseUrl ?? resolveApiBaseUrl();

  final String baseUrl;

  /// True for the unauthenticated /graphql/auth endpoint (otp, login),
  /// false for the main /graphql endpoint (everything that needs a session).
  final bool authEndpoint;

  Future<Map<String, dynamic>> query(
    String query, [
    Map<String, dynamic>? variables,
  ]) async {
    return _query(query, variables, retrying: false);
  }

  Future<Map<String, dynamic>> _query(
    String query,
    Map<String, dynamic>? variables, {
    required bool retrying,
  }) async {
    final path = authEndpoint ? '/graphql/auth' : '/graphql';
    final headers = {'Content-Type': 'application/json'};
    final token = AppState.I.token;
    if (!authEndpoint && token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    final res = await http
        .post(
          Uri.parse('$baseUrl$path'),
          headers: headers,
          body: jsonEncode({'query': query, 'variables': variables ?? {}}),
        )
        .timeout(const Duration(seconds: 15));

    // The backend's access tokens expire after just 15 minutes. A 401 here
    // (the middleware's own "Token expired" JSON, not a GraphQL error) gets
    // one silent refresh-and-retry via AppState.refreshSession() rather
    // than surfacing as a dead-end error mid-session — /graphql/auth never
    // carries a token, so this only applies to the main endpoint.
    if (!authEndpoint &&
        res.statusCode == 401 &&
        !retrying &&
        await AppState.I.refreshSession()) {
      return _query(query, variables, retrying: true);
    }

    final decoded = jsonDecode(res.body) as Map<String, dynamic>;
    final errors = decoded['errors'] as List?;
    if (errors != null && errors.isNotEmpty) {
      final message = (errors.first as Map)['message'] as String? ??
          'Request failed';
      throw GraphQLException(message);
    }
    final singleError = decoded['error'];
    if (singleError is String && singleError.isNotEmpty) {
      throw GraphQLException(singleError);
    }

    return (decoded['data'] as Map?)?.cast<String, dynamic>() ?? {};
  }
}

class GraphQLException implements Exception {
  const GraphQLException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// /graphql/auth — otp + login/registration (unauthenticated).
final GraphQLClient gqlAuth = GraphQLClient(authEndpoint: true);

/// /graphql — everything that needs a logged-in session.
final GraphQLClient gql = GraphQLClient();
