// api_services.dart
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/App_data/App_data.dart';

class ApiService {
  static const String _base = 'http://36.253.137.34:8003/api/student';
  static const String _authBase = 'http://36.253.137.34:8010/api/auth';

  // ── Headers ───────────────────────────────────────────────────────────────

  static Map<String, String> _headers([String? token]) {
    final t = token ?? AppData().accessToken;
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (t != null && t.isNotEmpty) 'Authorization': 'Bearer $t',
    };
  }

  // ── Auto-retry on 401 ─────────────────────────────────────────────────────

  static Future<http.Response> _send(
    Future<http.Response> Function(Map<String, String> h) call,
  ) async {
    var res = await call(_headers());
    developer.log(
      '[API] ${res.statusCode} — ${res.body.substring(0, res.body.length.clamp(0, 300))}',
    );

    if (res.statusCode == 401) {
      developer.log('[API] 401 → refreshing token');
      final newToken = await _refresh();
      if (newToken != null) {
        res = await call(_headers(newToken));
        developer.log('[API] retry → ${res.statusCode}');
      }
    }
    return res;
  }

  static Future<String?> _refresh() async {
    try {
      final rt = AppData().refreshToken;
      if (rt == null || rt.isEmpty) return null;

      final res = await http
          .post(
            Uri.parse('$_authBase/token/refresh/'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'refresh': rt}),
          )
          .timeout(const Duration(seconds: 15));

      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        final t =
            data['access']?.toString() ?? data['access_token']?.toString();
        if (t != null && t.isNotEmpty) {
          await AppData().saveAccessToken(t);
          return t;
        }
      }
    } catch (e) {
      developer.log('[API] refresh error: $e');
    }
    return null;
  }

  // ── Error helper ──────────────────────────────────────────────────────────

  static Never _throw(http.Response r, String fallback) {
    Map<String, dynamic>? body;
    try {
      body = json.decode(r.body) as Map<String, dynamic>;
    } catch (_) {}
    final msg =
        body?['detail']?.toString() ??
        body?['message']?.toString() ??
        body?['error']?.toString() ??
        '$fallback (${r.statusCode})';
    throw switch (r.statusCode) {
      401 => Exception('Session expired. Please login again. 3'),
      403 => Exception('Access denied. $msg'),
      404 => Exception('Not found.'),
      _ => Exception(msg),
    };
  }

  // ── Media URL ─────────────────────────────────────────────────────────────

  static String getFullMediaUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return 'http://36.253.137.34:8003/${path.startsWith('/') ? path.substring(1) : path}';
  }

  /// Returns true when [url] is a YouTube link.
  static bool isYouTubeUrl(String url) =>
      url.contains('youtube.com') || url.contains('youtu.be');

  /// Extracts YouTube video ID from a full YouTube URL.
  /// Works for: watch?v=ID, youtu.be/ID, embed/ID
  static String? extractYouTubeId(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host.contains('youtu.be')) return uri.pathSegments.first;
      if (uri.queryParameters.containsKey('v')) return uri.queryParameters['v'];
      final seg = uri.pathSegments;
      final idx = seg.indexOf('embed');
      if (idx != -1 && idx + 1 < seg.length) return seg[idx + 1];
    } catch (_) {}
    return null;
  }

  // ── Courses ───────────────────────────────────────────────────────────────

  /// GET /api/student/courses/
  /// Response includes a nested `contents` list on each course object.
  static Future<List<Map<String, dynamic>>> getCourses() async {
    final url = Uri.parse('$_base/courses/');
    developer.log('[API] GET $url');
    final res = await _send(
      (h) => http.get(url, headers: h).timeout(const Duration(seconds: 30)),
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as List;
      developer.log('[API] ✓ ${data.length} courses');
      return data.cast<Map<String, dynamic>>();
    }
    _throw(res, 'Failed to load courses');
  }

  // ── Enrollments ───────────────────────────────────────────────────────────

  /// GET /api/student/enrollments/
  static Future<List<Map<String, dynamic>>> getEnrollments() async {
    final url = Uri.parse('$_base/enrollments/');
    developer.log('[API] GET $url');
    final res = await _send(
      (h) => http.get(url, headers: h).timeout(const Duration(seconds: 30)),
    );
    if (res.statusCode == 200) {
      return (json.decode(res.body) as List).cast<Map<String, dynamic>>();
    }
    _throw(res, 'Failed to load enrollments');
  }

  /// POST /api/student/enrollments/
  static Future<Map<String, dynamic>> enroll(String courseId) async {
    final url = Uri.parse('$_base/enrollments/');
    final body = json.encode({'course': courseId});
    developer.log('[API] POST $url  course=$courseId');
    final res = await _send(
      (h) => http
          .post(url, headers: h, body: body)
          .timeout(const Duration(seconds: 30)),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    _throw(res, 'Failed to enroll');
  }

  /// GET /api/student/enrollments/{id}/
  static Future<Map<String, dynamic>> getEnrollment(String id) async {
    final url = Uri.parse('$_base/enrollments/$id/');
    final res = await _send(
      (h) => http.get(url, headers: h).timeout(const Duration(seconds: 30)),
    );
    if (res.statusCode == 200)
      return json.decode(res.body) as Map<String, dynamic>;
    _throw(res, 'Failed to load enrollment');
  }

  /// PUT /api/student/enrollments/{id}/
  static Future<Map<String, dynamic>> updateEnrollment(
    String id,
    String courseId,
  ) async {
    final url = Uri.parse('$_base/enrollments/$id/');
    final body = json.encode({'course': courseId});
    final res = await _send(
      (h) => http
          .put(url, headers: h, body: body)
          .timeout(const Duration(seconds: 30)),
    );
    if (res.statusCode == 200)
      return json.decode(res.body) as Map<String, dynamic>;
    _throw(res, 'Failed to update enrollment');
  }

  /// PATCH /api/student/enrollments/{id}/
  static Future<Map<String, dynamic>> patchEnrollment(
    String id,
    String courseId,
  ) async {
    final url = Uri.parse('$_base/enrollments/$id/');
    final body = json.encode({'course': courseId});
    final res = await _send(
      (h) => http
          .patch(url, headers: h, body: body)
          .timeout(const Duration(seconds: 30)),
    );
    if (res.statusCode == 200)
      return json.decode(res.body) as Map<String, dynamic>;
    _throw(res, 'Failed to patch enrollment');
  }

  /// DELETE /api/student/enrollments/{id}/
  static Future<void> deleteEnrollment(String id) async {
    final url = Uri.parse('$_base/enrollments/$id/');
    developer.log('[API] DELETE $url');
    final res = await _send(
      (h) => http.delete(url, headers: h).timeout(const Duration(seconds: 30)),
    );
    if (res.statusCode != 200 && res.statusCode != 204) {
      _throw(res, 'Failed to delete enrollment');
    }
  }
}
