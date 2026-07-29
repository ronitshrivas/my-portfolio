import 'dart:async';
import 'dart:math' as math;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/Authorization/Login.dart';
import 'package:innovator/Innovator/constant/api_constants.dart';
import 'package:innovator/Innovator/constant/app_colors.dart';
import 'package:innovator/Innovator/controllers/user_controller.dart';
import 'package:innovator/Innovator/ui/ui.dart';
import 'package:innovator/Innovator/screens/Feed/Optimize%20Media/OptimizeMediaScreen.dart';
import 'package:innovator/Innovator/screens/Feed/Optimize%20Media/full_screen_image_viewer.dart';
import 'package:innovator/Innovator/screens/Feed/facebook_video_widget.dart';
import 'package:innovator/Innovator/screens/Likes/glow_bulb_button.dart';
import 'package:innovator/Innovator/screens/chatrrom/screen/chatlistscreen.dart';
import 'package:innovator/Innovator/utils/routing.dart';
import 'package:innovator/Innovator/widget/CustomizeFAB.dart';
import 'package:innovator/Innovator/widget/repost_button.dart';
import 'package:innovator/Innovator/screens/Feed/Repost/repost_list_screen.dart';
import 'package:innovator/Innovator/screens/Feed/Repost/sharedrepostcard.dart';
import 'package:innovator/Innovator/screens/Feed/Update%20Feed/API_Service.dart';
import 'package:innovator/Innovator/screens/Follow/follow_Button.dart';
import 'package:innovator/Innovator/screens/Likes/Content-Like-Service.dart';
import 'package:innovator/Innovator/screens/Likes/content-Like-Button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:innovator/Innovator/screens/Likes/reaction_sheet_screen.dart';
import 'package:innovator/Innovator/screens/SHow_Specific_Profile/Show_Specific_Profile.dart';
import 'package:innovator/Innovator/screens/chatrrom/sound/soundplayer.dart';
import 'package:innovator/Innovator/screens/comment/comment_section.dart';
import 'package:innovator/Innovator/widget/Custom_refresh_Indicator.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';
import 'dart:developer' as developer;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../../models/Feed_Content_Model.dart';

class ContentResponse {
  final int status;
  final ContentData data;
  final dynamic error;
  final String message;

  ContentResponse({
    required this.status,
    required this.data,
    this.error,
    required this.message,
  });

  factory ContentResponse.fromJson(Map<String, dynamic> json) {
    return ContentResponse(
      status: json['status'] as int? ?? 200,
      data: ContentData.fromNewFeedApi(json['data'] ?? {}),
      error: json['error'],
      message: json['message'] as String? ?? '',
    );
  }
}

class FileTypeHelper {
  static bool isImage(String url) {
    try {
      final l = url.toLowerCase();
      return l.endsWith('.jpg') ||
          l.endsWith('.jpeg') ||
          l.endsWith('.png') ||
          l.endsWith('.gif') ||
          l.endsWith('.webp') ||
          l.contains('_thumb.jpg');
    } catch (_) {
      return false;
    }
  }

  static bool isVideo(String url) {
    try {
      final l = url.toLowerCase();
      return l.endsWith('.mp4') ||
          l.endsWith('.mov') ||
          l.endsWith('.avi') ||
          l.endsWith('.m3u8');
    } catch (_) {
      return false;
    }
  }

  static bool isPdf(String url) {
    try {
      return url.toLowerCase().endsWith('.pdf');
    } catch (_) {
      return false;
    }
  }

  static bool isWordDoc(String url) {
    try {
      final l = url.toLowerCase();
      return l.endsWith('.doc') || l.endsWith('.docx');
    } catch (_) {
      return false;
    }
  }
}

class CursorHelper {
  static bool isValidObjectId(String? cursor) {
    if (cursor == null || cursor.isEmpty) return false;
    return RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(cursor);
  }

  static String? extractObjectId(String? cursor) {
    if (cursor == null || cursor.isEmpty) return null;
    if (isValidObjectId(cursor)) return cursor;
    final m = RegExp(r'[0-9a-fA-F]{24}').firstMatch(cursor);
    if (m != null && isValidObjectId(m.group(0))) return m.group(0);
    return null;
  }

  static String? cleanCursor(String? cursor) {
    if (cursor == null || cursor.isEmpty || cursor == 'null') return null;
    if (isValidObjectId(cursor)) return cursor;
    return extractObjectId(cursor);
  }
}

class FeedApiResponse {
  final int status;
  final Map<String, dynamic> data;
  final dynamic error;
  final String message;

  FeedApiResponse({
    required this.status,
    required this.data,
    this.error,
    required this.message,
  });

  factory FeedApiResponse.fromJson(Map<String, dynamic> json) {
    return FeedApiResponse(
      status: json['status'] as int? ?? 200,
      data: json['data'] as Map<String, dynamic>? ?? {},
      error: json['error'],
      message: json['message'] as String? ?? '',
    );
  }

  ContentData toContentData() => ContentData.fromNewFeedApi({'data': data});
}

class FeedApiService {
  //static const String baseUrl = 'http://36.253.137.34:8005';

  static Map<String, String> _headers() {
    final token = AppData().accessToken ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<ContentData> fetchContents({
    String? cursor,
    int limit = 20,
    String contentType = 'normal',
    required BuildContext context,
  }) async {
    try {
      // FeedService: GET /api/feed?page=<n>&pageSize=<n> (page-based, wrapped).
      final page = int.tryParse(cursor ?? '') ?? 1;
      const pageSize = 10;
      final uri = Uri.parse(
        'http://36.253.137.34:8012/api/feed',
      ).replace(
        queryParameters: {'page': '$page', 'pageSize': '$pageSize'},
      );
      // final uri =
      //     cursor != null && cursor.startsWith('http')
      //         ? Uri.parse(cursor) // full URL from "next" field
      //         : Uri.parse('http://36.253.137.34:8005/api/feed/');

      developer.log('[Feed] GET $uri');

      final response = await http
          .get(uri, headers: _headers())
          .timeout(const Duration(seconds: 30));

      developer.log('[Feed] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return ContentData.fromNewFeedApi(decoded, page: page, pageSize: pageSize);
      } else if (response.statusCode == 401) {
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => LoginPage()),
            (_) => false,
          );
        }
        throw Exception('Authentication required');
      } else {
        throw Exception('Failed to load feed: \${response.statusCode}');
      }
    } catch (e) {
      developer.log('[Feed] fetchContents error: \$e');
      rethrow;
    }
  }

  /// Offset-based fallback — delegates to cursor fetch without a cursor.
  static Future<ContentData> fetchContentsWithOffset({
    int offset = 0,
    int limit = 20,
    String contentType = 'normal',
    required BuildContext context,
  }) => fetchContents(
    cursor: null,
    limit: limit,
    contentType: contentType,
    context: context,
  );

  /// No-op — kept for call-site compatibility.
  static Future<void> testCursorFormat() async {
    developer.log('[Feed] Cursor pagination handled by server (next URL)');
  }

  static Future<ContentData> refreshFeed({
    String contentType = 'normal',
    required BuildContext context,
  }) => fetchContents(
    cursor: null,
    limit: 20,
    contentType: contentType,
    context: context,
  );
}

class ContentData {
  final List<FeedContent> contents;
  final bool hasMore;
  final String? nextCursor;

  const ContentData({
    required this.contents,
    required this.hasMore,
    this.nextCursor,
  });

  factory ContentData.fromNewFeedApi(
    dynamic rawJson, {
    int page = 1,
    int pageSize = 10,
  }) {
    try {
      List<dynamic> postList = [];
      String? nextCursor;
      bool hasMore = false;

      if (rawJson is List) {
        postList = rawJson;
      } else if (rawJson is Map<String, dynamic>) {
        // FeedService wraps the payload: { success, message, data: {...} }.
        final payload =
            rawJson['data'] is Map<String, dynamic>
                ? rawJson['data'] as Map<String, dynamic>
                : rawJson;

        postList = payload['results'] as List? ?? [];

        // Prefer the server's "next" URL; fall back to counting against the
        // total ("count") so load-more works even if "next" is absent.
        final next = payload['next'];
        if (next != null && next.toString().isNotEmpty) {
          hasMore = true;
          final match = RegExp(r'[?&]page=(\d+)').firstMatch(next.toString());
          nextCursor = match?.group(1) ?? '${page + 1}';
        } else {
          final total = (payload['count'] as num?)?.toInt() ?? 0;
          hasMore = page * pageSize < total;
          if (hasMore) nextCursor = '${page + 1}';
        }
      }

      developer.log(
        '[Feed] Parsing ${postList.length} posts — '
        'hasMore: $hasMore — next: $nextCursor',
      );

      final contents =
          postList
              .whereType<Map<String, dynamic>>()
              .map((item) {
                try {
                  return FeedContent.fromNewApiPost(item);
                } catch (e) {
                  developer.log('[Feed] Parse error: $e');
                  return null;
                }
              })
              .whereType<FeedContent>()
              .where((c) => c.id.isNotEmpty)
              .toList();

      developer.log('[Feed] ✓ ${contents.length} valid posts');
      _cacheAuthors(contents);

      return ContentData(
        contents: contents,
        hasMore: hasMore,
        nextCursor: nextCursor,
      );
    } catch (e) {
      developer.log('[Feed] ContentData error: $e');
      return const ContentData(contents: [], hasMore: false);
    }
  }

  factory ContentData.fromJson(Map<String, dynamic> json) =>
      ContentData.fromNewFeedApi(json);

  static void _cacheAuthors(List<FeedContent> contents) {
    try {
      if (!Get.isRegistered<UserController>()) return;
      final uc = Get.find<UserController>();
      final userMaps =
          contents
              .map(
                (c) => <String, dynamic>{
                  'user_id': c.author.id,
                  'username': c.author.name,
                  'avatar': c.author.picture,
                },
              )
              .toList();
      uc.cacheFromFeedPosts(userMaps);
    } catch (_) {}
  }

  bool get isEmpty => contents.isEmpty;
  int get totalCount => contents.length;
}

class Inner_HomePage extends ConsumerStatefulWidget {
  const Inner_HomePage({Key? key}) : super(key: key);

  @override
  _Inner_HomePageState createState() => _Inner_HomePageState();
}

class _Inner_HomePageState extends ConsumerState<Inner_HomePage> {
  final List<FeedContent> _allContents = [];
  final ScrollController _scrollController = ScrollController();
  final AppData _appData = AppData();

  Set<int> _suggestedUsersShownAt = {};
  List<int> _suggestionPositions = [];

  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _hasMoreContent = false;
  String? _nextCursor;
  bool _isOnline = true;
  bool _isInitialLoad = true;
  bool _hasInitialData = false;
  bool _isLoadingMore = false;

  int _currentOffset = 0;
  bool _useCursorPagination = false;

  Timer? _scrollDebounce;
  bool _isNearBottom = false;
  double _lastScrollPosition = 0;
  static const double _scrollThreshold = 0.8;
  static const int _preloadDistance = 300;
  static const int _maxContentItems = 100;
  static const int _itemsToRemoveOnCleanup = 100;

  DateTime _lastLoadTime = DateTime.now();
  static const int _minimumLoadInterval = 500;

  final Map<String, bool> _reactionState = {};

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<UserController>()) Get.put(UserController());
    _initializeInfiniteScroll();
    _checkConnectivity();
  }

  @override
  void dispose() {
    _scrollDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeInfiniteScroll() async {
    try {
      await _appData.initialize();
      if (await _verifyToken()) {
        await _loadInitialContent();
        _setupScrollListener();
        _isInitialLoad = false;
        _hasInitialData = true;
      }
    } catch (e) {
      developer.log('Error initializing feed: $e');
      _handleError('Failed to initialize feed');
    }
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      _scrollDebounce?.cancel();
      _scrollDebounce = Timer(
        const Duration(milliseconds: 150),
        _handleScrollEvent,
      );
    });
  }

  void _handleScrollEvent() {
    if (!_scrollController.hasClients ||
        _isLoading ||
        !_hasMoreContent ||
        _isLoadingMore)
      return;

    final position = _scrollController.position;
    final currentScroll = position.pixels;
    final maxScroll = position.maxScrollExtent;
    if (maxScroll <= 0) return;

    final scrollPercentage = currentScroll / maxScroll;
    _isNearBottom = scrollPercentage >= _scrollThreshold;

    if (_shouldLoadMoreContent(currentScroll, maxScroll, scrollPercentage)) {
      _loadMoreContent();
    }
    _lastScrollPosition = currentScroll;
  }

  bool _shouldLoadMoreContent(
    double currentScroll,
    double maxScroll,
    double scrollPercentage,
  ) {
    if (_isLoading || !_hasMoreContent || _isLoadingMore) return false;
    final elapsed = DateTime.now().difference(_lastLoadTime);
    if (elapsed.inMilliseconds < _minimumLoadInterval) return false;
    if (scrollPercentage >= _scrollThreshold) return true;
    if (maxScroll - currentScroll <= _preloadDistance) return true;
    if (scrollPercentage >= 0.85) return true;
    if (_allContents.length < 20 && scrollPercentage >= 0.9) return true;
    return false;
  }

  void _preloadVisibleUsers() {
    if (_allContents.isEmpty) return;
    try {
      final uc = Get.find<UserController>();
      final ids =
          _allContents
              .take(20)
              .map((c) => c.author.id)
              .where((id) => id.isNotEmpty)
              .toSet()
              .toList();
      if (ids.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => uc.prefetchAvatars(ids, context),
        );
      }
    } catch (e) {
      developer.log('prefetchAvatars error: $e');
    }
  }

  Future<void> _loadInitialContent() async {
    developer.log('[Feed] Loading initial content...');
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
    try {
      await FeedApiService.testCursorFormat();
      final data = await FeedApiService.fetchContents(
        cursor: null,
        limit: 20,
        contentType: 'normal',
        context: context,
      );
      if (mounted) {
        setState(() {
          _allContents.clear();
          _allContents.addAll(data.contents);
          _nextCursor = data.nextCursor;
          _hasMoreContent = data.hasMore;
          _isLoading = false;
          _currentOffset = data.contents.length;
          _useCursorPagination = true;
        });
        _preloadVisibleUsers();
        developer.log('[Feed] Initial: ${_allContents.length} posts');
      }
    } catch (e) {
      developer.log('[Feed] loadInitialContent error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreContent() async {
    if (_isLoading || !_hasMoreContent || _isLoadingMore) return;
    developer.log('[Feed] Loading more...');
    setState(() {
      _isLoading = true;
      _isLoadingMore = true;
      _hasError = false;
    });
    _lastLoadTime = DateTime.now();
    try {
      final data = await FeedApiService.fetchContents(
        cursor: _nextCursor,
        limit: 20,
        context: context,
      );
      if (mounted) {
        setState(() {
          _allContents.addAll(data.contents);
          _nextCursor = data.nextCursor;
          _hasMoreContent = data.hasMore;
          _isLoading = false;
          _isLoadingMore = false;
        });
        if (_allContents.length > _maxContentItems) _manageMemoryUsage();
      }
    } catch (e) {
      developer.log('[Feed] loadMoreContent error: $e');
      if (mounted)
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
    }
  }

  void _manageMemoryUsage() {
    if (_allContents.length <= _maxContentItems) return;
    final toRemove = (_allContents.length - _maxContentItems + 50).clamp(
      0,
      _itemsToRemoveOnCleanup,
    );
    if (toRemove <= 0) return;
    final scrollPos =
        _scrollController.hasClients ? _scrollController.position.pixels : 0.0;
    _allContents.removeRange(0, toRemove);
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          try {
            _scrollController.jumpTo(
              math.max(0.0, scrollPos - toRemove * 400.0),
            );
          } catch (_) {}
        }
      });
    }
  }

  Future<void> _refresh() async {
    developer.log('[Feed] Refreshing...');
    _suggestedUsersShownAt.clear();
    _suggestionPositions.clear();
    HapticFeedback.mediumImpact();
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
    _nextCursor = null;
    _currentOffset = 0;
    _hasMoreContent = false;
    _useCursorPagination = false;
    _lastLoadTime = DateTime.now().subtract(const Duration(seconds: 2));

    try {
      final data = await FeedApiService.refreshFeed(
        contentType: 'normal',
        context: context,
      );
      if (mounted) {
        setState(() {
          _allContents.clear();
          _allContents.addAll(data.contents);
          _nextCursor = data.nextCursor;
          _hasMoreContent = data.hasMore;
          _isLoading = false;
          _currentOffset = data.contents.length;
        });
        developer.log('[Feed] Refreshed: ${_allContents.length} posts');
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    } catch (e) {
      developer.log('[Feed] refresh error: $e');
      _handleError('Failed to refresh feed');
    }
  }

  void _handleError(String message) {
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        _hasError = true;
        _errorMessage = message;
      });
    }
  }

  Future<bool> _verifyToken() async {
    try {
      if (_appData.accessToken == null || _appData.accessToken!.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Authentication required. Please login.';
        });
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => LoginPage()),
            (_) => false,
          );
        }
        return false;
      }
      return true;
    } catch (e) {
      developer.log('verifyToken error: $e');
      return false;
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (!mounted) return;
      setState(() {
        _isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      });
      if (_isOnline) _refresh();
    } on SocketException catch (_) {
      if (!mounted) return;
      setState(() => _isOnline = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = ref.watch(chatUnreadCountProvider);

    return Scaffold(
      backgroundColor: BrandColors.canvas,
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBlobBackground()),
          CustomRefreshIndicator(
            onRefresh: _refresh,
            gifPath: 'animation/IdeaBulb.gif',
            child: _buildContent(),
          ),
        ],
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
          ).then((_) {
            ref.invalidate(mutualFriendsProvider);
          });
        },
      ),
    );
  }

  Widget _buildContent() {
    if ((_isInitialLoad || _isLoading) && _allContents.isEmpty) {
      return _buildShimmerList();
    }
    if (_hasError && _allContents.isEmpty) return _buildErrorState();
    return _buildInfiniteScrollList();
  }

  Widget _buildShimmerList() => const _ShimmerFeedList();

  Widget _buildErrorState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        Text(
          'Oops! Something went wrong',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _errorMessage,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _refresh,
          icon: const Icon(Icons.refresh),
          label: const Text('Try Again'),
          style: ElevatedButton.styleFrom(
            backgroundColor: BrandColors.secondarySurface,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildInfiniteScrollList() {
    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                cacheExtent: 1200.0,
                addAutomaticKeepAlives: false,
                addRepaintBoundaries: true,
                itemCount: _calculateTotalItemCount(),
                itemBuilder: (context, index) => _buildListItem(index),
              ),
            ),
          ],
        ),
        if (_isLoading && _allContents.isNotEmpty)
          const Positioned(top: 0, left: 0, right: 0, child: _FeedRefreshBar()),
      ],
    );
  }

  int _calculateTotalItemCount() {
    int n = _allContents.length;
    if (_isLoading) n++;
    if (_shouldShowEndMessage()) n++;
    n += _suggestionPositions.length;
    return n;
  }

  List<int> _getSuggestedUsersPositions() =>
      List.from(_suggestionPositions)..sort();

  int _getAdjustedContentIndex(int listIndex) {
    final positions = _getSuggestedUsersPositions();
    int count = 0;
    for (final pos in positions) {
      if (pos + count < listIndex)
        count++;
      else
        break;
    }
    return listIndex - count;
  }

  Widget _buildListItem(int index) {
    final adjusted = _getAdjustedContentIndex(index);
    if (adjusted < _allContents.length) {
      return buildContentItem(_allContents[adjusted], adjusted);
    }
    if (adjusted == _allContents.length && _isLoading) {
      return _buildLoadingIndicator();
    }
    return const SizedBox.shrink();
  }

  Widget buildContentItem(FeedContent content, int index) {
    return RepaintBoundary(
      key: ValueKey(content.id),
      child: FeedItem(
        content: content,
        onLikeToggled: (hasReaction) {
          if (!mounted) return;
          setState(() {
            final hadReaction = _reactionState[content.id] ?? content.isLiked;
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
            for (final c in _allContents) {
              if (c.author.id == authorId) {
                c.isFollowed = isFollowed;
              }
            }
          });
        },
        onDeleted: () {
          if (mounted) setState(() => _allContents.remove(content));
        },
        onStatusUpdated: (newStatus) {
          if (mounted) setState(() => content.status = newStatus);
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() =>
      Column(children: [const _ShimmerFeedCard(), const _ShimmerFeedCard()]);

  bool _shouldShowEndMessage() =>
      !_isLoading && !_hasMoreContent && _allContents.isNotEmpty;
}

class FeedItem extends StatefulWidget {
  final FeedContent content;
  final Function(bool) onLikeToggled;
  final Function(bool) onFollowToggled;
  final VoidCallback? onDeleted;
  final Function(String)? onStatusUpdated;
  final VoidCallback? onCommentAdded;

  const FeedItem({
    Key? key,
    required this.content,
    required this.onLikeToggled,
    required this.onFollowToggled,
    this.onDeleted,
    this.onStatusUpdated,
    this.onCommentAdded,
  }) : super(key: key);

  @override
  State<FeedItem> createState() => _FeedItemState();
}

class _FeedItemState extends State<FeedItem>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  static const int _maxLinesCollapsed = 3;
  bool _hasRecordedView = false;
  late AnimationController _controller;
  late String formattedTimeAgo;
  bool _showComments = false;
  bool _statusNeedsToggle = false;
  Color _typeColor = Colors.transparent;
  bool _isOwnContent = false;

  final ContentLikeService likeService = ContentLikeService(
    baseUrl: 'http://36.253.137.34:8012',
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    formattedTimeAgo = _formatTimeAgo(widget.content.createdAt);
    _statusNeedsToggle = widget.content.status.length > 120;

    _typeColor = _getTypeColor(widget.content.type);

    try {
      _isOwnContent = _isAuthorCurrentUser();
    } catch (_) {
      _isOwnContent = false;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _recordView());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _mapReportReason(String uiReason) {
    const Map<String, String> reasonMap = {
      'Spam': 'spam',
      'Harassment': 'harassment',
      'Inappropriate content': 'inappropriate_content',
      'Fake account': 'fake_account',
      'Copyright violation': 'copyright_violation',
      'Other': 'other',
    };
    return reasonMap[uiReason] ?? uiReason.toLowerCase().replaceAll(' ', '_');
  }

  String _formatTimeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inDays > 365) return '${(d.inDays / 365).floor()} years ago';
    if (d.inDays > 30) return '${(d.inDays / 30).floor()} months ago';
    if (d.inDays > 0) return '${d.inDays} days ago';
    if (d.inHours > 0) return '${d.inHours} hours ago';
    if (d.inMinutes > 0) return '${d.inMinutes} minutes ago';
    return 'Just now';
  }

  Future<bool> _checkConnectivity() async {
    try {
      final res = await Connectivity().checkConnectivity();
      return res.contains(ConnectivityResult.wifi) ||
          res.contains(ConnectivityResult.mobile) ||
          res.contains(ConnectivityResult.ethernet);
    } catch (_) {
      return false;
    }
  }

  Future<void> _recordView() async {
    if (_hasRecordedView || !await _checkConnectivity()) return;
    _hasRecordedView = true;
    try {
      final token = AppData().accessToken;
      if (token == null || token.isEmpty) return;
      final response = await http
          .post(
            Uri.parse('${ApiConstants.recordview}${widget.content.id}/view'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 401) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
          (_) => false,
        );
      }
    } catch (e) {
      _hasRecordedView = false;
      developer.log('recordView error: $e');
    }
  }

  bool _isAuthorCurrentUser() {
    return AppData().isMe(widget.content.author.id) ||
        AppData().isCurrentUserByUsername(widget.content.author.name);
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'innovation':
        return Colors.amber.shade700;
      case 'idea':
        return Colors.teal.shade600;
      case 'project':
        return Colors.indigo.shade600;
      case 'question':
        return BrandColors.accent;
      case 'announcement':
        return Colors.deepPurple.shade600;
      case 'fun':
        return Colors.pink.shade500;
      case 'technology':
        return Colors.blue.shade600;
      case 'other':
        return Colors.grey.shade600;
      default:
        return Colors.blueGrey.shade600;
    }
  }

  Widget _buildAuthorAvatar() {
    final avatarUrl =
        widget.content.author.picture.isNotEmpty
            ? widget.content.author.picture
            : null;
    final initial =
        widget.content.author.name.isNotEmpty
            ? widget.content.author.name[0].toUpperCase()
            : '?';

    if (avatarUrl == null) {
      return CircleAvatar(
        backgroundColor: Colors.grey.shade300,
        child: Text(
          initial,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.whitecolor,
            fontSize: 16,
          ),
        ),
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: avatarUrl,
        cacheKey: 'feed_avatar_${widget.content.author.id}',
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 150),
        placeholder:
            (ctx, url) => CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              child: Text(
                initial,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        errorWidget:
            (ctx, url, err) => CircleAvatar(
              backgroundColor: Colors.grey.shade300,
              child: Text(
                initial,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.whitecolor,
                ),
              ),
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return
    // AnimatedContainer(
    //   duration: const Duration(milliseconds: 200),
    //   margin: const EdgeInsets.symmetric(vertical: 5),
    //   padding: const EdgeInsets.symmetric(horizontal: 8.0),
    //   decoration: BoxDecoration(
    //     color: AppColors.whitecolor,
    //     borderRadius: const BorderRadius.only(
    //       bottomLeft: Radius.circular(20.0),
    //       bottomRight: Radius.circular(20.0),
    //       topLeft: Radius.circular(5.0),
    //       topRight: Radius.circular(5.0),
    //     ),
    //     boxShadow: [
    //       BoxShadow(
    //         color: Colors.black.withAlpha(15),
    //         blurRadius: 20.0,
    //         offset: const Offset(0, 4),
    //         spreadRadius: 0,
    //       ),
    //       BoxShadow(
    //         color: Colors.black.withAlpha(15),
    //         blurRadius: 8.0,
    //         offset: const Offset(0, 2),
    //         spreadRadius: 0,
    //       ),
    //     ],
    //   ),
    Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .72),
        borderRadius: const BorderRadius.all(Radius.circular(22.0)),
        border: Border.all(
          color: Colors.white.withValues(alpha: .85),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: BrandColors.secondarySurface.withValues(alpha: .06),
            blurRadius: 24.0,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => FullScreenImageViewer(
                            imageUrl: widget.content.author.picture,
                            tag:
                                'avatar_${widget.content.author.id}_${widget.content.id}',
                          ),
                    ),
                  );
                },
                child: Hero(
                  tag:
                      'avatar_${widget.content.author.id}_${widget.content.id}',
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          BrandColors.secondarySurface,
                          BrandColors.accent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: BrandColors.accent.withValues(alpha: .35),
                          blurRadius: 12.0,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(2.0),
                    child: _buildAuthorAvatar(),
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: GestureDetector(
                  onTap:
                      () => Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder:
                              (ctx, a, _) => SpecificUserProfilePage(
                                userId: widget.content.author.id,
                              ),
                          transitionsBuilder:
                              (ctx, a, _, child) => SlideTransition(
                                position: a.drive(
                                  Tween(
                                    begin: const Offset(1.0, 0.0),
                                    end: Offset.zero,
                                  ),
                                ),
                                child: child,
                              ),
                        ),
                      ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Flexible(
                                //   child: LayoutBuilder(
                                //     builder: (context, constraints) {
                                //       final nameStyle = const TextStyle(
                                //         fontWeight: FontWeight.w700,
                                //         fontSize: 16.0,
                                //         fontFamily: 'Inter Thin',
                                //       );
                                //       final tp = TextPainter(
                                //         text: TextSpan(
                                //           text: widget.content.author.name,
                                //           style: nameStyle,
                                //         ),
                                //         maxLines: 1,
                                //         textDirection: TextDirection.ltr,
                                //       )..layout(maxWidth: double.infinity);
                                //       final nameWillOverflow =
                                //           tp.width > constraints.maxWidth;
                                //       return Text(
                                //         widget.content.author.name,
                                //         style: nameStyle,
                                //         overflow:
                                //             nameWillOverflow
                                //                 ? TextOverflow.ellipsis
                                //                 : TextOverflow.visible,
                                //         maxLines: 1,
                                //         softWrap: false,
                                //       );
                                //     },
                                //   ),
                                // ),
                                Flexible(
                                  child: Text(
                                    widget.content.author.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16.0,
                                      fontFamily: 'Inter Thin',
                                    ),
                                    overflow:
                                        TextOverflow
                                            .ellipsis, // always ellipsis — no LayoutBuilder needed
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                if (!_isOwnContent)
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () {},
                                    child: FollowButton(
                                      targetUserId: widget.content.author.id,
                                      initialFollowStatus:
                                          widget.content.isFollowed,
                                      onFollowSuccess: () {
                                        SoundPlayer().FollowSound();
                                        if (mounted) {
                                          setState(
                                            () =>
                                                widget.content.isFollowed =
                                                    true,
                                          );
                                          widget.onFollowToggled(true);
                                        }
                                      },
                                      onUnfollowSuccess: () {
                                        SoundPlayer().FollowSound();
                                        if (mounted) {
                                          setState(
                                            () =>
                                                widget.content.isFollowed =
                                                    false,
                                          );
                                          widget.onFollowToggled(false);
                                        }
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(12.0),
                            onTap: () {
                              if (_isAuthorCurrentUser()) {
                                _showQuickSuggestions(context);
                              } else {
                                _showQuickspecificSuggestions(context);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.more_vert_rounded,
                                color: Colors.grey.shade600,
                                size: 20.0,
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ── Date + Type — NO Padding wrapper, NO vertical gaps ──
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            formattedTimeAgo,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            '· ${widget.content.type.toUpperCase()}',
                            style: TextStyle(
                              color: _typeColor,
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                              fontFamily: 'InterThin',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (widget.content.status.isNotEmpty)
            Container(
              padding: EdgeInsets.only(
                top: 12.0,
                left: 16.0,
                right: 16.0,
                bottom: widget.content.files.isNotEmpty ? 8.0 : 16.0,
              ),
              child:
              //  Column(
              //   crossAxisAlignment: CrossAxisAlignment.start,
              //   children: [
              //     LayoutBuilder(
              //       builder: (context, constraints) {
              //         final span = TextSpan(
              //           text: widget.content.status,
              //           style: const TextStyle(
              //             fontSize: 12.0,
              //             fontFamily: 'InterThin',
              //           ),
              //         );
              //         final tp = TextPainter(
              //           text: span,
              //           maxLines: _maxLinesCollapsed,
              //           textDirection: TextDirection.ltr,
              //         )..layout(maxWidth: constraints.maxWidth);
              //         final needsToggle = tp.didExceedMaxLines;
              //         return Column(
              //           crossAxisAlignment: CrossAxisAlignment.start,
              //           children: [
              //             AnimatedSize(
              //               duration: const Duration(milliseconds: 300),
              //               curve: Curves.easeInOut,
              //               child: _LinkifyText(
              //                 text: widget.content.status,
              //                 style: const TextStyle(
              //                   fontSize: 13.5,
              //                   height: 1.5,
              //                   color: Colors.black,
              //                   fontWeight: FontWeight.w500,
              //                   letterSpacing: 0.6,
              //                   fontStyle: FontStyle.normal,
              //                   fontFamily: 'InterThin',
              //                 ),
              //                 maxLines: _isExpanded ? null : _maxLinesCollapsed,
              //                 overflow:
              //                     _isExpanded ? null : TextOverflow.ellipsis,
              //               ),
              //             ),
              //             if (needsToggle)
              //               InkWell(
              //                 onTap:
              //                     () => setState(
              //                       () => _isExpanded = !_isExpanded,
              //                     ),
              //                 child: Text(
              //                   _isExpanded ? 'See Less' : 'See More',
              //                   style: TextStyle(
              //                     color: Colors.blue.shade700,
              //                     fontSize: 11.0,
              //                     fontWeight: FontWeight.w600,
              //                   ),
              //                 ),
              //               ),
              //           ],
              //         );
              //       },
              //     ),
              //   ],
              // ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LinkifyText(
                    text: widget.content.status,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.6,
                      fontStyle: FontStyle.normal,
                      fontFamily: 'InterThin',
                    ),
                    maxLines: _isExpanded ? null : _maxLinesCollapsed,
                    overflow: _isExpanded ? null : TextOverflow.ellipsis,
                  ),
                  if (_statusNeedsToggle) // ← use cached value, no TextPainter in build
                    InkWell(
                      onTap: () => setState(() => _isExpanded = !_isExpanded),
                      child: Text(
                        _isExpanded ? 'See Less' : 'See More',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 11.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          if (widget.content.isRepost &&
              widget.content.sharedPostDetails != null)
            SharedPostCard(details: widget.content.sharedPostDetails!),

          if (!widget.content.isRepost && widget.content.files.isNotEmpty)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 1.0, vertical: 6.0),
              child: _buildMediaPreview(),
            ),
          const SizedBox(height: 10.0),
          Divider(
            color: Colors.grey.shade300,
            endIndent: 10,
            indent: 10,
            height: 1.0,
            thickness: 1.0,
          ),
          const SizedBox(height: 10),

          Padding(
            padding: EdgeInsets.only(
              right: 10,
              left: 10,
              bottom: 13,
              // top: 10,
            ),
            child: Row(
              children: [
                Row(
                  children: [
                    // GlowBulbButton(
                    //   contentId: widget.content.id,
                    //   initialLikeStatus: widget.content.isLiked,
                    //   likeService: likeService,
                    //   initialReactionType: widget.content.currentUserReaction,
                    //   isReel: widget.content.isReel,
                    //   onLikeToggled: (isLiked) {
                    //     widget.onLikeToggled(isLiked);
                    //     SoundPlayer().playlikeSound();
                    //   },
                    // ),
                    LikeButton(
                      contentId: widget.content.id,
                      initialLikeStatus: widget.content.isLiked,
                      likeService: likeService,
                      initialReactionType: widget.content.currentUserReaction,
                      isReel: widget.content.isReel,
                      onLikeToggled: (isLiked) {
                        widget.onLikeToggled(isLiked);
                        SoundPlayer().playlikeSound();
                      },
                    ),
                    GestureDetector(
                      onTap: () => _showReactionsList(context),
                      child: Text(
                        '${widget.content.likes} Likes',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                          fontSize: 11.0,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 18),
                Flexible(
                  child: InkWell(
                    onTap: () => setState(() => _showComments = !_showComments),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/icon/comment.png',
                          color:
                              _showComments
                                  ? Colors.blue.shade700
                                  : Colors.grey.shade800,
                          width: 25,
                          height: 25,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            '${widget.content.comments} Comments',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                              fontSize: 11.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RepostButton(
                      postId: widget.content.id,
                      authorName: widget.content.author.name,
                      content: widget.content.status,
                      authorAvatar:
                          widget.content.author.picture.isNotEmpty
                              ? widget.content.author.picture
                              : null,
                      onViewReposts: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => RepostsListScreen(
                                  postId: widget.content.id,
                                  originalAuthorName:
                                      widget.content.author.name,
                                ),
                          ),
                        );
                      },
                      initialRepostCount: widget.content.repostCount,
                    ),
                  ],
                ),
                const Spacer(),
                InkWell(
                  onTap: () => _showShareOptions(context),
                  child: Image.asset(
                    'assets/icon/send.png',
                    width: 20,
                    height: 20,
                  ),
                ),
              ],
            ),
          ),

          if (_showComments)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20.0),
                  bottomRight: Radius.circular(20.0),
                ),
              ),
              padding: const EdgeInsets.all(16.0),
              child: CommentSection(
                contentId: widget.content.id,
                isReel: widget.content.isReel,
                onCommentCountChanged: (delta) {
                  setState(
                    () =>
                        widget.content.comments =
                            (widget.content.comments + delta).clamp(0, 999999),
                  );
                },
              ),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  void _showReactionsList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => reeactionsheet(
            postId: widget.content.id,
            isreel: widget.content.isReel,
          ),
    );
  }

  Widget _buildMediaPreview() {
    final hasOptimizedImages = widget.content.optimizedFiles.any(
      (f) => f['type'] == 'image',
    );

    if (hasOptimizedImages) {
      final imageUrls =
          widget.content.optimizedFiles
              .where((f) => f['type'] == 'image')
              .map((f) => f['original'] ?? f['url'] ?? f['thumbnail'])
              .where((url) => url != null)
              .map((url) => widget.content.formatUrl(url))
              .toList();
      if (imageUrls.isNotEmpty) return _buildFacebookImageGrid(imageUrls);
    }

    final mediaUrls = widget.content.mediaUrls;
    if (mediaUrls.isEmpty) return const SizedBox.shrink();

    if (mediaUrls.length == 1) {
      final fileUrl = mediaUrls.first;
      if (FileTypeHelper.isImage(fileUrl))
        return _buildFacebookImageGrid([fileUrl]);
      if (FileTypeHelper.isVideo(fileUrl)) {
        return FacebookVideoWidget(
          key: ValueKey('video_${widget.content.id}'),
          url: fileUrl,
          thumbnailUrl: widget.content.thumbnailUrl,
          startMuted: false,
          looping: true,
        );
      }
      if (FileTypeHelper.isPdf(fileUrl)) {
        return _buildDocumentPreview(
          fileUrl,
          'PDF Document',
          Icons.picture_as_pdf,
          Colors.red,
        );
      }
      if (FileTypeHelper.isWordDoc(fileUrl)) {
        return _buildDocumentPreview(
          fileUrl,
          'Word Document',
          Icons.description,
          Colors.blue,
        );
      }
    }

    return _buildFacebookImageGrid(mediaUrls);
  }

  Widget _buildFacebookImageGrid(List<String> urls) {
    final n = urls.length;
    if (n == 0) return const SizedBox.shrink();
    if (n == 1) return _fbSingleImage(urls[0], urls);
    final showCount = n > 5 ? 5 : n;
    final extraCount = n > 5 ? n - 4 : 0;

    if (n == 2) {
      return SizedBox(
        height: 240,
        child: Row(
          children: [
            Expanded(child: _fbTile(urls[0], 0, urls, double.infinity)),
            const SizedBox(width: 2),
            Expanded(child: _fbTile(urls[1], 1, urls, double.infinity)),
          ],
        ),
      );
    }

    if (n == 3) {
      return SizedBox(
        height: 400,
        child: Column(
          children: [
            SizedBox(
              height: 240,
              child: _fbTile(urls[0], 0, urls, double.infinity),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _fbTile(urls[1], 1, urls, double.infinity)),
                  const SizedBox(width: 2),
                  Expanded(child: _fbTile(urls[2], 2, urls, double.infinity)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (n == 4) {
      return SizedBox(
        height: 362,
        child: Column(
          children: [
            SizedBox(
              height: 240,
              child: _fbTile(urls[0], 0, urls, double.infinity),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _fbTile(urls[1], 1, urls, double.infinity)),
                  const SizedBox(width: 2),
                  Expanded(child: _fbTile(urls[2], 2, urls, double.infinity)),
                  const SizedBox(width: 2),
                  Expanded(child: _fbTile(urls[3], 3, urls, double.infinity)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 422,
      child: Column(
        children: [
          SizedBox(
            height: 240,
            child: _fbTile(urls[0], 0, urls, double.infinity),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _fbTile(urls[1], 1, urls, double.infinity)),
                const SizedBox(width: 2),
                Expanded(child: _fbTile(urls[2], 2, urls, double.infinity)),
                const SizedBox(width: 2),
                Expanded(child: _fbTile(urls[3], 3, urls, double.infinity)),
                const SizedBox(width: 2),
                Expanded(
                  child: _fbTile(
                    urls[4],
                    4,
                    urls,
                    double.infinity,
                    extraCount: extraCount > 0 ? extraCount : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fbSingleImage(String url, List<String> allUrls) {
    return GestureDetector(
      onTap: () => _openMediaGallery(context, allUrls, 0),
      child: CachedNetworkImage(
        imageUrl: url,
        filterQuality: FilterQuality.high,
        fit: BoxFit.contain,
        width: double.infinity,
        memCacheWidth: (MediaQuery.of(context).size.width * 1.5).toInt(),
        placeholder: (_, __) => Container(height: 280, color: Colors.grey[200]),
        errorWidget:
            (_, __, ___) => Container(
              height: 280,
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            ),
      ),
    );
  }

  Widget _fbTile(
    String url,
    int index,
    List<String> allUrls,
    double height, {
    int? extraCount,
  }) {
    return GestureDetector(
      onTap: () => _openMediaGallery(context, allUrls, index),
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              placeholder: (_, __) => Container(color: Colors.grey[200]),
              errorWidget:
                  (_, __, ___) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
            ),
            if (extraCount != null && extraCount > 0)
              Container(
                color: Colors.black.withOpacity(0.52),
                child: Center(
                  child: Text(
                    '+$extraCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openMediaGallery(
    BuildContext context,
    List<String> mediaUrls,
    int initialIndex,
  ) {
    final selectedUrl = mediaUrls[initialIndex];
    if (FileTypeHelper.isVideo(selectedUrl)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => FacebookFullscreenPage(
                url: selectedUrl,
                thumbnailUrl: widget.content.thumbnailUrl,
              ),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => OptimizedMediaGalleryScreen(
              mediaUrls: mediaUrls,
              initialIndex: initialIndex,
            ),
      ),
    );
  }

  Widget _buildDocumentPreview(
    String fileUrl,
    String label,
    IconData icon,
    Color color,
  ) => GestureDetector(
    onTap: () => _showMediaGallery(context, [fileUrl], 0),
    child: Container(
      height: 180.0,
      width: double.infinity,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: color),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[800])),
        ],
      ),
    ),
  );

  void _showMediaGallery(
    BuildContext context,
    List<String> mediaUrls,
    int initialIndex,
  ) {
    final selectedUrl = mediaUrls[initialIndex];
    if (FileTypeHelper.isVideo(selectedUrl)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => FacebookFullscreenPage(
                url: selectedUrl,
                thumbnailUrl: widget.content.thumbnailUrl,
              ),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => OptimizedMediaGalleryScreen(
              mediaUrls: mediaUrls,
              initialIndex: initialIndex,
            ),
      ),
    );
  }

  void _showShareOptions(BuildContext context) {
    final shareTextController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => Container(
            decoration: const BoxDecoration(
              color: AppColors.whitecolor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Share Post',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: shareTextController,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  _buildShareOption(
                    icon: Icons.link,
                    title: 'Copy Link',
                    subtitle: 'Copy post link to clipboard',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _shareContent(shareTextController.text);
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.share,
                    title: 'Share via Apps',
                    subtitle: 'Share using other apps',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _shareViaApps();
                    },
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) => ListTile(
    leading: CircleAvatar(
      backgroundColor: color.withAlpha(10),
      child: Icon(icon, color: color),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
    subtitle: Text(
      subtitle,
      style: TextStyle(color: Colors.grey[600], fontSize: 12),
    ),
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
  );

  Future<void> _shareContent(String? shareText) async {
    try {
      final token = AppData().accessToken;
      if (token == null || token.isEmpty) {
        Get.snackbar(
          'Error',
          'Authentication required to share content',
          backgroundColor: Colors.red,
          colorText: AppColors.whitecolor,
        );
        return;
      }
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black26,
        builder:
            (_) => const Center(
              child: SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  color: BrandColors.accent,
                  strokeWidth: 3,
                ),
              ),
            ),
      );
      final response = await http.post(
        Uri.parse(ApiConstants.post),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'content': shareText ?? '',
          'shared_post': widget.content.id,
        }),
      );
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.whitecolor,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Post shared successfully',
                    style: TextStyle(fontWeight: FontWeight.w600),
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
        }
      }
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      developer.log('shareContent error: $e');
    }
  }

  void _shareViaApps() async {
    try {
      final shareText =
          'Download Now \n https://play.google.com/store/apps/details?id=com.innovation.innovator&pcampaignid=web_share';

      // Share text
      await Share.share(shareText);

      // Share image file (if you want to share the image)
      final ByteData bytes = await rootBundle.load(
        'assets/images/shareimage.png',
      );
      final Uint8List imageBytes = bytes.buffer.asUint8List();

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/shareimage.png');
      await tempFile.writeAsBytes(imageBytes);

      await Share.shareXFiles([XFile(tempFile.path)], text: shareText);
    } catch (e) {
      developer.log('shareViaApps error: $e');
    }
  }

  void _showQuickSuggestions(BuildContext context) {
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (_) => Container(
            decoration: BoxDecoration(
              color: AppColors.whitecolor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.edit, color: BrandColors.secondarySurface),
                  title: const Text('Edit content'),
                  onTap: () => Navigator.pop(context, 'edit'),
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete post'),
                  onTap: () => Navigator.pop(context, 'delete'),
                ),
                ListTile(
                  leading: const Icon(Icons.copy, color: Colors.blue),
                  title: const Text('Copy content'),
                  onTap: () => Navigator.pop(context, 'copy'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
    ).then((value) async {
      if (value == 'edit') await _handleEditContent();
      if (value == 'delete') await _handleDeleteContent();
      if (value == 'copy') {
        Clipboard.setData(ClipboardData(text: widget.content.status));
        Get.snackbar(
          'Copied',
          'Content copied to clipboard',
          backgroundColor: Colors.green.withAlpha(80),
          colorText: AppColors.whitecolor,
          duration: const Duration(seconds: 1),
        );
      }
    });
  }

  void _showQuickspecificSuggestions(BuildContext context) {
    showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (_) => Container(
            decoration: BoxDecoration(
              color: AppColors.whitecolor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.copy, color: Colors.blue),
                  title: const Text('Copy content'),
                  onTap: () => Navigator.pop(context, 'copy'),
                ),
                ListTile(
                  leading: const Icon(Icons.flag, color: BrandColors.accent),
                  title: const Text('Report'),
                  onTap: () => Navigator.pop(context, 'report'),
                ),
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.red),
                  title: const Text('Block'),
                  onTap: () => Navigator.pop(context, 'block'),
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),
    ).then((value) {
      if (value == 'copy') {
        Clipboard.setData(ClipboardData(text: widget.content.status));
        Get.snackbar('Copied', 'Content copied to clipboard');
      } else if (value == 'report') {
        _reportUser();
      } else if (value == 'block') {
        _blockUser();
      }
    });
  }

  Future<void> _handleEditContent() async {
    // Reels use "caption"; normal posts use "content/status".
    final isReel = widget.content.isReel;
    final fieldLabel = isReel ? 'Caption' : 'Content';

    final controller = TextEditingController(text: widget.content.status);

    final result = await showDialog<String>(
      context: context,
      builder:
          (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                const Icon(Icons.edit, color: BrandColors.secondarySurface),
                const SizedBox(width: 8),
                Text('Edit $fieldLabel'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    maxLines: 8,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'Update your $fieldLabel',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: BrandColors.secondarySurface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (controller.text.trim().isEmpty) {
                    Get.snackbar(
                      'Error',
                      '$fieldLabel cannot be empty',
                      backgroundColor: Colors.red,
                      colorText: AppColors.whitecolor,
                    );
                    return;
                  }
                  Navigator.pop(context, controller.text.trim());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColors.secondarySurface,
                  foregroundColor: AppColors.whitecolor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Save'),
              ),
            ],
          ),
    );

    if (result == null ||
        result.trim().isEmpty ||
        result == widget.content.status) {
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      builder: (_) => const _SaveLoadingDialog(),
    );

    final bool success;
    if (isReel) {
      success = await ApiService.updateReel(
        widget.content.id,
        result.trim(),
        context: context,
      );
    } else {
      success = await ApiService.updateContent(
        widget.content.id,
        result.trim(),
        context: context,
      );
    }

    if (mounted && Navigator.canPop(context)) Navigator.pop(context);
    if (!mounted) return;

    if (success) {
      widget.onStatusUpdated?.call(result.trim());
      setState(() => widget.content.status = result.trim());
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
                '$fieldLabel updated successfully',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(milliseconds: 800),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: AppColors.whitecolor, size: 18),
              SizedBox(width: 10),
              Text(
                'Failed to update. Please try again.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  Future<void> _handleDeleteContent() async {
    final isReel = widget.content.isReel;
    final itemLabel = isReel ? 'Reel' : 'Post';

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
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.red.shade600,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Delete $itemLabel',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete this $itemLabel?',
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(
                  'This action cannot be undone.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
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
                  backgroundColor: Colors.red.shade600,
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
                  'Yes, Delete',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      builder: (_) => const _DeleteLoadingDialog(),
    );

    final bool success;
    if (isReel) {
      success = await ApiService.deleteReel(
        widget.content.id,
        context: context,
      );
    } else {
      success = await ApiService.deleteFiles(
        widget.content.id,
        context: context,
      );
    }

    if (mounted && Navigator.canPop(context)) Navigator.pop(context);
    if (!mounted) return;

    if (success) {
      widget.onDeleted?.call();
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
                '$itemLabel deleted successfully',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: AppColors.whitecolor,
                size: 18,
              ),
              const SizedBox(width: 10),
              Text(
                'Failed to delete $itemLabel. Please try again.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _reportUser() async {
    String? selectedReason;
    String description = '';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Report User',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Why are you reporting ${widget.content.author.name}?',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Reason:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...[
                          'Spam',
                          'Harassment',
                          'Inappropriate content',
                          'Fake account',
                          'Copyright violation',
                          'Other',
                        ]
                        .map(
                          (reason) => RadioListTile<String>(
                            title: Text(reason),
                            value: reason,
                            groupValue: selectedReason,
                            onChanged:
                                (v) => setState(() => selectedReason = v),
                            contentPadding: EdgeInsets.zero,
                          ),
                        )
                        .toList(),
                    const SizedBox(height: 16),
                    Text(
                      'Additional details (optional):',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Provide more details about this report...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      maxLines: 3,
                      onChanged: (v) => description = v,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      selectedReason != null
                          ? () => Navigator.of(context).pop({
                            'reason': selectedReason!,
                            'description': description,
                          })
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: AppColors.whitecolor,
                  ),
                  child: const Text('Report'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      await _submitReport(result['reason']!, result['description']!);
    }
  }

  Future<void> _submitReport(String reason, String description) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black26,
        builder:
            (_) => Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 48),
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.whitecolor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: Image.asset(
                          'animation/IdeaBulb.gif',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Submitting report...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      );

      final token = AppData().accessToken;
      if (token == null || token.isEmpty) {
        Navigator.of(context).pop();
        Get.snackbar(
          'Error',
          'Authentication required to report user',
          backgroundColor: Colors.red,
          colorText: AppColors.whitecolor,
          icon: const Icon(Icons.error, color: AppColors.whitecolor),
        );
        return;
      }

      final response = await http
          .post(
            Uri.parse(
              '${ApiConstants.reportuser}${widget.content.author.id}/report/',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'reason': _mapReportReason(reason),
              'description': description.isNotEmpty ? description : reason,
            }),
          )
          .timeout(const Duration(seconds: 30));

      Navigator.of(context).pop();

      if (response.statusCode == 200 || response.statusCode == 201) {
        developer.log('Report submitted: ${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: AppColors.whitecolor,
                    size: 18,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Report submitted successfully',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else if (response.statusCode == 401) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
          (_) => false,
        );
      } else {
        final errData =
            response.body.isNotEmpty
                ? jsonDecode(response.body) as Map<String, dynamic>
                : {};
        final msg = errData['message']?.toString() ?? 'Failed to submit report';
        developer.log('Report failed: ${response.statusCode} ${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                msg,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.of(context).pop();
      developer.log('submitReport error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Network error. Please check your connection.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _blockUser() async {
    String? selectedReason;
    String description = '';

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Block User',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Are you sure you want to block '
                      '${widget.content.author.name}?',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Blocked users won't be able to see your posts or contact you.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Reason for blocking:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...[
                          'Spamming my posts',
                          'Harassment',
                          'Inappropriate behavior',
                          'Fake account',
                          'Unwanted contact',
                          'Other',
                        ]
                        .map(
                          (reason) => RadioListTile<String>(
                            title: Text(reason),
                            value: reason,
                            groupValue: selectedReason,
                            onChanged:
                                (v) => setState(() => selectedReason = v),
                            contentPadding: EdgeInsets.zero,
                          ),
                        )
                        .toList(),
                    const SizedBox(height: 16),
                    Text(
                      'Additional details (optional):',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Provide more details...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      maxLines: 2,
                      onChanged: (v) => description = v,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      selectedReason != null
                          ? () => Navigator.of(context).pop({
                            'reason': selectedReason!,
                            'description': description,
                          })
                          : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: AppColors.whitecolor,
                  ),
                  child: const Text('Block User'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      await _submitBlockUser(result['reason']!, result['description']!);
    }
  }

  Future<void> _submitBlockUser(String reason, String description) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black26,
        builder:
            (_) => Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 48),
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.whitecolor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: Image.asset(
                          'animation/IdeaBulb.gif',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Blocking user...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      );

      final token = AppData().accessToken;
      if (token == null || token.isEmpty) {
        Navigator.of(context).pop();
        Get.snackbar(
          'Error',
          'Authentication required to block user',
          backgroundColor: Colors.red,
          colorText: AppColors.whitecolor,
          icon: const Icon(Icons.error, color: AppColors.whitecolor),
        );
        return;
      }

      final requestBody = {
        'reason': description.isNotEmpty ? description : reason,
      };

      developer.log('Blocking user: ${jsonEncode(requestBody)}');

      final response = await http
          .post(
            Uri.parse(
              '${ApiConstants.blockuser}${widget.content.author.id}/block',
            ),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      Navigator.of(context).pop();

      developer.log('Block response: ${response.statusCode} ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final msg =
            data['message']?.toString() ??
            'Successfully blocked ${widget.content.author.name}';
        Get.snackbar(
          'User Blocked',
          msg,
          backgroundColor: Colors.green,
          colorText: AppColors.whitecolor,
          icon: const Icon(Icons.block, color: AppColors.whitecolor),
          duration: const Duration(seconds: 1),
        );
      } else if (response.statusCode == 401) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
          (_) => false,
        );
      } else if (response.statusCode == 409) {
        final data =
            response.body.isNotEmpty
                ? jsonDecode(response.body) as Map<String, dynamic>
                : {};
        final msg = data['message']?.toString() ?? 'User is already blocked';
        Get.snackbar(
          'Already Blocked',
          msg,
          backgroundColor: BrandColors.secondarySurface,
          colorText: AppColors.whitecolor,
          icon: const Icon(Icons.info, color: AppColors.whitecolor),
        );
      } else {
        final data =
            response.body.isNotEmpty
                ? jsonDecode(response.body) as Map<String, dynamic>
                : {};
        final msg = data['message']?.toString() ?? 'Failed to block user';
        Get.snackbar(
          'Error',
          msg,
          backgroundColor: Colors.red,
          colorText: AppColors.whitecolor,
          icon: const Icon(Icons.error, color: AppColors.whitecolor),
        );
        developer.log('Block failed: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      if (Navigator.canPop(context)) Navigator.of(context).pop();
      developer.log('submitBlockUser error: $e');
      Get.snackbar(
        'Error',
        'Network error. Please check your connection.',
        backgroundColor: Colors.red,
        colorText: AppColors.whitecolor,
        icon: const Icon(Icons.error, color: AppColors.whitecolor),
      );
    }
  }
}

class FullscreenVideoPage extends StatefulWidget {
  final String url;
  final String? thumbnail;
  const FullscreenVideoPage({Key? key, required this.url, this.thumbnail})
    : super(key: key);
  @override
  State<FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<FullscreenVideoPage>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _isPlaying = false;
  bool _isMuted = true;
  bool _disposed = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enterFullscreen();
    _initController();
    _startHideControlsTimer();
  }

  Future<void> _enterFullscreen() async =>
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  Future<void> _exitFullscreen() async =>
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  Future<void> _initController() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await _controller!.setLooping(false);
      await _controller!.setVolume(0.0);
      await _controller!.initialize();
      if (_disposed) return;
      setState(() {
        _initialized = true;
        _isPlaying = true;
        _isMuted = true;
      });
      _controller!.play();
    } catch (e) {
      developer.log('FullscreenVideoPage init error: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _hideControlsTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller?.pause();
    _controller?.dispose();
    _controller = null;
    _exitFullscreen();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_controller == null || _disposed) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive)
      _controller!.pause();
    else if (state == AppLifecycleState.resumed && _isPlaying)
      _controller!.play();
  }

  void _togglePlayPause() {
    if (_controller == null || !_initialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
    _showControlsTemporarily();
  }

  void _toggleMute() {
    if (_controller == null || !_initialized) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    });
    _showControlsTemporarily();
  }

  void _showControlsTemporarily() {
    setState(() => _showControls = true);
    _startHideControlsTimer();
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) setState(() => _showControls = false);
    });
  }

  void _onScreenTap() {
    if (_showControls)
      _togglePlayPause();
    else
      _showControlsTemporarily();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child:
                  _initialized && _controller != null
                      ? AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      )
                      : (widget.thumbnail != null
                          ? CachedNetworkImage(
                            imageUrl: widget.thumbnail!,
                            fit: BoxFit.contain,
                            placeholder:
                                (_, __) => Center(
                                  child: Image.asset('animation/IdeaBulb.gif'),
                                ),
                          )
                          : Center(
                            child: Image.asset('animation/IdeaBulb.gif'),
                          )),
            ),
            Positioned.fill(
              child: GestureDetector(
                onTap: _onScreenTap,
                behavior: HitTestBehavior.translucent,
                child: Container(color: Colors.transparent),
              ),
            ),
            AnimatedOpacity(
              opacity: _showControls || !_isPlaying ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, left: 8, right: 8),
                  child: Row(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(
                              Icons.arrow_back,
                              color: AppColors.whitecolor,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!_isPlaying)
              Center(
                child: GestureDetector(
                  onTap: _togglePlayPause,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      size: 50,
                      color: AppColors.whitecolor,
                    ),
                  ),
                ),
              ),
            AnimatedOpacity(
              opacity: _showControls || !_isPlaying ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _toggleMute,
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isMuted ? Icons.volume_off : Icons.volume_up,
                              color: AppColors.whitecolor,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AutoPlayVideoWidget extends StatefulWidget {
  final String url;
  final double? height;
  final double? width;
  final String? thumbnailUrl;

  const AutoPlayVideoWidget({
    required this.url,
    this.thumbnailUrl,
    this.height,
    this.width,
    Key? key,
  }) : super(key: key);

  @override
  State<AutoPlayVideoWidget> createState() => AutoPlayVideoWidgetState();
}

class AutoPlayVideoWidgetState extends State<AutoPlayVideoWidget>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver, RouteAware {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _isMuted = true;
  bool _disposed = false;
  Timer? _initTimer;
  bool _isPlaying = true;
  final String videoId = UniqueKey().toString();
  static final Map<String, AutoPlayVideoWidgetState> _activeVideos = {};

  @override
  bool get wantKeepAlive => false;

  void _safeSetState(VoidCallback fn) {
    if (mounted && !_disposed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_disposed) setState(fn);
      });
    }
  }

  void pauseVideo() {
    if (_controller != null && !_disposed && _initialized) {
      _controller!.pause();
      _safeSetState(() => _isPlaying = false);
    }
  }

  void playVideo() {
    if (_controller != null && !_disposed && _initialized) {
      _controller!.play();
      _safeSetState(() => _isPlaying = true);
    }
  }

  void muteVideo() {
    if (_controller != null && !_disposed && _initialized) {
      _controller!
          .setVolume(0.0)
          .then((_) {
            _safeSetState(() => _isMuted = true);
          })
          .catchError((e) {
            developer.log('Error muting video: $e');
          });
    }
  }

  void unmuteVideo() {
    if (_controller != null && !_disposed && _initialized) {
      _controller!.setVolume(1.0);
      _safeSetState(() => _isMuted = false);
    }
  }

  bool get isMuted => _isMuted;
  bool get isPlaying => _isPlaying;
  bool get isInitialized => _initialized;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _activeVideos[videoId] = this;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPushNext() {
    // Pause when any screen is pushed on top of the feed
    _controller?.pause();

    _safeSetState(() => _isPlaying = false);
    AutoPlayVideoWidgetState.pauseAllAutoPlayVideos();
  }

  @override
  void didPopNext() {
    // Resume when returning to feed
    if (_initialized && _controller != null) {
      _controller?.play();
      _safeSetState(() => _isPlaying = true);
    }
  }

  void _initializeVideoPlayer() {
    if (_disposed) return;
    _initTimer = Timer(const Duration(seconds: 30), () {
      if (!_initialized && !_disposed) _handleInitializationError();
    });
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.url),
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        allowBackgroundPlayback: false,
      ),
    );
    _controller!
      ..setLooping(true)
      ..setVolume(0.0)
      ..initialize()
          .then((_) {
            _initTimer?.cancel();
            if (!_disposed) {
              _safeSetState(() => _initialized = true);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_disposed) _controller!.play();
              });
            }
          })
          .catchError((error) {
            _initTimer?.cancel();
            if (!_disposed) _handleInitializationError();
          });
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    if (!mounted || _disposed) return;
    final visibleFraction = info.visibleFraction;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _disposed) return;
      if (visibleFraction > 0.7) {
        if (!_initialized && !_disposed && _controller == null) {
          try {
            _initializeVideoPlayer();
          } catch (e) {
            developer.log('Error initializing video: $e');
          }
        }
        _activeVideos[videoId] = this;
        _muteOtherVideos();
        if (_initialized &&
            _controller != null &&
            !_controller!.value.isPlaying &&
            _isPlaying) {
          _controller!.play();
        }
      } else if (visibleFraction < 0.5) {
        _activeVideos.remove(videoId);
        if (_initialized && _controller != null) {
          _controller!.setVolume(0.0);
          _controller!.pause();
          _controller!.dispose();
          _controller = null;
          _initialized = false;
          if (mounted) setState(() => _isPlaying = false);
        }
      }
    });
  }

  void _muteOtherVideos() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final entry in _activeVideos.entries) {
        if (entry.key != videoId &&
            entry.value.mounted &&
            !entry.value._disposed) {
          entry.value._controller?.pause();
          entry.value._controller?.setVolume(0.0);
          entry.value._safeSetState(() {
            entry.value._isMuted = true;
            entry.value._isPlaying = false;
          });
        }
      }
    });
  }

  static void pauseAllAutoPlayVideos() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final entry in _activeVideos.entries) {
        if (entry.value.mounted && !entry.value._disposed) {
          entry.value._controller?.setVolume(0.0);
          entry.value._controller?.pause();
          entry.value._safeSetState(() {
            entry.value._isMuted = true;
            entry.value._isPlaying = false;
          });
        }
      }
    });
  }

  static void resumeAllAutoPlayVideos() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final entry in _activeVideos.entries) {
        if (entry.value._initialized &&
            entry.value.mounted &&
            !entry.value._disposed) {
          entry.value._controller?.play();
          entry.value._controller?.setVolume(0.0);
          entry.value._safeSetState(() {
            entry.value._isPlaying = true;
            entry.value._isMuted = true;
          });
        }
      }
    });
  }

  void _handleInitializationError([Object? error]) {
    _safeSetState(() => _initialized = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (_controller == null || _disposed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _disposed) return;
      switch (state) {
        case AppLifecycleState.paused:
        case AppLifecycleState.inactive:
          _controller!.pause();
          break;
        case AppLifecycleState.resumed:
          if (_initialized && mounted && _isPlaying) _controller!.play();
          break;
        case AppLifecycleState.detached:
        case AppLifecycleState.hidden:
          _controller!.pause();
          break;
      }
    });
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _disposed = true;
    _activeVideos.remove(videoId);
    _initTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  // void _openFullscreen() {
  //   if (!mounted || _controller == null) return;
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder:
  //           (_) => FullscreenVideoPage(
  //             url: widget.url,
  //             thumbnail: widget.thumbnailUrl,
  //           ),
  //     ),
  //   );
  // }

  void _openFullscreen() {
    if (!mounted || _controller == null) return;
    _controller!.pause(); // ← pause inline first
    _safeSetState(() => _isPlaying = false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => FullscreenVideoPage(
              url: widget.url,
              thumbnail: widget.thumbnailUrl,
            ),
      ),
    ).then((_) {
      // Resume inline when user returns from fullscreen
      if (mounted && !_disposed && _initialized && _controller != null) {
        _controller!.play();
        _safeSetState(() => _isPlaying = true);
      }
    });
  }

  void _toggleMute() {
    if (_controller == null || _disposed || !_initialized) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return VisibilityDetector(
      key: Key(videoId),
      onVisibilityChanged: _handleVisibilityChanged,
      child: Container(
        height: widget.height ?? MediaQuery.of(context).size.height,
        width: widget.width ?? MediaQuery.of(context).size.width,
        color: AppColors.whitecolor,
        child:
            !_initialized || _controller == null
                ? _buildLoadingOrThumbnail()
                : _buildVideoPlayer(),
      ),
    );
  }

  Widget _buildLoadingOrThumbnail() {
    if (widget.thumbnailUrl != null) {
      return CachedNetworkImage(
        imageUrl: widget.thumbnailUrl!,
        fit: BoxFit.cover,
        // placeholder:
        //     (_, __) => Center(
        //       child: SizedBox(
        //         width: 40,
        //         height: 40,
        //         child: Image.asset(
        //           'animation/IdeaBulb.gif',
        //           fit: BoxFit.contain,
        //         ),
        //       ),
        //     ),
        placeholder: (_, __) => const ColoredBox(color: Colors.black12),
        errorWidget:
            (_, __, ___) => Container(
              color: Colors.grey,
              child: const Center(
                child: Icon(Icons.videocam_off, color: AppColors.whitecolor),
              ),
            ),
      );
    }
    return const ColoredBox(color: Colors.black12);
  }

  Widget _buildVideoPlayer() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = _controller!.value.size;
        final aspectRatio = size.width / size.height;
        double targetWidth = constraints.maxWidth;
        double targetHeight = constraints.maxWidth / aspectRatio;
        if (targetHeight > constraints.maxHeight) {
          targetHeight = constraints.maxHeight;
          targetWidth = constraints.maxHeight * aspectRatio;
        }
        return Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              GestureDetector(
                onTap: _openFullscreen,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: targetWidth,
                  height: targetHeight,
                  child: VideoPlayer(_controller!),
                ),
              ),
              if (!_isPlaying)
                IgnorePointer(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      size: 50,
                      color: AppColors.whitecolor,
                    ),
                  ),
                ),
              Positioned(
                top: 16,
                right: 16,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.fullscreen,
                      color: AppColors.whitecolor,
                      size: 20,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: GestureDetector(
                  onTap: _toggleMute,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.whitecolor.withAlpha(30),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up,
                      color: AppColors.whitecolor,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;

  const _SBox({this.width, required this.height, this.radius = 6});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.whitecolor,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _SCircle extends StatelessWidget {
  final double size;
  const _SCircle(this.size);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.whitecolor,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _ShimmerCardTextOnly extends StatelessWidget {
  const _ShimmerCardTextOnly();

  @override
  Widget build(BuildContext context) {
    return _ShimmerWrapper(child: _PostSkeleton(showMedia: false));
  }
}

class _ShimmerWrapper extends StatelessWidget {
  final Widget child;
  const _ShimmerWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8E8E8),
      highlightColor: const Color(0xFFF8F8F8),
      period: const Duration(milliseconds: 1200),
      child: child,
    );
  }
}

class _PostSkeleton extends StatelessWidget {
  final bool showMedia;
  const _PostSkeleton({required this.showMedia});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.whitecolor,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1.0),
          bottom: BorderSide(color: Colors.grey.shade200, width: 3.0),
        ),
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
          mainAxisSize: MainAxisSize.min,
          children: [
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
                  child: const _SCircle(40),
                ),
                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SBox(width: w * 0.32, height: 13, radius: 4),
                      const SizedBox(height: 6),
                      _SBox(width: w * 0.20, height: 10, radius: 4),
                    ],
                  ),
                ),
                _SBox(width: 76, height: 26, radius: 20),
                const SizedBox(width: 8),
                const _SCircle(20),
              ],
            ),

            const SizedBox(height: 12),

            _SBox(width: w * 0.85, height: 12, radius: 4),
            const SizedBox(height: 7),
            _SBox(width: w * 0.72, height: 12, radius: 4),
            const SizedBox(height: 7),
            _SBox(width: w * 0.52, height: 12, radius: 4),

            if (showMedia) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: _SBox(
                  width: double.infinity,
                  height: (w - 16) * 0.72,
                  radius: 4,
                ),
              ),
            ],

            const SizedBox(height: 12),

            Container(
              height: 1,
              color: Colors.grey.shade200,
              margin: const EdgeInsets.symmetric(horizontal: 2),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                const _SCircle(18),
                const SizedBox(width: 6),
                _SBox(width: 48, height: 11, radius: 4),

                const SizedBox(width: 20),

                const _SCircle(18),
                const SizedBox(width: 6),
                _SBox(width: 62, height: 11, radius: 4),

                const Spacer(),

                const _SCircle(18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerFeedList extends StatelessWidget {
  const _ShimmerFeedList();

  @override
  Widget build(BuildContext context) {
    const pattern = [true, false, true, false, true];
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pattern.length,
      itemBuilder:
          (_, i) =>
              _ShimmerWrapper(child: _PostSkeleton(showMedia: pattern[i])),
    );
  }
}

typedef _ShimmerFeedCard = _ShimmerCardTextOnly;

// typedef _ShimmerFeedCardWithMedia = _ShimmerCardWithMedia;

class _FeedRefreshBar extends StatelessWidget {
  const _FeedRefreshBar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      child: LinearProgressIndicator(
        value: null,
        backgroundColor: BrandColors.accent.withValues(alpha: .15),
        valueColor: const AlwaysStoppedAnimation<Color>(
          BrandColors.accent,
        ),
        minHeight: 3,
      ),
    );
  }
}

class _DeleteLoadingDialog extends StatelessWidget {
  const _DeleteLoadingDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 48),
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.whitecolor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: Image.asset('animation/IdeaBulb.gif', fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
            Text(
              'Deleting post...',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red.shade400),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SaveLoadingDialog extends StatelessWidget {
  const _SaveLoadingDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 48),
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.whitecolor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: Image.asset('animation/IdeaBulb.gif', fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
            Text(
              'Saving changes...',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  BrandColors.accent,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LinkifyText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const _LinkifyText({
    required this.text,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  State<_LinkifyText> createState() => _LinkifyTextState();
}

class _LinkifyTextState extends State<_LinkifyText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Clear old recognizers before rebuilding
    for (final r in _recognizers) r.dispose();
    _recognizers.clear();

    final RegExp urlRegExp = RegExp(
      r'(https?:\/\/[^\s]+)',
      caseSensitive: false,
    );
    final RegExp hashtagRegExp = RegExp(
      r'(#[a-zA-Z0-9_]+)',
      caseSensitive: false,
    );

    final List<InlineSpan> spans = [];
    final List<_TextMatch> allMatches = [];

    allMatches.addAll(
      urlRegExp.allMatches(widget.text).map((m) => _TextMatch(m, 'url')),
    );
    allMatches.addAll(
      hashtagRegExp
          .allMatches(widget.text)
          .map((m) => _TextMatch(m, 'hashtag')),
    );
    allMatches.sort((a, b) => a.match.start.compareTo(b.match.start));

    final List<_TextMatch> filteredMatches = [];
    for (int i = 0; i < allMatches.length; i++) {
      bool shouldAdd = true;
      for (int j = 0; j < filteredMatches.length; j++) {
        if (_matchesOverlap(allMatches[i].match, filteredMatches[j].match)) {
          shouldAdd = false;
          break;
        }
      }
      if (shouldAdd) filteredMatches.add(allMatches[i]);
    }

    int lastMatchEnd = 0;
    for (final matchWithType in filteredMatches) {
      final match = matchWithType.match;
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: widget.text.substring(lastMatchEnd, match.start),
            style: widget.style,
          ),
        );
      }
      final matchText = match.group(0)!;
      if (matchWithType.type == 'url') {
        final recognizer =
            TapGestureRecognizer()
              ..onTap = () async {
                final uri = Uri.parse(matchText);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              };
        _recognizers.add(recognizer);
        spans.add(
          TextSpan(
            text: matchText,
            style: widget.style?.copyWith(
              color: Colors.blue.shade600,
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w500,
            ),
            recognizer: recognizer,
          ),
        );
      } else if (matchWithType.type == 'hashtag') {
        final recognizer =
            TapGestureRecognizer()
              ..onTap = () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Hashtag tapped: $matchText'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              };
        _recognizers.add(recognizer);
        spans.add(
          TextSpan(
            text: matchText,
            style: widget.style?.copyWith(
              color: Colors.purple.shade600,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.none,
            ),
            recognizer: recognizer,
          ),
        );
      }
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < widget.text.length) {
      spans.add(
        TextSpan(
          text: widget.text.substring(lastMatchEnd),
          style: widget.style,
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: widget.maxLines,
      overflow: widget.overflow ?? TextOverflow.clip,
    );
  }

  bool _matchesOverlap(RegExpMatch m1, RegExpMatch m2) =>
      m1.start < m2.end && m1.end > m2.start;
}

class _TextMatch {
  final RegExpMatch match;
  final String type;
  _TextMatch(this.match, this.type);
}

extension DateTimeExtension on DateTime {
  String timeAgo() {
    final difference = DateTime.now().difference(this);
    if (difference.inDays > 365)
      return '${(difference.inDays / 365).floor()} year(s) ago';
    if (difference.inDays > 30)
      return '${(difference.inDays / 30).floor()} month(s) ago';
    if (difference.inDays > 0) return '${difference.inDays} day(s) ago';
    if (difference.inHours > 0) return '${difference.inHours} hour(s) ago';
    if (difference.inMinutes > 0)
      return '${difference.inMinutes} minute(s) ago';
    return 'Just now';
  }
}
