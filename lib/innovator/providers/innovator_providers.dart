import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:innovator/core/cache/hive_cache.dart';
import 'package:innovator/innovator/data/models/feed_models.dart';
import 'package:innovator/innovator/data/sources/auth_api.dart';
import 'package:innovator/innovator/data/sources/chat_api.dart';
import 'package:innovator/innovator/data/sources/feed_api.dart';
import 'package:innovator/innovator/data/sources/profile_api.dart';
import 'package:innovator/innovator/data/sources/search_api.dart';
import 'package:innovator/innovator/data/models/profile_models.dart';
import 'package:innovator/innovator/data/models/search_models.dart';

/// ── Data sources ──────────────────────────────────────────────────────────
/// One instance each, shared across the app via Riverpod.

final feedApiProvider = Provider<FeedApi>((_) => FeedApi());
final profileApiProvider = Provider<ProfileApi>((_) => ProfileApi());
final chatApiProvider = Provider<ChatApi>((_) => ChatApi());
final searchApiProvider = Provider<SearchApi>((_) => SearchApi());
final authApiProvider = Provider<AuthApi>((_) => AuthApi());

/// Hive box for the Innovator feature (feed/profile snapshots for instant load).
final innovatorCacheProvider = FutureProvider<HiveCache>(
  (_) => HiveCache.open('innovator'),
);

/// ── Feed ──────────────────────────────────────────────────────────────────

/// Paginated feed loader with Hive-backed instant first paint.
class FeedController extends StateNotifier<AsyncValue<List<FeedPostDto>>> {
  FeedController(this._api, this._cache) : super(const AsyncValue.loading()) {
    _hydrateFromCache();
    refresh();
  }

  final FeedApi _api;
  final HiveCache? _cache;

  static const _cacheKey = 'feed.page1';
  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;
  final List<FeedPostDto> _items = [];

  bool get hasMore => _hasMore;

  void _hydrateFromCache() {
    final raw = _cache?.peek<List>(_cacheKey);
    if (raw == null) return;
    try {
      final cached = raw
          .whereType<Map>()
          .map((e) => FeedPostDto.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      if (cached.isNotEmpty) {
        _items
          ..clear()
          ..addAll(cached);
        state = AsyncValue.data(List.unmodifiable(_items));
      }
    } catch (_) {
      /* ignore malformed cache */
    }
  }

  Future<void> refresh() async {
    _page = 1;
    _hasMore = true;
    try {
      final pageData = await _api.getFeed(page: 1);
      _items
        ..clear()
        ..addAll(pageData.results);
      _hasMore = pageData.hasMore;
      state = AsyncValue.data(List.unmodifiable(_items));
      _cache?.put(_cacheKey, pageData.results.map((e) => e.toJson()).toList());
    } catch (e, st) {
      if (_items.isEmpty) state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore) return;
    _loadingMore = true;
    try {
      final next = await _api.getFeed(page: _page + 1);
      if (next.results.isNotEmpty) {
        _page += 1;
        _items.addAll(next.results);
        state = AsyncValue.data(List.unmodifiable(_items));
      }
      _hasMore = next.hasMore;
    } catch (_) {
      /* keep current items */
    } finally {
      _loadingMore = false;
    }
  }
}

final feedControllerProvider =
    StateNotifierProvider<FeedController, AsyncValue<List<FeedPostDto>>>((ref) {
      final api = ref.watch(feedApiProvider);
      final cache = ref.watch(innovatorCacheProvider).valueOrNull;
      return FeedController(api, cache);
    });

/// Feed categories, cached in memory by the api layer.
final feedCategoriesProvider = FutureProvider<List<FeedCategory>>((ref) {
  return ref.watch(feedApiProvider).categories();
});

/// ── Profile ───────────────────────────────────────────────────────────────

/// Current user's profile — instant from Hive, then refreshed from the server.
final myProfileProvider = FutureProvider<UserProfile>((ref) async {
  final api = ref.watch(profileApiProvider);
  final cache = ref.watch(innovatorCacheProvider).valueOrNull;

  final fresh = await api.getMe();
  cache?.put('profile.me', fresh.toJson());
  return fresh;
});

/// Any user's profile by auth id (for the "specific profile" screen).
final userProfileProvider = FutureProvider.family<UserProfile, String>((
  ref,
  authUserId,
) {
  return ref.watch(profileApiProvider).getByAuthUserId(authUserId);
});

/// A user's posts (personal feed shown on the profile page).
final userPostsProvider = FutureProvider.family<List<FeedPostDto>, String>((
  ref,
  authUserId,
) async {
  final page = await ref.watch(feedApiProvider).postsByAuthor(authUserId);
  return page.results;
});

/// ── Notifications ─────────────────────────────────────────────────────────

final notificationsProvider = FutureProvider<List<FeedNotification>>((ref) {
  return ref.watch(feedApiProvider).notifications();
});

/// ── Search ────────────────────────────────────────────────────────────────

final userSearchProvider = FutureProvider.family<List<SearchUserHit>, String>((
  ref,
  query,
) {
  if (query.trim().isEmpty) return Future.value(const []);
  return ref.watch(searchApiProvider).searchUsers(query.trim());
});

final suggestedUsersProvider = FutureProvider<List<SearchUserHit>>((ref) {
  return ref.watch(searchApiProvider).suggestedUsers();
});
