import 'package:google_sign_in/google_sign_in.dart';

import '../config/api_config.dart';
import '../models/api_response.dart';

class GoogleAuthTokens {
  const GoogleAuthTokens({required this.idToken, this.accessToken});

  final String idToken;
  final String? accessToken;
}

/// Obtains Google tokens for `POST /api/auth/sso/google`.
///
/// Uses the google_sign_in 6.x API (the version Innovator ships).
class GoogleAuthService {
  GoogleAuthService._();
  static final GoogleAuthService instance = GoogleAuthService._();

  static const _scopes = <String>['email', 'profile', 'openid'];

  GoogleSignIn? _client;

  GoogleSignIn get _google {
    final serverClientId = ApiConfig.googleServerClientId.trim();
    final clientId = ApiConfig.googleClientId.trim();
    return _client ??= GoogleSignIn(
      scopes: _scopes,
      clientId: clientId.isEmpty ? null : clientId,
      serverClientId: serverClientId.isEmpty ? null : serverClientId,
    );
  }

  /// Interactive Google account picker → ID token (+ optional access token).
  Future<GoogleAuthTokens> obtainTokens() async {
    try {
      final account = await _google.signIn();
      if (account == null) {
        throw ApiException('Google sign-in canceled');
      }

      final auth = await account.authentication;
      final idToken = auth.idToken?.trim() ?? '';
      if (idToken.isEmpty) {
        throw ApiException(
          'Google did not return an ID token. Confirm GOOGLE_SERVER_CLIENT_ID '
          'is your Web OAuth client ID.',
        );
      }

      return GoogleAuthTokens(
        idToken: idToken,
        accessToken: auth.accessToken,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(e.toString());
    }
  }

  Future<void> signOut() async {
    try {
      await _google.signOut();
    } catch (_) {
      // Local session clear still proceeds.
    }
  }
}
