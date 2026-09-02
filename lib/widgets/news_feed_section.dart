import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../models/api_response.dart';
import 'package:innovator/innovator/data/models/feed_models.dart';
import '../profile_page.dart';
import '../config/api_config.dart';
import '../services/auth_session.dart';
import 'package:innovator/innovator/data/sources/feed_api.dart';
import '../services/feed_cache.dart';
import '../services/media_cache.dart';
import '../services/pending_post.dart';
import '../services/sound_player.dart';
import '../services/view_reporter.dart';
import 'video_thumbnail_view.dart';
import 'package:innovator/innovator/data/sources/post_view_recorder.dart';
import 'package:innovator/innovator/data/sources/profile_api.dart';
import '../theme/brand_colors.dart';
import 'cached_feed_image.dart';
import 'fast_glass.dart';
import 'feed_video_player.dart';
import 'liquid_pressable.dart';

const _ink = BrandColors.ink;
const _likeRed = Color(0xFFE0245E);
const _repostGreen = Color(0xFF17A275);
const _mediaMinRatio = 0.9;
const _mediaMaxRatio = 1.91;

/// News feed backed by http://36.253.137.34:8012 (`/api/feed`).
class NewsFeedSection extends StatefulWidget {
  const NewsFeedSection({
    super.key,
    this.controller,
    this.padding = EdgeInsets.zero,
    this.pendingPost,
    this.onRetryPending,
    this.onDismissPending,
  });

  final ScrollController? controller;
  final EdgeInsets padding;

  final PendingPost? pendingPost;
  final VoidCallback? onRetryPending;
  final VoidCallback? onDismissPending;

  @override
  State<NewsFeedSection> createState() => _NewsFeedSectionState();
}

class _NewsFeedSectionState extends State<NewsFeedSection> {
  final _feedApi = FeedApi();
  final _posts = <FeedPostDto>[];
  var _page = 1;

  /// Seeds the ranked ordering. A NEW value is generated on first load and on
  /// every pull-to-refresh (fresh order); it stays fixed across pagination of
  /// the same session so page 2 continues page 1.
  String _feedSessionId = DateTime.now().microsecondsSinceEpoch.toString();

  var _loading = true;
  var _loadingMore = false;
  var _hasMore = true;
  var _refreshing = false;
  String? _error;
  ScrollController? _ownedController;

  ScrollController get _scroll =>
      widget.controller ?? (_ownedController ??= ScrollController());

  /// Batches ids of posts the user actually sees so the ranked feed stops
  /// re-showing them. Only the main feed list feeds this.
  final ViewReporter _viewReporter = ViewReporter();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _hydrateFromCache();
    _load(reset: true);
  }

  @override
  void dispose() {
    _viewReporter.dispose();
    _scroll.removeListener(_onScroll);
    _ownedController?.dispose();
    super.dispose();
  }

  void _hydrateFromCache() {
    final snap = FeedCache.snapshot();
    if (snap == null || snap.posts.isEmpty) return;
    _posts
      ..clear()
      ..addAll(snap.posts);
    _page = snap.highestPage;
    _hasMore = snap.hasMore;
    _loading = false;
    InnovatorMediaCache.prefetchPosts(snap.posts.take(12));
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _loading) return;
    final pos = _scroll.position;
    if (pos.pixels > pos.maxScrollExtent - 480) {
      _loadMore();
    }
  }

  Future<void> _load({required bool reset}) async {
    if (reset) {
      // A pull-to-refresh (there are already posts on screen) starts a NEW
      // ranking session and drops the page cache so a genuinely fresh order
      // loads. The very first load keeps its initial session + hydrated cache.
      final isRefresh = _posts.isNotEmpty;
      if (isRefresh) {
        _feedSessionId = DateTime.now().microsecondsSinceEpoch.toString();
        FeedCache.invalidate();
      }
      setState(() {
        _error = null;
        _refreshing = _posts.isNotEmpty;
        _loading = _posts.isEmpty;
        // Network refresh always starts at page 1; keep painted posts.
        _page = 1;
        _hasMore = true;
      });
    }

    final requestPage = reset ? 1 : _page;

    // Instant paint from dynamic page cache when loading more.
    if (!reset) {
      final cached = FeedCache.getPage(requestPage);
      if (cached != null) {
        if (!mounted) return;
        setState(() {
          _appendUnique(cached.posts);
          _hasMore = cached.hasMore;
          _loading = false;
          if (cached.isFresh) _loadingMore = false;
        });
        InnovatorMediaCache.prefetchPosts(cached.posts);
        if (cached.isFresh) return;
        // Stale — fall through and revalidate in background.
      }
    }

    try {
      final page = await _feedApi.getFeed(
        page: requestPage,
        pageSize: ApiConfig.feedPageSize,
        sessionId: _feedSessionId,
      );
      if (!mounted) return;

      FeedCache.putPage(requestPage, page.results, hasMore: page.hasMore);
      InnovatorMediaCache.prefetchPosts(page.results);

      setState(() {
        if (reset) {
          final snap = FeedCache.snapshot();
          _posts
            ..clear()
            ..addAll(snap?.posts ?? page.results);
          _page = snap?.highestPage ?? 1;
          _hasMore = snap?.hasMore ?? page.hasMore;
        } else {
          _appendUnique(page.results);
          _hasMore = page.hasMore;
        }
        _loading = false;
        _loadingMore = false;
        _refreshing = false;
      });

      // Warm next page JSON + media while user reads.
      if (page.hasMore) {
        unawaited(_prefetchPage(requestPage + 1));
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _refreshing = false;
        if (_posts.isEmpty) _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
        _refreshing = false;
        if (_posts.isEmpty) _error = 'Could not load feed';
      });
    }
  }

  void _appendUnique(List<FeedPostDto> incoming) {
    final seen = _posts.map((p) => p.id).toSet();
    for (final p in incoming) {
      if (seen.add(p.id)) _posts.add(p);
    }
  }

  Future<void> _prefetchPage(int page) async {
    if (FeedCache.isFresh(page)) {
      final cached = FeedCache.getPage(page);
      if (cached != null) {
        InnovatorMediaCache.prefetchPosts(cached.posts);
      }
      return;
    }
    try {
      final data = await _feedApi.getFeed(
        page: page,
        pageSize: ApiConfig.feedPageSize,
        sessionId: _feedSessionId,
      );
      FeedCache.putPage(page, data.results, hasMore: data.hasMore);
      InnovatorMediaCache.prefetchPosts(data.results);
    } catch (_) {}
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loadingMore) return;
    setState(() {
      _loadingMore = true;
      _page += 1;
    });
    await _load(reset: false);
  }

  void _replacePost(FeedPostDto updated) {
    final i = _posts.indexWhere((p) => p.id == updated.id);
    if (i < 0) return;
    setState(() => _posts[i] = updated);
  }

  void _removePost(String id) {
    setState(() => _posts.removeWhere((p) => p.id == id));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _posts.isEmpty) {
      return ListView(
        padding: widget.padding,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          _FeedSkeletonCard(),
          _FeedSkeletonCard(),
          _FeedSkeletonCard(),
        ],
      );
    }
    if (_error != null && _posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              TextButton(
                onPressed: () => _load(reset: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // One screen of look-ahead keeps scrolling smooth without building a huge
    // number of offscreen cards each frame.
    final cacheExtent = MediaQuery.sizeOf(context).height;
    // A leading "posting…" card occupies index 0 while an upload is in flight.
    final hasPending = widget.pendingPost != null;
    final leading = hasPending ? 1 : 0;
    final baseCount = _posts.length + (_loadingMore ? 1 : 0);
    final itemCount = leading + (baseCount == 0 ? 1 : baseCount);

    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: Stack(
        children: [
          ListView.builder(
            controller: _scroll,
            padding: widget.padding,
            itemCount: itemCount,
            cacheExtent: cacheExtent,
            physics: const SlipperyScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: true,
            addSemanticIndexes: false,
            itemBuilder: (context, rawIndex) {
              if (hasPending && rawIndex == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PostingCard(
                    pending: widget.pendingPost!,
                    onRetry: widget.onRetryPending,
                    onDismiss: widget.onDismissPending,
                  ),
                );
              }
              final index = rawIndex - leading;
              if (_posts.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: Text('No posts yet — be the first.')),
                );
              }
              if (index >= _posts.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.2),
                    ),
                  ),
                );
              }
              final item = _posts[index];
              return Padding(
                key: ValueKey('feed-card-${item.id}'),
                padding: EdgeInsets.only(
                  bottom: index == _posts.length - 1 && !_loadingMore ? 0 : 12,
                ),
                // Record the id once the card is ≥50% visible so the ranked
                // feed stops re-showing it. No setState — just buffer the id.
                child: VisibilityDetector(
                  key: ValueKey('feed-vis-${item.id}'),
                  onVisibilityChanged: (info) {
                    if (info.visibleFraction >= 0.5) {
                      _viewReporter.record(item.id);
                    }
                  },
                  child: RepaintBoundary(
                    child: FeedCard(
                      post: item,
                      onChanged: _replacePost,
                      onDeleted: _removePost,
                    ),
                  ),
                ),
              );
            },
          ),
          if (_refreshing)
            const Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Shimmer placeholder shown while the feed is loading — mirrors the real
/// card's shape (avatar, two text lines, a media block, action row).
class _FeedSkeletonCard extends StatelessWidget {
  const _FeedSkeletonCard();

  @override
  Widget build(BuildContext context) {
    final base = _ink.withValues(alpha: .08);
    final highlight = _ink.withValues(alpha: .03);
    Widget block(double w, double h, [double r = 8]) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(r),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 15, 0, 18),
      child: Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  block(42, 42, 999),
                  const SizedBox(width: 11),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      block(120, 13),
                      const SizedBox(height: 6),
                      block(80, 10),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: block(double.infinity, 12),
            ),
            const SizedBox(height: 12),
            Container(
              height: MediaQuery.sizeOf(context).width * .7,
              margin: const EdgeInsets.symmetric(horizontal: 0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Standalone view of a single post — used when opening a specific feed item
/// (e.g. tapping a "liked your post" notification). Loads by id, then renders
/// the same card as the feed.
class SinglePostPage extends StatefulWidget {
  const SinglePostPage({super.key, required this.postId});

  final String postId;

  @override
  State<SinglePostPage> createState() => _SinglePostPageState();
}

class _SinglePostPageState extends State<SinglePostPage> {
  final _feedApi = FeedApi();
  FeedPostDto? _post;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final post = await _feedApi.getPost(widget.postId);
      if (!mounted) return;
      setState(() {
        _post = post;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load this post';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _ink,
        title: const Text('Post'),
      ),
      body: SafeArea(
        child:
            _loading
                ? const Center(
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
                : _error != null
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        TextButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
                : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    FeedCard(
                      post: _post!,
                      onChanged: (p) => setState(() => _post = p),
                      onDeleted: (_) => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
      ),
    );
  }
}

class FeedCard extends StatefulWidget {
  const FeedCard({
    super.key,
    required this.post,
    required this.onChanged,
    required this.onDeleted,
  });

  final FeedPostDto post;
  final ValueChanged<FeedPostDto> onChanged;
  final ValueChanged<String> onDeleted;

  @override
  State<FeedCard> createState() => FeedCardState();
}

class FeedCardState extends State<FeedCard> {
  final _feedApi = FeedApi();
  final _profileApi = ProfileApi();
  bool _busy = false;

  FeedPostDto get post => widget.post;

  /// The reaction palette (backend stores the type string as-is).
  static const _reactionChoices = <({String type, String emoji})>[
    (type: 'like', emoji: '👍'),
    (type: 'love', emoji: '❤️'),
    (type: 'haha', emoji: '😂'),
    (type: 'wow', emoji: '😮'),
    (type: 'sad', emoji: '😢'),
    (type: 'angry', emoji: '😡'),
  ];

  /// The single reaction the current user chose, or null.
  String? get _myReaction =>
      post.currentUserReactions.isNotEmpty
          ? post.currentUserReactions.first
          : null;

  /// Emoji for the user's reaction, or empty when none.
  String get _myReactionEmoji {
    final type = _myReaction;
    if (type == null) return '';
    final match = _reactionChoices.where((r) => r.type == type);
    return match.isNotEmpty ? match.first.emoji : '';
  }

  /// Just the count — the emoji is rendered as the button's leading glyph.
  String get _reactionLabel => '${post.reactionsCount}';

  @override
  void initState() {
    super.initState();
    PostViewRecorder.schedule(post.id);
  }

  Future<void> _openPostMenu(BuildContext buttonContext) async {
    HapticFeedback.selectionClick();
    final box = buttonContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final origin = box.localToGlobal(Offset.zero);
    final anchor = origin & box.size;

    final action = await Navigator.of(
      context,
    ).push<_FeedMenuAction>(_FeedMenuRoute(anchorRect: anchor));
    if (!mounted || action == null) return;

    switch (action) {
      case _FeedMenuAction.repost:
        await _repost();
      case _FeedMenuAction.copy:
        await Clipboard.setData(ClipboardData(text: post.content ?? ''));
        HapticFeedback.selectionClick();
        _toast('Copied');
      case _FeedMenuAction.block:
        HapticFeedback.mediumImpact();
        try {
          await _profileApi.block(post.userId);
          _toast('Blocked ${post.displayAuthor}');
        } on ApiException catch (e) {
          _toast(e.message);
        }
      case _FeedMenuAction.delete:
        await _deleteOwnPost();
    }
  }

  Future<void> _repost() async {
    HapticFeedback.lightImpact();
    final choice = await showModalBottomSheet<_RepostChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _RepostSheet(),
    );
    if (choice == null || !mounted) return;

    String thought = '';
    if (choice == _RepostChoice.withThought) {
      final text = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _RepostThoughtSheet(post: post),
      );
      if (text == null || !mounted) return; // cancelled
      thought = text.trim();
    }

    try {
      await _feedApi.repost(sharedPostId: post.id, thought: thought);
      widget.onChanged(post.copyWith(shareCount: post.shareCount + 1));
      _toast(thought.isEmpty ? 'Reposted' : 'Reposted with your thoughts');
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  void _toast(String label) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        backgroundColor: _ink.withValues(alpha: .92),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        duration: const Duration(milliseconds: 1600),
      ),
    );
  }

  void _openAuthorProfile() {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder:
            (_, animation, __) => FadeTransition(
              opacity: animation,
              child: AuthorProfilePage(
                name: post.displayAuthor,
                authUserId: post.userId,
                username: post.username,
              ),
            ),
      ),
    );
  }

  void _openAvatarFullscreen() {
    HapticFeedback.selectionClick();
    final letter =
        post.displayAuthor.isEmpty ? '?' : post.displayAuthor[0].toUpperCase();
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: .82),
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder:
            (_, animation, __) => _AvatarLightbox(
              letter: letter,
              name: post.displayAuthor,
              imageUrl: post.avatar,
              heroTag: 'feed-avatar-${post.id}',
              animation: animation,
            ),
      ),
    );
  }

  /// Quick tap: toggle a plain 'like'.
  Future<void> _toggleLike() => _react('like');

  /// One reaction per user (Facebook-style): picking a new type replaces the
  /// old one; picking the same type again clears it.
  Future<void> _react(String type) async {
    if (_busy) return;
    HapticFeedback.lightImpact();
    final previous = post;
    final current =
        previous.currentUserReactions.isNotEmpty
            ? previous.currentUserReactions.first
            : null;
    final isSame = current == type;
    final hadReaction = current != null;

    final next = isSame ? <String>[] : <String>[type];
    final delta = isSame ? -1 : (hadReaction ? 0 : 1);
    // Play the reaction sound when adding/changing a reaction (not on clear).
    if (!isSame) SoundPlayer.instance.reaction();

    widget.onChanged(
      previous.copyWith(
        reactionsCount:
            (previous.reactionsCount + delta).clamp(0, 1 << 30).toInt(),
        currentUserReactions: next,
      ),
    );
    setState(() => _busy = true);
    try {
      await _feedApi.react(postId: previous.id, type: type);
      FeedCache.invalidate();
    } on ApiException catch (e) {
      widget.onChanged(previous);
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openReactionPicker([BuildContext? anchorContext]) {
    HapticFeedback.mediumImpact();

    // Position the bar just above the like button when we have its box.
    Offset? anchor;
    final box = anchorContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      anchor = box.localToGlobal(Offset.zero);
    }
    final screen = MediaQuery.sizeOf(context);

    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .15),
      builder: (dialogContext) {
        final bar = Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: BrandColors.canvas,
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: _ink.withValues(alpha: .18),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            // Scale the whole pill down if it can't fit the screen width, so
            // it never overflows on any device size.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final r in _reactionChoices)
                    FastTap(
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _react(r.type);
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        // 'love' can render as a white/outline heart on some
                        // emoji fonts, so draw it as a guaranteed-red icon.
                        child:
                            r.type == 'love'
                                ? const Icon(
                                  Icons.favorite_rounded,
                                  color: _likeRed,
                                  size: 28,
                                )
                                : Text(
                                  r.emoji,
                                  style: const TextStyle(fontSize: 28),
                                ),
                      ),
                    ),
                  if (post.reactionsCount > 0) ...[
                    Container(
                      width: 1,
                      height: 26,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: _ink.withValues(alpha: .12),
                    ),
                    FastTap(
                      onTap: () {
                        Navigator.pop(dialogContext);
                        _openLikes();
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Icon(
                          Icons.people_alt_rounded,
                          size: 22,
                          color: _ink.withValues(alpha: .6),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );

        // Cap the pill to the screen width (minus a 12px gutter each side) so
        // it can never overflow, then float it just above the like button.
        final capped = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: screen.width - 24),
          child: bar,
        );
        if (anchor == null) {
          return Center(child: capped);
        }
        final top = (anchor.dy - 64).clamp(60.0, screen.height - 120);
        return Stack(children: [Positioned(left: 12, top: top, child: capped)]);
      },
    );
  }

  Future<void> _toggleFollow() async {
    if (_busy || post.userId.isEmpty) return;
    final me = AuthSession.instance.userId;
    if (me != null && me == post.userId) return;
    HapticFeedback.selectionClick();
    SoundPlayer.instance.follow();
    final wasStatus = post.followStatus;
    final next = !post.isFollowed;
    widget.onChanged(
      post.copyWith(isFollowed: next, followStatus: next ? 'accepted' : 'none'),
    );
    setState(() => _busy = true);
    try {
      final result = await _profileApi.toggleFollow(post.userId);
      widget.onChanged(
        post.copyWith(
          isFollowed: result.isFollowing,
          followStatus: result.status,
        ),
      );
      // Drop the cached feed pages so a later refresh re-reads the real
      // is_followed from the server instead of a stale pre-follow snapshot.
      FeedCache.invalidate();
    } on ApiException catch (e) {
      widget.onChanged(
        post.copyWith(isFollowed: !next, followStatus: wasStatus),
      );
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openComments() async {
    HapticFeedback.selectionClick();
    final added = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(postId: post.id),
    );
    if (added != null && added > 0) {
      widget.onChanged(
        post.copyWith(commentsCount: post.commentsCount + added),
      );
    }
  }

  void _openLikes() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LikesSheet(post: post),
    );
  }

  void _openReposts() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RepostsSheet(post: post),
    );
  }

  Future<void> _deleteOwnPost() async {
    final me = AuthSession.instance.userId;
    if (me == null || me != post.userId) return;
    try {
      await _feedApi.deletePost(post.id);
      widget.onDeleted(post.id);
      _toast('Post deleted');
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwn = AuthSession.instance.userId == post.userId;
    // Subtitle shows occupation · category · date (skipping any empty part).
    final category =
        post.categories.isNotEmpty ? post.categories.first.name.trim() : '';
    final occupation = post.occupation?.trim() ?? '';
    final subtitle = [
      if (occupation.isNotEmpty) occupation,
      if (category.isNotEmpty) category,
      formatFeedTime(post.createdAt),
    ].where((e) => e.isNotEmpty).join(' · ');

    return FastGlass(
      // Opaque frosted card (no live blur) so fast scrolling stays smooth.
      borderRadius: BorderRadius.circular(26),
      padding: const EdgeInsets.fromLTRB(0, 15, 0, 8),
      blur: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,

            children: [
              const SizedBox(width: 8),
              FastTap(
                onTap: _openAvatarFullscreen,
                borderRadius: BorderRadius.circular(999),
                child: Hero(
                  tag: 'feed-avatar-${post.id}',
                  child: _Avatar(
                    letter:
                        post.displayAuthor.isEmpty
                            ? '?'
                            : post.displayAuthor[0],
                    imageUrl: post.avatar,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: FastTap(
                            onTap: _openAuthorProfile,
                            borderRadius: BorderRadius.circular(6),
                            child: Text(
                              post.displayAuthor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _ink,
                                letterSpacing: -.2,
                              ),
                            ),
                          ),
                        ),
                        if (post.isVerified) ...[
                          const SizedBox(width: 4),
                          const _NameBadge(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: _ink.withValues(alpha: .45),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!isOwn)
                _FollowButton(
                  following: post.isFollowed,
                  status: post.followStatus,
                  onTap: _toggleFollow,
                ),
              const SizedBox(width: 2),
              Builder(
                builder:
                    (buttonContext) => FastTap(
                      onTap: () => _openPostMenu(buttonContext),
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.more_vert_outlined,
                          size: 20,
                          color: _ink.withValues(alpha: .4),
                        ),
                      ),
                    ),
              ),
            ],
          ),
          if ((post.content ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ExpandableStatus(text: post.content!.trim()),
            ),
          ],
          if (post.sharedPost != null) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SharedPostPreview(post: post.sharedPost!),
            ),
          ],
          if (post.media.isNotEmpty) ...[
            const SizedBox(height: 12),
            _MediaCollage(items: post.media),
          ],
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Builder(
                  builder:
                      (likeContext) => _ActionButton(
                        // 'love' shows the red heart icon; other reactions show
                        // their emoji; no reaction shows the outline heart.
                        icon:
                            _myReaction == 'love'
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                        emoji: _myReaction == 'love' ? '' : _myReactionEmoji,
                        label: _reactionLabel,
                        active: _myReaction != null,
                        activeColor: _likeRed,
                        onTap: _toggleLike,
                        onLongPress: () => _openReactionPicker(likeContext),
                      ),
                ),
                _ActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: '${post.commentsCount}',
                  onTap: _openComments,
                ),
                _ActionButton(
                  icon: Icons.repeat_rounded,
                  label: '${post.shareCount}',
                  activeColor: _repostGreen,
                  onTap: _repost,
                  onLongPress: post.shareCount > 0 ? _openReposts : null,
                ),
                _ActionButton(
                  icon: Icons.ios_share_rounded,
                  label: 'Share',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Clipboard.setData(
                      ClipboardData(text: post.content ?? post.id),
                    );
                    _toast('Link copied');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SharedPostPreview extends StatelessWidget {
  const _SharedPostPreview({required this.post});
  final FeedPostDto post;

  void _openOriginalAuthor(BuildContext context) {
    final id = post.userId.trim();
    if (id.isEmpty) return;
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder:
            (_, animation, __) => FadeTransition(
              opacity: animation,
              child: AuthorProfilePage(
                name: post.displayAuthor,
                authUserId: post.userId,
                username: post.username,
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final letter = post.displayAuthor.isEmpty ? '?' : post.displayAuthor[0];
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _ink.withValues(alpha: .1)),
        color: Colors.white.withValues(alpha: .35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FastTap(
                  onTap: () => _openOriginalAuthor(context),
                  borderRadius: BorderRadius.circular(999),
                  child: Row(
                    children: [
                      _SmallAvatar(letter: letter, imageUrl: post.avatar),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          post.displayAuthor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            color: _ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if ((post.content ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    post.content!.trim(),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: _ink.withValues(alpha: .7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // The original post's media (empty on the outer repost, present here).
          if (post.media.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _MediaCollage(items: post.media),
            ),
        ],
      ),
    );
  }
}

/// Compact circular avatar for the shared-post header (smaller than [_Avatar]).
class _SmallAvatar extends StatelessWidget {
  const _SmallAvatar({required this.letter, this.imageUrl});

  final String letter;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    return Container(
      width: 26,
      height: 26,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: BrandColors.secondarySurface.withValues(alpha: .3),
      ),
      child:
          (url != null && url.isNotEmpty)
              ? CachedFeedImage(
                url: url,
                fit: BoxFit.cover,
                width: 26,
                height: 26,
                memCacheWidth: 72,
                errorWidget: Center(
                  child: Text(
                    letter.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ),
              )
              : Center(
                child: Text(
                  letter.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
              ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.letter, this.imageUrl});

  final String letter;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [BrandColors.secondarySurface, Color(0xFF8A93A8)],
        ),
      ),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: .95),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child:
            url != null && url.isNotEmpty
                ? ClipOval(
                  child: CachedFeedImage(
                    url: url,
                    fit: BoxFit.cover,
                    width: 42,
                    height: 42,
                    memCacheWidth: 96,
                    memCacheHeight: 96,
                    fadeDuration: const Duration(milliseconds: 120),
                    errorWidget: Center(
                      child: Text(
                        letter.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                        ),
                      ),
                    ),
                  ),
                )
                : Center(
                  child: Text(
                    letter.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ),
      ),
    );
  }
}

/// Immersive avatar preview — tap anywhere to dismiss.
class _AvatarLightbox extends StatelessWidget {
  const _AvatarLightbox({
    required this.letter,
    required this.name,
    required this.heroTag,
    required this.animation,
    this.imageUrl,
  });

  final String letter;
  final String name;
  final String? imageUrl;
  final String heroTag;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final url = imageUrl?.trim();

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).pop(),
        child: SafeArea(
          child: FadeTransition(
            opacity: curved,
            child: Stack(
              children: [
                Center(
                  child: ScaleTransition(
                    scale: Tween<double>(begin: .86, end: 1).animate(curved),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Hero(
                          tag: heroTag,
                          child: Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  BrandColors.secondarySurface,
                                  Color(0xFF8A93A8),
                                ],
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .9),
                                width: 3,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child:
                                url != null && url.isNotEmpty
                                    ? CachedFeedImage(
                                      url: url,
                                      fit: BoxFit.cover,
                                      memCacheWidth: 720,
                                    )
                                    : Center(
                                      child: Text(
                                        letter,
                                        style: const TextStyle(
                                          fontSize: 96,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fullscreen feed media gallery — swipe between images, pinch to zoom, tap close.
class _FeedMediaLightbox extends StatefulWidget {
  const _FeedMediaLightbox({
    required this.items,
    required this.initialIndex,
    required this.animation,
  });

  final List<FeedMediaItem> items;
  final int initialIndex;
  final Animation<double> animation;

  @override
  State<_FeedMediaLightbox> createState() => _FeedMediaLightboxState();
}

class _FeedMediaLightboxState extends State<_FeedMediaLightbox> {
  late final PageController _page = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: widget.animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final total = widget.items.length;

    return Material(
      type: MaterialType.transparency,
      child: FadeTransition(
        opacity: curved,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Dim backdrop — tap empty area to dismiss.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _close,
              child: const ColoredBox(color: Colors.transparent),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _close,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const Spacer(),
                        if (total > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: Colors.white.withValues(alpha: .12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .2),
                              ),
                            ),
                            child: Text(
                              '${_index + 1} / $total',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _page,
                      itemCount: total,
                      onPageChanged: (i) => setState(() => _index = i),
                      itemBuilder: (context, i) {
                        final item = widget.items[i];
                        if (item.isVideo) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: FeedVideoPlayer(
                              url: item.file,
                              posterUrl: item.thumbnail,
                              fit: BoxFit.contain,
                              autoplay: i == _index,
                              muted: false,
                              looping: true,
                              showControls: true,
                              requireVisible: false,
                            ),
                          );
                        }
                        final url = _MediaCollage.displayUrl(item);
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Center(
                            child: InteractiveViewer(
                              minScale: 1,
                              maxScale: 4,
                              child:
                                  url.isEmpty
                                      ? const Icon(
                                        Icons.broken_image_outlined,
                                        color: Colors.white38,
                                        size: 64,
                                      )
                                      : CachedFeedImage(
                                        url: url,
                                        fit: BoxFit.contain,
                                        memCacheWidth: 1080,
                                        fadeDuration: Duration.zero,
                                        errorWidget: const Icon(
                                          Icons.broken_image_outlined,
                                          color: Colors.white38,
                                          size: 64,
                                        ),
                                      ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (total > 1)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(total.clamp(0, 12), (i) {
                          final active = i == _index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: active ? 16 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: Colors.white.withValues(
                                alpha: active ? .95 : .35,
                              ),
                            ),
                          );
                        }),
                      ),
                    )
                  else
                    const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({required this.postId});
  final String postId;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _api = FeedApi();
  final _controller = TextEditingController();
  final _comments = <FeedComment>[];
  var _loading = true;
  var _sending = false;
  var _added = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.comments(postId: widget.postId);
      if (!mounted) return;
      setState(() {
        _comments
          ..clear()
          ..addAll(list);
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final created = await _api.createComment(
        postId: widget.postId,
        content: text,
      );
      if (!mounted) return;
      setState(() {
        _comments.insert(0, created);
        _controller.clear();
        _sending = false;
        _added += 1;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _editComment(FeedComment comment) async {
    final controller = TextEditingController(text: comment.content ?? '');
    final newText = await showDialog<String>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Edit comment'),
            content: TextField(
              controller: controller,
              autofocus: true,
              maxLines: 4,
              minLines: 1,
              decoration: const InputDecoration(
                hintText: 'Update your comment…',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed:
                    () => Navigator.pop(dialogContext, controller.text.trim()),
                child: const Text('Save'),
              ),
            ],
          ),
    );
    if (newText == null || newText.isEmpty || newText == comment.content)
      return;
    try {
      final updated = await _api.updateComment(comment.id, newText);
      if (!mounted) return;
      setState(() {
        final i = _comments.indexWhere((c) => c.id == comment.id);
        if (i >= 0) _comments[i] = updated;
      });
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    }
  }

  Future<void> _deleteComment(FeedComment comment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: const Text('Delete comment?'),
            content: const Text('This can\'t be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _likeRed),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirm != true) return;
    try {
      await _api.deleteComment(comment.id);
      if (!mounted) return;
      setState(() {
        _comments.removeWhere((c) => c.id == comment.id);
        _added -= 1;
      });
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: .72,
          child: Material(
            color: BrandColors.canvas,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _ink.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Comments',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context, _added),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child:
                      _loading
                          ? const _CommentSkeletonList()
                          : _error != null
                          ? Center(child: Text(_error!))
                          : _comments.isEmpty
                          ? const Center(child: Text('No comments yet'))
                          : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            itemCount: _comments.length,
                            separatorBuilder:
                                (_, __) => const SizedBox(height: 14),
                            itemBuilder: (_, i) {
                              final c = _comments[i];
                              return _CommentTile(
                                comment: c,
                                onEdit: () => _editComment(c),
                                onDelete: () => _deleteComment(c),
                              );
                            },
                          ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: InputDecoration(
                              hintText: 'Add a comment…',
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: .7),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _send(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: _sending ? null : _send,
                          style: IconButton.styleFrom(
                            backgroundColor: BrandColors.secondarySurface,
                          ),
                          icon:
                              _sending
                                  ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                  : const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single comment: avatar, author, dark body text, time, and a menu with
/// reply / edit / delete. Replies load inline on demand.
class _CommentTile extends StatefulWidget {
  const _CommentTile({
    required this.comment,
    required this.onEdit,
    required this.onDelete,
  });

  final FeedComment comment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  final _api = FeedApi();
  final _replies = <FeedComment>[];
  final _replyController = TextEditingController();
  bool _showReplies = false;
  bool _loadingReplies = false;
  bool _composingReply = false;
  bool _sendingReply = false;

  FeedComment get comment => widget.comment;

  bool get isOwn {
    final me = AuthSession.instance.username;
    return me != null && me == comment.username;
  }

  void _openProfile() {
    final id = comment.userId?.trim();
    if (id == null || id.isEmpty) return;
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => AuthorProfilePage(
              name: comment.username ?? 'User',
              authUserId: id,
              username: comment.username,
            ),
      ),
    );
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _toggleReplies() async {
    if (_showReplies) {
      setState(() => _showReplies = false);
      return;
    }
    setState(() {
      _showReplies = true;
      _loadingReplies = _replies.isEmpty;
    });
    if (_replies.isNotEmpty) return;
    try {
      final list = await _api.replies(comment.id);
      if (!mounted) return;
      setState(() {
        _replies
          ..clear()
          ..addAll(list);
        _loadingReplies = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingReplies = false);
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _sendingReply) return;
    setState(() => _sendingReply = true);
    try {
      final reply = await _api.createReply(parentId: comment.id, content: text);
      if (!mounted) return;
      setState(() {
        _replies.add(reply);
        _replyController.clear();
        _composingReply = false;
        _sendingReply = false;
        _showReplies = true;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _sendingReply = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _openMenu() {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (sheetContext) => SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BrandColors.canvas,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.reply_rounded, color: _ink),
                    title: const Text('Reply'),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      setState(() => _composingReply = true);
                    },
                  ),
                  if (isOwn) ...[
                    ListTile(
                      leading: const Icon(Icons.edit_outlined, color: _ink),
                      title: const Text('Edit'),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        widget.onEdit();
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.delete_outline_rounded,
                        color: _likeRed,
                      ),
                      title: const Text(
                        'Delete',
                        style: TextStyle(color: _likeRed),
                      ),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        widget.onDelete();
                      },
                    ),
                  ],
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = comment.username?.trim();
    final letter = (name == null || name.isEmpty) ? '?' : name[0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FastTap(
              onTap: _openProfile,
              borderRadius: BorderRadius.circular(999),
              child: _Avatar(letter: letter, imageUrl: comment.avatar),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      FastTap(
                        onTap: _openProfile,
                        borderRadius: BorderRadius.circular(6),
                        child: Text(
                          name ?? 'User',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: _ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        formatFeedTime(comment.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: _ink.withValues(alpha: .4),
                        ),
                      ),
                      const Spacer(),
                      FastTap(
                        onTap: _openMenu,
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.more_horiz_rounded,
                            size: 18,
                            color: _ink.withValues(alpha: .4),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    comment.content ?? '',
                    style: TextStyle(
                      color: _ink.withValues(alpha: .82),
                      height: 1.35,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      FastTap(
                        onTap: () => setState(() => _composingReply = true),
                        borderRadius: BorderRadius.circular(6),
                        child: Text(
                          'Reply',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _ink.withValues(alpha: .5),
                          ),
                        ),
                      ),
                      if (comment.replyCount > 0 || _replies.isNotEmpty) ...[
                        const SizedBox(width: 14),
                        FastTap(
                          onTap: _toggleReplies,
                          borderRadius: BorderRadius.circular(6),
                          child: Text(
                            _showReplies
                                ? 'Hide replies'
                                : 'View ${_replies.isNotEmpty ? _replies.length : comment.replyCount} '
                                    '${(_replies.isNotEmpty ? _replies.length : comment.replyCount) == 1 ? 'reply' : 'replies'}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: BrandColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_composingReply)
          Padding(
            padding: const EdgeInsets.only(left: 52, top: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    autofocus: true,
                    style: const TextStyle(color: _ink, fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'Write a reply…',
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: .7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _sendReply(),
                  ),
                ),
                IconButton(
                  onPressed: _sendingReply ? null : _sendReply,
                  icon:
                      _sendingReply
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.send_rounded, size: 20),
                ),
              ],
            ),
          ),
        if (_showReplies)
          Padding(
            padding: const EdgeInsets.only(left: 52, top: 8),
            child:
                _loadingReplies
                    ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final r in _replies)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Avatar(
                                  letter:
                                      (r.username?.trim().isNotEmpty == true)
                                          ? r.username!.trim()[0]
                                          : '?',
                                  imageUrl: r.avatar,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.username ?? 'User',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12.5,
                                          color: _ink,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        r.content ?? '',
                                        style: TextStyle(
                                          color: _ink.withValues(alpha: .8),
                                          height: 1.3,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
          ),
      ],
    );
  }
}

/// Shimmer placeholder rows while comments load.
class _CommentSkeletonList extends StatelessWidget {
  const _CommentSkeletonList();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _ink.withValues(alpha: .08),
      highlightColor: _ink.withValues(alpha: .03),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder:
            (_, __) => Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 110,
                        height: 11,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        height: 11,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

enum _RepostChoice { direct, withThought }

/// Bottom sheet letting the user repost directly or add their thoughts.
class _RepostSheet extends StatelessWidget {
  const _RepostSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: BrandColors.canvas,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _ink.withValues(alpha: .2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.repeat_rounded, color: _repostGreen),
              title: const Text(
                'Repost',
                style: TextStyle(fontWeight: FontWeight.w600, color: _ink),
              ),
              subtitle: Text(
                'Share instantly with your followers',
                style: TextStyle(color: _ink.withValues(alpha: .5)),
              ),
              onTap: () => Navigator.pop(context, _RepostChoice.direct),
            ),
            ListTile(
              leading: const Icon(Icons.edit_note_rounded, color: _ink),
              title: const Text(
                'Repost with your thoughts',
                style: TextStyle(fontWeight: FontWeight.w600, color: _ink),
              ),
              subtitle: Text(
                'Add a note before sharing',
                style: TextStyle(color: _ink.withValues(alpha: .5)),
              ),
              onTap: () => Navigator.pop(context, _RepostChoice.withThought),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Composer for a repost-with-thought — returns the entered text on send.
class _RepostThoughtSheet extends StatefulWidget {
  const _RepostThoughtSheet({required this.post});

  final FeedPostDto post;

  @override
  State<_RepostThoughtSheet> createState() => _RepostThoughtSheetState();
}

class _RepostThoughtSheetState extends State<_RepostThoughtSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: BrandColors.canvas,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _ink.withValues(alpha: .2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Add your thoughts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Reposting @${widget.post.displayAuthor}',
                style: TextStyle(
                  fontSize: 12.5,
                  color: _ink.withValues(alpha: .5),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                autofocus: true,
                maxLines: 4,
                minLines: 2,
                decoration: InputDecoration(
                  hintText: 'Say something about this…',
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: .7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: BrandColors.secondarySurface,
                    ),
                    onPressed:
                        () => Navigator.pop(context, _controller.text.trim()),
                    child: const Text('Repost'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shared header used by the likes / reposts list sheets.
Widget _sheetHandle() => Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    const SizedBox(height: 10),
    Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: _ink.withValues(alpha: .2),
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  ],
);

/// Likes list — the backend exposes only reaction id/type/date (no per-user
/// info), so this shows the total and a breakdown by reaction type.
class _LikesSheet extends StatefulWidget {
  const _LikesSheet({required this.post});

  final FeedPostDto post;

  @override
  State<_LikesSheet> createState() => _LikesSheetState();
}

class _LikesSheetState extends State<_LikesSheet> {
  final _api = FeedApi();
  final _reactions = <FeedReaction>[];
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _api.reactionsForPost(widget.post.id);
      if (!mounted) return;
      setState(() {
        _reactions
          ..clear()
          ..addAll(list);
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  void _openReactorProfile(FeedReaction r) {
    final id = r.userId?.trim();
    if (id == null || id.isEmpty) return;
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => AuthorProfilePage(
              name: r.username ?? 'User',
              authUserId: id,
              username: r.username,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: .55,
        child: Material(
          color: BrandColors.canvas,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Column(
            children: [
              _sheetHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_reactions.isNotEmpty ? _reactions.length : widget.post.reactionsCount} likes',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    _loading
                        ? const _CommentSkeletonList()
                        : _error != null
                        ? Center(child: Text(_error!))
                        : _reactions.isEmpty
                        ? const Center(child: Text('No reactions yet'))
                        : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: _reactions.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final r = _reactions[i];
                            final name = r.username?.trim();
                            final letter =
                                (name == null || name.isEmpty) ? '?' : name[0];
                            return FastTap(
                              onTap: () => _openReactorProfile(r),
                              borderRadius: BorderRadius.circular(12),
                              child: Row(
                                children: [
                                  _Avatar(letter: letter, imageUrl: r.avatar),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      name ?? 'User',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: _ink,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.favorite_rounded,
                                    size: 18,
                                    color: _likeRed.withValues(alpha: .8),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reposts list — the posts that reposted this one (each with the reposter's
/// name, avatar, and any added thought).
class _RepostsSheet extends StatefulWidget {
  const _RepostsSheet({required this.post});

  final FeedPostDto post;

  @override
  State<_RepostsSheet> createState() => _RepostsSheetState();
}

class _RepostsSheetState extends State<_RepostsSheet> {
  final _api = FeedApi();
  final _reposts = <FeedPostDto>[];
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final page = await _api.repostsForPost(widget.post.id);
      if (!mounted) return;
      setState(() {
        _reposts
          ..clear()
          ..addAll(page.results);
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: .72,
        child: Material(
          color: BrandColors.canvas,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Column(
            children: [
              _sheetHandle(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Reposts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child:
                    _loading
                        ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                        : _error != null
                        ? Center(child: Text(_error!))
                        : _reposts.isEmpty
                        ? const Center(child: Text('No reposts yet'))
                        : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _reposts.length,
                          separatorBuilder:
                              (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final r = _reposts[i];
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _Avatar(
                                  letter:
                                      r.displayAuthor.isEmpty
                                          ? '?'
                                          : r.displayAuthor[0],
                                  imageUrl: r.avatar,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.displayAuthor,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: _ink,
                                        ),
                                      ),
                                      if ((r.content ?? '')
                                          .trim()
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          r.content!.trim(),
                                          style: TextStyle(
                                            color: _ink.withValues(alpha: .78),
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Collapses long captions to 3 lines with a liquid-light “see more”.
class _ExpandableStatus extends StatefulWidget {
  const _ExpandableStatus({required this.text});

  final String text;

  @override
  State<_ExpandableStatus> createState() => _ExpandableStatusState();
}

class _ExpandableStatusState extends State<_ExpandableStatus> {
  static const _maxLines = 3;

  bool _expanded = false;
  bool _hasOverflow = false;
  double _measuredWidth = -1;

  static final _style = TextStyle(
    fontSize: 13.5,
    height: 1.5,
    color: _ink.withValues(alpha: .82),
  );

  void _measureIfNeeded(double maxWidth) {
    if (maxWidth <= 0 || maxWidth == _measuredWidth) return;
    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: _style),
      maxLines: _maxLines,
      textDirection: TextDirection.ltr,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    final overflows = painter.didExceedMaxLines;
    _measuredWidth = maxWidth;
    if (overflows == _hasOverflow) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _hasOverflow = overflows);
    });
  }

  @override
  void didUpdateWidget(covariant _ExpandableStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _measuredWidth = -1;
      _hasOverflow = false;
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _measureIfNeeded(constraints.maxWidth);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: _style,
              maxLines: _expanded ? null : _maxLines,
              overflow:
                  _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (_hasOverflow) ...[
              const SizedBox(height: 4),
              FastTap(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _expanded = !_expanded);
                },
                borderRadius: BorderRadius.circular(6),
                child: Text(
                  _expanded ? 'see less' : 'see more',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: const ui.Color.fromARGB(
                      255,
                      7,
                      4,
                      4,
                    ).withValues(alpha: .5),
                    letterSpacing: -.1,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Tiny verified mark that sits flush beside the author name.
class _NameBadge extends StatelessWidget {
  const _NameBadge();

  @override
  Widget build(BuildContext context) {
    return const Tooltip(
      message: 'Verified Innovator',
      child: Padding(
        padding: EdgeInsets.only(top: .5),
        child: Icon(
          Icons.verified_rounded,
          size: 15,
          color: BrandColors.accent,
        ),
      ),
    );
  }
}

/// Lightweight follow pill — FastTap + AnimatedContainer (no idle tickers).
/// Reads [status]: accepted → Following, pending → Requested, none → Follow.
class _FollowButton extends StatelessWidget {
  const _FollowButton({
    required this.following,
    required this.onTap,
    this.status = 'none',
  });

  final bool following;
  final String status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pending = status == 'pending';
    // Pending and following both use the light "already actioned" pill.
    final actioned = following || pending;
    final labelColor = actioned ? _ink : Colors.white;
    final label = pending ? 'Requested' : (following ? 'Following' : 'Follow');
    final icon =
        pending
            ? Icons.schedule_rounded
            : (following ? Icons.check_rounded : Icons.add_rounded);
    return FastTap(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color:
              actioned
                  ? Colors.white.withValues(alpha: .78)
                  : BrandColors.secondarySurface,
          border: Border.all(
            color:
                actioned
                    ? _ink.withValues(alpha: .22)
                    : Colors.white.withValues(alpha: .28),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: labelColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: labelColor,
                letterSpacing: .2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The "posting…" card shown at the top of the feed while an upload runs in
/// the background. On failure it flips to a Retry / Dismiss state.
class _PostingCard extends StatelessWidget {
  const _PostingCard({required this.pending, this.onRetry, this.onDismiss});

  final PendingPost pending;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final failed = pending.status == PendingPostStatus.failed;
    final preview = pending.previewBytes;
    final videoPath = pending.videoPreviewPath;
    return FastGlass(
      borderRadius: BorderRadius.circular(26),
      blur: true,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          if (preview != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                preview,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            )
          else if (videoPath != null && videoPath.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    VideoThumbnailView(path: videoPath),
                    const Center(
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: _ink.withValues(alpha: .06),
              ),
              child: Icon(
                Icons.article_outlined,
                color: _ink.withValues(alpha: .5),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  failed ? 'Post failed to upload' : 'Posting…',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: failed ? const Color(0xFFC0392B) : _ink,
                  ),
                ),
                const SizedBox(height: 6),
                if (failed)
                  Text(
                    'Check your connection and try again.',
                    style: TextStyle(
                      fontSize: 12,
                      color: _ink.withValues(alpha: .55),
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      backgroundColor: _ink.withValues(alpha: .1),
                      valueColor: const AlwaysStoppedAnimation(
                        BrandColors.secondarySurface,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (failed) ...[
            const SizedBox(width: 8),
            _PostingAction(
              label: 'Retry',
              filled: true,
              onTap: onRetry ?? () {},
            ),
            const SizedBox(width: 6),
            _PostingAction(
              label: 'Dismiss',
              filled: false,
              onTap: onDismiss ?? () {},
            ),
          ],
        ],
      ),
    );
  }
}

class _PostingAction extends StatelessWidget {
  const _PostingAction({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FastTap(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color:
              filled
                  ? BrandColors.secondarySurface
                  : Colors.white.withValues(alpha: .6),
          border:
              filled ? null : Border.all(color: _ink.withValues(alpha: .18)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: filled ? Colors.white : _ink.withValues(alpha: .8),
          ),
        ),
      ),
    );
  }
}

/// Professional multi-image collage — Instagram-style layouts for 1–4+ media.
class _MediaCollage extends StatelessWidget {
  const _MediaCollage({required this.items});

  final List<FeedMediaItem> items;

  static const _gap = 2.5;
  static const _radius = 18.0;

  /// Show at most 4 tiles; remaining count as +N on the last cell.
  static const _maxTiles = 4;

  List<FeedMediaItem> get _valid =>
      items.where((m) => m.file.trim().isNotEmpty).toList();

  static String displayUrl(FeedMediaItem m) {
    if (m.isVideo && m.thumbnail?.trim().isNotEmpty == true) {
      return m.thumbnail!.trim();
    }
    final file = m.file.trim();
    if (file.isNotEmpty) return file;
    return m.thumbnail?.trim() ?? '';
  }

  static String thumbUrl(FeedMediaItem m) =>
      m.thumbnail?.trim().isNotEmpty == true
          ? m.thumbnail!.trim()
          : m.file.trim();

  void _open(BuildContext context, List<FeedMediaItem> media, int index) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withValues(alpha: .92),
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder:
            (_, animation, __) => _FeedMediaLightbox(
              items: media,
              initialIndex: index.clamp(0, media.length - 1),
              animation: animation,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = _valid;
    if (media.isEmpty) return const SizedBox.shrink();
    if (media.length == 1) {
      final item = media.first;
      if (item.isVideo) {
        return _SingleVideoFrame(
          url: item.file,
          posterUrl: item.thumbnail,
          onOpenFullscreen: () => _open(context, media, 0),
        );
      }
      return GestureDetector(
        onTap: () => _open(context, media, 0),
        child: _MediaSection(
          isVideo: false,
          label: 'Photo',
          imageUrl: thumbUrl(item),
        ),
      );
    }

    // Height is chosen per layout so each cell stays close to square and never
    // looks stretched: a 2-up row is short (cells ~square), a 3/4 collage is a
    // little taller. Capped at half the screen height.
    final screenCap = MediaQuery.sizeOf(context).height * .5;
    final n = media.length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Aspect (width/height) of the whole media block by layout.
        final blockRatio =
            n == 2
                ? 2.0 // two square cells side by side
                : (n == 3 ? 1.5 : 1.1); // 3-up / 2x2 grids
        final height = math
            .min(width / blockRatio, screenCap)
            .clamp(160.0, screenCap);

        return RepaintBoundary(
          child: SizedBox(
            width: width,
            height: height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_radius),
                border: Border.all(color: Colors.white.withValues(alpha: .4)),
                color: const Color(0xFF1B1E28),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_radius),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildGrid(context, media),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: IgnorePointer(
                        child: _CountBadge(
                          count: media.length,
                          hasVideo: media.any((m) => m.isVideo),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrid(BuildContext context, List<FeedMediaItem> media) {
    final n = media.length;

    if (n == 2) {
      return Row(
        children: [
          Expanded(child: _tile(context, media, 0)),
          const SizedBox(width: _gap),
          Expanded(child: _tile(context, media, 1)),
        ],
      );
    }

    if (n == 3) {
      return Row(
        children: [
          Expanded(flex: 55, child: _tile(context, media, 0)),
          const SizedBox(width: _gap),
          Expanded(
            flex: 45,
            child: Column(
              children: [
                Expanded(child: _tile(context, media, 1)),
                const SizedBox(height: _gap),
                Expanded(child: _tile(context, media, 2)),
              ],
            ),
          ),
        ],
      );
    }

    final extra = n > _maxTiles ? n - _maxTiles : 0;
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _tile(context, media, 0)),
              const SizedBox(width: _gap),
              Expanded(child: _tile(context, media, 1)),
            ],
          ),
        ),
        const SizedBox(height: _gap),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _tile(context, media, 2)),
              const SizedBox(width: _gap),
              Expanded(
                child: _tile(
                  context,
                  media,
                  3,
                  overlayCount: extra > 0 ? extra : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tile(
    BuildContext context,
    List<FeedMediaItem> media,
    int index, {
    int? overlayCount,
  }) {
    final item = media[index];
    // Don't feed .mp4 URLs into Image.network — use thumb only when present.
    final preview =
        item.isVideo ? (item.thumbnail?.trim() ?? '') : thumbUrl(item);
    return GestureDetector(
      onTap: () => _open(context, media, index),
      child: _CollageTile(
        url: preview,
        isVideo: item.isVideo,
        overlayCount: overlayCount,
      ),
    );
  }
}

/// Inline feed video — poster-first, tap to stream (keeps scroll fast).
class _SingleVideoFrame extends StatefulWidget {
  const _SingleVideoFrame({
    required this.url,
    required this.onOpenFullscreen,
    this.posterUrl,
  });

  final String url;
  final String? posterUrl;
  final VoidCallback onOpenFullscreen;

  @override
  State<_SingleVideoFrame> createState() => _SingleVideoFrameState();
}

class _SingleVideoFrameState extends State<_SingleVideoFrame> {
  var _active = false;

  // Most feed videos are landscape; a ~16:9 frame avoids the tall, elongated
  // look a portrait 4:5 frame gave every clip.
  double get _frameRatio => (16 / 9).clamp(_mediaMinRatio, _mediaMaxRatio);

  void _startPlayback() {
    HapticFeedback.selectionClick();
    setState(() => _active = true);
  }

  /// Auto-start playback once the video scrolls into view. Pausing off-screen
  /// is handled by [FeedVideoPlayer]'s own requireVisible logic.
  void _onVisibility(VisibilityInfo info) {
    if (_active) return;
    if (info.visibleFraction >= 0.55 && mounted) {
      setState(() => _active = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenCap = MediaQuery.sizeOf(context).height * .62;
    final poster = widget.posterUrl?.trim() ?? '';

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = math.min(width / _frameRatio, screenCap);

        return VisibilityDetector(
          key: ValueKey('feed-video-${widget.url}'),
          onVisibilityChanged: _onVisibility,
          child: RepaintBoundary(
            child: SizedBox(
              width: width,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withValues(alpha: .4)),
                  color: const Color(0xFF1B1E28),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_active)
                        FeedVideoPlayer(
                          url: widget.url,
                          posterUrl: poster.isEmpty ? null : poster,
                          fit: BoxFit.cover,
                          autoplay: true,
                          muted: true,
                          looping: true,
                          showControls: true,
                          requireVisible: true,
                        )
                      else
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _startPlayback,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (poster.isNotEmpty)
                                CachedFeedImage(
                                  url: poster,
                                  fit: BoxFit.cover,
                                  width: width,
                                  height: height,
                                  memCacheWidth: InnovatorMediaCache.memCachePx(
                                    context,
                                    width,
                                  ),
                                )
                              else
                                const ColoredBox(color: Color(0xFF1B1E28)),
                              Center(
                                child: Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.black.withValues(alpha: .4),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: .55,
                                      ),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Positioned(
                        left: 12,
                        top: 12,
                        child: IgnorePointer(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: Colors.black.withValues(alpha: .4),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: .3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.videocam_outlined,
                                  size: 12,
                                  color: Colors.white.withValues(alpha: .9),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Video',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: .9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 10,
                        top: 10,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget.onOpenFullscreen,
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black.withValues(alpha: .4),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .35),
                                ),
                              ),
                              child: const Icon(
                                Icons.fullscreen_rounded,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count, required this.hasVideo});

  final int count;
  final bool hasVideo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.black.withValues(alpha: .42),
        border: Border.all(color: Colors.white.withValues(alpha: .3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasVideo ? Icons.collections_rounded : Icons.photo_library_outlined,
            size: 12,
            color: Colors.white.withValues(alpha: .92),
          ),
          const SizedBox(width: 5),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: .92),
              letterSpacing: .2,
            ),
          ),
        ],
      ),
    );
  }
}

class _CollageTile extends StatelessWidget {
  const _CollageTile({
    required this.url,
    required this.isVideo,
    this.overlayCount,
  });

  final String url;
  final bool isVideo;
  final int? overlayCount;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (url.isNotEmpty)
          CachedFeedImage(
            url: url,
            fit: BoxFit.cover,
            memCacheWidth: 560,
            fadeDuration: const Duration(milliseconds: 120),
          )
        else
          const ColoredBox(color: Color(0xFF1B1E28)),
        // Soft vignette so edges stay readable.
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x14000000), Color(0x00000000), Color(0x33000000)],
              stops: [0, .5, 1],
            ),
          ),
        ),
        if (isVideo && (overlayCount == null || overlayCount == 0))
          Center(
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: .4),
                border: Border.all(color: Colors.white.withValues(alpha: .5)),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                size: 22,
                color: Colors.white,
              ),
            ),
          ),
        if (overlayCount != null && overlayCount! > 0)
          ColoredBox(
            color: Colors.black.withValues(alpha: .48),
            child: Center(
              child: Text(
                '+$overlayCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Adaptive feed media — single network image/video thumb.
class _MediaSection extends StatefulWidget {
  const _MediaSection({
    required this.isVideo,
    required this.label,
    required this.imageUrl,
  });

  final bool isVideo;
  final String label;
  final String imageUrl;

  @override
  State<_MediaSection> createState() => _MediaSectionState();
}

class _MediaSectionState extends State<_MediaSection> {
  // Real image aspect ratio (width/height), resolved once the image loads.
  // Until then we use a neutral 4:5 so the card doesn't jump too much.
  double? _naturalRatio;
  ImageStream? _stream;
  ImageStreamListener? _listener;

  bool get isVideo => widget.isVideo;
  String get label => widget.label;
  String get imageUrl => widget.imageUrl;

  @override
  void initState() {
    super.initState();
    _resolveRatio();
  }

  @override
  void didUpdateWidget(covariant _MediaSection old) {
    super.didUpdateWidget(old);
    if (old.imageUrl != widget.imageUrl) {
      _naturalRatio = null;
      _resolveRatio();
    }
  }

  void _resolveRatio() {
    final url = imageUrl.trim();
    if (url.isEmpty) return;
    final provider = CachedNetworkImageProvider(url);
    _detach();
    _stream = provider.resolve(const ImageConfiguration());
    _listener = ImageStreamListener((info, _) {
      final w = info.image.width.toDouble();
      final h = info.image.height.toDouble();
      if (h > 0 && mounted) {
        setState(() => _naturalRatio = w / h);
      }
    }, onError: (_, __) {});
    _stream!.addListener(_listener!);
  }

  void _detach() {
    if (_stream != null && _listener != null) {
      _stream!.removeListener(_listener!);
    }
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Clamp the real ratio so nothing is absurdly tall or wide; fall back to a
    // neutral 1:1 until the natural ratio is known.
    final ratio = (_naturalRatio ?? 1.0).clamp(_mediaMinRatio, _mediaMaxRatio);
    final screenCap = MediaQuery.sizeOf(context).height * .5;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = math.min(width / ratio, screenCap);

        return RepaintBoundary(
          child: SizedBox(
            width: width,
            height: height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: .4)),
                color: const Color(0xFF1B1E28),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (imageUrl.isNotEmpty)
                      CachedFeedImage(
                        url: imageUrl,
                        fit: BoxFit.cover,
                        width: width,
                        height: height,
                        memCacheWidth: InnovatorMediaCache.memCachePx(
                          context,
                          width,
                        ),
                        fadeDuration: const Duration(milliseconds: 120),
                      )
                    else
                    //   const ColoredBox(color: Color(0xFF1B1E28)),
                    // const DecoratedBox(
                    //   decoration: BoxDecoration(
                    //     gradient: LinearGradient(
                    //       begin: Alignment.topCenter,
                    //       end: Alignment.bottomCenter,
                    //       colors: [
                    //         Color(0x2E000000),
                    //         Color(0x00000000),
                    //         Color(0x8C000000),
                    //       ],
                    //       stops: [0, .45, 1],
                    //     ),
                    //   ),
                    // ),
                    if (isVideo)
                      Center(
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: .35),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .55),
                            ),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Colors.black.withValues(alpha: .4),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isVideo
                                  ? Icons.videocam_outlined
                                  : Icons.image_outlined,
                              size: 12,
                              color: Colors.white.withValues(alpha: .9),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isVideo ? 'Video' : 'Photo',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: .9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Positioned(
                    //   left: 14,
                    //   bottom: 12,
                    //   right: 14,
                    //   child: Text(
                    //     label,
                    //     maxLines: 1,
                    //     overflow: TextOverflow.ellipsis,
                    //     style: TextStyle(
                    //       fontSize: 12,
                    //       fontWeight: FontWeight.w600,
                    //       color: Colors.white.withValues(alpha: .92),
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.onLongPress,
    this.active = false,
    this.activeColor = _ink,
    this.emoji = '',
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Long-press opens the associated list (likes / reposts).
  final VoidCallback? onLongPress;
  final bool active;
  final Color activeColor;

  /// When non-empty, shown instead of [icon] (used for the chosen reaction).
  final String emoji;

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : _ink.withValues(alpha: .55);

    return FastTap(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedScale(
                    scale: active ? 1.18 : 1,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutBack,
                    child:
                        emoji.isNotEmpty
                            ? Text(emoji, style: const TextStyle(fontSize: 17))
                            : Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(width: 6),
                  Text(label),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- post menu

enum _FeedMenuAction { repost, copy, block, delete }

class _FeedMenuRoute extends PopupRoute<_FeedMenuAction> {
  _FeedMenuRoute({required this.anchorRect});

  final Rect anchorRect;

  @override
  Color? get barrierColor => _ink.withValues(alpha: .12);

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 280);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _FeedMenuPopover(anchorRect: anchorRect, animation: animation);
  }
}

class _FeedMenuPopover extends StatelessWidget {
  const _FeedMenuPopover({required this.anchorRect, required this.animation});

  final Rect anchorRect;
  final Animation<double> animation;

  static const _width = 168.0;
  static const _height = 156.0;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);

    var left = anchorRect.right - _width;
    left = left.clamp(12.0, size.width - _width - 12);

    var top = anchorRect.bottom + 6;
    final maxTop = size.height - padding.bottom - _height - 12;
    final openAbove = top > maxTop;
    if (openAbove) top = anchorRect.top - _height - 6;
    top = top.clamp(padding.top + 8, maxTop);

    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            width: _width,
            child: FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: .92, end: 1).animate(curved),
                alignment:
                    openAbove ? Alignment.bottomRight : Alignment.topRight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: .9),
                            Colors.white.withValues(alpha: .62),
                          ],
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .95),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _ink.withValues(alpha: .16),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _FeedMenuTile(
                              icon: Icons.repeat_rounded,
                              label: 'Repost',
                              onTap:
                                  () => Navigator.of(
                                    context,
                                  ).pop(_FeedMenuAction.repost),
                            ),
                            const SizedBox(height: 4),
                            _FeedMenuTile(
                              icon: Icons.copy_rounded,
                              label: 'Copy',
                              onTap:
                                  () => Navigator.of(
                                    context,
                                  ).pop(_FeedMenuAction.copy),
                            ),
                            const SizedBox(height: 4),
                            if (AuthSession.instance.userId != null) ...[
                              // Delete shown for everyone; server enforces ownership.
                              _FeedMenuTile(
                                icon: Icons.delete_outline_rounded,
                                label: 'Delete',
                                destructive: true,
                                onTap:
                                    () => Navigator.of(
                                      context,
                                    ).pop(_FeedMenuAction.delete),
                              ),
                              const SizedBox(height: 4),
                            ],
                            _FeedMenuTile(
                              icon: Icons.block_rounded,
                              label: 'Block',
                              destructive: true,
                              onTap:
                                  () => Navigator.of(
                                    context,
                                  ).pop(_FeedMenuAction.block),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedMenuTile extends StatelessWidget {
  const _FeedMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? const Color(0xFFC0392B) : _ink;

    return LiquidPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      rippleColor: destructive ? accent : _ink,
      intensity: 1.1,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color:
              destructive
                  ? accent.withValues(alpha: .08)
                  : Colors.white.withValues(alpha: .42),
          border: Border.all(
            color:
                destructive
                    ? accent.withValues(alpha: .2)
                    : Colors.white.withValues(alpha: .7),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: accent.withValues(alpha: .85)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: -.1,
                color: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
