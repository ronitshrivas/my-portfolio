import 'dart:convert';

/// Normalises the login/register/SSO responses from the .NET backend, which wrap
/// their payload as { success, message, data: { accessToken, refreshToken, user } }.
/// Legacy snake_case and SimpleJWT shapes are still accepted so older responses
/// keep working during the transition.
class AuthResult {
  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final Map<String, dynamic> user;

  bool get hasToken => accessToken.isNotEmpty;

  factory AuthResult.fromResponseBody(String body) {
    final decoded = jsonDecode(body);
    return AuthResult.fromMap(
      decoded is Map<String, dynamic> ? decoded : const {},
    );
  }

  factory AuthResult.fromMap(Map<String, dynamic> root) {
    final payload = root['data'] is Map<String, dynamic>
        ? root['data'] as Map<String, dynamic>
        : root;

    final tokens = payload['tokens'] is Map<String, dynamic>
        ? payload['tokens'] as Map<String, dynamic>
        : const <String, dynamic>{};

    final user = payload['user'] is Map<String, dynamic>
        ? payload['user'] as Map<String, dynamic>
        : <String, dynamic>{};

    return AuthResult(
      accessToken: firstNonEmpty([
        payload['accessToken'],
        payload['access_token'],
        payload['access'],
        payload['token'],
        tokens['access'],
      ]),
      refreshToken: firstNonEmpty([
        payload['refreshToken'],
        payload['refresh_token'],
        payload['refresh'],
        tokens['refresh'],
      ]),
      user: user,
    );
  }

  static String firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }
}
