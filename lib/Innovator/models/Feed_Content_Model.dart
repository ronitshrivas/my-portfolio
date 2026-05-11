const String _kBaseUrl = 'http://36.253.137.34:8005';

String _resolveUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  return '$_kBaseUrl${path.startsWith('/') ? '' : '/'}$path';
}

class SharedPostMedia {
  final String id;
  final String file;
  final String mediaType;

  const SharedPostMedia({
    required this.id,
    required this.file,
    required this.mediaType,
  });

  factory SharedPostMedia.fromJson(Map<String, dynamic> j) => SharedPostMedia(
    id: j['id']?.toString() ?? '',
    file: _resolveUrl(j['file']?.toString()),
    mediaType: j['media_type']?.toString() ?? 'image',
  );

  bool get isImage => mediaType == 'image';
  bool get isVideo => mediaType == 'video';
}

// ─────────────────────────────────────────────────────────────────────────────
// SharedPostDetails  — the embedded original post shown in a repost card
// ─────────────────────────────────────────────────────────────────────────────

class SharedPostDetails {
  final String id;
  final String username;
  final String fullName;
  final String? avatar; // may be null from API
  final String content;
  final DateTime createdAt;
  final List<SharedPostMedia> media;

  const SharedPostDetails({
    required this.id,
    required this.username,
    required this.fullName,
    this.avatar,
    required this.content,
    required this.createdAt,
    required this.media,
  });

  factory SharedPostDetails.fromJson(Map<String, dynamic> j) {
    final rawMedia = j['media'] as List<dynamic>? ?? [];
    return SharedPostDetails(
      id: j['id']?.toString() ?? '',
      username: j['username']?.toString() ?? '',
      fullName: j['full_name']?.toString() ?? j['username']?.toString() ?? '',
      avatar:
          j['avatar'] != null && j['avatar'].toString().isNotEmpty
              ? _resolveUrl(j['avatar'].toString())
              : null,
      content: j['content']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(j['created_at']?.toString() ?? '') ??
          DateTime.now(),
      media:
          rawMedia
              .whereType<Map<String, dynamic>>()
              .map(SharedPostMedia.fromJson)
              .toList(),
    );
  }

  bool get hasMedia => media.isNotEmpty;
  String? get firstImageUrl =>
      media.where((m) => m.isImage).map((m) => m.file).firstOrNull;
}

// ─────────────────────────────────────────────────────────────────────────────
// Author
// ─────────────────────────────────────────────────────────────────────────────

class Author {
  final String id;
  final String name;
  final String picture;
  final String email;

  Author({
    required this.id,
    required this.name,
    required this.picture,
    required this.email,
  });

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      name:
          json['name']?.toString() ?? json['username']?.toString() ?? 'Unknown',
      picture: json['picture']?.toString() ?? json['avatar']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    '_id': id,
    'name': name,
    'picture': picture,
    'email': email,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// FeedContent
// ─────────────────────────────────────────────────────────────────────────────

class FeedContent {
  final String id;
  final Author author;
  String status;
  String description;
  final String type;
  final List<String> files;
  final List<String> mediaUrls;
  final List<Map<String, dynamic>> optimizedFiles;
  final String? thumbnailUrl;
  int likes;
  bool isLiked;
  String? currentUserReaction;
  int comments;
  bool isFollowed;
  final DateTime createdAt;
  final List<String> tags;
  final List<Map<String, dynamic>> categoriesDetail;
  final List<String> reactionTypes;

  // ── Repost fields ──────────────────────────────────────────────────────────
  /// Non-null when this post IS a repost (has `shared_post` field)
  final String? sharedPostId;
  final SharedPostDetails? sharedPostDetails;
  final bool isReel;
  bool get isRepost => sharedPostId != null && sharedPostId!.isNotEmpty;

  FeedContent({
    required this.id,
    required this.author,
    required this.status,
    required this.description,
    required this.type,
    required this.files,
    required this.mediaUrls,
    required this.optimizedFiles,
    this.thumbnailUrl,
    required this.likes,
    required this.isLiked,
    this.currentUserReaction,
    required this.comments,
    required this.isFollowed,
    required this.createdAt,
    this.tags = const [],
    this.categoriesDetail = const [],
    this.reactionTypes = const [],
    this.sharedPostId,
    this.sharedPostDetails,
    this.isReel = false,
  });

  // ── Legacy factory ─────────────────────────────────────────────────────────
  factory FeedContent.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('user_id') || json.containsKey('username')) {
      return FeedContent.fromNewApiPost(json);
    }

    final author = Author.fromJson(
      json['author'] is Map<String, dynamic>
          ? json['author'] as Map<String, dynamic>
          : <String, dynamic>{},
    );

    final rawFiles = json['files'] as List<dynamic>? ?? [];
    final files =
        rawFiles.whereType<String>().where((f) => f.isNotEmpty).toList();

    final rawMedia = json['mediaUrls'] as List<dynamic>? ?? [];
    final mediaUrls =
        rawMedia.whereType<String>().where((u) => u.isNotEmpty).toList();

    final rawOpt = json['optimizedFiles'] as List<dynamic>? ?? [];
    final optimizedFiles = rawOpt.whereType<Map<String, dynamic>>().toList();

    final rawReactions = json['reactionTypes'] as List<dynamic>? ?? [];
    final reactionTypes = rawReactions.whereType<String>().toList();

    return FeedContent(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      author: author,
      status: json['status']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      type: json['type']?.toString() ?? 'post',
      files: files,
      mediaUrls: mediaUrls,
      optimizedFiles: optimizedFiles,
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] == true,
      comments: (json['comments_count'] as num?)?.toInt() ?? 0,
      isFollowed: json['isFollowed'] == true,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      tags:
          (json['tags'] as List<dynamic>?)?.map((t) => t.toString()).toList() ??
          [],
      categoriesDetail: const [],
      reactionTypes: reactionTypes,
    );
  }

  // ── New API factory ────────────────────────────────────────────────────────
  factory FeedContent.fromNewApiPost(Map<String, dynamic> post) {
    final id = post['id']?.toString() ?? '';
    final userId = post['user_id']?.toString() ?? '';
    final username = post['username']?.toString() ?? 'Unknown';
    final avatar =
        post['avatar'] != null ? _resolveUrl(post['avatar'].toString()) : '';
    final content =
        post['content']?.toString() ?? post['caption']?.toString() ?? '';
    // ── Categories ──────────────────────────────────────────────────────────
    final rawCategories = post['categories_detail'] as List<dynamic>? ?? [];
    final categoriesDetail =
        rawCategories.whereType<Map<String, dynamic>>().toList();
    final categoryNames =
        categoriesDetail
            .map((c) => c['name']?.toString() ?? '')
            .where((n) => n.isNotEmpty)
            .toList();

    // ── Reactions ───────────────────────────────────────────────────────────
    final reactCount =
        (post['reactions_count'] as num?)?.toInt() ??
        (post['like_count'] as num?)?.toInt() ??
        0;
    final isLiked = post['current_user_reaction'] != null;
    final currentUserReaction = post['current_user_reaction']?.toString();
    final commentCount = (post['comments_count'] as num?)?.toInt() ?? 0;
    final isFollowed =
        post['is_followed'] == true || post['isFollowed'] == true;

    final createdAt =
        DateTime.tryParse(post['created_at']?.toString() ?? '') ??
        DateTime.now();

    final type =
        post['type']?.toString() ??
        (categoryNames.isNotEmpty ? categoryNames.first : 'post');
    final author = Author(
      id: userId,
      name: username,
      picture: avatar,
      email: '',
    );

    // ── Media (own post media) ───────────────────────────────────────────────
    final files = <String>[];
    final rawMedia = post['media'];
    if (rawMedia is List) {
      for (final m in rawMedia) {
        if (m is Map) {
          final fileUrl = _resolveUrl(m['file']?.toString());
          if (fileUrl.isNotEmpty) files.add(fileUrl);
        }
      }
    }
    // Handle reel video field
    final videoUrl = post['video']?.toString();
    if (videoUrl != null && videoUrl.isNotEmpty) {
      files.add(_resolveUrl(videoUrl));
    }

    // ── Reaction types ───────────────────────────────────────────────────────
    final rawReactions = post['reaction_types'];
    final reactionTypes =
        rawReactions is List
            ? rawReactions.whereType<String>().toList()
            : <String>[];

    // ── Repost fields ────────────────────────────────────────────────────────
    final sharedPostId = post['shared_post']?.toString();
    SharedPostDetails? sharedPostDetails;
    final rawShared = post['shared_post_details'];
    if (rawShared is Map<String, dynamic>) {
      sharedPostDetails = SharedPostDetails.fromJson(rawShared);
    }

    return FeedContent(
      id: id,
      author: author,
      status: content,
      description: content,
      type: type,
      files: files,
      mediaUrls: List<String>.from(files),
      optimizedFiles: const [],
      thumbnailUrl:
          post['thumbnail'] != null
              ? _resolveUrl(post['thumbnail'].toString())
              : null,
      likes: reactCount,
      isLiked: isLiked,
      currentUserReaction: currentUserReaction,
      comments: commentCount,
      isFollowed: isFollowed,
      createdAt: createdAt,
      tags: List<String>.from(categoryNames),
      categoriesDetail: categoriesDetail,
      reactionTypes: reactionTypes,
      sharedPostId: sharedPostId,
      sharedPostDetails: sharedPostDetails,
      isReel: post['type']?.toString() == 'reel',
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String formatUrl(String? path) => _resolveUrl(path);

  Map<String, dynamic> toJson() => {
    '_id': id,
    'author': author.toJson(),
    'status': status,
    'description': description,
    'type': type,
    'files': files,
    'mediaUrls': mediaUrls,
    'optimizedFiles': optimizedFiles,
    'thumbnailUrl': thumbnailUrl,
    'likes': likes,
    'isLiked': isLiked,
    'comments_count': comments,
    'isFollowed': isFollowed,
    'createdAt': createdAt.toIso8601String(),
    'tags': tags,
    'categoriesDetail': categoriesDetail,
    if (sharedPostId != null) 'shared_post': sharedPostId,
  };
}
