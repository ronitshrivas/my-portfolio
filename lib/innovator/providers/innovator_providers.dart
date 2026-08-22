import 'dart:async';

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
  // Seed the shared live copy so every screen that watches it updates.
  ref.read(currentUserProvider.notifier).set(fresh);
  return fresh;
});

/// Live, mutable copy of the signed-in user shown across the app (profile
/// header, drawer, feed header). Any screen can push an updated profile via
/// [CurrentUserNotifier.set] after an avatar / cover / profile edit, and every
/// widget watching this provider rebuilds instantly — no manual refresh.
class CurrentUserNotifier extends StateNotifier<UserProfile?> {
  CurrentUserNotifier(this._api, this._cache) : super(null) {
    _hydrate();
  }

  final ProfileApi _api;
  final HiveCache? _cache;

  void _hydrate() {
    final raw = _cache?.peek<Map>('profile.me');
    if (raw == null) return;
    try {
      state = UserProfile.fromJson(Map<String, dynamic>.from(raw));
    } catch (_) {
      /* ignore malformed cache */
    }
  }

  /// Replace the whole profile (after a fetch or full edit).
  void set(UserProfile profile) {
    state = profile;
    _cache?.put('profile.me', profile.toJson());
  }

  /// Fetch the latest from the server and broadcast it.
  Future<void> refresh() async {
    try {
      final fresh = await _api.getMe();
      set(fresh);
    } catch (_) {
      /* keep current */
    }
  }

  /// Patch just the avatar (after upload) so it updates everywhere at once.
  void setAvatar(String? url) {
    final p = state;
    if (p == null) return;
    set(p.copyWith(avatar: url));
  }

  /// Patch just the cover (after upload).
  void setCover(String? url) {
    final p = state;
    if (p == null) return;
    set(p.copyWith(coverImage: url));
  }
}

final currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, UserProfile?>((ref) {
      final api = ref.watch(profileApiProvider);
      final cache = ref.watch(innovatorCacheProvider).valueOrNull;
      return CurrentUserNotifier(api, cache);
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

/// Count of unread notifications, derived from [notificationsProvider]. Drives
/// the badge on the drawer's Notification entry. Refresh by invalidating
/// [notificationsProvider] after marking notifications read.
final notificationUnreadCountProvider = Provider<int>((ref) {
  final async = ref.watch(notificationsProvider);
  return async.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

/// ── Chat unread ───────────────────────────────────────────────────────────

/// Total unread messages across all conversations. Seeded from the API and
/// kept live by the chat UI (bump on incoming socket message, clear on open).
/// Drives the badge on the bottom nav's Chat icon.
class ChatUnreadNotifier extends StateNotifier<int> {
  ChatUnreadNotifier(this._chatApi) : super(0) {
    refresh();
  }

  final ChatApi _chatApi;

  Future<void> refresh() async {
    try {
      final convos = await _chatApi.listConversations();
      state = convos.fold<int>(0, (sum, c) => sum + c.unreadCount);
    } catch (_) {
      // Leave the last known count on failure.
    }
  }

  /// A new incoming message for a conversation the user isn't viewing.
  void increment([int by = 1]) => state = state + by;

  /// The user opened a conversation with [conversationUnread] unread messages.
  void clearFor(int conversationUnread) {
    final next = state - conversationUnread;
    state = next < 0 ? 0 : next;
  }

  void reset() => state = 0;
}

final chatUnreadCountProvider =
    StateNotifierProvider<ChatUnreadNotifier, int>((ref) {
  return ChatUnreadNotifier(ref.watch(chatApiProvider));
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

/// "Suggested for you" people-to-follow row, from ProfileService. Holds the
/// list and lets each card update follow/dismiss without rebuilding the screen.
class SuggestedPeopleNotifier
    extends StateNotifier<AsyncValue<List<SuggestedUser>>> {
  SuggestedPeopleNotifier(this._api) : super(const AsyncValue.loading()) {
    load();
  }

  final ProfileApi _api;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final people = await _api.suggestedUsers(limit: 10);
      state = AsyncValue.data(people);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => load();

  List<SuggestedUser>? get _current => state.valueOrNull;

  void _replace(String id, SuggestedUser Function(SuggestedUser) update) {
    final list = _current;
    if (list == null) return;
    state = AsyncValue.data([
      for (final u in list) u.id == id ? update(u) : u,
    ]);
  }

  /// Follows / unfollows the suggested user; optimistic, reverts on error.
  Future<void> toggleFollow(String id) async {
    final list = _current;
    if (list == null) return;
    final person = list.firstWhere((u) => u.id == id,
        orElse: () => const SuggestedUser(id: ''));
    if (person.id.isEmpty) return;
    final wasStatus = person.followStatus;
    final wasFollowing = person.isFollowing || person.isPending;
    // Optimistic: assume accepted; the server confirms pending/accepted.
    _replace(id, (u) => u.copyWith(followStatus: wasFollowing ? 'none' : 'accepted'));
    try {
      final result = await _api.toggleFollow(id);
      _replace(id, (u) => u.copyWith(followStatus: result.status));
    } catch (_) {
      _replace(id, (u) => u.copyWith(followStatus: wasStatus));
    }
  }

  /// Removes the card immediately and tells the server to hide it 30 days.
  void dismiss(String id) {
    final list = _current;
    if (list == null) return;
    state = AsyncValue.data(list.where((u) => u.id != id).toList());
    unawaited(_api.dismissSuggestion(id));
  }
}

final suggestedPeopleProvider = StateNotifierProvider<SuggestedPeopleNotifier,
    AsyncValue<List<SuggestedUser>>>((ref) {
  return SuggestedPeopleNotifier(ref.watch(profileApiProvider));
});

/// ── Find friends ──────────────────────────────────────────────────────────

/// Immutable view-state for the Find Friends screen: the loaded people, the
/// active search query, and loading / paging flags.
class FindFriendsState {
  const FindFriendsState({
    this.people = const [],
    this.query = '',
    this.loading = true,
    this.loadingMore = false,
    this.hasMore = false,
    this.error,
  });

  final List<FindFriend> people;
  final String query;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final String? error;

  FindFriendsState copyWith({
    List<FindFriend>? people,
    String? query,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return FindFriendsState(
      people: people ?? this.people,
      query: query ?? this.query,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class FindFriendsNotifier extends StateNotifier<FindFriendsState> {
  FindFriendsNotifier(this._api) : super(const FindFriendsState()) {
    refresh();
  }

  final ProfileApi _api;
  int _page = 1;
  int _searchToken = 0;

  /// Loads the first page for the current query (fresh).
  Future<void> refresh() async {
    _page = 1;
    final token = ++_searchToken;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final result = await _api.findFriends(query: state.query, page: 1);
      if (token != _searchToken) return; // superseded by a newer search
      state = state.copyWith(
        people: result.people,
        loading: false,
        hasMore: result.hasMore,
      );
    } catch (_) {
      if (token != _searchToken) return;
      state = state.copyWith(loading: false, error: 'Could not load people');
    }
  }

  /// Debounced-ish search: sets the query and reloads from page 1.
  Future<void> search(String query) async {
    if (query == state.query) return;
    state = state.copyWith(query: query);
    await refresh();
  }

  /// Appends the next page when the user scrolls near the end.
  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore || state.loading) return;
    final token = _searchToken;
    state = state.copyWith(loadingMore: true);
    try {
      final next = _page + 1;
      final result = await _api.findFriends(query: state.query, page: next);
      if (token != _searchToken) return;
      _page = next;
      state = state.copyWith(
        people: [...state.people, ...result.people],
        loadingMore: false,
        hasMore: result.hasMore,
      );
    } catch (_) {
      if (token != _searchToken) return;
      state = state.copyWith(loadingMore: false);
    }
  }

  /// Optimistically toggles follow for [id]; reverts on failure.
  Future<void> toggleFollow(String id) async {
    final idx = state.people.indexWhere((p) => p.id == id);
    if (idx < 0) return;
    final was = state.people[idx].followStatus;
    final optimistic = was == 'accepted' ? 'none' : 'accepted';
    _setStatus(id, optimistic);
    try {
      final result = await _api.toggleFollow(id);
      _setStatus(id, result.status);
    } catch (_) {
      _setStatus(id, was);
    }
  }

  void _setStatus(String id, String status) {
    state = state.copyWith(
      people: [
        for (final p in state.people)
          if (p.id == id) p.copyWith(followStatus: status) else p,
      ],
    );
  }
}

final findFriendsProvider =
    StateNotifierProvider<FindFriendsNotifier, FindFriendsState>((ref) {
  return FindFriendsNotifier(ref.watch(profileApiProvider));
});
