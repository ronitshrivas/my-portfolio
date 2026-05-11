import 'package:innovator/Innovator/models/Feed_Content_Model.dart';

class RepostEntry {
  final String id;
  final String userId;
  final String username;
  final String avatar;
  final String content; // reposter's caption
  final int reactionsCount;
  final int commentsCount;
  final int viewsCount;
  final DateTime createdAt;
  final SharedPostDetails? sharedPostDetails;

  const RepostEntry({
    required this.id,
    required this.userId,
    required this.username,
    required this.avatar,
    required this.content,
    required this.reactionsCount,
    required this.commentsCount,
    required this.viewsCount,
    required this.createdAt,
    this.sharedPostDetails,
  });

  factory RepostEntry.fromJson(Map<String, dynamic> j) {
    SharedPostDetails? details;
    final rawShared = j['shared_post_details'];
    if (rawShared is Map<String, dynamic>) {
      details = SharedPostDetails.fromJson(rawShared);
    }
    return RepostEntry(
      id: j['id']?.toString() ?? '',
      userId: j['user_id']?.toString() ?? '',
      username: j['username']?.toString() ?? '',
      avatar: j['avatar']?.toString() ?? '',
      content: j['content']?.toString() ?? '',
      reactionsCount: (j['reactions_count'] as num?)?.toInt() ?? 0,
      commentsCount: (j['comments_count'] as num?)?.toInt() ?? 0,
      viewsCount: (j['views_count'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse(j['created_at']?.toString() ?? '') ??
          DateTime.now(),
      sharedPostDetails: details,
    );
  }
}
