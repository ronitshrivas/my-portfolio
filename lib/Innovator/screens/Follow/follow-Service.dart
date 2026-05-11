import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/constant/api_constants.dart';

class FollowService {
  // UUID v4 pattern
  static final _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}'
    r'-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  // In-memory username → UUID cache (avoids redundant API calls)
  static final Map<String, String> _usernameToUuidCache = {};

  static bool _isUuid(String value) => _uuidRegex.hasMatch(value.trim());

  static Map<String, String> _headers() {
    final token = AppData().accessToken ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ── Resolve username → UUID ─────────────────────────────────────────────
  // If the value is already a UUID it is returned as-is.
  // Otherwise GET /api/users/?username=<value> is called to fetch the UUID.
  static Future<String> resolveToUuid(String usernameOrUuid) async {
    final value = usernameOrUuid.trim();
    if (_isUuid(value)) return value;

    // Check in-memory cache first
    if (_usernameToUuidCache.containsKey(value)) {
      return _usernameToUuidCache[value]!;
    }

    debugPrint('[FollowService] Resolving username "$value" → UUID...');

    try {
      final uri = Uri.parse(
        ApiConstants.fetchuuid,
      ).replace(queryParameters: {'username': value});
      final response = await http
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 15));

      debugPrint(
        '[FollowService] Lookup ${response.statusCode}: ${response.body}',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Handle both list response and single-object response
        Map<String, dynamic>? user;
        if (data is List && data.isNotEmpty) {
          user = data.first as Map<String, dynamic>;
        } else if (data is Map<String, dynamic>) {
          // Could be { results: [...] } or direct object
          if (data.containsKey('results') &&
              (data['results'] as List).isNotEmpty) {
            user = (data['results'] as List).first as Map<String, dynamic>;
          } else if (data.containsKey('id') || data.containsKey('user_id')) {
            user = data;
          }
        }

        if (user != null) {
          final uuid =
              user['id']?.toString() ?? user['user_id']?.toString() ?? '';
          if (_isUuid(uuid)) {
            _usernameToUuidCache[value] = uuid;
            debugPrint('[FollowService] Resolved "$value" → "$uuid"');
            return uuid;
          }
        }
      }
    } catch (e) {
      debugPrint('[FollowService] Username lookup error: $e');
    }

    // Could not resolve — return the original value and let the API return 404
    debugPrint('[FollowService] Could not resolve "$value" to UUID');
    return value;
  }

  // ── Follow ──────────────────────────────────────────────────────────────
  // POST /api/users/<UUID>/follow/
  static Future<Map<String, dynamic>> sendFollowRequest(
    String userIdOrUsername,
  ) async {
    _assertAuth();

    final userId = await resolveToUuid(userIdOrUsername);
    final url = Uri.parse('${ApiConstants.sendFollowrequest}$userId/follow/');
    debugPrint('[FollowService] POST $url');

    final response = await http
        .post(url, headers: _headers())
        .timeout(const Duration(seconds: 30));

    debugPrint(
      '[FollowService] follow ${response.statusCode}: ${response.body}',
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      throw Exception('Authentication failed. Please login again.');
    } else if (response.statusCode == 400) {
      final body =
          response.body.isNotEmpty
              ? jsonDecode(response.body) as Map<String, dynamic>
              : <String, dynamic>{};
      return {
        'message': body['detail'] ?? 'Already following',
        'followers_count': 0,
      };
    } else {
      throw Exception(
        'Failed to follow (${response.statusCode}): ${response.body}',
      );
    }
  }

  // ── Unfollow ────────────────────────────────────────────────────────────
  // POST /api/users/<UUID>/unfollow/
  static Future<Map<String, dynamic>> unfollowUser(
    String userIdOrUsername,
  ) async {
    _assertAuth();

    final userId = await resolveToUuid(userIdOrUsername);
    final url = Uri.parse('${ApiConstants.sendFollowrequest}$userId/unfollow/');
    debugPrint('[FollowService] POST $url');

    final response = await http
        .post(url, headers: _headers())
        .timeout(const Duration(seconds: 30));

    debugPrint(
      '[FollowService] unfollow ${response.statusCode}: ${response.body}',
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else if (response.statusCode == 401) {
      throw Exception('Authentication failed. Please login again.');
    } else if (response.statusCode == 400) {
      final body =
          response.body.isNotEmpty
              ? jsonDecode(response.body) as Map<String, dynamic>
              : <String, dynamic>{};
      return {
        'message': body['detail'] ?? 'Not following',
        'followers_count': 0,
      };
    } else {
      throw Exception(
        'Failed to unfollow (${response.statusCode}): ${response.body}',
      );
    }
  }

  // ── Check follow status ─────────────────────────────────────────────────
  static Future<bool> checkFollowStatus(String targetUserIdOrUsername) async {
    final ids = _localFollowingIds();
    if (ids == null) return false;
    // Check both UUID and username matches
    if (ids.contains(targetUserIdOrUsername)) return true;
    final cached = _usernameToUuidCache[targetUserIdOrUsername];
    if (cached != null) return ids.contains(cached);
    return false;
  }

  // ── Clear cache (call on logout) ─────────────────────────────────────────
  static void clearCache() => _usernameToUuidCache.clear();

  // ── Helpers ─────────────────────────────────────────────────────────────

  static void _assertAuth() {
    final token = AppData().accessToken;
    if (token == null || token.isEmpty) {
      throw Exception('User not authenticated');
    }
  }

  static List<String>? _localFollowingIds() {
    final profile = AppData().currentUser?['profile'] as Map<String, dynamic>?;
    final raw =
        profile?['following_usernames'] as List<dynamic>? ??
        AppData().currentUser?['following_usernames'] as List<dynamic>?;
    return raw?.map((e) => e.toString()).toList();
  }
}
