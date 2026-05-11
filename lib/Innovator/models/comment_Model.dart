// comment_Model.dart
// Maps the new API response from http://36.253.137.34:8005/api/comments/

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
  // Replies are loaded separately via /api/replies/ but stored here after fetch
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
    this.replies = const [],
  });

  bool get isReply => parentId != null;

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? 'Unknown',
      avatar: json['avatar']?.toString(),
      postId: json['post']?.toString() ?? '',
      parentId: json['parent']?.toString(),
      reel: json['reel'] ?? '',
      content: json['content']?.toString() ?? '',
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
