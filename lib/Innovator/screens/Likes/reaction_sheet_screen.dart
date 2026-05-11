import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/constant/api_constants.dart';
import 'package:innovator/Innovator/constant/app_colors.dart';
import 'package:innovator/Innovator/screens/show_Specific_Profile/Show_Specific_Profile.dart';

class reeactionsheet extends StatefulWidget {
  final String postId;
  final bool isreel;
  const reeactionsheet({required this.postId, this.isreel = false});

  @override
  State<reeactionsheet> createState() => _reeactionsheetState();
}

class _reeactionsheetState extends State<reeactionsheet> {
  List<Map<String, dynamic>> _reactions = [];
  String _activeTab = 'all';
  bool _isLoading = true;

  final Map<String, String> _emojiMap = {
    'like': '👍',
    'love': '❤️',
    'haha': '😂',
    'wow': '😮',
    'sad': '😢',
    'angry': '😡',
    'celebrate': '🎉',
    'dislike': '👎',
  };

  @override
  void initState() {
    super.initState();
    _fetchReactions();
  }

  Future<void> _fetchReactions() async {
    try {
      final token = AppData().accessToken ?? '';

      final baseUrl =
          widget.isreel
              ? ApiConstants
                  .fetchreelreactions // → /api/reels/
              : ApiConstants.fetchreactions;

      final res = await http.get(
        Uri.parse('$baseUrl${widget.postId}/reactions-list/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        final list = json.decode(res.body) as List;
        if (mounted)
          setState(() {
            _reactions = list.cast<Map<String, dynamic>>();
            _isLoading = false;
          });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered =>
      _activeTab == 'all'
          ? _reactions
          : _reactions.where((r) => r['type'] == _activeTab).toList();

  Map<String, int> get _counts {
    final m = <String, int>{};
    for (final r in _reactions) {
      final t = r['type'] as String? ?? 'like';
      m[t] = (m[t] ?? 0) + 1;
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final counts = _counts;
    final tabs = ['all', ...counts.keys.toList()];

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: AppColors.whitecolor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Reactions',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          // Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children:
                  tabs.map((tab) {
                    final isActive = _activeTab == tab;
                    final count =
                        tab == 'all' ? _reactions.length : (counts[tab] ?? 0);
                    return GestureDetector(
                      onTap: () => setState(() => _activeTab = tab),
                      child: Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color:
                                  isActive
                                      ? Colors.blue.shade700
                                      : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            if (tab != 'all')
                              Text(
                                _emojiMap[tab] ?? '👍',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.red,
                                ),
                              ),
                            if (tab != 'all') const SizedBox(width: 4),
                            Text(
                              tab == 'all' ? 'All' : '',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    isActive
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                color:
                                    isActive
                                        ? Colors.blue.shade700
                                        : Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
          const Divider(height: 1),
          // List
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFF48706),
                        strokeWidth: 2,
                      ),
                    )
                    : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final r = _filtered[i];
                        final name =
                            r['full_name']?.toString() ?? r['username'] ?? '';
                        final username = r['username']?.toString() ?? '';
                        final avatar = r['avatar']?.toString() ?? '';
                        final type = r['type']?.toString() ?? 'like';
                        final initial =
                            name.isNotEmpty ? name[0].toUpperCase() : '?';
                        final avatarUrl =
                            avatar.isNotEmpty
                                ? (avatar.startsWith('http')
                                    ? avatar
                                    : '${ApiConstants.userBase}$avatar')
                                : null;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 4,
                          ),
                          leading: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => SpecificUserProfilePage(
                                            userId: r['user']?.toString() ?? '',
                                          ),
                                    ),
                                  );
                                },
                                child: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.grey.shade200,
                                  backgroundImage:
                                      avatarUrl != null
                                          ? NetworkImage(avatarUrl)
                                          : null,
                                  child:
                                      avatarUrl == null
                                          ? Text(
                                            initial,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                          : null,
                                ),
                              ),
                              Positioned(
                                bottom: -3,
                                right: -3,
                                child: Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.whitecolor,
                                    border: Border.all(
                                      color: AppColors.whitecolor,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _emojiMap[type] ?? '👍',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '@$username',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          // trailing:
                          //     r['user']?.toString() == AppData().currentUserId
                          //         ? null
                          //         : OutlinedButton(
                          //           onPressed: () {},
                          //           style: OutlinedButton.styleFrom(
                          //             side: BorderSide(
                          //               color: Colors.blue.shade700,
                          //             ),
                          //             shape: RoundedRectangleBorder(
                          //               borderRadius: BorderRadius.circular(20),
                          //             ),
                          //             padding: const EdgeInsets.symmetric(
                          //               horizontal: 14,
                          //               vertical: 6,
                          //             ),
                          //             minimumSize: Size.zero,
                          //           ),
                          //           child: Text(
                          //             '+ Follow',
                          //             style: TextStyle(
                          //               fontSize: 13,
                          //               color: Colors.blue.shade700,
                          //             ),
                          //           ),
                          //         ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}


/*
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/constant/api_constants.dart';
import 'package:innovator/Innovator/constant/app_colors.dart';
import 'package:innovator/Innovator/screens/show_Specific_Profile/Show_Specific_Profile.dart';

class reeactionsheet extends StatefulWidget {
  final String contentId;
  final String contentType; // 'post' or 'reel'

  const reeactionsheet({
    required this.contentId,
    required this.contentType,
    super.key,
  });

  @override
  State<reeactionsheet> createState() => _reeactionsheetState();
}

class _reeactionsheetState extends State<reeactionsheet> {
  List<Map<String, dynamic>> _reactions = [];
  String _activeTab = 'all';
  bool _isLoading = true;
  String? _errorMessage;

  final Map<String, String> _emojiMap = {
    'like': '👍',
    'love': '❤️',
    'haha': '😂',
    'wow': '😮',
    'sad': '😢',
    'angry': '😡',
    'celebrate': '🎉',
    'dislike': '👎',
  };

  @override
  void initState() {
    super.initState();
    _fetchReactions();
  }

  Future<void> _fetchReactions() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = AppData().accessToken ?? '';

      // ── Step 1: Fetch raw reactions from /api/reactions/ ──────────────────
      // Filter by post or reel id using query params
      final Map<String, String> queryParams = {
        'content_type': widget.contentType,
        if (widget.contentType == 'post') 'post': widget.contentId,
        if (widget.contentType == 'reel') 'reel': widget.contentId,
      };

      final uri = Uri.parse(
        '${ApiConstants.sendreaction}',
        // = http://36.253.137.34:8005/api/reactions/
      ).replace(queryParameters: queryParams);

      debugPrint('=== REACTION API CALL ===');
      debugPrint('URL: $uri');
      debugPrint('contentType: ${widget.contentType}');
      debugPrint('contentId: ${widget.contentId}');

      final res = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('Status: ${res.statusCode}');

      if (!mounted) return;

      if (res.statusCode != 200) {
        setState(() {
          _errorMessage = 'Failed to load reactions (${res.statusCode})';
          _isLoading = false;
        });
        return;
      }

      final decoded = json.decode(res.body);

      // Handle both List and paginated Map response
      List<dynamic> rawList = [];
      if (decoded is List) {
        rawList = decoded;
      } else if (decoded is Map && decoded.containsKey('results')) {
        rawList = decoded['results'] as List;
      }

      debugPrint('Total reactions from API: ${rawList.length}');

      // ── Step 2: Filter for this specific content only ─────────────────────
      final filtered = rawList
          .cast<Map<String, dynamic>>()
          .where((r) {
            final ct = r['content_type']?.toString();
            if (widget.contentType == 'reel') {
              return ct == 'reel' &&
                  r['reel']?.toString() == widget.contentId;
            } else {
              return ct == 'post' &&
                  r['post']?.toString() == widget.contentId;
            }
          })
          .toList();

      debugPrint('Filtered reactions for this content: ${filtered.length}');

      if (filtered.isEmpty) {
        setState(() {
          _reactions = [];
          _isLoading = false;
        });
        return;
      }

      // ── Step 3: Collect unique user IDs ───────────────────────────────────
      final userIds = filtered
          .map((r) => r['user']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      debugPrint('Unique users to fetch: ${userIds.length}');

      // ── Step 4: Fetch each user profile in parallel ───────────────────────
      // ApiConstants.fetchotheruserprofile = http://36.253.137.34:8005/api/users/
      final Map<String, Map<String, dynamic>> profileCache = {};

      await Future.wait(
        userIds.map((userId) async {
          try {
            final profileRes = await http
                .get(
                  Uri.parse(
                    '${ApiConstants.fetchotheruserprofile}$userId/',
                  ),
                  headers: {
                    'Authorization': 'Bearer $token',
                    'Accept': 'application/json',
                  },
                )
                .timeout(const Duration(seconds: 10));

            if (profileRes.statusCode == 200) {
              final profile =
                  json.decode(profileRes.body) as Map<String, dynamic>;

              debugPrint('=== PROFILE for $userId ===');
              debugPrint('Keys: ${profile.keys.toList()}');
              debugPrint('full_name: ${profile['full_name']}');
              debugPrint('username: ${profile['username']}');
              debugPrint('avatar: ${profile['avatar']}');

              profileCache[userId] = profile;
            } else {
              debugPrint(
                'Profile fetch failed for $userId: ${profileRes.statusCode}',
              );
            }
          } catch (e) {
            debugPrint('Profile fetch error for $userId: $e');
          }
        }),
      );

      // ── Step 5: Merge profile data into each reaction ─────────────────────
      final enriched = filtered.map((r) {
        final userId = r['user']?.toString() ?? '';
        final profile = profileCache[userId] ?? {};

        // Extract name — try all possible field names
        String fullName = '';
        if (profile['full_name'] != null &&
            profile['full_name'].toString().trim().isNotEmpty) {
          fullName = profile['full_name'].toString().trim();
        } else if (profile['name'] != null &&
            profile['name'].toString().trim().isNotEmpty) {
          fullName = profile['name'].toString().trim();
        } else if (profile['first_name'] != null ||
            profile['last_name'] != null) {
          fullName =
              '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'
                  .trim();
        }

        final username = profile['username']?.toString().trim() ?? '';

        // Use fullName if available, else username, else 'Unknown'
        final displayName = fullName.isNotEmpty
            ? fullName
            : username.isNotEmpty
                ? username
                : 'Unknown';

        // Extract avatar — resolve relative URLs using ApiConstants.userBase
        final rawAvatar = profile['avatar']?.toString() ??
            profile['profile_picture']?.toString() ??
            profile['picture']?.toString() ??
            '';

        String resolvedAvatar = '';
        if (rawAvatar.isNotEmpty) {
          if (rawAvatar.startsWith('http')) {
            resolvedAvatar = rawAvatar;
          } else {
            // Same as old code — use userBase
            resolvedAvatar =
                '${ApiConstants.userBase}${rawAvatar.startsWith('/') ? '' : '/'}$rawAvatar';
          }
        }

        debugPrint('=== MERGED ===');
        debugPrint('userId: $userId');
        debugPrint('displayName: $displayName');
        debugPrint('username: $username');
        debugPrint('avatar: $resolvedAvatar');

        return {
          ...r, // keep original reaction fields (type, created_at, etc.)
          'full_name': displayName,
          'username': username,
          'avatar': resolvedAvatar,
          'user': userId,
        };
      }).toList();

      if (!mounted) return;
      setState(() {
        _reactions = enriched;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('_fetchReactions error: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Network error. Please try again.';
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered =>
      _activeTab == 'all'
          ? _reactions
          : _reactions.where((r) => r['type'] == _activeTab).toList();

  Map<String, int> get _counts {
    final m = <String, int>{};
    for (final r in _reactions) {
      final t = r['type'] as String? ?? 'like';
      m[t] = (m[t] ?? 0) + 1;
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final counts = _counts;
    final tabs = ['all', ...counts.keys.toList()];

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: AppColors.whitecolor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              children: [
                const Text(
                  'Reactions',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: widget.contentType == 'reel'
                        ? Colors.purple.shade50
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: widget.contentType == 'reel'
                          ? Colors.purple.shade200
                          : Colors.blue.shade200,
                    ),
                  ),
                  child: Text(
                    widget.contentType == 'reel' ? '🎬 Reel' : '📝 Post',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: widget.contentType == 'reel'
                          ? Colors.purple.shade700
                          : Colors.blue.shade700,
                    ),
                  ),
                ),
                const Spacer(),
                if (!_isLoading)
                  Text(
                    '${_reactions.length} total',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),

          // Tabs
          if (!_isLoading && _reactions.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: tabs.map((tab) {
                  final isActive = _activeTab == tab;
                  final count = tab == 'all'
                      ? _reactions.length
                      : (counts[tab] ?? 0);

                  return GestureDetector(
                    onTap: () => setState(() => _activeTab = tab),
                    child: Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: isActive
                                ? Colors.blue.shade700
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          if (tab != 'all')
                            Text(
                              _emojiMap[tab] ?? '👍',
                              style: const TextStyle(fontSize: 14),
                            ),
                          if (tab != 'all') const SizedBox(width: 4),
                          Text(
                            tab == 'all' ? 'All' : '',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isActive
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isActive
                                  ? Colors.blue.shade700
                                  : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.blue.shade50
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isActive
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isActive
                                    ? Colors.blue.shade700
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          if (!_isLoading && _reactions.isNotEmpty)
            Divider(height: 1, color: Colors.grey.shade200),

          // Body
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFF48706),
          strokeWidth: 2,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.grey.shade400,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _fetchReactions,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _activeTab == 'all'
                  ? '😶'
                  : (_emojiMap[_activeTab] ?? '😶'),
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(height: 12),
            Text(
              _activeTab == 'all'
                  ? 'No reactions yet'
                  : 'No ${_activeTab} reactions',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _buildReactionTile(_filtered[i]),
    );
  }

  Widget _buildReactionTile(Map<String, dynamic> r) {
    final name = r['full_name']?.toString().isNotEmpty == true
        ? r['full_name'].toString()
        : r['username']?.toString() ?? 'Unknown';

    final username = r['username']?.toString() ?? '';
    final type = r['type']?.toString() ?? 'like';
    final userId = r['user']?.toString() ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    // Avatar — already resolved in _fetchReactions
    final rawAvatar = r['avatar']?.toString() ?? '';
    final String? avatarUrl = rawAvatar.isNotEmpty ? rawAvatar : null;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 4,
      ),
      leading: GestureDetector(
        onTap: () {
          if (userId.isEmpty) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SpecificUserProfilePage(userId: userId),
            ),
          );
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: avatarUrl != null
                  ? NetworkImage(avatarUrl)
                  : null,
              child: avatarUrl == null
                  ? Text(
                      initial,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            Positioned(
              bottom: -3,
              right: -3,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.whitecolor,
                  border: Border.all(
                    color: AppColors.whitecolor,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    _emojiMap[type] ?? '👍',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      title: Text(
        name,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: username.isNotEmpty
          ? Text(
              '@$username',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            )
          : null,
    );
  }
}
*/