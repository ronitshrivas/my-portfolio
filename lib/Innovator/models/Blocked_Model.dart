class BlockedUser {
  final String id;
  final String username;
  final String? fullName;
  final String email;
  final String role;
  final String? avatar;
  final int followersCount;
  final int followingCount;
  final String? bio;
  final String? occupation;
  final String? education;

  BlockedUser({
    required this.id,
    required this.username,
    this.fullName,
    required this.email,
    required this.role,
    this.avatar,
    required this.followersCount,
    required this.followingCount,
    this.bio,
    this.occupation,
    this.education,
  });

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>?;
    return BlockedUser(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      fullName: json['full_name'],
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      avatar: profile?['avatar'],
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
      bio: profile?['bio'],
      occupation: profile?['occupation'],
      education: profile?['education'],
    );
  }

  String get displayName =>
      (fullName != null && fullName!.isNotEmpty) ? fullName! : username;

  String get avatarUrl {
    if (avatar == null || avatar!.isEmpty) return '';
    if (avatar!.startsWith('http')) return avatar!;
    return 'http://36.253.137.34:8005$avatar';
  }
}
