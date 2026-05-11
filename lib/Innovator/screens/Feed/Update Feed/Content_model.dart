// Content_model.dart
// Maps the new API post shape from GET/PATCH /api/posts/<id>/
// Response fields: id, username, avatar, content, media[], category_names[],
//                  reactions_count, current_user_reaction, comments_count,
//                  created_at, updated_at

import 'dart:io';

class ContentMedia {
  final String id;
  final String fileUrl; // absolute URL
  final String mediaType; // "image" | "video"

  const ContentMedia({
    required this.id,
    required this.fileUrl,
    required this.mediaType,
  });

  factory ContentMedia.fromJson(Map<String, dynamic> json) => ContentMedia(
    id: json['id']?.toString() ?? '',
    fileUrl: json['file']?.toString() ?? '',
    mediaType: json['media_type']?.toString() ?? 'image',
  );

  bool get isImage => mediaType == 'image';
  bool get isVideo => mediaType == 'video';
}

class ContentModel {
  final String id;
  String content; // editable — maps to "content" field
  final String username; // author
  final String? avatar;
  final List<ContentMedia> media;
  final List<String> categoryNames;
  int reactionsCount;
  String? currentUserReaction;
  int commentsCount;
  final DateTime createdAt;
  DateTime updatedAt;

  // Local-only: new media file picked by the user before uploading
  File? pendingMediaFile;

  ContentModel({
    required this.id,
    required this.content,
    required this.username,
    this.avatar,
    this.media = const [],
    this.categoryNames = const [],
    this.reactionsCount = 0,
    this.currentUserReaction,
    this.commentsCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.pendingMediaFile,
  });

  bool get hasMedia => media.isNotEmpty;
  bool get isLiked => currentUserReaction != null;

  factory ContentModel.fromJson(Map<String, dynamic> json) {
    final rawMedia = json['media'] as List<dynamic>? ?? [];
    final media =
        rawMedia
            .whereType<Map<String, dynamic>>()
            .map(ContentMedia.fromJson)
            .toList();

    final rawCategories = json['category_names'] as List<dynamic>? ?? [];
    final categories = rawCategories.map((c) => c.toString()).toList();

    return ContentModel(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      media: media,
      categoryNames: categories,
      reactionsCount: (json['reactions_count'] as num?)?.toInt() ?? 0,
      currentUserReaction: json['current_user_reaction']?.toString(),
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'username': username,
    'avatar': avatar,
    'media':
        media
            .map(
              (m) => {'id': m.id, 'file': m.fileUrl, 'media_type': m.mediaType},
            )
            .toList(),
    'category_names': categoryNames,
    'reactions_count': reactionsCount,
    'current_user_reaction': currentUserReaction,
    'comments_count': commentsCount,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  /// Returns a shallow copy with updated fields.
  ContentModel copyWith({
    String? content,
    List<ContentMedia>? media,
    int? reactionsCount,
    String? currentUserReaction,
    int? commentsCount,
    File? pendingMediaFile,
  }) => ContentModel(
    id: id,
    content: content ?? this.content,
    username: username,
    avatar: avatar,
    media: media ?? this.media,
    categoryNames: categoryNames,
    reactionsCount: reactionsCount ?? this.reactionsCount,
    currentUserReaction: currentUserReaction ?? this.currentUserReaction,
    commentsCount: commentsCount ?? this.commentsCount,
    createdAt: createdAt,
    updatedAt: updatedAt,
    pendingMediaFile: pendingMediaFile ?? this.pendingMediaFile,
  );
}
