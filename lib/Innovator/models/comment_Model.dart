// comment_Model.dart
import 'package:innovator/Innovator/constant/api_constants.dart';

// ✅ Top-level — outside the class
String _resolveAvatarUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  return '${ApiConstants.userBase}${path.startsWith('/') ? '' : '/'}$path';
}

class Comment {
  final String id;
  final String username;
  final String? avatar;
  final String postId;
  final String? parentId;
  final String? reel;
  final String content;
  final DateTime createdAt;
  final bool isReel;
  final int replyCount;
  List<Comment> replies;

  Comment({
    required this.id,
    required this.username,
    this.avatar,
    required this.postId,
    this.parentId,
    this.reel,
    required this.content,
    required this.createdAt,
    this.isReel = false,
    this.replyCount = 0,
    this.replies = const [],
  });

  bool get isReply => parentId != null;

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? 'Unknown',
      avatar: _resolveAvatarUrl(json['avatar']?.toString()),
      postId: json['post']?.toString() ?? '',
      parentId: json['parent']?.toString(),
      reel: json['reel'] ?? '',
      content: json['content']?.toString() ?? '',
      replyCount:
          (json['reply_count'] ?? json['replies_count'] ?? json['replies'] ?? 0)
              as int,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'avatar': avatar,
    'post': postId,
    'parent': parentId,
    'content': content,
    'reel': reel,
    'created_at': createdAt.toIso8601String(),
  };
}
