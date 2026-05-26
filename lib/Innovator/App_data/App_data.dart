import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';

class AppData {
  static final AppData _instance = AppData._internal();
  factory AppData() => _instance;
  AppData._internal();

  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _currentUser;
  bool _isInitialized = false;
  SharedPreferences? _prefs;

  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserData = 'user_data';

  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  Map<String, dynamic>? get currentUser => _currentUser;

  String? get currentUserId => _currentUser?['id']?.toString();

  String? get currentUsername => _currentUser?['username']?.toString();

  String? get currentUserName {
    final fn = _currentUser?['full_name']?.toString() ?? '';
    if (fn.isNotEmpty) return fn;
    return _currentUser?['name']?.toString();
  }

  String? get currentUserEmail => _currentUser?['email']?.toString();
  String? get currentUserRole => _currentUser?['role']?.toString();

  Map<String, dynamic>? get _profile =>
      _currentUser?['profile'] as Map<String, dynamic>?;

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

  Future<void> updateUserField(String field, dynamic value) async {
    _currentUser ??= {};
    _currentUser![field] = value;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(keyUserData, jsonEncode(_currentUser));
  }

  Future<void> updateUser(Map<String, dynamic> user) async {
    _currentUser = user;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(keyUserData, jsonEncode(user));
    developer.log('AppData: user data updated ✓');
  }

  Future<void> saveAccessToken(String token) async {
    _accessToken = token;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(keyAccessToken, token);
    developer.log('AppData: access token refreshed ✓');
  }

  Future<void> updateProfilePicture(String pictureUrl) async {
    await updateUserField('photo_url', pictureUrl);
    developer.log('AppData: avatar updated → $pictureUrl');
  }

  bool isCurrentUser(String userId) {
    final id = currentUserId;
    return id != null && id == userId;
  }

  bool isCurrentUserByUsername(String username) {
    final stored = currentUsername?.trim().toLowerCase();
    return stored != null && stored == username.trim().toLowerCase();
  }

  bool isCurrentUserByEmail(String email) {
    final stored = currentUserEmail?.trim().toLowerCase();
    return stored != null && stored == email.trim().toLowerCase();
  }

  bool isMe(String value) =>
      isCurrentUser(value) ||
      isCurrentUserByUsername(value) ||
      isCurrentUserByEmail(value);

  Future<void> setAuthToken(String token) => saveAccessToken(token);

  Future<void> clearAuthToken() async {
    _accessToken = null;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(keyAccessToken);
    developer.log('AppData: access token cleared ✓');
  }

  Future<void> setCurrentUser(Map<String, dynamic> userData) =>
      updateUser(userData);

  Future<void> clearCurrentUser() async {
    _currentUser = null;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(keyUserData);
    developer.log('AppData: current user cleared ✓');
  }

  Future<void> updateCurrentUserField(String field, dynamic value) =>
      updateUserField(field, value);

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

  @override
  String toString() =>
      'AppData(authenticated: $isAuthenticated, '
      'user: ${currentUsername ?? currentUserId ?? 'none'})';
}
