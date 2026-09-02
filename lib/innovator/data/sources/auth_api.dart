import 'dart:async';

import 'package:innovator/core/config/api_config.dart';
import 'package:innovator/models/api_response.dart';
import 'package:innovator/core/network/dio_client.dart';
import 'package:innovator/services/auth_session.dart';
import 'package:innovator/services/push_service.dart';
import 'package:innovator/services/chat_socket.dart';
import 'package:innovator/services/notification_poller.dart';
import 'package:innovator/innovator/data/sources/google_auth_service.dart';
import 'package:innovator/services/memory_cache.dart';
import 'package:innovator/innovator/data/sources/profile_api.dart';

/// Result of `GET /api/users/check-username`.
class UsernameCheck {
  const UsernameCheck({required this.available, this.suggestions = const []});

  final bool available;
  final List<String> suggestions;

  factory UsernameCheck.fromJson(Map<String, dynamic> json) {
    final raw = json['suggestions'];
    return UsernameCheck(
      available: json['available'] == true,
      suggestions: raw is List
          ? raw.map((e) => e.toString()).toList()
          : const [],
    );
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    this.username,
    this.email,
    this.role,
    this.isEmailVerified = false,
  });

  final String id;
  final String? username;
  final String? email;
  final String? role;
  final bool isEmailVerified;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? '',
      username: json['username'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String?,
      // Email login returns camelCase; Google SSO returns snake_case.
      isEmailVerified:
          json['isEmailVerified'] == true || json['is_email_verified'] == true,
    );
  }
}

class AuthResult {
  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final AuthUser user;

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    // Email login returns camelCase (accessToken); Google SSO returns
    // snake_case (access_token). Accept either so both paths store a real token.
    return AuthResult(
      accessToken:
          (json['accessToken'] ?? json['access_token'])?.toString() ?? '',
      refreshToken:
          (json['refreshToken'] ?? json['refresh_token'])?.toString() ?? '',
      expiresIn:
          ((json['expiresIn'] ?? json['expires_in']) as num?)?.toInt() ?? 0,
      user: AuthUser.fromJson(
        Map<String, dynamic>.from(json['user'] as Map? ?? const {}),
      ),
    );
  }
}

/// Auth service — http://36.253.137.34:8010/swagger
class AuthApi {
  AuthApi({DioClient? client}) : _client = client ?? DioClient.shared;

  final DioClient _client;

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final envelope = await _client.post<AuthResult>(
      ApiConfig.authBaseUrl,
      '/api/auth/sso/login',
      auth: false,
      body: {'email': email, 'password': password},
      parse: (raw) => AuthResult.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) throw ApiException(envelope.message ?? 'Login failed');
    await AuthSession.instance.save(
      accessToken: data.accessToken,
      refreshToken: data.refreshToken,
      userId: data.user.id,
      username: data.user.username ?? '',
      email: data.user.email ?? email,
    );
    await _ensureProfile(data.user);
    unawaited(PushService.instance.init());
    return data;
  }

  /// Google SSO — `POST /api/auth/sso/google` with `{ google_token }`.
  ///
  /// Tries the ID token first (correct for most backends), then the access
  /// token if the server rejects the ID token.
  Future<AuthResult> loginWithGoogle() async {
    final tokens = await GoogleAuthService.instance.obtainTokens();
    try {
      return await _exchangeGoogleToken(tokens.idToken);
    } on ApiException catch (e) {
      final access = tokens.accessToken?.trim();
      final looksInvalid = e.message.toLowerCase().contains('invalid google');
      if (!looksInvalid || access == null || access.isEmpty) {
        if (looksInvalid) {
          throw ApiException(
            'Invalid Google token. The auth server must verify tokens using '
            'this Web Client ID:\n'
            '${ApiConfig.googleServerClientId}\n'
            'Ask the backend team to update their Google OAuth Client ID '
            '(and secret) to match, then try again.',
          );
        }
        rethrow;
      }
      try {
        return await _exchangeGoogleToken(access);
      } on ApiException catch (_) {
        throw ApiException(
          'Invalid Google token. The auth server must verify tokens using '
          'this Web Client ID:\n'
          '${ApiConfig.googleServerClientId}\n'
          'Ask the backend team to update their Google OAuth Client ID '
          '(and secret) to match, then try again.',
        );
      }
    }
  }

  Future<AuthResult> _exchangeGoogleToken(String googleToken) async {
    final envelope = await _client.post<AuthResult>(
      ApiConfig.authBaseUrl,
      '/api/auth/sso/google',
      auth: false,
      body: {'google_token': googleToken},
      parse: (raw) => AuthResult.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'Google sign-in failed');
    }
    await AuthSession.instance.save(
      accessToken: data.accessToken,
      refreshToken: data.refreshToken,
      userId: data.user.id,
      username: data.user.username ?? '',
      email: data.user.email ?? '',
    );
    await _ensureProfile(data.user);
    unawaited(PushService.instance.init());
    return data;
  }

  /// Checks whether a username is available. Returns availability + suggestions.
  /// `GET /api/users/check-username?username=...`
  Future<UsernameCheck> checkUsername(String username) async {
    final envelope = await _client.get<UsernameCheck>(
      ApiConfig.authBaseUrl,
      '/api/users/check-username',
      query: {'username': username},
      auth: false,
      parse: (raw) => UsernameCheck.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    return envelope.data ??
        const UsernameCheck(available: false, suggestions: []);
  }

  Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
    String? phone,
    String role = 'user',
  }) async {
    final envelope = await _client.post<AuthResult>(
      ApiConfig.authBaseUrl,
      '/api/auth/register',
      auth: false,
      body: {
        'username': username,
        'email': email,
        'password': password,
        'phone': phone,
        'role': role,
      },
      parse: (raw) => AuthResult.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'Registration failed');
    }
    await AuthSession.instance.save(
      accessToken: data.accessToken,
      refreshToken: data.refreshToken,
      userId: data.user.id,
      username: data.user.username ?? username,
      email: data.user.email ?? email,
    );
    await _ensureProfile(data.user);
    unawaited(PushService.instance.init());
    return data;
  }

  // ------------------------------------------------------- email verification

  /// Confirms the signup OTP emailed after register. [code] is the 6-digit OTP.
  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    final envelope = await _client.post<Object?>(
      ApiConfig.authBaseUrl,
      '/api/auth/verify-email',
      auth: false,
      body: {'email': email, 'code': code},
      parse: (_) => null,
    );
    if (!envelope.success) {
      throw ApiException(envelope.message ?? 'Could not verify email');
    }
  }

  /// Re-sends the signup verification OTP to [email].
  Future<void> resendVerificationOtp({required String email}) async {
    final envelope = await _client.post<Object?>(
      ApiConfig.authBaseUrl,
      '/api/auth/resend-verification-otp',
      auth: false,
      body: {'email': email},
      parse: (_) => null,
    );
    if (!envelope.success) {
      throw ApiException(envelope.message ?? 'Could not resend the code');
    }
  }

  // ---------------------------------------------------------- forgot password

  /// Emails a 6-digit reset OTP to [email].
  Future<void> forgotPassword({required String email}) async {
    final envelope = await _client.post<Object?>(
      ApiConfig.authBaseUrl,
      '/api/auth/forgot-password',
      auth: false,
      body: {'email': email},
      parse: (_) => null,
    );
    if (!envelope.success) {
      throw ApiException(envelope.message ?? 'Could not send the reset code');
    }
  }

  /// Verifies the reset OTP before allowing a new password.
  Future<void> verifyForgotOtp({
    required String email,
    required String code,
  }) async {
    final envelope = await _client.post<Object?>(
      ApiConfig.authBaseUrl,
      '/api/auth/forgot-password/verify',
      auth: false,
      body: {'email': email, 'code': code},
      parse: (_) => null,
    );
    if (!envelope.success) {
      throw ApiException(envelope.message ?? 'Invalid or expired code');
    }
  }

  /// Sets a new password using the verified reset OTP.
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final envelope = await _client.post<Object?>(
      ApiConfig.authBaseUrl,
      '/api/auth/forgot-password/reset-password',
      auth: false,
      body: {'email': email, 'code': code, 'newPassword': newPassword},
      parse: (_) => null,
    );
    if (!envelope.success) {
      throw ApiException(envelope.message ?? 'Could not reset password');
    }
  }

  /// Changes the signed-in user's password.
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final envelope = await _client.post<Object?>(
      ApiConfig.authBaseUrl,
      '/api/auth/change-password',
      body: {'old_password': oldPassword, 'new_password': newPassword},
      parse: (_) => null,
    );
    if (!envelope.success) {
      throw ApiException(envelope.message ?? 'Could not change password');
    }
  }

  /// Starts an email change: verifies the password and sends an OTP to the
  /// new address. Confirm with [verifyChangeEmail].
  Future<void> changeEmail({
    required String newEmail,
    required String password,
  }) async {
    final envelope = await _client.post<Object?>(
      ApiConfig.authBaseUrl,
      '/api/auth/change-email',
      body: {'new_email': newEmail, 'password': password},
      parse: (_) => null,
    );
    if (!envelope.success) {
      throw ApiException(envelope.message ?? 'Could not start email change');
    }
  }

  /// Confirms the new email with the OTP sent to it.
  Future<void> verifyChangeEmail({required String code}) async {
    final envelope = await _client.post<Object?>(
      ApiConfig.authBaseUrl,
      '/api/auth/change-email/verify',
      body: {'code': code},
      parse: (_) => null,
    );
    if (!envelope.success) {
      throw ApiException(envelope.message ?? 'Invalid or expired code');
    }
  }

  /// Soft-deletes the signed-in account after verifying the password.
  Future<void> deleteAccount({required String password}) async {
    final envelope = await _client.delete<Object?>(
      ApiConfig.authBaseUrl,
      '/api/auth/account',
      body: {'password': password},
      parse: (_) => null,
    );
    if (!envelope.success) {
      throw ApiException(envelope.message ?? 'Could not delete account');
    }
  }

  Future<void> _ensureProfile(AuthUser user) async {
    if (AuthSession.instance.profileEnsured) return;
    try {
      await ProfileApi().ensureProfile(
        authUserId: user.id,
        username: user.username,
        email: user.email,
        role: user.role ?? 'user',
      );
    } catch (_) {
      // Profile can still be ensured on first ProfileSection load.
    }
  }

  Future<void> logout() async {
    // Remove the device's push token before the Bearer is cleared.
    await PushService.instance.unregister();
    ChatSocket.instance.dispose();
    NotificationPoller.instance.reset();
    try {
      if (AuthSession.instance.isSignedIn) {
        await _client.post<Object?>(
          ApiConfig.authBaseUrl,
          '/api/auth/logout',
          parse: (_) => null,
        );
      }
    } catch (_) {
      // Still clear local session.
    }
    await GoogleAuthService.instance.signOut();
    await AuthSession.instance.clear();
    MemoryCache.clear();
  }
}
