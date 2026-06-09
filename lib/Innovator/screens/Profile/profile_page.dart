import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/Authorization/Login.dart';
import 'package:innovator/Innovator/constant/api_constants.dart';
import 'package:innovator/Innovator/constant/app_colors.dart';
import 'package:innovator/Innovator/models/Feed_Content_Model.dart';
import 'package:innovator/Innovator/screens/Feed/Inner_Homepage.dart';
import 'package:innovator/Innovator/screens/Feed/Optimize%20Media/full_screen_image_viewer.dart';
import 'package:innovator/Innovator/screens/Feed/specific_video_feed.dart';
import 'package:innovator/Innovator/screens/Follow/follow_Button.dart';
import 'package:innovator/Innovator/screens/Profile/Edit_Profile.dart';
import 'package:innovator/Innovator/screens/Profile/cv_screen.dart';
import 'package:innovator/Innovator/screens/SHow_Specific_Profile/Show_Specific_Profile.dart';
import 'package:innovator/Innovator/screens/chatrrom/screen/chatlistscreen.dart';
import 'package:innovator/Innovator/utils/Drawer/custom_drawer.dart';
import 'package:innovator/Innovator/widget/Custom_refresh_Indicator.dart';
import 'package:innovator/Innovator/widget/CustomizeFAB.dart';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import 'package:get/get.dart';
import 'package:innovator/Innovator/controllers/user_controller.dart';

class UserProfileData {
  final String id;
  final String username;
  final String fullName;
  final String email;
  final String role;
  final String? bio;
  final String? avatar;
  final String? dateOfBirth;
  final String? phone;
  final String? gender;
  final String? address;
  final String? education;
  final String? occupation;
  final List<String> interests;
  final int followersCount;
  final int followingCount;
  final List<String> followerUsernames;
  final List<String> followingUsernames;
  final DateTime createdAt;
  final List<FeedContent> posts;

  UserProfileData({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
    this.bio,
    this.avatar,
    this.dateOfBirth,
    this.phone,
    this.gender,
    this.address,
    this.education,
    this.occupation,
    required this.interests,
    required this.followersCount,
    required this.followingCount,
    required this.followerUsernames,
    required this.followingUsernames,
    required this.createdAt,
    this.posts = const [],
  });

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>? ?? {};
    final rawPosts = json['posts'] as List<dynamic>? ?? [];
    final posts =
        rawPosts
            .whereType<Map<String, dynamic>>()
            // .map((p) {
            //   try {
            //     return FeedContent.fromNewApiPost(p);
            //   } catch (_) {
            //     return null;
            //   }
            // })
            .map((p) {
              // If the item has a 'video' field, it's a reel
              if (p['video'] != null) p['type'] = 'reel';
              return FeedContent.fromNewApiPost(p);
            })
            .whereType<FeedContent>()
            .toList();

    return UserProfileData(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      bio: profile['bio']?.toString(),
      avatar: profile['avatar']?.toString(),
      dateOfBirth:
          profile['date_of_birth']?.toString() ??
          json['date_of_birth']?.toString(),
      phone:
          profile['phone_number']?.toString() ??
          json['phone_number']?.toString(),
      gender: profile['gender']?.toString() ?? json['gender']?.toString(),
      address: profile['address']?.toString() ?? json['address']?.toString(),
      education: profile['education']?.toString(),
      occupation: profile['occupation']?.toString(),
      interests: List<String>.from(profile['interests'] ?? []),
      followersCount: (json['followers_count'] as num?)?.toInt() ?? 0,
      followingCount: (json['following_count'] as num?)?.toInt() ?? 0,
      followerUsernames: List<String>.from(json['follower_usernames'] ?? []),
      followingUsernames: List<String>.from(json['following_usernames'] ?? []),
      createdAt:
          profile['created_at'] != null
              ? DateTime.parse(profile['created_at'])
              : DateTime.now(),
      posts: posts,
    );
  }

  String? get avatarUrl {
    if (avatar == null || avatar!.isEmpty) return null;
    if (avatar!.startsWith('http://') || avatar!.startsWith('https://')) {
      return avatar;
    }
    return '${ApiConstants.userBase}$avatar';
  }
}

class FollowerFollowing {
  final String id;
  final String name;
  final String email;
  final String? picture;
  final String? username;

  FollowerFollowing({
    required this.id,
    required this.name,
    required this.email,
    this.picture,
    this.username,
  });

  factory FollowerFollowing.fromNewApi(Map<String, dynamic> json) {
    final profile = json['profile'] as Map<String, dynamic>? ?? {};
    final avatar = profile['avatar']?.toString();
    final fullName = json['full_name']?.toString() ?? '';
    final username = json['username']?.toString() ?? '';

    return FollowerFollowing(
      id: json['id']?.toString() ?? '',
      name: fullName.isNotEmpty ? fullName : username,
      email: json['email']?.toString() ?? '',
      picture: avatar,
      username: username,
    );
  }

  String? get fullPictureUrl {
    if (picture == null || picture!.isEmpty) return null;
    if (picture!.startsWith('http://') || picture!.startsWith('https://')) {
      return picture;
    }
    return '${ApiConstants.userBase}$picture';
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}

class UserProfileService {
  static Future<UserProfileData> getUserProfile() async {
    final token = AppData().accessToken;
    if (token == null || token.isEmpty) {
      throw AuthException('No authentication token found');
    }
    final url = Uri.parse(ApiConstants.fetchuserprofile);
    final response = await http.get(url, headers: authHeaders(token));

    if (response.statusCode == 200) {
      return UserProfileData.fromJson(
        json.decode(response.body) as Map<String, dynamic>,
      );
    } else if (response.statusCode == 401) {
      await AppData().clearAuthToken();
      throw AuthException('Authentication token expired or invalid');
    } else {
      throw Exception('Failed to load profile: ${response.statusCode}');
    }
  }

  static Future<String> uploadProfilePicture(File imageFile) async {
    final token = AppData().accessToken;
    if (token == null || token.isEmpty) {
      throw AuthException('No authentication token found');
    }
    final filename = path.basename(imageFile.path);
    final url = Uri.parse(ApiConstants.updateuserprofilepicture);
    final mimeType =
        filename.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';

    var request =
        http.MultipartRequest('POST', url)
          ..headers['authorization'] = 'Bearer $token'
          ..files.add(
            http.MultipartFile(
              'avatar',
              http.ByteStream(imageFile.openRead()),
              await imageFile.length(),
              filename: filename,
              contentType: MediaType.parse(mimeType),
            ),
          );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    log('Avatar upload response [${response.statusCode}]: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final avatarPath =
          data['avatar']?.toString() ??
          data['data']?['avatar']?.toString() ??
          data['data']?['picture']?.toString() ??
          '';
      if (avatarPath.isEmpty) throw Exception('No avatar URL in response');
      return avatarPath;
    } else if (response.statusCode == 401) {
      await AppData().clearAuthToken();
      throw AuthException('Authentication token expired or invalid');
    } else {
      throw Exception('Failed to upload avatar: ${response.statusCode}');
    }
  }

  static Future<List<FollowerFollowing>> getFollowers() async {
    final token = AppData().accessToken;
    if (token == null || token.isEmpty) throw AuthException('No token');
    final response = await http.get(
      Uri.parse(ApiConstants.getfollowers),
      headers: authHeaders(token),
    );
    log('Followers API [${response.statusCode}]: ${response.body}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final list = data['followers'] as List<dynamic>? ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(FollowerFollowing.fromNewApi)
          .toList();
    } else if (response.statusCode == 401) {
      await AppData().clearAuthToken();
      throw AuthException('Authentication token expired or invalid');
    } else {
      throw Exception('Failed to load followers: ${response.statusCode}');
    }
  }

  static Future<List<FollowerFollowing>> getFollowing() async {
    final token = AppData().accessToken;
    if (token == null || token.isEmpty) throw AuthException('No token');
    final response = await http.get(
      Uri.parse(ApiConstants.getfollowing),
      headers: authHeaders(token),
    );
    log('Following API [${response.statusCode}]: ${response.body}');
    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      final list = data['following'] as List<dynamic>? ?? [];
      return list
          .whereType<Map<String, dynamic>>()
          .map(FollowerFollowing.fromNewApi)
          .toList();
    } else if (response.statusCode == 401) {
      await AppData().clearAuthToken();
      throw AuthException('Authentication token expired or invalid');
    } else {
      throw Exception('Failed to load following: ${response.statusCode}');
    }
  }

  static Map<String, String> authHeaders(String token) => {
    'Content-Type': 'application/json',
    'authorization': 'Bearer $token',
  };
}

class SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  const SkeletonBox({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  }) : super(key: key);

  @override
  State<SkeletonBox> createState() => SkeletonBoxState();
}

class SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> animation;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    animation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder:
          (_, __) => Opacity(
            opacity: animation.value,
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: widget.borderRadius,
              ),
            ),
          ),
    );
  }
}

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SkeletonBox(
                    width: 120,
                    height: 120,
                    borderRadius: BorderRadius.all(Radius.circular(60)),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SkeletonBox(width: 140, height: 20),
                      const SizedBox(height: 8),
                      const SkeletonBox(width: 180, height: 14),
                      const SizedBox(height: 12),
                      SkeletonBox(
                        width: 80,
                        height: 26,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(thickness: 0.8, color: Colors.grey[300]),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Column(
                          children: const [
                            SkeletonBox(width: 30, height: 18),
                            SizedBox(height: 4),
                            SkeletonBox(width: 60, height: 12),
                          ],
                        ),
                        const SizedBox(width: 40),
                        Column(
                          children: const [
                            SkeletonBox(width: 30, height: 18),
                            SizedBox(height: 4),
                            SkeletonBox(width: 60, height: 12),
                          ],
                        ),
                      ],
                    ),
                    SkeletonBox(
                      width: 35,
                      height: 35,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SkeletonBox(width: 60, height: 20),
              SkeletonBox(
                width: 90,
                height: 36,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
        ),
        Divider(thickness: 0.8, color: Colors.grey[300]),
        const SizedBox(height: 12),
        ...List.generate(3, (_) => const PostCardSkeleton()),
      ],
    );
  }
}

class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SkeletonBox(
                width: 40,
                height: 40,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 120, height: 11),
                  SizedBox(height: 4),
                  SkeletonBox(width: 80, height: 11),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          SkeletonBox(
            width: double.infinity,
            height: 200,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 10),
          const SkeletonBox(width: double.infinity, height: 13),
          const SizedBox(height: 6),
          const SkeletonBox(width: 220, height: 13),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class UserProfileScreen extends ConsumerStatefulWidget {
  final String userId;
  const UserProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  UserProfileScreenState createState() => UserProfileScreenState();
}

class UserProfileScreenState extends ConsumerState<UserProfileScreen>
    with SingleTickerProviderStateMixin {
  late Future<UserProfileData> profileFuture;
  bool isUploading = false;
  bool isPickingImage = false;
  String? errorMessage;
  bool postsLoaded = false;
  bool isLoading = false;
  List<FeedContent> posts = [];
  late TabController tabController;
  final UserController userController = Get.put(UserController());
  final List<FeedContent> contents = [];
  final ScrollController scrollController = ScrollController();

  late ValueNotifier<({int followers, int following})> countsNotifier;

  @override
  void initState() {
    super.initState();
    tabController = TabController(length: 2, vsync: this);
    countsNotifier = ValueNotifier((followers: 0, following: 0));
    tabController.addListener(_onTabChanged);
    loadProfile();
  }

  void _onTabChanged() {
    if (tabController.indexIsChanging) return;
    AutoPlayVideoWidgetState.pauseAllAutoPlayVideos();
  }

  @override
  void dispose() {
    tabController.removeListener(_onTabChanged);
    tabController.dispose();
    scrollController.dispose();
    countsNotifier.dispose();
    super.dispose();
  }

  void loadProfile({bool showSkeletonImmediately = true}) {
    setState(() {
      if (showSkeletonImmediately) contents.clear();
      postsLoaded = false;
      isLoading = true;
    });
    profileFuture = UserProfileService.getUserProfile();
  }

  Future<void> refresh() async {
    setState(() {
      contents.clear();
      postsLoaded = false;
    });
    final newFuture = UserProfileService.getUserProfile();
    setState(() {
      profileFuture = newFuture;
    });
    try {
      final freshProfile = await newFuture;
      if (!mounted) return;
      populatePostsFromProfile(freshProfile);
      countsNotifier.value = (
        followers: freshProfile.followersCount,
        following: freshProfile.followingCount,
      );
    } catch (_) {}
  }

  void populatePostsFromProfile(UserProfileData profile) {
    if (!mounted) return;
    setState(() {
      contents
        ..clear()
        ..addAll(profile.posts);
      postsLoaded = true;
    });
  }

  String formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> pickAndUploadImage() async {
    if (isPickingImage || isUploading) return;
    setState(() => isPickingImage = true);
    try {
      final XFile? image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 100,
      );
      setState(() => isPickingImage = false);
      if (image == null) return;

      setState(() {
        isUploading = true;
        errorMessage = null;
      });

      final oldPath = userController.getFullProfilePicturePath();
      if (oldPath != null) {
        imageCache.evict(NetworkImage(oldPath));
        imageCache.evict(
          NetworkImage(
            '$oldPath?v=${userController.profilePictureVersion.value}',
          ),
        );
      }

      final newAvatarPath = await UserProfileService.uploadProfilePicture(
        File(image.path),
      );
      userController.updateProfilePicture(newAvatarPath);
      await AppData().updateProfilePicture(newAvatarPath);
      InstantCache.invalidate();
      imageCache.evict(NetworkImage(newAvatarPath));
      userController.profilePictureVersion.value++;

      setState(() => isUploading = false);
      loadProfile();
    } catch (e) {
      setState(() {
        isPickingImage = false;
        isUploading = false;
        errorMessage = e.toString();
      });
    }
  }

  Widget buildPostsTab() {
    if (!postsLoaded) {
      return ListView.builder(
        itemCount: 2,
        padding: const EdgeInsets.all(8),
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (_, __) => const PostCardSkeleton(),
      );
    }

    if (contents.isEmpty) {
      return const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.article_outlined, size: 60, color: Colors.grey),
              SizedBox(height: 12),
              Text('No posts yet', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: contents.length,
      itemBuilder: (context, index) => buildContentItem(index),
    );
  }

  void showFollowersFollowingSheet(BuildContext context, {int initialTab = 0}) {
    tabController.index = initialTab;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => FollowersFollowingSheet(
            tabController: tabController,
            onCountsChanged: (followersDelta, followingDelta) {
              countsNotifier.value = (
                followers: countsNotifier.value.followers + followersDelta,
                following: countsNotifier.value.following + followingDelta,
              );
            },
          ),
    );
  }

  void showMoreOptionsSheet(BuildContext context, UserProfileData profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => ProfileOptionsSheet(profile: profile, formatDate: formatDate),
    );
  }

  Widget buildProfileSection(UserProfileData profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      Obx(
                        () => GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => FullScreenImageViewer(
                                      imageUrl:
                                          userController
                                              .getFullProfilePicturePath() ??
                                          profile.avatarUrl ??
                                          '',
                                      tag:
                                          'profile_${userController.profilePictureVersion.value}',
                                    ),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: const Color.fromRGBO(
                              235,
                              111,
                              70,
                              0.2,
                            ),
                            key: ValueKey(
                              'profile_${userController.profilePictureVersion.value}',
                            ),
                            backgroundImage: resolveAvatarImage(profile),
                            child:
                                shouldShowPlaceholder(profile)
                                    ? const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Color.fromRGBO(244, 135, 6, 1),
                                    )
                                    : null,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: GestureDetector(
                          onTap:
                              (isUploading || isPickingImage)
                                  ? null
                                  : pickAndUploadImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color.fromRGBO(244, 135, 6, 1),
                              shape: BoxShape.circle,
                            ),
                            child:
                                isUploading
                                    ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: AppColors.whitecolor,
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Icon(
                                      Icons.camera_alt,
                                      color: AppColors.whitecolor,
                                      size: 16,
                                    ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.fullName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          profile.email,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              Divider(thickness: 0.8, color: Colors.grey[300]),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ValueListenableBuilder<({int followers, int following})>(
                      valueListenable: countsNotifier,
                      builder:
                          (context, counts, _) => Flexible(
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap:
                                      () => showFollowersFollowingSheet(
                                        context,
                                        initialTab: 0,
                                      ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '${counts.followers}',
                                        style: const TextStyle(
                                          color: Color.fromRGBO(244, 135, 6, 1),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Followers',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 40),
                                GestureDetector(
                                  onTap:
                                      () => showFollowersFollowingSheet(
                                        context,
                                        initialTab: 1,
                                      ),
                                  child: Column(
                                    children: [
                                      Text(
                                        '${counts.following}',
                                        style: const TextStyle(
                                          color: Color.fromRGBO(244, 135, 6, 1),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Following',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 40),
                                buildStatCard(
                                  '${contents.length}',
                                  'Posts',
                                  Icons.grid_on,
                                  Colors.orange,
                                ),
                              ],
                            ),
                          ),
                    ),
                    SizedBox(
                      height: 35,
                      width: 35,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.more_vert_outlined,
                            color: Colors.grey,
                          ),
                          onPressed:
                              () => showMoreOptionsSheet(context, profile),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        Divider(thickness: 0.8, color: Colors.grey[300]),
      ],
    );
  }

  Widget buildStatCard(
    String value,
    String label,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: AppColors.whitecolor,
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color:
                      Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  ImageProvider? resolveAvatarImage(UserProfileData profile) {
    final controllerPath = userController.getFullProfilePicturePath();
    if (controllerPath != null && controllerPath.isNotEmpty) {
      return NetworkImage(
        '$controllerPath?v=${userController.profilePictureVersion.value}',
      );
    }
    final url = profile.avatarUrl;
    if (url != null && url.isNotEmpty) return NetworkImage(url);
    return null;
  }

  bool shouldShowPlaceholder(UserProfileData profile) {
    final controllerPath = userController.getFullProfilePicturePath();
    return (controllerPath == null || controllerPath.isEmpty) &&
        (profile.avatarUrl == null || profile.avatarUrl!.isEmpty);
  }

  Widget buildContentItem(int index) {
    final content = contents[index];
    return RepaintBoundary(
      key: ValueKey(content.id),
      child: FeedItem(
        content: content,
        onLikeToggled: (hasReaction) {
          setState(() {
            final wasAlreadyLiked = content.isLiked;
            content.isLiked = hasReaction;
            if (hasReaction && !wasAlreadyLiked) {
              content.likes = content.likes + 1;
            } else if (!hasReaction && wasAlreadyLiked) {
              content.likes = (content.likes - 1).clamp(0, 999999);
            }
          });
        },
        onFollowToggled: (isFollowed) {
          if (!mounted) return;
          setState(() => content.isFollowed = isFollowed);
        },
        onDeleted: () {
          if (mounted) setState(() => contents.remove(content));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(chatUnreadCountProvider);

    return Scaffold(
      backgroundColor: AppColors.whitecolor,
      body: SafeArea(
        child: CustomRefreshIndicator(
          onRefresh: refresh,
          child: NestedScrollView(
            controller: scrollController,
            headerSliverBuilder:
                (context, innerBoxIsScrolled) => [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: () => Navigator.pop(context),
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: FutureBuilder<UserProfileData>(
                        future: profileFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const ProfileSkeleton();
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    size: 48,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Error loading profile',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed:
                                        () => setState(() => loadProfile()),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromRGBO(
                                        244,
                                        135,
                                        6,
                                        1,
                                      ),
                                    ),
                                    child: const Text(
                                      'Try Again',
                                      style: TextStyle(
                                        color: AppColors.whitecolor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          if (snapshot.hasData) {
                            if (!postsLoaded) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!mounted) return;
                                populatePostsFromProfile(snapshot.data!);
                                if (countsNotifier.value.followers == 0 &&
                                    countsNotifier.value.following == 0) {
                                  countsNotifier.value = (
                                    followers: snapshot.data!.followersCount,
                                    following: snapshot.data!.followingCount,
                                  );
                                }
                              });
                            }
                            return buildProfileSection(snapshot.data!);
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: TabBarDelegate(
                      TabBar(
                        controller: tabController,
                        labelColor: const Color.fromRGBO(244, 135, 6, 1),
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: const Color.fromRGBO(244, 135, 6, 1),
                        indicatorWeight: 2,
                        tabs: const [
                          Tab(
                            child: Text(
                              'Posts',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Tab(
                            child: Text(
                              'My Reels',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: TabBarView(
                controller: tabController,
                children: [
                  buildPostsTab(),
                  FutureBuilder<UserProfileData>(
                    future: profileFuture,
                    builder: (context, snapshot) {
                      final userId = snapshot.data?.id ?? widget.userId;
                      if (userId.isEmpty) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color.fromRGBO(244, 135, 6, 1),
                          ),
                        );
                      }
                      return MyReelsScreen(userId: userId);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: CountBadgeFAB(
        count: unreadCount,
        gifAsset: 'animation/chaticon.gif',
        backgroundColor: Colors.transparent,
        onPressed: () {
          ref.read(mutualFriendsProvider.notifier).refresh();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatListScreen()),
          ).then((_) => ref.invalidate(mutualFriendsProvider));
        },
      ),
    );
  }
}

class ProfileOptionsSheet extends StatelessWidget {
  final UserProfileData profile;
  final String Function(DateTime) formatDate;

  const ProfileOptionsSheet({
    Key? key,
    required this.profile,
    required this.formatDate,
  }) : super(key: key);

  static const Color primary = Color.fromRGBO(244, 135, 6, 1);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      snap: true,
      snapSizes: const [0.55, 0.92],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Text(
                  'Options',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Divider(color: Colors.grey[100], thickness: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  children: [
                    buildOptionTile(
                      context,
                      icon: Icons.info_outline_rounded,
                      label: 'My Information',
                      onTap: () {
                        Navigator.of(context).pop();
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder:
                              (_) => PersonalInfoSheet(
                                profile: profile,
                                formatDate: formatDate,
                              ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    buildOptionTile(
                      context,
                      icon: Icons.description_outlined,
                      label: 'Make a CV',
                      onTap: () {
                        Navigator.of(context).pop(); // close the options sheet
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CvScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    buildOptionTile(
                      context,
                      icon: Icons.logout_rounded,
                      label: 'Logout',
                      isDestructive: true,
                      onTap: () async {
                        await AppData().clearAuthToken();
                        Get.offAll(() => LoginPage());
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red.shade400 : Colors.grey[800]!;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDestructive ? Colors.red.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      isDestructive
                          ? Colors.red.shade100
                          : const Color.fromRGBO(244, 135, 6, 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isDestructive ? Colors.red.shade400 : primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PersonalInfoSheet extends StatelessWidget {
  final UserProfileData profile;
  final String Function(DateTime) formatDate;

  const PersonalInfoSheet({
    Key? key,
    required this.profile,
    required this.formatDate,
  }) : super(key: key);

  static const Color primary = Color.fromRGBO(244, 135, 6, 1);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      snap: true,
      snapSizes: const [0.6, 0.92],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Personal Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => EditProfileScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: primary,
                      ),
                      label: const Text(
                        'Edit',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        backgroundColor: const Color.fromRGBO(
                          244,
                          135,
                          6,
                          0.08,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.grey[100], thickness: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    ProfileInfoCard(
                      title: 'Username',
                      value:
                          profile.username.isNotEmpty
                              ? profile.username
                              : '(not set)',
                      icon: Icons.alternate_email_rounded,
                    ),
                    const SizedBox(height: 10),
                    ProfileInfoCard(
                      title: 'Full Name',
                      value:
                          profile.fullName.isNotEmpty
                              ? profile.fullName
                              : '(not set)',
                      icon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 10),
                    ProfileInfoCard(
                      title: 'Email',
                      value:
                          profile.email.isNotEmpty
                              ? profile.email
                              : '(not set)',
                      icon: Icons.email_outlined,
                    ),
                    if (profile.phone != null && profile.phone!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ProfileInfoCard(
                        title: 'Phone',
                        value: profile.phone!,
                        icon: Icons.phone_outlined,
                      ),
                    ],
                    if (profile.dateOfBirth != null &&
                        profile.dateOfBirth!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ProfileInfoCard(
                        title: 'Date of Birth',
                        value: profile.dateOfBirth!,
                        icon: Icons.cake_outlined,
                      ),
                    ],
                    if (profile.gender != null &&
                        profile.gender!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ProfileInfoCard(
                        title: 'Gender',
                        value: profile.gender!,
                        icon: Icons.person_outline_rounded,
                      ),
                    ],
                    if (profile.address != null &&
                        profile.address!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ProfileInfoCard(
                        title: 'Address',
                        value: profile.address!,
                        icon: Icons.location_on_outlined,
                      ),
                    ],
                    if (profile.education != null &&
                        profile.education!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ProfileInfoCard(
                        title: 'Education',
                        value: profile.education!,
                        icon: Icons.school_outlined,
                      ),
                    ],
                    if (profile.occupation != null &&
                        profile.occupation!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ProfileInfoCard(
                        title: 'Occupation',
                        value: profile.occupation!,
                        icon: Icons.work_outline_rounded,
                      ),
                    ],
                    const SizedBox(height: 10),
                    ProfileInfoCard(
                      title: 'Member Since',
                      value: formatDate(profile.createdAt),
                      icon: Icons.access_time_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class FollowersFollowingSheet extends StatefulWidget {
  final TabController tabController;
  final void Function(int followersDelta, int followingDelta) onCountsChanged;

  const FollowersFollowingSheet({
    Key? key,
    required this.tabController,
    required this.onCountsChanged,
  }) : super(key: key);

  @override
  State<FollowersFollowingSheet> createState() =>
      FollowersFollowingSheetState();
}

class FollowersFollowingSheetState extends State<FollowersFollowingSheet> {
  List<FollowerFollowing>? followers;
  List<FollowerFollowing>? following;
  final Set<String> followingIds = {};
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadBoth();
  }

  Future<void> loadBoth() async {
    try {
      final results = await Future.wait([
        UserProfileService.getFollowers(),
        UserProfileService.getFollowing(),
      ]);
      if (!mounted) return;
      setState(() {
        followers = results[0];
        following = results[1];
        followingIds
          ..clear()
          ..addAll(following!.map((f) => f.id));
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  void onFollowFromFollowersList(FollowerFollowing person) {
    setState(() {
      followingIds.add(person.id);
      if (following != null && !following!.any((f) => f.id == person.id)) {
        following!.add(person);
      }
    });
    widget.onCountsChanged(0, 1);
  }

  void onUnfollowFromFollowersList(FollowerFollowing person) {
    setState(() {
      followingIds.remove(person.id);
      following?.removeWhere((f) => f.id == person.id);
    });
    widget.onCountsChanged(0, -1);
  }

  void onFollowFromFollowingList(FollowerFollowing person) {
    setState(() => followingIds.add(person.id));
    widget.onCountsChanged(0, 1);
  }

  void onUnfollowFromFollowingList(FollowerFollowing person) {
    setState(() {
      following?.removeWhere((f) => f.id == person.id);
      followingIds.remove(person.id);
    });
    widget.onCountsChanged(0, -1);
  }

  Widget buildFollowersList() {
    if (followers == null || followers!.isEmpty) {
      return const Center(child: Text('No followers yet'));
    }
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: followers!.length,
      itemBuilder: (context, index) {
        final person = followers![index];
        final isFollowedByMe = followingIds.contains(person.id);
        return PersonTile(
          person: person,
          isFollowing: isFollowedByMe,
          onFollow: () => onFollowFromFollowersList(person),
          onUnfollow: () => onUnfollowFromFollowersList(person),
        );
      },
    );
  }

  Widget buildFollowingList() {
    if (following == null || following!.isEmpty) {
      return const Center(child: Text('Not following anyone yet'));
    }
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: following!.length,
      itemBuilder: (context, index) {
        final person = following![index];
        return PersonTile(
          person: person,
          isFollowing: true,
          onFollow: () => onFollowFromFollowingList(person),
          onUnfollow: () => onUnfollowFromFollowingList(person),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 1.0,
      expand: false,
      snap: true,
      snapSizes: const [0.55, 1.0],
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              TabBar(
                controller: widget.tabController,
                labelColor: const Color.fromRGBO(244, 135, 6, 1),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color.fromRGBO(244, 135, 6, 1),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 16),
                        SizedBox(width: 4),
                        Text('Followers'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_add_outlined, size: 16),
                        SizedBox(width: 4),
                        Text('Following'),
                      ],
                    ),
                  ),
                ],
              ),
              Expanded(
                child:
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : error != null
                        ? Center(child: Text('Error: $error'))
                        : TabBarView(
                          controller: widget.tabController,
                          physics: const ClampingScrollPhysics(),
                          children: [
                            SingleChildScrollView(
                              controller: scrollController,
                              child: buildFollowersList(),
                            ),
                            SingleChildScrollView(
                              controller: scrollController,
                              child: buildFollowingList(),
                            ),
                          ],
                        ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PersonTile extends StatelessWidget {
  final FollowerFollowing person;
  final bool isFollowing;
  final VoidCallback onFollow;
  final VoidCallback onUnfollow;

  const PersonTile({
    Key? key,
    required this.person,
    required this.isFollowing,
    required this.onFollow,
    required this.onUnfollow,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final pictureUrl = person.fullPictureUrl;
    final displayName =
        person.name.isNotEmpty ? person.name : '@${person.username ?? ''}';

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: const Color.fromRGBO(235, 111, 70, 0.2),
        backgroundImage: pictureUrl != null ? NetworkImage(pictureUrl) : null,
        child:
            pictureUrl == null
                ? const Icon(
                  Icons.person,
                  color: Color.fromRGBO(244, 135, 6, 1),
                )
                : null,
      ),
      title: GestureDetector(
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SpecificUserProfilePage(userId: person.id),
            ),
          );
        },
        child: Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      subtitle: Text(
        person.username != null ? '@${person.username}' : person.email,
        style: TextStyle(color: Colors.grey[500], fontSize: 12),
      ),
      trailing: FollowButton(
        targetUserId: person.id,
        targetUserEmail: person.email,
        initialFollowStatus: isFollowing,
        onFollowSuccess: onFollow,
        onUnfollowSuccess: onUnfollow,
        size: 36,
      ),
    );
  }
}

class ProfileInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const ProfileInfoCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
  }) : super(key: key);

  static const Color primary = Color.fromRGBO(244, 135, 6, 1);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(244, 135, 6, 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const TabBarDelegate(this.tabBar);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: AppColors.whitecolor, child: tabBar);
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(TabBarDelegate old) => false;
}
