import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/constant/api_constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:innovator/Innovator/constant/app_colors.dart';
import 'package:innovator/Innovator/screens/show_Specific_Profile/Show_Specific_Profile.dart';

class FollowersFollowingScreen extends StatefulWidget {
  final String userId;

  const FollowersFollowingScreen({Key? key, required this.userId})
    : super(key: key);

  @override
  _FollowersFollowingScreenState createState() =>
      _FollowersFollowingScreenState();
}

class _FollowersFollowingScreenState extends State<FollowersFollowingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final appData = AppData();

  List<Map<String, dynamic>> followers = [];
  List<Map<String, dynamic>> following = [];

  bool isLoadingFollowers = false;
  bool isLoadingFollowing = false;
  String? errorFollowers;
  String? errorFollowing;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchFollowers();
    _fetchFollowing();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchFollowers() async {
    setState(() {
      isLoadingFollowers = true;
      errorFollowers = null;
    });
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.fetchspecificfollowersandfollowing}${widget.userId}/followers/',
        ),
        headers: {
          'Authorization': 'Bearer ${appData.accessToken}',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> raw = data['followers'] ?? [];
        setState(() {
          followers = raw.whereType<Map<String, dynamic>>().toList();
          isLoadingFollowers = false;
        });
      } else {
        setState(() {
          errorFollowers = 'Server error: ${response.statusCode}';
          isLoadingFollowers = false;
        });
      }
    } catch (e) {
      setState(() {
        errorFollowers = 'Network error';
        isLoadingFollowers = false;
      });
    }
  }

  Future<void> _fetchFollowing() async {
    setState(() {
      isLoadingFollowing = true;
      errorFollowing = null;
    });
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.fetchspecificfollowersandfollowing}${widget.userId}/following/',
        ),
        headers: {
          'Authorization': 'Bearer ${appData.accessToken}',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> raw = data['following'] ?? [];
        setState(() {
          following = raw.whereType<Map<String, dynamic>>().toList();
          isLoadingFollowing = false;
        });
      } else {
        setState(() {
          errorFollowing = 'Server error: ${response.statusCode}';
          isLoadingFollowing = false;
        });
      }
    } catch (e) {
      setState(() {
        errorFollowing = 'Network error';
        isLoadingFollowing = false;
      });
    }
  }

  /// Extracts the user ID from the new API response shape (field is "id", not "_id")
  String? _extractUserId(Map<String, dynamic> user) {
    final id = user['id']?.toString().trim() ?? '';
    return id.isNotEmpty ? id : null;
  }

  String _extractName(Map<String, dynamic> user) {
    final fn = user['full_name']?.toString().trim() ?? '';
    return fn.isNotEmpty ? fn : user['username']?.toString() ?? 'Unknown';
  }

  String? _extractAvatarUrl(Map<String, dynamic> user) {
    final raw = user['profile']?['avatar']?.toString() ?? '';
    if (raw.isEmpty) return null;
    return raw.startsWith('http') ? raw : '${ApiConstants.userBase}$raw';
  }

  void _navigateToProfile(Map<String, dynamic> user) {
    final userId = _extractUserId(user);

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot open profile: User ID not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (userId == appData.currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This is your profile'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SpecificUserProfilePage(userId: userId),
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> user) {
    final avatarUrl = _extractAvatarUrl(user);
    final name = _extractName(user);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return CircleAvatar(
      radius: 25,
      backgroundColor: Colors.grey[300],
      child:
          avatarUrl != null
              ? ClipOval(
                child: CachedNetworkImage(
                  imageUrl: avatarUrl,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.grey[200]),
                  errorWidget:
                      (_, __, ___) => Text(
                        initial,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.whitecolor,
                        ),
                      ),
                ),
              )
              : Text(
                initial,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.whitecolor,
                ),
              ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final userId = _extractUserId(user);
    final isCurrentUser = userId == appData.currentUserId;
    final name = _extractName(user);
    final username = user['username']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]?.withAlpha(30)
                : AppColors.whitecolor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        onTap: isCurrentUser ? null : () => _navigateToProfile(user),
        leading: _buildAvatar(user),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle:
            username.isNotEmpty
                ? Text(
                  '@$username',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                )
                : null,
        trailing:
            isCurrentUser
                ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'You',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
                : const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
      ),
    );
  }

  Widget _buildList(
    bool isLoading,
    String? error,
    List<Map<String, dynamic>> items,
    VoidCallback onRetry,
    IconData emptyIcon,
    String emptyText,
  ) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              emptyText,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRetry as Future<void> Function(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: items.length,
        itemBuilder: (_, i) => _buildUserTile(items[i]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF0A0A0A)
              : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Connections'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color.fromRGBO(244, 135, 6, 1),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color.fromRGBO(244, 135, 6, 1),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 18),
                  const SizedBox(width: 8),
                  Text('Followers (${followers.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text('Following (${following.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(
            isLoadingFollowers,
            errorFollowers,
            followers,
            _fetchFollowers,
            Icons.people_outline,
            'No followers yet',
          ),
          _buildList(
            isLoadingFollowing,
            errorFollowing,
            following,
            _fetchFollowing,
            Icons.person_add_outlined,
            'Not following anyone yet',
          ),
        ],
      ),
    );
  }
}

// ── Dialog helper ─────────────────────────────────────────────────────────────

void showFollowersFollowingDialog(BuildContext context, String userId) {
  showDialog(
    context: context,
    builder:
        (_) => Dialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1A1A1A)
                      : AppColors.whitecolor,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: FollowersFollowingContent(userId: userId),
          ),
        ),
  );
}

// ── Dialog content widget ──────────────────────────────────────────────────────

class FollowersFollowingContent extends StatefulWidget {
  final String userId;

  const FollowersFollowingContent({Key? key, required this.userId})
    : super(key: key);

  @override
  _FollowersFollowingContentState createState() =>
      _FollowersFollowingContentState();
}

class _FollowersFollowingContentState extends State<FollowersFollowingContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final appData = AppData();

  List<Map<String, dynamic>> followers = [];
  List<Map<String, dynamic>> following = [];

  bool isLoadingFollowers = false;
  bool isLoadingFollowing = false;
  String? errorFollowers;
  String? errorFollowing;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchFollowers();
    _fetchFollowing();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchFollowers() async {
    setState(() {
      isLoadingFollowers = true;
      errorFollowers = null;
    });
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.fetchspecificfollowersandfollowing}${widget.userId}/followers/',
        ),
        headers: {
          'Authorization': 'Bearer ${appData.accessToken}',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> raw = data['followers'] ?? [];
        setState(() {
          followers = raw.whereType<Map<String, dynamic>>().toList();
          isLoadingFollowers = false;
        });
      } else {
        setState(() {
          errorFollowers = 'Server error: ${response.statusCode}';
          isLoadingFollowers = false;
        });
      }
    } catch (e) {
      setState(() {
        errorFollowers = 'Network error';
        isLoadingFollowers = false;
      });
    }
  }

  Future<void> _fetchFollowing() async {
    setState(() {
      isLoadingFollowing = true;
      errorFollowing = null;
    });
    try {
      final response = await http.get(
        Uri.parse(
          '${ApiConstants.fetchspecificfollowersandfollowing}${widget.userId}/following/',
        ),
        headers: {
          'Authorization': 'Bearer ${appData.accessToken}',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> raw = data['following'] ?? [];
        setState(() {
          following = raw.whereType<Map<String, dynamic>>().toList();
          isLoadingFollowing = false;
        });
      } else {
        setState(() {
          errorFollowing = 'Server error: ${response.statusCode}';
          isLoadingFollowing = false;
        });
      }
    } catch (e) {
      setState(() {
        errorFollowing = 'Network error';
        isLoadingFollowing = false;
      });
    }
  }

  String? _extractUserId(Map<String, dynamic> user) {
    final id = user['id']?.toString().trim() ?? '';
    return id.isNotEmpty ? id : null;
  }

  String _extractName(Map<String, dynamic> user) {
    final fn = user['full_name']?.toString().trim() ?? '';
    return fn.isNotEmpty ? fn : user['username']?.toString() ?? 'Unknown';
  }

  String? _extractAvatarUrl(Map<String, dynamic> user) {
    final raw = user['profile']?['avatar']?.toString() ?? '';
    if (raw.isEmpty) return null;
    return raw.startsWith('http') ? raw : '${ApiConstants.userBase}$raw';
  }

  void _navigateToProfile(Map<String, dynamic> user) {
    final userId = _extractUserId(user);

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot open profile: User ID not found'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (userId == appData.currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This is your profile'),
          backgroundColor: Colors.blue,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    // Close dialog, then navigate
    Navigator.of(context).pop();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SpecificUserProfilePage(userId: userId),
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final userId = _extractUserId(user);
    final isCurrentUser = userId == appData.currentUserId;
    final name = _extractName(user);
    final username = user['username']?.toString() ?? '';
    final avatarUrl = _extractAvatarUrl(user);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[800]?.withAlpha(30)
                : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: isCurrentUser ? null : () => _navigateToProfile(user),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: Colors.grey[300],
          child:
              avatarUrl != null
                  ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: avatarUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      placeholder:
                          (_, __) => Container(color: Colors.grey[200]),
                      errorWidget:
                          (_, __, ___) => Text(
                            initial,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                    ),
                  )
                  : Text(
                    initial,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
        ),
        title: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        subtitle:
            username.isNotEmpty
                ? Text(
                  '@$username',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                )
                : null,
        trailing:
            isCurrentUser
                ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'You',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                )
                : const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.grey,
                ),
      ),
    );
  }

  Widget _buildList(
    bool isLoading,
    String? error,
    List<Map<String, dynamic>> items,
    VoidCallback onRetry,
    IconData emptyIcon,
    String emptyText,
  ) {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 32, color: Colors.red),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ],
        ),
      );
    }
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 32, color: Colors.grey),
            const SizedBox(height: 8),
            Text(
              emptyText,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      itemCount: items.length,
      itemBuilder: (_, i) => _buildUserTile(items[i]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Connections',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TabBar(
          controller: _tabController,
          labelColor: const Color.fromRGBO(244, 135, 6, 1),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color.fromRGBO(244, 135, 6, 1),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 16),
                  const SizedBox(width: 4),
                  Text('Followers (${followers.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_add_outlined, size: 16),
                  const SizedBox(width: 4),
                  Text('Following (${following.length})'),
                ],
              ),
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildList(
                isLoadingFollowers,
                errorFollowers,
                followers,
                _fetchFollowers,
                Icons.people_outline,
                'No followers yet',
              ),
              _buildList(
                isLoadingFollowing,
                errorFollowing,
                following,
                _fetchFollowing,
                Icons.person_add_outlined,
                'Not following anyone yet',
              ),
            ],
          ),
        ),
      ],
    );
  }
}
