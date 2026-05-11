import 'dart:developer';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:innovator/Innovator/hive/cached_feed_item.dart';
import 'package:innovator/Innovator/models/Feed_Content_Model.dart';

class FeedCacheService {
  static const String _boxName = 'feed_cache';
  static const int maxCachedItems = 20;

  static FeedCacheService? _instance;
  FeedCacheService._();
  static FeedCacheService get instance => _instance ??= FeedCacheService._();

  Box<CachedFeedItem>? _box;

  // Call this once in main() after Hive.initFlutter()
  Future<void> init() async {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(CachedFeedItemAdapter());
    }
    _box = await Hive.openBox<CachedFeedItem>(_boxName);
    log('[FeedCache] Box opened. Cached items: ${_box!.length}');
  }

  Box<CachedFeedItem> get box {
    if (_box == null || !_box!.isOpen) {
      throw StateError('Feed cache box not open. Call init() first.');
    }
    return _box!;
  }

  // ── Save up to 20 posts from a fresh API response ─────────────────────────
  Future<void> saveFeed(List<FeedContent> contents) async {
    try {
      final toSave = contents.take(maxCachedItems).toList();
      await box.clear(); // always replace — no merging
      final now = DateTime.now().toIso8601String();
      final items = toSave.map((c) => _fromFeedContent(c, now)).toList();
      // putAll is one write — much faster than looping put()
      await box.putAll({for (int i = 0; i < items.length; i++) i: items[i]});
      log('[FeedCache] Saved ${items.length} posts');
    } catch (e) {
      log('[FeedCache] saveFeed error: $e');
    }
  }

  // ── Load cached posts (returns empty list if nothing cached) ──────────────
  List<FeedContent> loadFeed() {
    try {
      if (box.isEmpty) return [];
      final items = box.values.toList();
      final result = items.map(_toFeedContent).toList();
      log('[FeedCache] Loaded ${result.length} cached posts');
      return result;
    } catch (e) {
      log('[FeedCache] loadFeed error: $e');
      return [];
    }
  }

  // ── Update a single post's like state (called when user taps like) ────────
  Future<void> updateLike(
    String postId,
    bool isLiked,
    int newLikeCount,
    String? reactionType,
  ) async {
    try {
      for (final key in box.keys) {
        final item = box.get(key);
        if (item != null && item.id == postId) {
          item.isLiked = isLiked;
          item.likes = newLikeCount;
          item.currentUserReaction = reactionType;
          await item.save(); // HiveObject.save() updates in place
          log('[FeedCache] Like updated for $postId');
          break;
        }
      }
    } catch (e) {
      log('[FeedCache] updateLike error: $e');
    }
  }

  // ── Update comment count ──────────────────────────────────────────────────
  Future<void> updateCommentCount(String postId, int delta) async {
    try {
      for (final key in box.keys) {
        final item = box.get(key);
        if (item != null && item.id == postId) {
          item.comments = (item.comments + delta).clamp(0, 999999);
          await item.save();
          break;
        }
      }
    } catch (e) {
      log('[FeedCache] updateCommentCount error: $e');
    }
  }

  // ── Remove a post (called after delete) ──────────────────────────────────
  Future<void> removePost(String postId) async {
    try {
      dynamic targetKey;
      for (final key in box.keys) {
        if (box.get(key)?.id == postId) {
          targetKey = key;
          break;
        }
      }
      if (targetKey != null) await box.delete(targetKey);
    } catch (e) {
      log('[FeedCache] removePost error: $e');
    }
  }

  // ── Update post content (after edit) ─────────────────────────────────────
  Future<void> updatePostStatus(String postId, String newStatus) async {
    try {
      for (final key in box.keys) {
        final item = box.get(key);
        if (item != null && item.id == postId) {
          item.status = newStatus;
          await item.save();
          break;
        }
      }
    } catch (e) {
      log('[FeedCache] updatePostStatus error: $e');
    }
  }

  bool get hasCachedFeed => box.isNotEmpty;

  // ── Converters ────────────────────────────────────────────────────────────
  CachedFeedItem _fromFeedContent(FeedContent c, String savedAt) {
    return CachedFeedItem(
      id: c.id,
      authorId: c.author.id,
      authorName: c.author.name,
      authorAvatar: c.author.picture,
      status: c.status,
      type: c.type,
      mediaUrls: List<String>.from(c.mediaUrls),
      likes: c.likes,
      isLiked: c.isLiked,
      comments: c.comments,
      isFollowed: c.isFollowed,
      createdAt: c.createdAt.toIso8601String(),
      isReel: c.isReel,
      sharedPostId: c.sharedPostId,
      thumbnailUrl: c.thumbnailUrl,
      currentUserReaction: c.currentUserReaction,
      savedAt: savedAt,
    );
  }

  FeedContent _toFeedContent(CachedFeedItem item) {
    final author = Author(
      id: item.authorId,
      name: item.authorName,
      picture: item.authorAvatar,
      email: '',
    );
    return FeedContent(
      id: item.id,
      author: author,
      status: item.status,
      description: item.status,
      type: item.type,
      files: List<String>.from(item.mediaUrls),
      mediaUrls: List<String>.from(item.mediaUrls),
      optimizedFiles: const [],
      thumbnailUrl: item.thumbnailUrl,
      likes: item.likes,
      isLiked: item.isLiked,
      currentUserReaction: item.currentUserReaction,
      comments: item.comments,
      isFollowed: item.isFollowed,
      createdAt: DateTime.tryParse(item.createdAt) ?? DateTime.now(),
      isReel: item.isReel,
      sharedPostId: item.sharedPostId,
    );
  }
}
