
import 'dart:developer';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:innovator/KMS/core/constants/api_constants.dart';
import 'package:innovator/KMS/core/constants/network/base_api_service.dart';
import 'package:innovator/KMS/model/notification_model.dart';  
import 'package:shared_preferences/shared_preferences.dart';

class KMSNotificationService extends BaseApiService{
  // KMSNotificationService() : super(dio: DioClient.instance);
    KMSNotificationService() : super(silent: true);

  static const String _prefKey = 'kms_fcm_token_id';

  Future<void> registerFcmToken(String token) async {
    try {
      final device = await deviceInfo();
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_prefKey);

      if (savedId == null) {
        await _createToken(token: token, device: device, prefs: prefs);
      } else {
        await _updateToken(
          id: savedId,
          token: token,
          device: device,
          prefs: prefs,
        );
      }
    } catch (e) {
      log('KMS: registerFcmToken error: $e');
    }
  }

  Future<void> _createToken({
    required String token,
    required String device,
    required SharedPreferences prefs,
  }) async {
    final data = await post(
      ApiConstants.fcmTokens,
      data: {'token': token, 'device_name': device},
    );
    final id = data?['id']?.toString();
    if (id != null) {
      await prefs.setString(_prefKey, id);
      log('KMS: Created — id: $id');
    }
  }

  Future<void> _updateToken({
    required String id,
    required String token,
    required String device,
    required SharedPreferences prefs,
  }) async {
    try {
      await patch(
        '${ApiConstants.fcmTokens}$id/',
        data: {'token': token, 'device_name': device},
      );
      log('KMS: Updated — id: $id');
    } catch (e) {
      await prefs.remove(_prefKey);
      await _createToken(token: token, device: device, prefs: prefs);
    }
  }

  Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(_prefKey);
      if (id != null) {
        await delete('${ApiConstants.fcmTokens}$id/');
        await prefs.remove(_prefKey);
        log('KMS: Cleared');
      }
    } catch (e) {
      log('KMS: clearToken error: $e');
    }
  }

  Future<String> deviceInfo() async {
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await info.androidInfo;
        return '${a.manufacturer} ${a.model}';
      } else if (Platform.isIOS) {
        final i = await info.iosInfo;
        return i.utsname.machine;
      }
    } catch (_) {}
    return 'Unknown Device';
  }

  // List of notifications

  Future<List<KMSNotificationModel>> getNotifications() async {
    final data = await get<List<dynamic>>(ApiConstants.notificationsList);
    return data
        .map((e) => KMSNotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  //Mark as read
  Future<void> markAsRead(String notificationId) async {
    await patch(ApiConstants.markNotificationAsRead(notificationId));
  }

  // Mark all as read
  Future<void> markAllAsRead() async {
    await patch(ApiConstants.markAllNotificationsAsRead);
  }
}
