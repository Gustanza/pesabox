import 'dart:convert';

import 'package:http/http.dart' as http;

import 'app_data.dart';
import '../i18n/i18n.dart';
import 'api_base.dart';

/// Base URL of the HelaBox Go backend — local server in debug runs, live
/// server in release builds (see api_base.dart).
String resolveApiBaseUrl() => apiBaseUrl();

/// Thin GraphQL client for the real PesaBox Go backend. Sessions are carried
/// as `Authorization: Bearer <accessToken>` rather than cookies — cookies
/// work fine for a browser but a native/mobile client has no shared cookie
/// jar the way a browser does. The backend only ever sets the session as an
/// httpOnly `Set-Cookie` (never in the JSON body), so `AuthService.verifyOtp`
/// pulls the token out of the raw response headers via [extractCookie] and
/// hands it to `AppState` to carry as a Bearer token from then on.
class GraphQLClient {
  GraphQLClient({String? baseUrl, this.authEndpoint = false})
      : baseUrl = baseUrl ?? resolveApiBaseUrl();

  final String baseUrl;

  /// True for the unauthenticated /graphql/auth endpoint (otp, login),
  /// false for the main /graphql endpoint (everything that needs a session).
  final bool authEndpoint;

  /// [onHeaders], if given, receives the raw HTTP response headers — used by
  /// the login/refresh calls to pull the session token out of `Set-Cookie`
  /// (see [extractCookie]), since the backend never puts it in the JSON body.
  Future<Map<String, dynamic>> query(
    String query, [
    Map<String, dynamic>? variables,
    void Function(Map<String, String> headers)? onHeaders,
  ]) async {
    return _query(query, variables, retrying: false, onHeaders: onHeaders);
  }

  Future<Map<String, dynamic>> _query(
    String query,
    Map<String, dynamic>? variables, {
    required bool retrying,
    void Function(Map<String, String> headers)? onHeaders,
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
    onHeaders?.call(res.headers);

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
          tr('Request failed');
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

/// Pulls a cookie's value (e.g. `access_token`) out of a raw `Set-Cookie`
/// response header. The backend issues the session as httpOnly cookies, and
/// a plain `http` client has no cookie jar of its own, so this is how the
/// token gets extracted to carry as a normal Bearer token instead — exactly
/// the fallback the backend's middleware is documented to accept. Matches
/// `name=value` up to the next `;` rather than splitting on commas, since
/// `Set-Cookie` headers can get comma-folded together (e.g. by an
/// `Expires=Wed, 21 Oct ...` attribute) when multiple cookies are present.
String? extractCookie(Map<String, String> headers, String name) {
  final raw = headers['set-cookie'];
  if (raw == null) return null;
  final match = RegExp('(?:^|[;, ])$name=([^;]+)').firstMatch(raw);
  return match?.group(1);
}

/// /graphql/auth — otp + login/registration (unauthenticated).
final GraphQLClient gqlAuth = GraphQLClient(authEndpoint: true);

/// /graphql — everything that needs a logged-in session.
final GraphQLClient gql = GraphQLClient();
