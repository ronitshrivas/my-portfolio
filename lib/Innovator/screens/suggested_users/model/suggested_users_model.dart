class SuggestionResponse {
  final int total;
  final List<SuggestedUser> suggestions;

  const SuggestionResponse({required this.total, required this.suggestions});

  factory SuggestionResponse.fromJson(Map<String, dynamic> json) {
    return SuggestionResponse(
      total: json['total'] as int? ?? 0,
      suggestions:
          (json['suggestions'] as List<dynamic>?)
              ?.map(
                (item) => SuggestedUser.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'total': total,
    'suggestions': suggestions.map((e) => e.toJson()).toList(),
  };

  @override
  String toString() =>
      'SuggestionResponse(total: $total, suggestions: $suggestions)';
}

class SuggestedUser {
  final String userId;
  final String username;
  final String fullName;
  final String? avatar;
  final String? bio;
  final bool isFollowing;
  final bool followsMe;
  final int mutualCount;
  final int affinityScore;
  final List<String> sharedTags;
  final String reason;

  const SuggestedUser({
    required this.userId,
    required this.username,
    required this.fullName,
    this.avatar,
    this.bio,
    required this.isFollowing,
    required this.followsMe,
    required this.mutualCount,
    required this.affinityScore,
    required this.sharedTags,
    required this.reason,
  });

  factory SuggestedUser.fromJson(Map<String, dynamic> json) {
    return SuggestedUser(
      userId: json['user_id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      avatar: json['avatar'] as String?,
      bio: json['bio'] as String?,
      isFollowing: json['is_following'] as bool? ?? false,
      followsMe: json['follows_me'] as bool? ?? false,
      mutualCount: json['mutual_count'] as int? ?? 0,
      affinityScore: json['affinity_score'] as int? ?? 0,
      sharedTags:
          (json['shared_tags'] as List<dynamic>?)
              ?.map((tag) => tag as String)
              .toList() ??
          [],
      reason: json['reason'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'username': username,
    'full_name': fullName,
    'avatar': avatar,
    'bio': bio,
    'is_following': isFollowing,
    'mutual_count': mutualCount,
    'affinity_score': affinityScore,
    'shared_tags': sharedTags,
    'reason': reason,
  };

  String get displayName => fullName.isNotEmpty ? fullName : username;

  bool get hasAvatar => avatar != null && avatar!.isNotEmpty;

  @override
  String toString() =>
      'SuggestedUser(userId: $userId, username: $username, '
      'fullName: $fullName, mutualCount: $mutualCount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuggestedUser &&
          runtimeType == other.runtimeType &&
          userId == other.userId;

  @override
  int get hashCode => userId.hashCode;
}
