import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'package:innovator/core/config/api_config.dart';
import 'package:innovator/core/network/dio_client.dart';
import 'package:innovator/models/api_response.dart';
import 'package:innovator/innovator/data/models/profile_models.dart';
import 'package:innovator/innovator/data/models/search_models.dart';
import 'package:innovator/services/auth_session.dart';
import 'package:innovator/services/memory_cache.dart';
import 'package:innovator/innovator/data/sources/search_api.dart';

/// Profile service — http://36.253.137.34:8011/swagger
class ProfileApi {
  ProfileApi({DioClient? client}) : _client = client ?? DioClient.shared;

  final DioClient _client;

  static const _meKey = 'profile.me';

  /// Creates the profile row if missing (InternalProfile).
  Future<void> ensureProfile({
    required String authUserId,
    String? username,
    String? email,
    String? role,
  }) async {
    if (AuthSession.instance.profileEnsured) return;
    await _client.post<Object?>(
      ApiConfig.profileBaseUrl,
      '/api/internal/profiles/ensure',
      body: {
        'auth_user_id': authUserId,
        'username': username,
        'email': email,
        'role': role,
      },
      parse: (_) => null,
    );
    AuthSession.instance.profileEnsured = true;
    // Search index sync must not block login / profile open.
    unawaited(() async {
      try {
        await SearchApi().upsertUser(
          UpsertUserIndexRequest(
            authUserId: authUserId,
            username: username,
            fullName: username,
            role: role,
          ),
        );
      } catch (_) {}
    }());
  }

  /// Ensures then returns the signed-in user's profile.
  Future<UserProfile> getMe({bool ensureIfMissing = true}) async {
    final cached = MemoryCache.get<UserProfile>(_meKey);
    if (cached != null) return cached;
    try {
      final me = await _getMeOnce();
      MemoryCache.set(_meKey, me, ttl: const Duration(minutes: 2));
      AuthSession.instance.profileEnsured = true;
      return me;
    } on ApiException catch (e) {
      if (!ensureIfMissing || e.statusCode != 404) rethrow;
      final session = AuthSession.instance;
      final userId = session.userId;
      if (userId == null || userId.isEmpty) rethrow;
      await ensureProfile(
        authUserId: userId,
        username: session.username,
        email: session.email,
        role: 'user',
      );
      final me = await _getMeOnce();
      MemoryCache.set(_meKey, me, ttl: const Duration(minutes: 2));
      return me;
    }
  }

  Future<UserProfile> _getMeOnce() async {
    final envelope = await _client.get<UserProfile>(
      ApiConfig.profileBaseUrl,
      '/api/users/me',
      parse: (raw) => UserProfile.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'Profile not found');
    }
    return data;
  }

  Future<UserProfile> getByAuthUserId(String authUserId) async {
    final envelope = await _client.get<UserProfile>(
      ApiConfig.profileBaseUrl,
      '/api/users/$authUserId',
      parse: (raw) => UserProfile.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'User not found');
    }
    return data;
  }

  Future<UserProfile> getByUsername(String username) async {
    final envelope = await _client.get<UserProfile>(
      ApiConfig.profileBaseUrl,
      '/api/users/$username',
      parse: (raw) => UserProfile.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'User not found');
    }
    return data;
  }

  Future<UserProfile> updateProfile(UpdateProfileRequest request) async {
    final envelope = await _client.put<UserProfile>(
      ApiConfig.profileBaseUrl,
      '/api/profile',
      body: request.toJson(),
      parse: (raw) => UserProfile.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'Could not update profile');
    }
    MemoryCache.set(_meKey, data, ttl: const Duration(minutes: 2));
    unawaited(_syncUserIndex(data));
    return data;
  }

  Future<UserProfile> patchProfile(UpdateProfileRequest request) async {
    final envelope = await _client.patch<UserProfile>(
      ApiConfig.profileBaseUrl,
      '/api/profile',
      body: request.toJson(),
      parse: (raw) => UserProfile.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'Could not update profile');
    }
    MemoryCache.set(_meKey, data, ttl: const Duration(minutes: 2));
    unawaited(_syncUserIndex(data));
    return data;
  }

  Future<void> _syncUserIndex(UserProfile data) async {
    try {
      await SearchApi().upsertUser(
        UpsertUserIndexRequest(
          authUserId: data.authUserId,
          username: data.username,
          fullName: data.fullName,
          avatar: data.avatar,
          bio: data.bio,
          role: data.role,
          interests: data.interests,
          followersCount: data.followersCount,
          followingCount: data.followingCount,
        ),
      );
    } catch (_) {}
  }

  Future<String> uploadAvatar(
    Uint8List bytes, {
    String filename = 'avatar.png',
  }) async {
    final formData = FormData();
    formData.files.add(MapEntry(
      'file',
      MultipartFile.fromBytes(bytes, filename: filename),
    ));
    final envelope = await _client.upload<String>(
      ApiConfig.profileBaseUrl,
      '/api/users/me/avatar',
      formData: formData,
      parse: (raw) => raw?.toString() ?? '',
    );
    final url = envelope.data?.trim() ?? '';
    if (url.isEmpty) {
      throw ApiException(envelope.message ?? 'Avatar upload failed');
    }
    return url;
  }

  /// Uploads the profile cover banner and returns the new cover_image URL.
  /// Mirrors [uploadAvatar]; the response nests the url under `cover_image`.
  Future<String> uploadCover(
    Uint8List bytes, {
    String filename = 'cover.jpg',
  }) async {
    final formData = FormData();
    formData.files.add(MapEntry(
      'file',
      MultipartFile.fromBytes(bytes, filename: filename),
    ));
    final envelope = await _client.upload<String>(
      ApiConfig.profileBaseUrl,
      '/api/users/me/cover',
      formData: formData,
      parse: (raw) {
        if (raw is Map) {
          final url = raw['cover_image'] ?? raw['coverImage'] ?? raw['url'];
          if (url is String) return url;
        }
        return raw?.toString() ?? '';
      },
    );
    final url = envelope.data?.trim() ?? '';
    if (url.isEmpty) {
      throw ApiException(envelope.message ?? 'Cover upload failed');
    }
    MemoryCache.invalidate(_meKey);
    return url;
  }

  Future<void> deleteCover() async {
    await _client.delete<Object?>(
      ApiConfig.profileBaseUrl,
      '/api/users/me/cover',
      parse: (_) => null,
    );
    MemoryCache.invalidate(_meKey);
  }

  Future<List<ProfileListUser>> followers({String? authUserId}) async {
    final path = authUserId == null || authUserId.isEmpty
        ? '/api/users/followers'
        : '/api/users/$authUserId/followers';
    return _listUsers(path);
  }

  Future<List<ProfileListUser>> following({String? authUserId}) async {
    final path = authUserId == null || authUserId.isEmpty
        ? '/api/users/following'
        : '/api/users/$authUserId/following';
    return _listUsers(path);
  }

  Future<List<ProfileListUser>> blockedList() =>
      _listUsers('/api/users/blocked-list');

  Future<FollowToggleResult> toggleFollow(String targetAuthUserId) async {
    final envelope = await _client.post<FollowToggleResult>(
      ApiConfig.profileBaseUrl,
      '/api/users/$targetAuthUserId/follow',
      parse: (raw) => FollowToggleResult.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'Follow failed');
    }
    MemoryCache.invalidate(_meKey);
    final me = AuthSession.instance.userId;
    if (me != null && me.isNotEmpty) {
      unawaited(() async {
        try {
          await SearchApi().syncFollow(
            SyncFollowRequest(
              followerId: me,
              followingId: targetAuthUserId,
              isFollowing: data.isFollowing,
            ),
          );
        } catch (_) {}
      }());
    }
    return data;
  }

  Future<BlockToggleResult> block(String targetAuthUserId) async {
    final envelope = await _client.post<BlockToggleResult>(
      ApiConfig.profileBaseUrl,
      '/api/users/$targetAuthUserId/block',
      parse: (raw) => BlockToggleResult.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'Block failed');
    }
    return data;
  }

  Future<BlockToggleResult> unblock(String targetAuthUserId) async {
    final envelope = await _client.post<BlockToggleResult>(
      ApiConfig.profileBaseUrl,
      '/api/users/$targetAuthUserId/unblock',
      parse: (raw) => BlockToggleResult.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'Unblock failed');
    }
    return data;
  }

  /// Pending follow requests sent to me (private-account approvals).
  Future<List<ProfileListUser>> followRequests() =>
      _listUsers('/api/users/follow-requests');

  Future<void> acceptFollowRequest(String requesterAuthUserId) async {
    final envelope = await _client.post<Object?>(
      ApiConfig.profileBaseUrl,
      '/api/users/follow-requests/$requesterAuthUserId/accept',
      parse: (_) => null,
    );
    if (!envelope.success) {
      throw ApiException(envelope.message ?? 'Could not accept request');
    }
  }

  Future<void> rejectFollowRequest(String requesterAuthUserId) async {
    final envelope = await _client.post<Object?>(
      ApiConfig.profileBaseUrl,
      '/api/users/follow-requests/$requesterAuthUserId/reject',
      parse: (_) => null,
    );
    if (!envelope.success) {
      throw ApiException(envelope.message ?? 'Could not reject request');
    }
  }

  Future<List<ProfileListUser>> _listUsers(String path) async {
    final envelope = await _client.get<List<ProfileListUser>>(
      ApiConfig.profileBaseUrl,
      path,
      parse: (raw) {
        if (raw is! List) return <ProfileListUser>[];
        return raw
            .whereType<Map>()
            .map((e) => ProfileListUser.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      },
    );
    return envelope.data ?? const [];
  }
}
