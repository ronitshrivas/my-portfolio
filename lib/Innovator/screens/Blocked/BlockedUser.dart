import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/constant/api_constants.dart';
import 'package:innovator/Innovator/constant/app_colors.dart';
import 'package:innovator/Innovator/models/Blocked_Model.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({Key? key}) : super(key: key);

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  static const _orange = Color.fromRGBO(244, 135, 6, 1);

  List<BlockedUser> _blockedUsers = [];
  int _blockedCount = 0;
  bool _isLoading = true;
  String? _error;

  // Track which users are being unblocked
  final Set<String> _unblockingIds = {};

  @override
  void initState() {
    super.initState();
    _fetchBlockedUsers();
  }

  // ── API ───────────────────────────────────────────────────────────────────

  Future<void> _fetchBlockedUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = AppData().accessToken;
      if (token == null || token.isEmpty) {
        setState(() {
          _error = 'Authentication required. Please login again.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse(ApiConstants.blocklistuser),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      developer.log('[Blocked] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> usersData = data['blocked_users'] ?? [];
        setState(() {
          _blockedCount = data['blocked_count'] ?? 0;
          _blockedUsers =
              usersData.map((j) => BlockedUser.fromJson(j)).toList();
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _error = 'Session expired. Please login again. 4';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load blocked users: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('[Blocked] fetch error: $e');
      setState(() {
        _error = 'Network error. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  Future<void> _unblockUser(BlockedUser user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _orange.withAlpha(10),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_open, color: _orange, size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Unblock User',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(
              'Unblock @${user.username}? They will be able to see your '
              'posts and contact you again.',
              style: const TextStyle(fontSize: 15),
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: AppColors.whitecolor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Unblock',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _unblockingIds.add(user.id));

    try {
      final token = AppData().accessToken;
      final response = await http
          .post(
            Uri.parse('${ApiConstants.unblockuser}${user.id}/unblock/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _blockedUsers.removeWhere((u) => u.id == user.id);
          _blockedCount = _blockedUsers.length;
          _unblockingIds.remove(user.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.whitecolor,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  '@${user.username} has been unblocked',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        setState(() => _unblockingIds.remove(user.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to unblock user. Please try again.'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _unblockingIds.remove(user.id));
      developer.log('[Blocked] unblock error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Network error. Please check your connection.'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        // title: Text(
        //   _blockedCount > 0
        //       ? 'Blocked Users ($_blockedCount)'
        //       : 'Blocked Users',
        //   style: const TextStyle(
        //     fontWeight: FontWeight.bold,
        //     color: AppColors.whitecolor,
        //   ),
        // ),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.refresh, color: AppColors.whitecolor),
        //     onPressed: _fetchBlockedUsers,
        //   ),
        // ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return _buildLoading();
    if (_error != null) return _buildError();
    if (_blockedUsers.isEmpty) return _buildEmpty();
    return _buildList();
  }

  Widget _buildLoading() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_orange),
        ),
        const SizedBox(height: 16),
        Text(
          'Loading blocked users...',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    ),
  );

  Widget _buildError() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('animation/NoGallery.gif', height: 160),
        const SizedBox(height: 16),
        Text(
          _error!,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _fetchBlockedUsers,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _orange,
            foregroundColor: AppColors.whitecolor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: _orange.withAlpha(10),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.block, size: 48, color: _orange),
        ),
        const SizedBox(height: 20),
        const Text(
          'No Blocked Users',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "You haven't blocked anyone yet.",
          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
        ),
      ],
    ),
  );

  Widget _buildList() => RefreshIndicator(
    onRefresh: _fetchBlockedUsers,
    color: _orange,
    child: ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _blockedUsers.length,
      itemBuilder: (context, index) {
        final user = _blockedUsers[index];
        return _BlockedUserCard(
          user: user,
          isUnblocking: _unblockingIds.contains(user.id),
          onUnblock: () => _unblockUser(user),
        );
      },
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Card
// ─────────────────────────────────────────────────────────────────────────────

class _BlockedUserCard extends StatelessWidget {
  final BlockedUser user;
  final bool isUnblocking;
  final VoidCallback onUnblock;

  const _BlockedUserCard({
    required this.user,
    required this.isUnblocking,
    required this.onUnblock,
  });

  static const _orange = Color.fromRGBO(244, 135, 6, 1);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.whitecolor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // ── Avatar ──────────────────────────────────────────────────
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color.fromRGBO(244, 135, 6, 1),
                    Color.fromRGBO(255, 204, 0, 1),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orangeAccent.shade100,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(2),
              child: ClipOval(child: _buildAvatar()),
            ),
            const SizedBox(width: 14),

            // ── Info ─────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + role badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.role.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _orange.withAlpha(10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user.role.toUpperCase(),
                            style: const TextStyle(
                              color: _orange,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Username
                  Text(
                    '@${user.username}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  // Occupation / education
                  if (user.occupation != null &&
                      user.occupation!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.work_outline,
                          size: 12,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          user.occupation!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 6),

                  // Followers / following
                  Row(
                    children: [
                      _StatChip(
                        label: '${user.followersCount} followers',
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        label: '${user.followingCount} following',
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // ── Unblock button ───────────────────────────────────────────
            isUnblocking
                ? const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(_orange),
                  ),
                )
                : GestureDetector(
                  onTap: onUnblock,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: _orange.withAlpha(10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _orange.withAlpha(40),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'Unblock',
                      style: TextStyle(
                        color: _orange,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final initial =
        user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?';

    if (user.avatarUrl.isEmpty) {
      return CircleAvatar(
        backgroundColor: Colors.grey.shade300,
        child: Text(
          initial,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.whitecolor,
            fontSize: 20,
          ),
        ),
      );
    }

    return Image.network(
      user.avatarUrl,
      fit: BoxFit.cover,
      errorBuilder:
          (_, __, ___) => CircleAvatar(
            backgroundColor: Colors.grey.shade300,
            child: Text(
              initial,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.whitecolor,
                fontSize: 20,
              ),
            ),
          ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small stat chip
// ─────────────────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
