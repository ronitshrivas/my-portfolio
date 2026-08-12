import 'package:innovator/core/config/api_config.dart';
import 'package:innovator/core/models/banner_models.dart';
import 'package:innovator/core/payment/khalti_models.dart';
import 'package:innovator/core/network/dio_client.dart';
import 'package:innovator/models/api_response.dart';
import 'package:innovator/elearning/data/models/elearning_dtos.dart';

/// E-learning service — http://36.253.137.34:8003/swagger
/// Student surface: courses, enrollments, payments, notifications, vendor login.
class ElearningApi {
  ElearningApi({DioClient? client}) : _client = client ?? DioClient.shared;

  final DioClient _client;
  static const _base = ApiConfig.elearningBaseUrl;

  // ---------------------------------------------------------------- courses

  Future<List<Course>> courses() async {
    final envelope = await _client.get<List<Course>>(
      _base,
      '/api/courses',
      auth: false,
      parse: (raw) => _list(raw).map((e) => Course.fromJson(e)).toList(),
    );
    return envelope.data ?? const [];
  }

  /// Admin-managed promo banners shown atop the E-learning section.
  Future<List<AppBanner>> banners() async {
    final envelope = await _client.get<List<AppBanner>>(
      _base,
      '/api/banners',
      auth: false,
      parse: (raw) => parseBanners(raw, baseUrl: _base),
    );
    return envelope.data ?? const [];
  }

  // ------------------------------------------------------------ enrollments

  Future<List<Enrollment>> enrollments() async {
    final envelope = await _client.get<List<Enrollment>>(
      _base,
      '/api/student/enrollments',
      parse: (raw) => _list(raw).map((e) => Enrollment.fromJson(e)).toList(),
    );
    return envelope.data ?? const [];
  }

  Future<Enrollment> enroll(String courseId) async {
    final envelope = await _client.post<Enrollment>(
      _base,
      '/api/student/enrollments',
      body: {'course': courseId},
      parse: (raw) => Enrollment.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) throw ApiException(envelope.message ?? 'Enrollment failed');
    return data;
  }

  // --------------------------------------------------------------- payments

  /// Enrolls (free) or starts a Khalti payment (paid) for [courseId].
  /// Free courses return `status: enrolled` with no URL; paid ones return a
  /// hosted `payment_url` + pidx.
  Future<KhaltiInit> initiatePayment(String courseId) async {
    final envelope = await _client.post<KhaltiInit>(
      _base,
      '/api/payments/initiate',
      body: {'course_id': courseId},
      parse: (raw) => KhaltiInit.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null || !envelope.success) {
      throw ApiException(envelope.message ?? 'Could not start enrollment');
    }
    return data;
  }

  // ---------------------------------------------------------- notifications

  Future<List<ElearningNotification>> notifications() async {
    final envelope = await _client.get<List<ElearningNotification>>(
      _base,
      '/api/notifications',
      parse: (raw) =>
          _list(raw).map((e) => ElearningNotification.fromJson(e)).toList(),
    );
    return envelope.data ?? const [];
  }

  Future<void> markNotificationRead(String id) async {
    await _client.post<Object?>(
      _base,
      '/api/notifications/$id/mark_as_read',
      parse: (_) => null,
    );
  }

  Future<void> markAllRead() async {
    await _client.post<Object?>(
      _base,
      '/api/notifications/mark_all_as_read',
      parse: (_) => null,
    );
  }

  Future<void> registerFcmToken(String token, {String? deviceName}) async {
    await _client.post<Object?>(
      _base,
      '/api/fcm-tokens',
      body: {'token': token, 'device_name': deviceName},
      parse: (_) => null,
    );
  }

  // -------------------------------------------------------------- vendor auth

  Future<VendorSession> vendorLogin(String username, String password) async {
    final envelope = await _client.post<VendorSession>(
      _base,
      '/api/vendor/auth/login',
      auth: false,
      body: {'username': username, 'password': password},
      parse: (raw) => VendorSession.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null || data.accessToken.isEmpty) {
      throw ApiException(envelope.message ?? 'Invalid vendor credentials');
    }
    return data;
  }

  // -------------------------------------------------------------- helpers

  List<Map<String, dynamic>> _list(Object? raw) {
    Object? node = raw;
    if (node is Map) {
      node = node['results'] ?? node['data'] ?? node['items'] ?? node;
    }
    if (node is! List) return const [];
    return node
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
