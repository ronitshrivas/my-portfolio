import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';

class AppData {
  static final AppData _instance = AppData._internal();
  factory AppData() => _instance;
  AppData._internal();

  // ── In-memory cache ──────────────────────────────────────────────────────
  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _currentUser;
  bool _isInitialized = false;
  SharedPreferences? _prefs;

  // ── SharedPreferences keys ───────────────────────────────────────────────
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserData = 'user_data';

  // ─────────────────────────────────────────────────────────────────────────
  // Getters — auth
  // ─────────────────────────────────────────────────────────────────────────

  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  /// The raw user map as saved at login / after profile updates.
  Map<String, dynamic>? get currentUser => _currentUser;

  // ─────────────────────────────────────────────────────────────────────────
  // Getters — flat user fields (root level of the stored map)
  // ─────────────────────────────────────────────────────────────────────────

  /// UUID string — new API key: "id".
  String? get currentUserId => _currentUser?['id']?.toString();

  /// @-handle — new API key: "username".
  String? get currentUsername => _currentUser?['username']?.toString();

  /// Display name. New API: "full_name". Legacy fallback: "name".
  String? get currentUserName {
    final fn = _currentUser?['full_name']?.toString() ?? '';
    if (fn.isNotEmpty) return fn;
    return _currentUser?['name']?.toString();
  }

  String? get currentUserEmail => _currentUser?['email']?.toString();
  String? get currentUserRole => _currentUser?['role']?.toString();

  // ─────────────────────────────────────────────────────────────────────────
  // Getters — nested profile fields  (stored under "profile" key)
  // ─────────────────────────────────────────────────────────────────────────

  Map<String, dynamic>? get _profile =>
      _currentUser?['profile'] as Map<String, dynamic>?;

  /// Avatar URL.
  /// Priority: flat "photo_url" written after upload → nested "profile.avatar".
  String? get currentUserAvatar {
    final flat = _currentUser?['photo_url']?.toString() ?? '';
    if (flat.isNotEmpty) return flat;
    return _profile?['avatar']?.toString();
  }

  String? get currentUserBio => _profile?['bio']?.toString();
  String? get currentUserPhone => _profile?['phone_number']?.toString();
  String? get currentUserGender => _profile?['gender']?.toString();
  String? get currentUserDob => _profile?['date_of_birth']?.toString();
  String? get currentUserAddress => _profile?['address']?.toString();
  String? get currentUserEducation => _profile?['education']?.toString();
  String? get currentUserOccupation => _profile?['occupation']?.toString();
  String? get currentUserHobbies => _profile?['hobbies']?.toString();

  int get currentFollowersCount =>
      (_profile?['followers_count'] as num?)?.toInt() ?? 0;
  int get currentFollowingCount =>
      (_profile?['following_count'] as num?)?.toInt() ?? 0;

  // ─────────────────────────────────────────────────────────────────────────
  // Initialisation
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      _prefs ??= await SharedPreferences.getInstance();

      _accessToken = _prefs!.getString(keyAccessToken);
      _refreshToken = _prefs!.getString(keyRefreshToken);

      final raw = _prefs!.getString(keyUserData);
      if (raw != null && raw.isNotEmpty) {
        try {
          _currentUser = jsonDecode(raw) as Map<String, dynamic>;
        } catch (e) {
          developer.log('AppData: error parsing user_data: $e');
          _currentUser = null;
        }
      }

      _isInitialized = true;
      developer.log(
        'AppData initialised — authenticated: $isAuthenticated, '
        'user: ${currentUsername ?? currentUserName ?? currentUserId ?? 'none'}',
      );
      developer.log('AppData keys in prefs: ${_prefs!.getKeys()}');
    } catch (e) {
      developer.log('AppData initialize error: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Setters — called by Login.dart after a successful login
  // ─────────────────────────────────────────────────────────────────────────

  /// Primary save after login.
  /// [accessToken]  — key "access" in new API response
  /// [refreshToken] — key "refresh"
  /// [user]         — the user object (key "user" in new API, or flat root)
  Future<void> saveLoginData({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> user,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _currentUser = user;

    _prefs ??= await SharedPreferences.getInstance();
    await Future.wait([
      _prefs!.setString(keyAccessToken, accessToken),
      _prefs!.setString(keyRefreshToken, refreshToken),
      _prefs!.setString(keyUserData, jsonEncode(user)),
    ]);
    developer.log(
      'AppData: login saved — user: ${currentUsername ?? currentUserId}',
    );
  }

  /// Update a single field in the stored user map (e.g. after profile edit).
  Future<void> updateUserField(String field, dynamic value) async {
    _currentUser ??= {};
    _currentUser![field] = value;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(keyUserData, jsonEncode(_currentUser));
  }

  /// Replace the entire user map (e.g. after a full /api/users/me/ refresh).
  Future<void> updateUser(Map<String, dynamic> user) async {
    _currentUser = user;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(keyUserData, jsonEncode(user));
    developer.log('AppData: user data updated ✓');
  }

  /// Save a new access token (called after a server-side token refresh).
  Future<void> saveAccessToken(String token) async {
    _accessToken = token;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(keyAccessToken, token);
    developer.log('AppData: access token refreshed ✓');
  }

  /// Store the avatar URL returned after a profile picture upload.
  /// Written under "photo_url" so [currentUserAvatar] finds it immediately
  /// without a full profile re-fetch.
  Future<void> updateProfilePicture(String pictureUrl) async {
    await updateUserField('photo_url', pictureUrl);
    developer.log('AppData: avatar updated → $pictureUrl');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Identity helpers
  // ─────────────────────────────────────────────────────────────────────────

  /// True if [userId] (UUID string) matches the logged-in user.
  bool isCurrentUser(String userId) {
    final id = currentUserId;
    return id != null && id == userId;
  }

  /// True if the @-handle matches the logged-in user.
  /// Use for new-API feed / comment responses that return "username"
  /// instead of a UUID.
  bool isCurrentUserByUsername(String username) {
    final stored = currentUsername?.trim().toLowerCase();
    return stored != null && stored == username.trim().toLowerCase();
  }

  /// True if the email matches the logged-in user.
  bool isCurrentUserByEmail(String email) {
    final stored = currentUserEmail?.trim().toLowerCase();
    return stored != null && stored == email.trim().toLowerCase();
  }

  /// Convenience — checks id, username, AND email so callers don't need to
  /// know which identifier a given API response provides.
  bool isMe(String value) =>
      isCurrentUser(value) ||
      isCurrentUserByUsername(value) ||
      isCurrentUserByEmail(value);

  // ─────────────────────────────────────────────────────────────────────────
  // Backward-compatibility aliases (keep all existing callers working)
  // ─────────────────────────────────────────────────────────────────────────

  /// Alias for [saveAccessToken].
  Future<void> setAuthToken(String token) => saveAccessToken(token);

  /// Clears only the access token (used on 401 responses before re-login).
  Future<void> clearAuthToken() async {
    _accessToken = null;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(keyAccessToken);
    developer.log('AppData: access token cleared ✓');
  }

  /// Alias for [updateUser].
  Future<void> setCurrentUser(Map<String, dynamic> userData) =>
      updateUser(userData);

  Future<void> clearCurrentUser() async {
    _currentUser = null;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(keyUserData);
    developer.log('AppData: current user cleared ✓');
  }

  /// Alias for [updateUserField] — kept for backward compat.
  Future<void> updateCurrentUserField(String field, dynamic value) =>
      updateUserField(field, value);

  // ─────────────────────────────────────────────────────────────────────────
  // Logout
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;
    _isInitialized = false;

    _prefs ??= await SharedPreferences.getInstance();
    await Future.wait([
      _prefs!.remove(keyAccessToken),
      _prefs!.remove(keyRefreshToken),
      _prefs!.remove(keyUserData), 
    ]);
    developer.log('AppData: logout complete ✓');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Profile completeness check
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns true when all required fields are present and non-empty.
  ///
  /// Root fields (always present after login):  id, username, email
  /// Profile fields (filled via EditProfile):   phone_number, gender,
  ///                                            date_of_birth, address
  bool get isProfileComplete {
    if (_currentUser == null) return false;

    const rootRequired = ['id', 'username', 'email'];
    for (final key in rootRequired) {
      if ((_currentUser![key]?.toString().trim() ?? '').isEmpty) {
        developer.log('AppData: profile incomplete — missing root: $key');
        return false;
      }
    }

    const profileRequired = [
      'phone_number',
      'gender',
      'date_of_birth',
      'address',
    ];
    final profile = _profile ?? {};
    for (final key in profileRequired) {
      if ((profile[key]?.toString().trim() ?? '').isEmpty) {
        developer.log('AppData: profile incomplete — missing profile.$key');
        return false;
      }
    }

    return true;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Debug
  // ─────────────────────────────────────────────────────────────────────────

  @override
  String toString() =>
      'AppData(authenticated: $isAuthenticated, '
      'user: ${currentUsername ?? currentUserId ?? 'none'})';
}
