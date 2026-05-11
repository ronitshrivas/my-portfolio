import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/constant/app_colors.dart';
import 'package:innovator/Innovator/models/Feed_Content_Model.dart';
import 'package:innovator/Innovator/screens/Feed/Inner_Homepage.dart';

// ─── Service ──────────────────────────────────────────────────────────────────

class MyReelsService {
  static const String _base = 'http://36.253.137.34:8005';

  static Map<String, String> _headers() {
    final token = AppData().accessToken ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<({List<FeedContent> reels, String? next})> fetchMyReels({
    required String userId,
    String? cursor,
  }) async {
    final uri =
        cursor != null
            ? Uri.parse(cursor)
            : Uri.parse('$_base/api/reels/?user=$userId');

    log('[MyReels] GET $uri');
    final res = await http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 30));
    log('[MyReels] ${res.statusCode}');

    if (res.statusCode == 200) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      final results =
          (body['results'] as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>()
              .map((j) => FeedContent.fromNewApiPost(j))
              .where((c) => c.id.isNotEmpty)
              .toList();
      final next = body['next']?.toString();
      return (reels: results, next: next);
    }
    throw Exception('Failed to load reels: ${res.statusCode}');
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class MyReelsScreen extends StatefulWidget {
  final String userId;
  const MyReelsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<MyReelsScreen> createState() => _MyReelsScreenState();
}

class _MyReelsScreenState extends State<MyReelsScreen> {
  final List<FeedContent> _reels = [];
  final ScrollController _scroll = ScrollController();
  final Map<String, bool> _reactionState = {};

  bool _loading = false;
  bool _hasMore = true;
  String? _nextCursor;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400 &&
        !_loading &&
        _hasMore) {
      _load();
    }
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await MyReelsService.fetchMyReels(
        userId: widget.userId,
        cursor: _nextCursor,
      );
      if (!mounted) return;
      setState(() {
        _reels.addAll(result.reels);
        _nextCursor = result.next;
        _hasMore = result.next != null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _reels.clear();
      _nextCursor = null;
      _hasMore = true;
      _error = null;
      _reactionState.clear();
    });
    await _load();
  }

  // ── Empty / error states ───────────────────────────────────────────────────

  Widget _buildEmpty() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.video_collection_outlined, size: 72, color: Colors.grey),
        SizedBox(height: 16),
        Text(
          'No reels yet',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Your reels will appear here',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    ),
  );

  Widget _buildError() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 12),
        Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _refresh,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
          ),
          child: const Text(
            'Retry',
            style: TextStyle(color: AppColors.whitecolor),
          ),
        ),
      ],
    ),
  );

  // ── Skeleton — identical to Inner_Homepage ─────────────────────────────────

  Widget _buildSkeleton() => ListView.builder(
    physics: const NeverScrollableScrollPhysics(),
    itemCount: 3,
    itemBuilder: (_, i) => _ShimmerReelCard(showMedia: i.isEven),
  );

  // ── Main list ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading && _reels.isEmpty) return _buildSkeleton();
    if (_error != null && _reels.isEmpty) return _buildError();
    if (_reels.isEmpty) return _buildEmpty();

    // ← Remove RefreshIndicator, return ListView directly
    return ListView.builder(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: _reels.length + (_loading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _reels.length) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(
                color: Color.fromRGBO(244, 135, 6, 1),
              ),
            ),
          );
        }

        final content = _reels[index];
        return RepaintBoundary(
          key: ValueKey(content.id),
          child: FeedItem(
            content: content,
            onLikeToggled: (hasReaction) {
              if (!mounted) return;
              setState(() {
                final hadReaction =
                    _reactionState[content.id] ?? content.isLiked;
                if (hasReaction && !hadReaction) {
                  content.likes = (content.likes + 1).clamp(0, 999999);
                } else if (!hasReaction && hadReaction) {
                  content.likes = (content.likes - 1).clamp(0, 999999);
                }
                content.isLiked = hasReaction;
                _reactionState[content.id] = hasReaction;
              });
            },
            onFollowToggled: (isFollowed) {
              if (!mounted) return;
              setState(() {
                final authorId = content.author.id;
                for (final r in _reels) {
                  if (r.author.id == authorId) r.isFollowed = isFollowed;
                }
              });
            },
            onDeleted: () {
              if (mounted) setState(() => _reels.remove(content));
            },
            onStatusUpdated: (newStatus) {
              if (mounted) setState(() => content.status = newStatus);
            },
          ),
        );
      },
    );
  }
}

// ─── Shimmer skeleton (mirrors _PostSkeleton from Inner_Homepage) ─────────────

class _ShimmerReelCard extends StatefulWidget {
  final bool showMedia;
  const _ShimmerReelCard({required this.showMedia});

  @override
  State<_ShimmerReelCard> createState() => _ShimmerReelCardState();
}

class _ShimmerReelCardState extends State<_ShimmerReelCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Widget _box(double w, double h, {double r = 6}) => AnimatedBuilder(
    animation: _anim,
    builder:
        (_, __) => Opacity(
          opacity: _anim.value,
          child: Container(
            width: w,
            height: h,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(r),
            ),
          ),
        ),
  );

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.whitecolor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
          topLeft: Radius.circular(5),
          topRight: Radius.circular(5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.grey.shade300, Colors.grey.shade200],
                    ),
                  ),
                  child: AnimatedBuilder(
                    animation: _anim,
                    builder:
                        (_, __) => Opacity(
                          opacity: _anim.value,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _box(w * 0.32, 13, r: 4),
                      const SizedBox(height: 6),
                      _box(w * 0.20, 10, r: 4),
                    ],
                  ),
                ),
                _box(76, 26, r: 20),
              ],
            ),
            const SizedBox(height: 12),
            // Text lines
            _box(w * 0.85, 12, r: 4),
            const SizedBox(height: 7),
            _box(w * 0.65, 12, r: 4),
            // Video placeholder
            if (widget.showMedia) ...[
              const SizedBox(height: 12),
              _box(double.infinity, (w - 16) * 0.72, r: 12),
            ],
            const SizedBox(height: 12),
            // Divider
            Container(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 12),
            // Action row
            Row(
              children: [
                AnimatedBuilder(
                  animation: _anim,
                  builder:
                      (_, __) => Opacity(
                        opacity: _anim.value,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                ),
                const SizedBox(width: 6),
                _box(48, 11, r: 4),
                const SizedBox(width: 20),
                AnimatedBuilder(
                  animation: _anim,
                  builder:
                      (_, __) => Opacity(
                        opacity: _anim.value,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                ),
                const SizedBox(width: 6),
                _box(62, 11, r: 4),
                const Spacer(),
                AnimatedBuilder(
                  animation: _anim,
                  builder:
                      (_, __) => Opacity(
                        opacity: _anim.value,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
