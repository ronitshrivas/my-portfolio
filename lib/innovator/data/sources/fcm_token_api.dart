import 'package:innovator/core/config/api_config.dart';
import 'package:innovator/core/network/dio_client.dart';

/// Registers the device's FCM token with the backend services that send push.
///
/// The Feed service (8012) owns the primary token record and returns an id we
/// keep so we can delete it on logout. The Ecommerce service (8004) also keeps
/// a copy so order/shop pushes reach the device.
class FcmTokenApi {
  FcmTokenApi({DioClient? client}) : _client = client ?? DioClient.shared;

  final DioClient _client;

  /// Ecommerce push registration lives on its own host/port.
  static const _ecommerceBaseUrl = 'http://36.253.137.34:8004';

  /// Registers on the Feed service and returns the token record id (or null).
  Future<String?> registerFeed({
    required String token,
    required String deviceName,
  }) async {
    final envelope = await _client.post<String?>(
      ApiConfig.feedBaseUrl,
      '/api/fcm-tokens',
      body: {'token': token, 'device_name': deviceName},
      parse: (raw) {
        if (raw is Map) {
          final id = raw['id'];
          if (id != null) return id.toString();
        }
        return null;
      },
    );
    return envelope.data;
  }

  /// Upserts an existing Feed token record.
  Future<void> updateFeed({
    required String tokenId,
    required String token,
    required String deviceName,
  }) async {
    await _client.patch<Object?>(
      ApiConfig.feedBaseUrl,
      '/api/fcm-tokens/$tokenId',
      body: {'token': token, 'device_name': deviceName},
      parse: (_) => null,
    );
  }

  Future<void> deleteFeed(String tokenId) async {
    await _client.delete<Object?>(
      ApiConfig.feedBaseUrl,
      '/api/fcm-tokens/$tokenId',
      parse: (_) => null,
    );
  }

  /// Registers the token with the Ecommerce service (best-effort).
  Future<void> registerEcommerce({required String token}) async {
    await _client.post<Object?>(
      _ecommerceBaseUrl,
      '/api/fcm-tokens',
      body: {'token': token, 'platform': 'android'},
      parse: (_) => null,
    );
  }
}
