import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenService {
  static const _storage = FlutterSecureStorage();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _roleKey = 'user_role'; 
 

  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<bool> hasToken() async {
    final token = await _storage.read(key: _accessTokenKey);
    return token != null && token.isNotEmpty;
  }

Future<void> clearTokens() async {
  final accessToken = await _storage.read(key: _accessTokenKey);
  final refreshToken = await _storage.read(key: _refreshTokenKey);
  final role = await _storage.read(key: _roleKey);

  await _storage.delete(key: _accessTokenKey);
  log('Access_token cleared: ${accessToken != null ? '$accessToken' : 'was already empty'}');

  await _storage.delete(key: _refreshTokenKey);
  log('Refresh_token cleared: ${refreshToken != null ? '$refreshToken' : 'was already empty'}');

  await _storage.delete(key: _roleKey);
  log('Role cleared: ${role ?? 'was already empty'}');
}
 
  Future<void> saveRole(String role) async {
    await _storage.write(key: _roleKey, value: role);
  }
 
  Future<String?> getRole() async {
    return await _storage.read(key: _roleKey);
  }
}