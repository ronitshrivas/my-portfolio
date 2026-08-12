import 'dart:developer' as developer;

import 'package:innovator/core/config/api_config.dart';

/// Feed media is served by the feed service (8012). The backend sometimes
/// embeds an absolute URL pointing at the dead gateway (8005) or returns a
/// relative path; normalise both onto the live feed host so images load
/// instead of falling back to a black placeholder.
String resolveFeedMediaUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  const feedHost = ApiConfig.feedBaseUrl; // http://36.253.137.34:8012
  String result;
  if (path.startsWith('http://') || path.startsWith('https://')) {
    final uri = Uri.tryParse(path);
    if (uri != null && uri.host == '36.253.137.34' && uri.port != 8012) {
      final tail = uri.path.startsWith('/') ? uri.path : '/${uri.path}';
      final query = uri.hasQuery ? '?${uri.query}' : '';
      result = '$feedHost$tail$query';
    } else {
      result = path;
    }
  } else {
    result = '$feedHost${path.startsWith('/') ? '' : '/'}$path';
  }
  developer.log('[FeedMedia] raw="$path"  ->  resolved="$result"');
  return result;
}

/// Avatars are served by the profile service (8011). Prefix relative paths and
/// rewrite any wrong-host absolute URL so author avatars load.
String? _resolveAvatar(String? path) {
  if (path == null || path.isEmpty) return null;
  const profileHost = ApiConfig.profileBaseUrl; // http://36.253.137.34:8011
  if (path.startsWith('http://') || path.startsWith('https://')) {
    final uri = Uri.tryParse(path);
    if (uri != null &&
        (uri.host == 'localhost' ||
            (uri.host == '36.253.137.34' && uri.port != 8011))) {
      final tail = uri.path.startsWith('/') ? uri.path : '/${uri.path}';
      return '$profileHost$tail';
    }
    return path;
  }
  return '$profileHost${path.startsWith('/') ? '' : '/'}$path';
}

class FeedMediaItem {
  const FeedMediaItem({
    required this.id,
    required this.file,
    this.mediaType,
    this.thumbnail,
  });

  final String id;
  final String file;
  final String? mediaType;
  final String? thumbnail;

  bool get isVideo {
    final type = (mediaType ?? '').toLowerCase();
    if (type.contains('video')) return true;
    final path = file.toLowerCase().split('?').first;
    return path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.webm') ||
        path.endsWith('.m4v') ||
        path.endsWith('.avi');
  }

  factory FeedMediaItem.fromJson(Map<String, dynamic> json) {
    return FeedMediaItem(
      id: json['id']?.toString() ?? '',
      file: resolveFeedMediaUrl(json['file']?.toString()),
      mediaType:
          (json['media_type'] ?? json['mediaType'] ?? json['type'])?.toString(),
      thumbnail:
          json['thumbnail'] != null
              ? resolveFeedMediaUrl(json['thumbnail'].toString())
              : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'file': file,
    'media_type': mediaType,
    'thumbnail': thumbnail,
  };
}

class FeedCategory {
  const FeedCategory({required this.id, required this.name, this.description});

  final String id;
  final String name;
  final String? description;

  factory FeedCategory.fromJson(Map<String, dynamic> json) {
    return FeedCategory(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
  };
}

class FeedPostDto {
  const FeedPostDto({
    required this.id,
    required this.userId,
    this.username,
    this.avatar,
    this.occupation,
    this.content,
    this.type,
    this.isReel = false,
    this.media = const [],
    this.categories = const [],
    this.reactionsCount = 0,
    this.commentsCount = 0,
    this.shareCount = 0,
    this.viewsCount = 0,
    this.currentUserReactions = const [],
    this.isFollowed = false,
    this.followStatus = 'none',
    this.sharedPostId,
    this.sharedPost,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String? username;
  final String? avatar;
  final String? occupation;
  final String? content;
  final String? type;
  final bool isReel;
  final List<FeedMediaItem> media;
  final List<FeedCategory> categories;
  final int reactionsCount;
  final int commentsCount;
  final int shareCount;
  final int viewsCount;
  final List<String> currentUserReactions;
  final bool isFollowed;

  /// Follow state for private accounts: none | pending | accepted.
  final String followStatus;
  final String? sharedPostId;
  final FeedPostDto? sharedPost;
  final DateTime? createdAt;

  String get displayAuthor {
    final u = username?.trim();
    if (u != null && u.isNotEmpty) return u;
    return 'Innovator';
  }

  bool get likedByMe {
    final r =
        currentUserReactions
            .map((e) => e.toLowerCase())
            .where((e) => e.isNotEmpty)
            .toSet();
    return r.contains('like') || r.contains('love');
  }

  FeedPostDto copyWith({
    int? reactionsCount,
    int? commentsCount,
    int? shareCount,
    String? followStatus,
    List<String>? currentUserReactions,
    bool clearReaction = false,
    bool? isFollowed,
  }) {
    return FeedPostDto(
      id: id,
      userId: userId,
      username: username,
      avatar: avatar,
      occupation: occupation,
      content: content,
      type: type,
      isReel: isReel,
      media: media,
      categories: categories,
      reactionsCount: reactionsCount ?? this.reactionsCount,
      commentsCount: commentsCount ?? this.commentsCount,
      shareCount: shareCount ?? this.shareCount,
      viewsCount: viewsCount,
      currentUserReactions:
          clearReaction
              ? const []
              : (currentUserReactions ?? this.currentUserReactions),
      isFollowed: isFollowed ?? this.isFollowed,
      followStatus: followStatus ?? this.followStatus,
      sharedPostId: sharedPostId,
      sharedPost: sharedPost,
      createdAt: createdAt,
    );
  }

  /// Snake-case JSON matching [fromJson], used for Hive caching.
  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'username': username,
    'avatar': avatar,
    'occupation': occupation,
    'content': content,
    'type': type,
    'is_reel': isReel,
    'media': media.map((m) => m.toJson()).toList(),
    'categories_detail': categories.map((c) => c.toJson()).toList(),
    'reactions_count': reactionsCount,
    'comments_count': commentsCount,
    'share_count': shareCount,
    'views_count': viewsCount,
    'current_user_reaction': currentUserReactions,
    'is_followed': isFollowed,
    'shared_post': sharedPostId,
    if (sharedPost != null) 'shared_post_details': sharedPost!.toJson(),
    'created_at': createdAt?.toIso8601String(),
  };

  factory FeedPostDto.fromJson(Map<String, dynamic> json) {
    final shared = json['shared_post_details'] ?? json['shared_post'];
    return FeedPostDto(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      username: json['username'] as String?,
      avatar: _resolveAvatar(
        (json['avatar'] ??
                json['user_avatar'] ??
                json['author_avatar'] ??
                json['profile_picture'])
            ?.toString(),
      ),
      occupation: json['occupation'] as String?,
      content: json['content'] as String?,
      type: json['type'] as String?,
      isReel: json['is_reel'] == true,
      media:
          json['media'] is List
              ? (json['media'] as List)
                  .whereType<Map>()
                  .map(
                    (e) => FeedMediaItem.fromJson(Map<String, dynamic>.from(e)),
                  )
                  .toList()
              : const [],
      categories:
          json['categories_detail'] is List
              ? (json['categories_detail'] as List)
                  .whereType<Map>()
                  .map(
                    (e) => FeedCategory.fromJson(Map<String, dynamic>.from(e)),
                  )
                  .toList()
              : const [],
      reactionsCount: (json['reactions_count'] as num?)?.toInt() ?? 0,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
      shareCount: (json['share_count'] as num?)?.toInt() ?? 0,
      viewsCount: (json['views_count'] as num?)?.toInt() ?? 0,
      currentUserReactions: () {
        final currentUserReactions = <String>[];
        final currentReactionValue = json['current_user_reaction'];
        if (currentReactionValue is String) {
          currentUserReactions.add(currentReactionValue);
        } else if (currentReactionValue is Iterable) {
          currentUserReactions.addAll(
            currentReactionValue
                .where((e) => e != null)
                .map((e) => e.toString()),
          );
        }
        return currentUserReactions;
      }(),
      isFollowed: json['is_followed'] == true,
      followStatus: () {
        final raw = (json['follow_status'] as String?)?.trim();
        if (raw != null && raw.isNotEmpty) return raw;
        return json['is_followed'] == true ? 'accepted' : 'none';
      }(),
      sharedPostId:
          json['shared_post'] is String
              ? json['shared_post'] as String
              : json['shared_post']?.toString(),
      sharedPost:
          shared is Map
              ? FeedPostDto.fromJson(Map<String, dynamic>.from(shared))
              : null,
      createdAt:
          json['created_at'] is String
              ? DateTime.tryParse(json['created_at'] as String)
              : null,
    );
  }
}

class FeedPage {
  const FeedPage({
    required this.results,
    this.count = 0,
    this.next,
    this.previous,
  });

  final List<FeedPostDto> results;
  final int count;
  final String? next;
  final String? previous;

  bool get hasMore => next != null && next!.isNotEmpty;

  factory FeedPage.fromJson(Map<String, dynamic> json) {
    return FeedPage(
      results:
          json['results'] is List
              ? (json['results'] as List)
                  .whereType<Map>()
                  .map(
                    (e) => FeedPostDto.fromJson(Map<String, dynamic>.from(e)),
                  )
                  .toList()
              : const [],
      count: (json['count'] as num?)?.toInt() ?? 0,
      next: json['next'] as String?,
      previous: json['previous'] as String?,
    );
  }
}

class FeedComment {
  const FeedComment({
    required this.id,
    this.userId,
    this.username,
    this.avatar,
    this.postId,
    this.parentId,
    this.content,
    this.replyCount = 0,
    this.createdAt,
  });

  final String id;

  /// Auth user id of the commenter — used to open their profile.
  final String? userId;
  final String? username;
  final String? avatar;
  final String? postId;
  final String? parentId;
  final String? content;
  final int replyCount;
  final DateTime? createdAt;

  factory FeedComment.fromJson(Map<String, dynamic> json) {
    return FeedComment(
      id: json['id']?.toString() ?? '',
      userId: (json['user_id'] ?? json['user'])?.toString(),
      username: json['username'] as String?,
      avatar: _resolveAvatar(json['avatar']?.toString()),
      postId: json['post']?.toString(),
      parentId: json['parent']?.toString(),
      content: json['content'] as String?,
      replyCount: (json['reply_count'] as num?)?.toInt() ?? 0,
      createdAt:
          json['created_at'] is String
              ? DateTime.tryParse(json['created_at'] as String)
              : null,
    );
  }
}

class FeedReaction {
  const FeedReaction({
    required this.id,
    required this.postId,
    this.userId,
    this.username,
    this.avatar,
    this.type,
    this.createdAt,
  });

  final String id;
  final String postId;

  /// Reactor identity (new fields) — used to show avatar/name and open profile.
  final String? userId;
  final String? username;
  final String? avatar;
  final String? type;
  final DateTime? createdAt;

  factory FeedReaction.fromJson(Map<String, dynamic> json) {
    return FeedReaction(
      id: json['id']?.toString() ?? '',
      postId: json['post']?.toString() ?? '',
      userId: (json['user_id'] ?? json['user'])?.toString(),
      username: json['username'] as String?,
      avatar: _resolveAvatar(json['avatar']?.toString()),
      type: json['type'] as String?,
      createdAt:
          json['created_at'] is String
              ? DateTime.tryParse(json['created_at'] as String)
              : null,
    );
  }
}

class FeedNotification {
  const FeedNotification({
    required this.id,
    this.title,
    this.message,
    this.type,
    this.senderId,
    this.senderUsername,
    this.senderAvatar,
    this.relatedPostId,
    this.isRead = false,
    this.createdAt,
  });

  final String id;
  final String? title;
  final String? message;
  final String? type;
  final String? senderId;
  final String? senderUsername;
  final String? senderAvatar;
  final String? relatedPostId;
  final bool isRead;
  final DateTime? createdAt;

  factory FeedNotification.fromJson(Map<String, dynamic> json) {
    return FeedNotification(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String?,
      message: json['message'] as String? ?? json['body'] as String?,
      type: json['type'] as String?,
      senderId: json['sender_id']?.toString(),
      senderUsername: json['sender_username'] as String?,
      senderAvatar: json['sender_avatar'] as String?,
      relatedPostId: json['related_post_id']?.toString(),
      isRead: json['is_read'] == true || json['read'] == true,
      createdAt:
          json['created_at'] is String
              ? DateTime.tryParse(json['created_at'] as String)
              : null,
    );
  }
}

String formatFeedTime(DateTime? createdAt) {
  if (createdAt == null) return '';
  final diff = DateTime.now().toUtc().difference(createdAt.toUtc());
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${createdAt.month}/${createdAt.day}';
}
