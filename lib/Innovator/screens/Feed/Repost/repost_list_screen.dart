import 'dart:convert';
import 'dart:developer' as developer;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/Authorization/Login.dart';
import 'package:innovator/Innovator/constant/app_colors.dart';
import 'package:innovator/Innovator/models/repost_model.dart';
import 'package:innovator/Innovator/screens/Feed/Repost/sharedrepostcard.dart';
import 'package:innovator/Innovator/screens/Likes/Content-Like-Service.dart';
import 'package:innovator/Innovator/screens/Likes/content-Like-Button.dart';
import 'package:innovator/Innovator/screens/chatrrom/screen/chatlistscreen.dart';
import 'package:innovator/Innovator/screens/comment/comment_section.dart';
import 'package:innovator/Innovator/widget/Custom_refresh_Indicator.dart';
import 'package:innovator/Innovator/widget/CustomizeFAB.dart';

const _kOrange = Color.fromRGBO(244, 135, 6, 1);
const _kOrangeLight = Color.fromRGBO(244, 135, 6, 0.10);
const _kGold = Color.fromRGBO(255, 204, 0, 1);
const _kBaseUrl = 'http://36.253.137.34:8005';

class _RepostsApiService {
  static Map<String, String> _headers() {
    final token = AppData().accessToken ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<List<RepostEntry>> fetchReposts({
    required String postId,
    required BuildContext context,
    String? nextUrl,
  }) async {
    final uri =
        nextUrl != null
            ? Uri.parse(nextUrl)
            : Uri.parse('$_kBaseUrl/api/posts/$postId/reposts-list/');

    developer.log('[RepostsList] GET $uri');
    final response = await http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 30));

    developer.log('[RepostsList] Status: ${response.statusCode}');

    if (response.statusCode == 401) {
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
          (_) => false,
        );
      }
      throw Exception('Authentication required');
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to load reposts (${response.statusCode})');
    }

    final decoded = jsonDecode(response.body);
    List<dynamic> rawList = [];

    if (decoded is List) {
      rawList = decoded;
    } else if (decoded is Map) {
      rawList =
          decoded['results'] as List<dynamic>? ??
          decoded['data'] as List<dynamic>? ??
          [];
    }

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(RepostEntry.fromJson)
        .where((e) => e.id.isNotEmpty)
        .toList();
  }
}

class RepostsListScreen extends ConsumerStatefulWidget {
  final String postId;

  /// Shown in the app bar subtitle — pass original post author name if known.
  final String? originalAuthorName;

  const RepostsListScreen({
    Key? key,
    required this.postId,
    this.originalAuthorName,
  }) : super(key: key);

  @override
  _RepostsListScreenState createState() => _RepostsListScreenState();
}

class _RepostsListScreenState extends ConsumerState<RepostsListScreen>
    with SingleTickerProviderStateMixin {
  final List<RepostEntry> _entries = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMsg = '';

  late final AnimationController _headerAnim;

  @override
  void initState() {
    super.initState();
    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _load();
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final entries = await _RepostsApiService.fetchReposts(
        postId: widget.postId,
        context: context,
      );
      if (mounted) {
        setState(() {
          _entries
            ..clear()
            ..addAll(entries);
          _isLoading = false;
        });
        _headerAnim.forward(from: 0);
      }
    } catch (e) {
      developer.log('[RepostsList] error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMsg = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  // ── Time helper ──────────────────────────────────────────────────────────

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inDays > 365) return '${(d.inDays / 365).floor()}y ago';
    if (d.inDays > 30) return '${(d.inDays / 30).floor()}mo ago';
    if (d.inDays > 0) return '${d.inDays}d ago';
    if (d.inHours > 0) return '${d.inHours}h ago';
    if (d.inMinutes > 0) return '${d.inMinutes}m ago';
    return 'Just now';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(chatUnreadCountProvider);
    return Scaffold(
      body: CustomRefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildAppBar(),
            if (_isLoading)
              const SliverFillRemaining(child: _RepostsShimmer())
            else if (_hasError)
              SliverFillRemaining(child: _buildError())
            else if (_entries.isEmpty)
              SliverFillRemaining(child: _buildEmpty())
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _RepostEntryCard(
                      entry: _entries[i],
                      index: i,
                      timeAgo: _timeAgo,
                    ),
                    childCount: _entries.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: CountBadgeFAB(
        count: unreadCount, // ← real-time total
        gifAsset: 'animation/chaticon.gif',
        backgroundColor: Colors.transparent,
        onPressed: () {
          ref.read(mutualFriendsProvider.notifier).refresh();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChatListScreen()),
          ).then((_) {
            ref.invalidate(mutualFriendsProvider);
            //ref.read(mutualFriendsProvider.notifier).refresh();
          });
        },
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      // expandedHeight: 130,
      backgroundColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.black12,
      //surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: Colors.grey.shade800,
        onPressed: () => Navigator.pop(context),
      ),
      // actions: [
      //   IconButton(
      //     icon: const Icon(Icons.refresh_rounded),
      //     color: _kOrange,
      //     onPressed: _isLoading ? null : _load,
      //   ),
      //   const SizedBox(width: 8),
      // ],
      // flexibleSpace: FlexibleSpaceBar(
      //   titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
      //   title: FadeTransition(
      //     opacity: CurvedAnimation(parent: _headerAnim, curve: Curves.easeOut),
      //     child: Row(
      //       mainAxisSize: MainAxisSize.min,
      //       crossAxisAlignment: CrossAxisAlignment.start,
      //       children: [
      //         const Text(
      //           'Reposts',
      //           style: TextStyle(
      //             color: Color(0xFF1A1A1A),
      //             fontSize: 22,
      //             fontWeight: FontWeight.w800,
      //             fontFamily: 'InterThin',
      //             letterSpacing: -0.5,
      //           ),
      //         ),
      //         if (widget.originalAuthorName != null)
      //           Text(
      //             'of @${widget.originalAuthorName}\'s post',
      //             style: TextStyle(
      //               color: Colors.grey.shade500,
      //               fontSize: 11,
      //               fontWeight: FontWeight.w500,
      //               fontFamily: 'InterThin',
      //             ),
      //           ),
      //       ],
      //     ),
      //   ),
      // ),
    );
  }

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Could not load reposts',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              fontFamily: 'InterThin',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMsg,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              fontFamily: 'InterThin',
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kOrange,
              foregroundColor: AppColors.whitecolor,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _kOrangeLight,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.repeat_rounded, size: 48, color: _kOrange),
        ),
        const SizedBox(height: 20),
        const Text(
          'No reposts yet',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'InterThin',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Be the first to repost this!',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade500,
            fontFamily: 'InterThin',
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Count pill in app bar
// ─────────────────────────────────────────────────────────────────────────────

class CountPill extends StatelessWidget {
  final int count;
  const CountPill({required this.count});

  @override
  Widget build(BuildContext context) => Container(
    // padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
    // decoration: BoxDecoration(
    //   gradient: const LinearGradient(colors: [_kOrange, _kGold]),
    //   borderRadius: BorderRadius.circular(20),
    //   boxShadow: [
    //     BoxShadow(
    //       color: _kOrange.withAlpha(55),
    //       blurRadius: 10,
    //       offset: const Offset(0, 3),
    //     ),
    //   ],
    // ),
    child: Row(
      //
      // mainAxisSize: MainAxisSize.min,
      children: [
        //const Icon(Icons.repeat_rounded, color: Colors.black, size: 14),
        const SizedBox(width: 3),
        Text(
          '$count${count == 1 ? '' : ''}',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 11,
            fontFamily: 'InterThin',
          ),
        ),
      ],
    ),
  );
}

class _RepostEntryCard extends StatefulWidget {
  final RepostEntry entry;
  final int index;
  final String Function(DateTime) timeAgo;
  //final FeedContent content;

  const _RepostEntryCard({
    required this.entry,
    required this.index,
    required this.timeAgo,
    //required this.content,
  });

  @override
  State<_RepostEntryCard> createState() => _RepostEntryCardState();
}

class _RepostEntryCardState extends State<_RepostEntryCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  bool _showComments = false; // ← ADD THIS
  int _localLikeCount = 0;
  late int _localCommentCount;

  final ContentLikeService likeService = ContentLikeService(
    baseUrl: 'http://36.253.137.34:8005',
  );
  @override
  void initState() {
    super.initState();
    _localLikeCount = widget.entry.reactionsCount; // ← ADD THIS
    _localCommentCount = widget.entry.commentsCount; // ← shadow the final field
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: widget.index * 55), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _avatar(String url, String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    if (url.isEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey.shade300,
        child: Text(
          initial,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.whitecolor,
            fontSize: 15,
          ),
        ),
      );
    }
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        placeholder:
            (_, __) => CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade200,
              child: Text(
                initial,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              ),
            ),
        errorWidget:
            (_, __, ___) => CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade300,
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppColors.whitecolor,
                  fontSize: 14,
                ),
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    ;
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.whitecolor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(9),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Orange accent bar ──────────────────────────────────────
                Container(
                  height: 3,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [_kOrange, _kGold]),
                  ),
                ),

                // ── Reposter header ────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar with gradient ring
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(colors: [_kOrange, _kGold]),
                        ),
                        child: _avatar(e.avatar, e.username),
                      ),
                      const SizedBox(width: 10),

                      // Name + time + caption
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '@${e.username}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      fontFamily: 'InterThin',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                // Repost badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _kOrangeLight,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.repeat_rounded,
                                        size: 11,
                                        color: _kOrange,
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        'Reposted',
                                        style: TextStyle(
                                          color: _kOrange,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          fontFamily: 'InterThin',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              widget.timeAgo(e.createdAt),
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 11,
                                fontFamily: 'InterThin',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (e.content.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 2),
                    child: Text(
                      e.content,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'InterThin',
                      ),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // ── Embedded original post ─────────────────────────────────
                if (e.sharedPostDetails != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: SharedPostCard(
                      details: e.sharedPostDetails!,
                      compact: true,
                    ),
                  ),

                // ── Stats row ──────────────────────────────────────────────
                // ── Action bar ──────────────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                  child: Row(
                    children: [
                      // Like button — owns count internally, no external counter needed
                      LikeButton(
                        contentId: e.id,
                        initialLikeStatus: false,
                        likeService: likeService,
                        showLabel: true,
                        initialCount: e.reactionsCount,
                      ),

                      const SizedBox(width: 20),

                      // Comment toggle button
                      // Comment toggle button — use _localCommentCount
                      InkWell(
                        onTap:
                            () =>
                                setState(() => _showComments = !_showComments),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 20,
                                color:
                                    _showComments
                                        ? Colors.blue.shade700
                                        : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '$_localCommentCount', // ← use local mutable count
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      _showComments
                                          ? Colors.blue.shade700
                                          : Colors.grey.shade600,
                                  fontFamily: 'InterThin',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Views — read-only
                      _StatChip(
                        icon: Icons.visibility_outlined,
                        value: e.viewsCount,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),

                // ── Inline comments (AnimatedSize collapse/expand) ──────────────────────
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child:
                      _showComments
                          ? Container(
                            margin: const EdgeInsets.only(top: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: CommentSection(
                              contentId: e.id,
                              // In CommentSection onCommentAdded:
                              // onCommentAdded: () {
                              //   if (!mounted) return;
                              //   setState(() => _localCommentCount++);
                              // },
                              onCommentCountChanged: (delta) {
                                if (!mounted) return;
                                setState(
                                  () =>
                                      _localCommentCount = (_localCommentCount +
                                              delta)
                                          .clamp(0, 999999),
                                );
                              },
                            ),
                          )
                          : const SizedBox.shrink(),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final int value;
  final Color color;
  const _StatChip({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: color),
      const SizedBox(width: 4),
      Text(
        '$value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
          fontFamily: 'InterThin',
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer skeleton
// ─────────────────────────────────────────────────────────────────────────────

class _RepostsShimmer extends StatelessWidget {
  const _RepostsShimmer();

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    itemCount: 5,
    itemBuilder: (_, __) => const _ShimCard(),
  );
}

class _ShimCard extends StatefulWidget {
  const _ShimCard();
  @override
  State<_ShimCard> createState() => _ShimCardState();
}

class _ShimCardState extends State<_ShimCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final c =
            Color.lerp(
              const Color(0xFFE8E8E8),
              const Color(0xFFF8F8F8),
              _ctrl.value,
            )!;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.whitecolor,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _S(w: 44, h: 44, r: 22, c: c),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _S(w: 110, h: 13, r: 4, c: c),
                      const SizedBox(height: 5),
                      _S(w: 70, h: 10, r: 4, c: c),
                    ],
                  ),
                  const Spacer(),
                  _S(w: 72, h: 24, r: 20, c: c),
                ],
              ),
              const SizedBox(height: 12),
              _S(w: double.infinity, h: 13, r: 4, c: c),
              const SizedBox(height: 7),
              _S(w: double.infinity * 0.7, h: 13, r: 4, c: c),
              const SizedBox(height: 12),
              // Quoted post skeleton
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _S(w: 28, h: 28, r: 14, c: c),
                        const SizedBox(width: 8),
                        _S(w: 90, h: 11, r: 4, c: c),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _S(w: double.infinity, h: 100, r: 8, c: c),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _S(w: 40, h: 12, r: 4, c: c),
                  const SizedBox(width: 14),
                  _S(w: 40, h: 12, r: 4, c: c),
                  const SizedBox(width: 14),
                  _S(w: 40, h: 12, r: 4, c: c),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _S extends StatelessWidget {
  final double? w;
  final double h;
  final double r;
  final Color c;
  const _S({this.w, required this.h, required this.r, required this.c});

  @override
  Widget build(BuildContext context) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(r)),
  );
}
