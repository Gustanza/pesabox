import 'app_data.dart';
import 'graphql_client.dart';
import '../i18n/i18n.dart';

/// Registration and login are the same flow against the real backend: enter
/// a phone number (requestOtp), verify the code that comes back (verifyOtp).
/// The account is created automatically on first successful verification —
/// there's no separate sign-up step or password.
class AuthService {
  AuthService._();

  static String _usernameType(String phone) {
    final trimmed = phone.trim();
    final isEmail = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(trimmed);
    return isEmail ? 'email' : 'phone';
  }

  /// Sends (or resends) an OTP to [phone]. Returns true if the backend
  /// accepted the request.
  static Future<bool> requestOtp(String phone) async {
    final data = await gqlAuth.query(
      r'''
        mutation($input: OtpInput!, $type: UsernameIdentifier){
          otp(input: $input, type: $type) { status message }
        }
      ''',
      {
        'input': {'username': phone, 'usernameType': _usernameType(phone)},
        'type': _usernameType(phone),
      },
    );
    return (data['otp'] as Map?)?['status'] == true;
  }

  /// Verifies [code] for [phone]. On success this both logs the user in and
  /// (for a brand-new phone number) creates their account — same call does
  /// both, there's nothing separate to "register". The response body never
  /// carries a token (the backend sets it as an httpOnly `Set-Cookie`
  /// instead), so it's pulled out of the raw response headers here.
  static Future<void> verifyOtp(String phone, String code) async {
    Map<String, String> headers = const {};
    final data = await gqlAuth.query(
      r'''
        mutation($input: LoginInput!, $type: UsernameIdentifier){
          login(input: $input, type: $type) {
            id username email phone firstName lastName role status isActive
          }
        }
      ''',
      {
        'input': {
          'username': phone,
          'usernameType': _usernameType(phone),
          'password': code,
          'type': 'OTP',
        },
        'type': _usernameType(phone),
      },
      (h) => headers = h,
    );

    final user = data['login'] as Map<String, dynamic>?;
    if (user == null) {
      throw GraphQLException(tr('Invalid or expired code'));
    }

    final accessToken = extractCookie(headers, 'access_token');
    if (accessToken == null) {
      throw GraphQLException(tr('Login succeeded but no session was issued'));
    }
    final refreshToken = extractCookie(headers, 'refresh_token');

    await AppState.I.setSession(user, accessToken, refreshToken);
  }
}
