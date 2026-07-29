import 'package:shared_preferences/shared_preferences.dart';

import '../../App_data/App_data.dart';

/// In-memory + persisted auth session (Bearer token for chat/API calls).
///
/// The new UI screens read their Bearer token and current-user identity
/// from here. Innovator owns the real session in [AppData], so this is kept
/// in sync with it via [syncFromAppData] at startup and after login/logout —
/// that single bridge is what lets every new UI API call authenticate
/// against Innovator's shared backend.
class AuthSession {
  AuthSession._();
  static final AuthSession instance = AuthSession._();

  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  static const _kUserId = 'auth_user_id';
  static const _kUsername = 'auth_username';
  static const _kEmail = 'auth_email';

  String? accessToken;
  String? refreshToken;
  String? userId;
  String? username;
  String? email;

  /// Set after a successful profile ensure so we skip repeat POSTs.
  bool profileEnsured = false;

  bool get isSignedIn =>
      accessToken != null && accessToken!.isNotEmpty && userId != null;

  String get authorizationHeader => 'Bearer ${accessToken ?? ''}';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString(_kAccess);
    refreshToken = prefs.getString(_kRefresh);
    userId = prefs.getString(_kUserId);
    username = prefs.getString(_kUsername);
    email = prefs.getString(_kEmail);
    // Innovator's live session takes precedence when present.
    syncFromAppData();
  }

  /// Mirror Innovator's [AppData] session into this session so every new UI
  /// service call carries Innovator's Bearer token and identity. Reads the
  /// already-loaded in-memory values (no extra disk I/O). Safe to call often.
  void syncFromAppData() {
    final app = AppData();
    final token = app.accessToken;
    if (token == null || token.isEmpty) return;
    accessToken = token;
    refreshToken = app.refreshToken ?? refreshToken;
    userId = app.currentUserId ?? userId;
    username = app.currentUsername ?? username;
    email = app.currentUserEmail ?? email;
  }

  Future<void> save({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String username,
    required String email,
  }) async {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    this.userId = userId;
    this.username = username;
    this.email = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAccess, accessToken);
    await prefs.setString(_kRefresh, refreshToken);
    await prefs.setString(_kUserId, userId);
    await prefs.setString(_kUsername, username);
    await prefs.setString(_kEmail, email);
  }

  Future<void> clear() async {
    accessToken = null;
    refreshToken = null;
    userId = null;
    username = null;
    email = null;
    profileEnsured = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kAccess);
    await prefs.remove(_kRefresh);
    await prefs.remove(_kUserId);
    await prefs.remove(_kUsername);
    await prefs.remove(_kEmail);
  }
}
