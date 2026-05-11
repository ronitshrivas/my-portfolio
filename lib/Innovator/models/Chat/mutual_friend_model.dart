class MutualFriend {
  final String id;
  final String username;
  final String fullName;
  final String avatar;
  final bool onlineStatus;
  final int unreadCount;
  final DateTime lastMessageAt; // ← ADD

  MutualFriend({
    required this.id,
    required this.username,
    required this.fullName,
    required this.avatar,
    required this.onlineStatus,
    this.unreadCount = 0,
    DateTime? lastMessageAt, // ← ADD
  }) : lastMessageAt = lastMessageAt ?? DateTime(2000); // ← ADD

  factory MutualFriend.fromJson(Map<String, dynamic> json) => MutualFriend(
    id: json['id']?.toString() ?? '',
    username: json['username']?.toString() ?? '',
    fullName: json['full_name']?.toString() ?? '',
    avatar: json['avatar']?.toString() ?? '',
    onlineStatus: json['online_status'] == true,
    lastMessageAt:
        json['last_message_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
              json['last_message_at'] * 1000,
            )
            : DateTime(2000), // ← ADD
  );

  MutualFriend copyWithUnread(int count) => MutualFriend(
    id: id,
    username: username,
    fullName: fullName,
    avatar: avatar,
    onlineStatus: onlineStatus,
    unreadCount: count,
    lastMessageAt: lastMessageAt, // ← ADD
  );

  // ← ADD THIS METHOD
  MutualFriend copyWithLastMessageAt(DateTime t) => MutualFriend(
    id: id,
    username: username,
    fullName: fullName,
    avatar: avatar,
    onlineStatus: onlineStatus,
    unreadCount: unreadCount,
    lastMessageAt: t,
  );

  String get displayName => fullName.isNotEmpty ? fullName : username;
  String get initial =>
      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
}
