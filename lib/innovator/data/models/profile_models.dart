import 'package:innovator/core/config/api_config.dart';

List<String> _stringList(Object? raw) => raw is List
    ? raw.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList()
    : const [];

/// Avatars are served by the profile service (8011). Prefix relative paths and
/// rewrite wrong-host absolute URLs so list avatars actually load.
String? resolveProfileAvatar(String? path) {
  final raw = path?.trim();
  if (raw == null || raw.isEmpty) return null;
  const host = ApiConfig.profileBaseUrl;
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    final uri = Uri.tryParse(raw);
    if (uri != null &&
        (uri.host == 'localhost' ||
            (uri.host == '36.253.137.34' && uri.port != 8011))) {
      final tail = uri.path.startsWith('/') ? uri.path : '/${uri.path}';
      return '$host$tail';
    }
    return raw;
  }
  return '$host${raw.startsWith('/') ? '' : '/'}$raw';
}

/// A labelled external link on a profile (LinkedIn, portfolio, etc.).
class ProfileLink {
  const ProfileLink({this.label, this.url});

  final String? label;
  final String? url;

  factory ProfileLink.fromJson(Map<String, dynamic> json) => ProfileLink(
        label: json['label'] as String?,
        url: json['url'] as String?,
      );

  Map<String, dynamic> toJson() => {'label': label, 'url': url};
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.authUserId,
    this.username,
    this.fullName,
    this.email,
    this.role,
    this.bio,
    this.avatar,
    this.coverImage,
    this.dateOfBirth,
    this.phone,
    this.gender,
    this.address,
    this.education,
    this.occupation,
    this.interests = const [],
    this.educations = const [],
    this.occupations = const [],
    this.links = const [],
    this.followersCount = 0,
    this.followingCount = 0,
    this.isFollowed = false,
    this.createdAt,
  });

  final String id;
  final String authUserId;
  final String? username;
  final String? fullName;
  final String? email;
  final String? role;
  final String? bio;
  final String? avatar;

  /// Wide banner image at the top of the profile (full URL or null).
  final String? coverImage;
  final String? dateOfBirth;
  final String? phone;
  final String? gender;
  final String? address;
  final String? education;
  final String? occupation;
  final List<String> interests;

  /// Multiple entries (new backend); singular [education]/[occupation] kept
  /// for backward compatibility.
  final List<String> educations;
  final List<String> occupations;
  final List<ProfileLink> links;

  final int followersCount;
  final int followingCount;
  final bool isFollowed;
  final DateTime? createdAt;

  /// All education entries, merging the singular field with the list.
  List<String> get allEducations => _merge(education, educations);
  List<String> get allOccupations => _merge(occupation, occupations);

  static List<String> _merge(String? single, List<String> many) {
    final out = <String>[];
    final s = single?.trim();
    if (s != null && s.isNotEmpty) out.add(s);
    for (final m in many) {
      final t = m.trim();
      if (t.isNotEmpty && !out.contains(t)) out.add(t);
    }
    return out;
  }

  String get displayName {
    final full = fullName?.trim();
    if (full != null && full.isNotEmpty) return full;
    final user = username?.trim();
    if (user != null && user.isNotEmpty) return user;
    return 'Innovator';
  }

  UserProfile copyWith({
    String? fullName,
    String? bio,
    String? avatar,
    String? coverImage,
    String? occupation,
    int? followersCount,
    int? followingCount,
    bool? isFollowed,
  }) {
    return UserProfile(
      id: id,
      authUserId: authUserId,
      username: username,
      fullName: fullName ?? this.fullName,
      email: email,
      role: role,
      bio: bio ?? this.bio,
      avatar: avatar ?? this.avatar,
      coverImage: coverImage ?? this.coverImage,
      dateOfBirth: dateOfBirth,
      phone: phone,
      gender: gender,
      address: address,
      education: education,
      occupation: occupation ?? this.occupation,
      interests: interests,
      educations: educations,
      occupations: occupations,
      links: links,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isFollowed: isFollowed ?? this.isFollowed,
      createdAt: createdAt,
    );
  }

  /// Snake-case JSON matching [fromJson], used for Hive caching.
  Map<String, dynamic> toJson() => {
        'id': id,
        'auth_user_id': authUserId,
        'username': username,
        'full_name': fullName,
        'email': email,
        'role': role,
        'bio': bio,
        'avatar': avatar,
        'cover_image': coverImage,
        'date_of_birth': dateOfBirth,
        'phone': phone,
        'gender': gender,
        'address': address,
        'education': education,
        'occupation': occupation,
        'interests': interests,
        'educations': educations,
        'occupations': occupations,
        'links': links.map((l) => l.toJson()).toList(),
        'followers_count': followersCount,
        'following_count': followingCount,
        'is_followed': isFollowed,
        'created_at': createdAt?.toIso8601String(),
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final rawInterests = json['interests'];
    return UserProfile(
      id: json['id'] as String? ?? '',
      authUserId: json['auth_user_id'] as String? ?? '',
      username: json['username'] as String?,
      fullName: json['full_name'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String?,
      bio: json['bio'] as String?,
      avatar: resolveProfileAvatar(json['avatar'] as String?),
      coverImage: resolveProfileAvatar(json['cover_image'] as String?),
      dateOfBirth: json['date_of_birth'] as String?,
      phone: json['phone'] as String?,
      gender: json['gender'] as String?,
      address: json['address'] as String?,
      education: json['education'] as String?,
      occupation: json['occupation'] as String?,
      interests: _stringList(rawInterests),
      educations: _stringList(json['educations']),
      occupations: _stringList(json['occupations']),
      links: json['links'] is List
          ? (json['links'] as List)
              .whereType<Map>()
              .map((e) => ProfileLink.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      followersCount: (json['followers_count'] as num?)?.toInt() ?? 0,
      followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
      isFollowed: json['is_followed'] == true,
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }
}

class ProfileListUser {
  const ProfileListUser({
    required this.id,
    this.username,
    this.fullName,
    this.avatar,
    this.role,
    this.occupation,
    this.isFollowed = false,
  });

  /// Auth user id (used by follow/block endpoints).
  final String id;
  final String? username;
  final String? fullName;
  final String? avatar;
  final String? role;
  final String? occupation;
  final bool isFollowed;

  String get displayName {
    final full = fullName?.trim();
    if (full != null && full.isNotEmpty) return full;
    final user = username?.trim();
    if (user != null && user.isNotEmpty) return user;
    return 'User';
  }

  ProfileListUser copyWith({bool? isFollowed}) {
    return ProfileListUser(
      id: id,
      username: username,
      fullName: fullName,
      avatar: avatar,
      role: role,
      occupation: occupation,
      isFollowed: isFollowed ?? this.isFollowed,
    );
  }

  factory ProfileListUser.fromJson(Map<String, dynamic> json) {
    return ProfileListUser(
      id: json['id'] as String? ?? '',
      username: json['username'] as String?,
      fullName: json['full_name'] as String?,
      avatar: resolveProfileAvatar(json['avatar'] as String?),
      role: json['role'] as String?,
      occupation: (json['occupation'] as String?)?.trim(),
      isFollowed: json['is_followed'] == true,
    );
  }
}

/// A "Suggested for you" person from `GET /api/users/suggested`.
class SuggestedUser {
  const SuggestedUser({
    required this.id,
    this.username,
    this.fullName,
    this.avatar,
    this.occupation,
    this.mutualCount = 0,
    this.reason,
    this.followStatus = 'none',
  });

  /// Auth user id (used by follow / dismiss / profile-open).
  final String id;
  final String? username;
  final String? fullName;
  final String? avatar;
  final String? occupation;
  final int mutualCount;
  final String? reason;

  /// Local follow state: none | pending | accepted.
  final String followStatus;

  bool get isFollowing => followStatus == 'accepted';
  bool get isPending => followStatus == 'pending';

  String get displayName {
    final full = fullName?.trim();
    if (full != null && full.isNotEmpty) return full;
    final user = username?.trim();
    if (user != null && user.isNotEmpty) return '@$user';
    return 'User';
  }

  SuggestedUser copyWith({String? followStatus}) {
    return SuggestedUser(
      id: id,
      username: username,
      fullName: fullName,
      avatar: avatar,
      occupation: occupation,
      mutualCount: mutualCount,
      reason: reason,
      followStatus: followStatus ?? this.followStatus,
    );
  }

  factory SuggestedUser.fromJson(Map<String, dynamic> json) {
    return SuggestedUser(
      id: json['id'] as String? ?? '',
      username: json['username'] as String?,
      fullName: json['full_name'] as String?,
      avatar: resolveProfileAvatar(json['avatar'] as String?),
      occupation: (json['occupation'] as String?)?.trim(),
      mutualCount: (json['mutual_count'] as num?)?.toInt() ?? 0,
      reason: (json['reason'] as String?)?.trim(),
    );
  }
}

class FollowToggleResult {
  const FollowToggleResult({
    required this.isFollowing,
    this.message,
    this.status = 'none',
  });

  final bool isFollowing;
  final String? message;

  /// Follow state for private accounts: none | pending | accepted.
  final String status;

  bool get isPending => status == 'pending';

  factory FollowToggleResult.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['status'] as String?)?.trim();
    return FollowToggleResult(
      isFollowing: json['is_following'] == true,
      message: json['message'] as String?,
      status: rawStatus == null || rawStatus.isEmpty
          ? (json['is_following'] == true ? 'accepted' : 'none')
          : rawStatus,
    );
  }
}

class BlockToggleResult {
  const BlockToggleResult({
    required this.isBlocked,
    this.message,
  });

  final bool isBlocked;
  final String? message;

  factory BlockToggleResult.fromJson(Map<String, dynamic> json) {
    return BlockToggleResult(
      isBlocked: json['is_blocked'] == true,
      message: json['message'] as String?,
    );
  }
}

class UpdateProfileRequest {
  const UpdateProfileRequest({
    this.fullName,
    this.bio,
    this.dateOfBirth,
    this.phone,
    this.gender,
    this.address,
    this.education,
    this.occupation,
    this.interests,
    this.educations,
    this.occupations,
    this.links,
  });

  final String? fullName;
  final String? bio;
  final String? dateOfBirth;
  final String? phone;
  final String? gender;
  final String? address;
  final String? education;
  final String? occupation;
  final List<String>? interests;
  final List<String>? educations;
  final List<String>? occupations;
  final List<ProfileLink>? links;

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'bio': bio,
        'date_of_birth': dateOfBirth,
        'phone': phone,
        'gender': gender,
        'address': address,
        'education': education,
        'occupation': occupation,
        'interests': interests,
        'educations': educations,
        'occupations': occupations,
        'links': links?.map((l) => l.toJson()).toList(),
      };
}

/// A person in the "Find friends" directory. [headline] is the user's
/// occupation, or their education when no occupation is set.
class FindFriend {
  const FindFriend({
    required this.id,
    required this.username,
    required this.fullName,
    this.avatar,
    this.headline,
    this.followStatus = 'none',
  });

  /// Auth user id — used for follow / opening the profile.
  final String id;
  final String username;
  final String fullName;
  final String? avatar;
  final String? headline;

  /// none | pending | accepted.
  final String followStatus;

  bool get isFollowing => followStatus == 'accepted';
  bool get isPending => followStatus == 'pending';

  String get displayName {
    final full = fullName.trim();
    if (full.isNotEmpty) return full;
    return username.trim().isNotEmpty ? '@${username.trim()}' : 'User';
  }

  FindFriend copyWith({String? followStatus}) => FindFriend(
        id: id,
        username: username,
        fullName: fullName,
        avatar: avatar,
        headline: headline,
        followStatus: followStatus ?? this.followStatus,
      );

  factory FindFriend.fromJson(Map<String, dynamic> json) {
    final rawStatus = (json['follow_status'] as String?)?.trim();
    final isFollowed = json['is_followed'] == true;
    return FindFriend(
      id: (json['id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      fullName: (json['full_name'] ?? '').toString(),
      avatar: (json['avatar'] as String?)?.trim().isNotEmpty == true
          ? (json['avatar'] as String).trim()
          : null,
      headline: (json['headline'] as String?)?.trim().isNotEmpty == true
          ? (json['headline'] as String).trim()
          : null,
      followStatus: (rawStatus == null || rawStatus.isEmpty)
          ? (isFollowed ? 'accepted' : 'none')
          : rawStatus,
    );
  }
}

/// One page of [FindFriend]s plus whether more pages remain.
class FindFriendsPage {
  const FindFriendsPage({
    required this.people,
    required this.page,
    required this.pageSize,
    required this.hasMore,
  });

  final List<FindFriend> people;
  final int page;
  final int pageSize;
  final bool hasMore;

  factory FindFriendsPage.fromJson(Map<String, dynamic> json) {
    final rawPeople = json['people'];
    final people = rawPeople is List
        ? rawPeople
            .whereType<Map>()
            .map((e) => FindFriend.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <FindFriend>[];
    return FindFriendsPage(
      people: people,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['page_size'] as num?)?.toInt() ?? people.length,
      hasMore: json['has_more'] == true,
    );
  }
}
