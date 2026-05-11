import 'package:hive/hive.dart';

part 'cached_feed_item.g.dart';

@HiveType(typeId: 0)
class CachedFeedItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String authorId;

  @HiveField(2)
  final String authorName;

  @HiveField(3)
  final String authorAvatar;

  @HiveField(4)
  String status;

  @HiveField(5)
  final String type;

  @HiveField(6)
  final List<String> mediaUrls;

  @HiveField(7)
  int likes;

  @HiveField(8)
  bool isLiked;

  @HiveField(9)
  int comments;

  @HiveField(10)
  bool isFollowed;

  @HiveField(11)
  final String createdAt; // stored as ISO8601 string

  @HiveField(12)
  final bool isReel;

  @HiveField(13)
  final String? sharedPostId;

  @HiveField(14)
  final String? thumbnailUrl;

  @HiveField(15)
  String? currentUserReaction;

  @HiveField(16)
  final String savedAt; // when we cached this item

  CachedFeedItem({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorAvatar,
    required this.status,
    required this.type,
    required this.mediaUrls,
    required this.likes,
    required this.isLiked,
    required this.comments,
    required this.isFollowed,
    required this.createdAt,
    required this.isReel,
    this.sharedPostId,
    this.thumbnailUrl,
    this.currentUserReaction,
    required this.savedAt,
  });
}
