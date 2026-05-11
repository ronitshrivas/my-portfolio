import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/constant/api_constants.dart';

class UserController extends GetxController {
  static UserController get to => Get.find();
  final Rx<String?> profilePicture = Rx<String?>(null);
  final Rx<String?> userName = Rx<String?>(null);
  RxInt profilePictureVersion = 0.obs;
  final Map<String, _UserEntry> _cache = {};
  final Set<String> _prefetched = {};
  static const Duration _ttl = Duration(hours: 2);
  static const int _maxEntries = 500;
  static const int _evictCount = 50;

  @override
  void onInit() {
    super.onInit();
    _syncFromAppData();
    Timer.periodic(const Duration(minutes: 30), (_) => _evictExpired());
  }

  void _syncFromAppData() {
    final user = AppData().currentUser;
    if (user == null) return;
    final avatar =
        user['avatar']?.toString() ?? // new API flat
        user['photo_url']?.toString() ?? // after upload
        (user['profile'] as Map?)?['avatar']?.toString() ?? // nested
        user['picture']?.toString(); // legacy

    if (avatar != null && avatar.isNotEmpty) {
      profilePicture.value = _toAbsolute(avatar);
    }

    userName.value =
        user['username']?.toString() ?? // new API
        user['full_name']?.toString() ?? // new API profile
        user['name']?.toString(); // legacy
  }

  // ── Current-user helpers ─────────────────────────────────────────────────

  void updateProfilePicture(String newPath) {
    profilePicture.value = newPath;
    profilePictureVersion.value++;
    update();
  }

  void updateUserName(String? newName) => userName.value = newName;

  /// Absolute URL for the current user's avatar.
  /// Returns null only if the user genuinely has no avatar set.
  String? getFullProfilePicturePath() {
    final pic = profilePicture.value;
    if (pic == null || pic.isEmpty) {
      // Last resort: re-read from AppData in case onInit ran before login saved
      _syncFromAppData();
      final retried = profilePicture.value;
      if (retried == null || retried.isEmpty) return null;
      return _toAbsolute(retried);
    }
    return _toAbsolute(pic);
  }

  // ── Phase 1 — bulk cache from feed response ──────────────────────────────

  /// Called once per page of posts inside ContentData.fromNewFeedApi.
  /// Stores every author's avatar + name with O(1) cost per post.
  void cacheFromFeedPosts(List<Map<String, dynamic>> posts) {
    if (posts.isEmpty) return;
    _maybeEvict();
    for (final post in posts) {
      final userId = post['user_id']?.toString() ?? '';
      if (userId.isEmpty) continue;
      if (_cache.containsKey(userId)) continue; // already cached — skip

      final avatar = post['avatar']?.toString() ?? '';
      final name = post['username']?.toString() ?? '';
      _cache[userId] = _UserEntry(
        avatarUrl: avatar.isNotEmpty ? _toAbsolute(avatar) : null,
        name: name,
        ts: DateTime.now(),
      );
    }
  }

  // ── Backward-compatible single-entry cache ───────────────────────────────

  /// Cache a single user (called from _buildAuthorAvatar on first render).
  void cacheUserProfilePicture(
    String userId,
    String? pictureUrl,
    String? name,
  ) {
    if (userId.isEmpty) return;
    _maybeEvict();
    final existing = _cache[userId];
    // Only write if we have new data or the entry is missing
    if (existing != null &&
        existing.avatarUrl != null &&
        (pictureUrl == null || pictureUrl.isEmpty)) {
      // Already have a picture — just refresh timestamp
      _cache[userId] = existing.copyWithTs(DateTime.now());
      return;
    }
    _cache[userId] = _UserEntry(
      avatarUrl:
          (pictureUrl != null && pictureUrl.isNotEmpty)
              ? _toAbsolute(pictureUrl)
              : null,
      name: name ?? '',
      ts: DateTime.now(),
    );
  }

  /// Bulk cache from follower/following user list objects.
  void bulkCacheUsers(List<Map<String, dynamic>> users) {
    _maybeEvict();
    for (final u in users) {
      final id = (u['_id'] ?? u['id'] ?? u['user_id'])?.toString() ?? '';
      if (id.isEmpty) continue;
      final pic = (u['picture'] ?? u['avatar'])?.toString() ?? '';
      final name = (u['name'] ?? u['username'])?.toString() ?? '';
      if (!_cache.containsKey(id)) {
        _cache[id] = _UserEntry(
          avatarUrl: pic.isNotEmpty ? _toAbsolute(pic) : null,
          name: name,
          ts: DateTime.now(),
        );
      }
    }
  }

  // ── Phase 2 — parallel prefetch ──────────────────────────────────────────

  /// Fire-and-forget parallel image prefetch for the first visible avatars.
  /// Call this after setState() — it runs off the UI thread via Future.wait.
  void prefetchAvatars(List<String> userIds, BuildContext context) {
    final toPrefetch =
        userIds
            .where((id) => !_prefetched.contains(id) && _avatarUrl(id) != null)
            .take(15)
            .toList();

    if (toPrefetch.isEmpty) return;

    // Fire all precacheImage calls in parallel — Instagram does the same
    Future.wait(
      toPrefetch.map((id) async {
        final url = _avatarUrl(id);
        if (url == null) return;
        try {
          await precacheImage(CachedNetworkImageProvider(url), context);
          _prefetched.add(id);
        } catch (_) {} // silently ignore network errors
      }),
    );
  }

  // ── Phase 3 — read helpers ───────────────────────────────────────────────

  /// Absolute avatar URL for another user (null if not cached / no avatar).
  String? getOtherUserFullProfilePicturePath(String userId) =>
      _avatarUrl(userId);

  /// Display name for another user.
  String? getOtherUserName(String userId) {
    final e = _entry(userId);
    return (e?.name.isNotEmpty == true) ? e!.name : null;
  }

  /// True if we have a valid cache entry for [userId].
  bool isUserCached(String userId) {
    final e = _cache[userId];
    if (e == null) return false;
    if (DateTime.now().difference(e.ts) > _ttl) {
      _cache.remove(userId);
      return false;
    }
    return true;
  }

  void clearOtherUsersCache() {
    _cache.clear();
    _prefetched.clear();
  }

  Map<String, dynamic> getCacheStats() => {
    'totalCached': _cache.length,
    'prefetched': _prefetched.length,
    'maxEntries': _maxEntries,
    'ttlHours': _ttl.inHours,
  };

  // ── Backward compat — kept so existing call sites don't break ────────────

  /// Kept for call sites that still pass user-ids for preloading.
  Future<void> preloadVisibleUsers(
    List<String> userIds,
    BuildContext context,
  ) async {
    prefetchAvatars(userIds, context);
  }

  // ── Private helpers ──────────────────────────────────────────────────────

  _UserEntry? _entry(String userId) {
    final e = _cache[userId];
    if (e == null) return null;
    if (DateTime.now().difference(e.ts) > _ttl) {
      _cache.remove(userId);
      return null;
    }
    return e;
  }

  String? _avatarUrl(String userId) => _entry(userId)?.avatarUrl;

  /// Ensures the URL is absolute. New API already serves absolute URLs;
  /// this just future-proofs against relative paths.
  String _toAbsolute(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '${ApiConstants.userBase}${url.startsWith('/') ? url : '/$url'}';
  }

  void _maybeEvict() {
    if (_cache.length <= _maxEntries) return;
    // Evict the _evictCount oldest entries
    final sorted =
        _cache.entries.toList()
          ..sort((a, b) => a.value.ts.compareTo(b.value.ts));
    for (final e in sorted.take(_evictCount)) {
      _cache.remove(e.key);
    }
  }

  void _evictExpired() {
    final now = DateTime.now();
    _cache.removeWhere((_, v) => now.difference(v.ts) > _ttl);
  }
}

// ── Internal data class ───────────────────────────────────────────────────────
class _UserEntry {
  final String? avatarUrl; // always absolute
  final String name;
  final DateTime ts;

  const _UserEntry({
    required this.avatarUrl,
    required this.name,
    required this.ts,
  });

  _UserEntry copyWithTs(DateTime newTs) =>
      _UserEntry(avatarUrl: avatarUrl, name: name, ts: newTs);
}
