import 'dart:developer';
import 'dart:developer' as console;
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:innovator/ecommerce/core/constants/api_constants.dart';
import 'package:innovator/ecommerce/core/constants/network/base_api_service.dart';
import 'package:innovator/ecommerce/model/notification_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EcommerceNotificationService extends EcommerBaseApiService {
  // EcommerceNotificationService() : super(dio: DioClient.instance);
  EcommerceNotificationService() : super(silent: true);

  static const String _prefKey = 'ecommerce_fcm_token_id';

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
      console.log('Ecommerce: registerFcmToken error: $e');
    }
  }

  Future<void> _createToken({
    required String token,
    required String device,
    required SharedPreferences prefs,
  }) async {
    final data = await post(
      EcommerceApi.fcmTokens,
      data: {'token': token, 'device_name': device},
    );
    final id = data?['id']?.toString();
    if (id != null) {
      await prefs.setString(_prefKey, id);
      log('Ecommerce: Created — id: $id');
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
        '${EcommerceApi.fcmTokens}$id/',
        data: {'token': token, 'device_name': device},
      );
      log('Ecommerce: Updated — id: $id');
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
        await delete('${EcommerceApi.fcmTokens}$id/');
        await prefs.remove(_prefKey);
        log('Ecommerce: Cleared');
      }
    } catch (e) {
      log('Ecommerce: clearToken error: $e');
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

  Future<List<EcommerceNotificationModel>> getNotifications() async {
    final data = await get<List<dynamic>>(EcommerceApi.notificationsList);
    return data
        .map(
          (e) => EcommerceNotificationModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  //Mark as read
  Future<void> markAsRead(String notificationId) async {
    await patch(EcommerceApi.markNotificationAsRead(notificationId));
  }

  // Mark all as read
  Future<void> markAllAsRead() async {
    await patch(EcommerceApi.markAllNotificationsAsRead);
  }
}
