// fcm_service.dart
import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  static const String _baseUrl = 'http://36.253.137.34:8005/api/fcm-tokens/';
  static const String _prefKey = 'fcm_token_id';  

  /// Call this after login AND on app start
  Future<void> registerToken() async {
    try {
      final accessToken = AppData().accessToken;
      if (accessToken == null || accessToken.isEmpty) {
        developer.log('FCM: No access token, skipping');
        return;
      }

      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null) return;

      final deviceName = await _getDeviceName();
      final prefs = await SharedPreferences.getInstance();
      final savedTokenId = prefs.getString(_prefKey);

      if (savedTokenId != null) {
        // Token record already exists — UPDATE it
        await _updateToken(
          tokenId: savedTokenId,
          fcmToken: fcmToken,
          deviceName: deviceName,
          accessToken: accessToken,
          prefs: prefs,
        );
      } else {
        // No record yet — CREATE it
        await _createToken(
          fcmToken: fcmToken,
          deviceName: deviceName,
          accessToken: accessToken,
          prefs: prefs,
        );
      }
    } catch (e) {
      developer.log('FCM: registerToken error: $e');
    }
  }

  Future<void> _createToken({
    required String fcmToken,
    required String deviceName,
    required String accessToken,
    required SharedPreferences prefs,
  }) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({'token': fcmToken, 'device_name': deviceName}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final tokenId = data['id']?.toString();

      // Save the record ID so we can PATCH it next time
      if (tokenId != null) {
        await prefs.setString(_prefKey, tokenId);
        developer.log('FCM: Token created — id: $tokenId');
      }
    } else {
      developer.log(
        'FCM: Create failed ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<void> _updateToken({
    required String tokenId,
    required String fcmToken,
    required String deviceName,
    required String accessToken,
    required SharedPreferences prefs,
  }) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl$tokenId/'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({'token': fcmToken, 'device_name': deviceName}),
    );

    if (response.statusCode == 200) {
      developer.log('FCM: Token updated — id: $tokenId');
    } else if (response.statusCode == 404) {
      // Record was deleted on backend — create a fresh one
      developer.log('FCM: Token record not found, creating new one');
      await prefs.remove(_prefKey);
      await _createToken(
        fcmToken: fcmToken,
        deviceName: deviceName,
        accessToken: accessToken,
        prefs: prefs,
      );
    } else {
      developer.log(
        'FCM: Update failed ${response.statusCode} ${response.body}',
      );
    }
  }

  /// Call this on logout — clears saved token ID
  Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTokenId = prefs.getString(_prefKey);
      final accessToken = AppData().accessToken;

      // Delete token from backend on logout
      if (savedTokenId != null && accessToken != null) {
        await http.delete(
          Uri.parse('$_baseUrl$savedTokenId/'),
          headers: {'Authorization': 'Bearer $accessToken'},
        );
      }

      await prefs.remove(_prefKey);
      developer.log('FCM: Token cleared on logout');
    } catch (e) {
      developer.log('FCM: clearToken error: $e');
    }
  }

  Future<String> _getDeviceName() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        return '${info.manufacturer} ${info.model}';
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        return info.utsname.machine;
      }
    } catch (_) {}
    return 'Unknown Device';
  }
}
