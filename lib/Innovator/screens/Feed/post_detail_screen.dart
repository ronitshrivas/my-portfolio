// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:innovator/Innovator/App_data/App_data.dart';
// import 'package:innovator/Innovator/Authorization/Login.dart';
// import 'package:innovator/Innovator/constant/app_colors.dart';
// import 'package:innovator/Innovator/models/Feed_Content_Model.dart';
// import 'package:innovator/Innovator/screens/Feed/Inner_Homepage.dart';

// class NewFeedPostDetailScreen extends StatefulWidget {
//   final String postId;
//   final String? highlightAction;

//   const NewFeedPostDetailScreen({
//     Key? key,
//     required this.postId,
//     this.highlightAction,
//   }) : super(key: key);

//   @override
//   State<NewFeedPostDetailScreen> createState() =>
//       _NewFeedPostDetailScreenState();
// }

// class _NewFeedPostDetailScreenState extends State<NewFeedPostDetailScreen> {
//   FeedContent? _post;
//   bool _isLoading = true;
//   bool _hasError = false;
//   String _errorMessage = '';

//   @override
//   void initState() {
//     super.initState();
//     _fetchPost();
//   }

//   Future<void> _fetchPost() async {
//     setState(() {
//       _isLoading = true;
//       _hasError = false;
//     });

//     try {
//       final token = AppData().accessToken;
//       if (token == null || token.isEmpty) {
//         if (mounted) {
//           Navigator.pushAndRemoveUntil(
//             context,
//             MaterialPageRoute(builder: (_) => LoginPage()),
//             (_) => false,
//           );
//         }
//         return;
//       }

//       // New API: GET /api/posts/<id>/
//       final response = await http
//           .get(
//             Uri.parse('http://36.253.137.34:8005/api/posts/${widget.postId}/'),
//             headers: {
//               'Content-Type': 'application/json',
//               'Accept': 'application/json',
//               'Authorization': 'Bearer $token',
//             },
//           )
//           .timeout(const Duration(seconds: 30));

//       if (!mounted) return;

//       if (response.statusCode == 200) {
//         final decoded = json.decode(response.body);
//         // The endpoint returns a single post object (same shape as results[])
//         final post = FeedContent.fromNewApiPost(
//           decoded is Map<String, dynamic> ? decoded : decoded,
//         );
//         setState(() {
//           _post = post;
//           _isLoading = false;
//         });
//       } else if (response.statusCode == 401) {
//         Navigator.pushAndRemoveUntil(
//           context,
//           MaterialPageRoute(builder: (_) => LoginPage()),
//           (_) => false,
//         );
//       } else if (response.statusCode == 404) {
//         setState(() {
//           _hasError = true;
//           _errorMessage = 'Post not found or has been deleted.';
//           _isLoading = false;
//         });
//       } else {
//         setState(() {
//           _hasError = true;
//           _errorMessage = 'Failed to load post (${response.statusCode})';
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         _hasError = true;
//         _errorMessage = 'Network error. Please try again.';
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         title: const Text(
//           'Post',
//           style: TextStyle(
//             color: AppColors.whitecolor,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: AppColors.whitecolor),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: _buildBody(),
//     );
//   }

//   Widget _buildBody() {
//     if (_isLoading) {
//       return const Center(
//         child: CircularProgressIndicator(
//           valueColor: AlwaysStoppedAnimation<Color>(
//             Color.fromRGBO(244, 135, 6, 1),
//           ),
//         ),
//       );
//     }

//     if (_hasError || _post == null) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
//             const SizedBox(height: 16),
//             Text(
//               _errorMessage.isNotEmpty ? _errorMessage : 'Failed to load post',
//               textAlign: TextAlign.center,
//               style: TextStyle(fontSize: 16, color: Colors.grey[600]),
//             ),
//             const SizedBox(height: 16),
//             ElevatedButton.icon(
//               onPressed: _fetchPost,
//               icon: const Icon(Icons.refresh),
//               label: const Text('Retry'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
//                 foregroundColor: AppColors.whitecolor,
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     // Reuse your existing FeedItem widget — it already handles
//     // likes, comments, reposts, media, share, edit, delete, follow, etc.
//     return SingleChildScrollView(
//       physics: const AlwaysScrollableScrollPhysics(),
//       child: Column(
//         children: [
//           // Optional: highlight banner when coming from a notification
//           if (widget.highlightAction != null)
//             // _buildHighlightBanner(widget.highlightAction!),
//             FeedItem(
//               content: _post!,
//               onLikeToggled: (isLiked) {
//                 if (!mounted) return;
//                 setState(() {
//                   _post!.isLiked = isLiked;
//                   _post!.likes =
//                       isLiked
//                           ? (_post!.likes + 1).clamp(0, 999999)
//                           : (_post!.likes - 1).clamp(0, 999999);
//                 });
//               },
//               onFollowToggled: (isFollowed) {
//                 if (!mounted) return;
//                 setState(() => _post!.isFollowed = isFollowed);
//               },
//               onDeleted: () {
//                 if (mounted) Navigator.pop(context);
//               },
//               onStatusUpdated: (newStatus) {
//                 if (mounted) setState(() => _post!.status = newStatus);
//               },
//               onCommentAdded: () {
//                 if (mounted) setState(() => _post!.comments++);
//               },
//             ),

//           const SizedBox(height: 80),
//         ],
//       ),
//     );
//   }

//   Widget _buildHighlightBanner(String action) {
//     final config = _bannerConfig(action);
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//       color: config['color'] as Color,
//       child: Row(
//         children: [
//           Icon(config['icon'] as IconData, color: Colors.white, size: 18),
//           const SizedBox(width: 8),
//           Text(
//             config['text'],
//             style: const TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.w600,
//               fontSize: 13,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Map<String, dynamic> _bannerConfig(String action) {
//     switch (action) {
//       case 'like':
//         return {
//           'color': Colors.red.shade400,
//           'icon': Icons.favorite,
//           //'text': 'Someone reacted to this post',
//         };
//       case 'comment':
//         return {
//           'color': Colors.blue.shade500,
//           'icon': Icons.mode_comment,
//           'text': 'Someone commented on this post',
//         };
//       case 'repost':
//       case 'share':
//         return {
//           'color': Colors.green.shade500,
//           'icon': Icons.repeat,
//           'text': 'Someone reposted this',
//         };
//       default:
//         return {
//           'color': const Color.fromRGBO(244, 135, 6, 1),
//           'icon': Icons.notifications,
//           'text': 'You have a new notification on this post',
//         };
//     }
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/Authorization/Login.dart';
import 'package:innovator/Innovator/constant/app_colors.dart';
import 'package:innovator/Innovator/models/Feed_Content_Model.dart';
import 'package:innovator/Innovator/screens/Feed/Inner_Homepage.dart';
import 'package:innovator/Innovator/screens/Feed/facebook_video_widget.dart';
import 'package:innovator/Innovator/screens/Likes/Content-Like-Service.dart';
import 'package:innovator/Innovator/screens/Likes/content-Like-Button.dart';
import 'package:innovator/Innovator/screens/Likes/reaction_sheet_screen.dart';
import 'package:innovator/Innovator/screens/SHow_Specific_Profile/Show_Specific_Profile.dart';
import 'package:innovator/Innovator/screens/chatrrom/sound/soundplayer.dart';
import 'package:innovator/Innovator/screens/comment/comment_section.dart';
import 'package:innovator/Innovator/widget/repost_button.dart';
import 'package:innovator/Innovator/screens/Feed/Repost/repost_list_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'dart:developer' as developer;

class NewFeedPostDetailScreen extends StatefulWidget {
  final String postId;
  final String? highlightAction;

  const NewFeedPostDetailScreen({
    Key? key,
    required this.postId,
    this.highlightAction,
  }) : super(key: key);

  @override
  State<NewFeedPostDetailScreen> createState() =>
      _NewFeedPostDetailScreenState();
}

class _NewFeedPostDetailScreenState extends State<NewFeedPostDetailScreen> {
  FeedContent? _post;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchPost();
  }

  Future<void> _fetchPost() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final token = AppData().accessToken;
      if (token == null || token.isEmpty) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => LoginPage()),
            (_) => false,
          );
        }
        return;
      }

      final response = await http
          .get(
            Uri.parse('http://36.253.137.34:8005/api/posts/${widget.postId}/'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final post = FeedContent.fromNewApiPost(
          decoded is Map<String, dynamic> ? decoded : decoded,
        );
        setState(() {
          _post = post;
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
          (_) => false,
        );
      } else if (response.statusCode == 404) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Post not found or has been deleted.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to load post (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = 'Network error. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use immersive full-screen for reels
    final isReel = _post?.isReel ?? false;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      extendBodyBehindAppBar: isReel,
      appBar: isReel ? _buildReelAppBar() : _buildNormalAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildNormalAppBar() => AppBar(
    backgroundColor: Colors.transparent,
    title: const Text(
      'Post',
      style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
    ),
    //backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
    elevation: 0,
    scrolledUnderElevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
      onPressed: () => Navigator.pop(context),
    ),
  );

  PreferredSizeWidget _buildReelAppBar() => AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    systemOverlayStyle: SystemUiOverlayStyle.light,
    leading: IconButton(
      icon: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.black45,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
      ),
      onPressed: () => Navigator.pop(context),
    ),
    title: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_circle_fill, color: Colors.white, size: 16),
          SizedBox(width: 6),
          Text(
            'Reel',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            _post?.isReel ?? false
                ? Colors.white
                : const Color.fromRGBO(244, 135, 6, 1),
          ),
        ),
      );
    }

    if (_hasError || _post == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _errorMessage.isNotEmpty ? _errorMessage : 'Failed to load post',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchPost,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
                foregroundColor: AppColors.whitecolor,
              ),
            ),
          ],
        ),
      );
    }

    // Route to reel player or normal feed item
    if (_post!.isReel) {
      return _ReelDetailView(
        post: _post!,
        highlightAction: widget.highlightAction,
        onLikeToggled: (isLiked) {
          if (!mounted) return;
          setState(() {
            _post!.isLiked = isLiked;
            _post!.likes =
                isLiked
                    ? (_post!.likes + 1).clamp(0, 999999)
                    : (_post!.likes - 1).clamp(0, 999999);
          });
        },
        onFollowToggled: (isFollowed) {
          if (!mounted) return;
          setState(() => _post!.isFollowed = isFollowed);
        },
        onDeleted: () {
          if (mounted) Navigator.pop(context);
        },
        onStatusUpdated: (newStatus) {
          if (mounted) setState(() => _post!.status = newStatus);
        },
        onCommentAdded: () {
          if (mounted) setState(() => _post!.comments++);
        },
      );
    }

    // Normal post layout
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          // if (widget.highlightAction != null)
          //   _buildHighlightBanner(widget.highlightAction!),
          FeedItem(
            content: _post!,
            onLikeToggled: (isLiked) {
              if (!mounted) return;
              setState(() {
                _post!.isLiked = isLiked;
                _post!.likes =
                    isLiked
                        ? (_post!.likes + 1).clamp(0, 999999)
                        : (_post!.likes - 1).clamp(0, 999999);
              });
            },
            onFollowToggled: (isFollowed) {
              if (!mounted) return;
              setState(() => _post!.isFollowed = isFollowed);
            },
            onDeleted: () {
              if (mounted) Navigator.pop(context);
            },
            onStatusUpdated: (newStatus) {
              if (mounted) setState(() => _post!.status = newStatus);
            },
            onCommentAdded: () {
              if (mounted) setState(() => _post!.comments++);
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHighlightBanner(String action) {
    final config = _bannerConfig(action);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: config['color'] as Color,
      child: Row(
        children: [
          Icon(config['icon'] as IconData, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            config['text'] as String,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _bannerConfig(String action) {
    switch (action) {
      case 'like':
      case 'reel_like':
        return {
          'color': Colors.red.shade400,
          'icon': Icons.favorite,
          'text': 'Someone reacted to this',
        };
      case 'comment':
      case 'reel_comment':
        return {
          'color': Colors.blue.shade500,
          'icon': Icons.mode_comment,
          'text': 'Someone commented on this',
        };
      case 'reel':
      case 'new_reel':
        return {
          'color': Colors.purple.shade600,
          'icon': Icons.play_circle_fill,
          'text': 'New reel posted',
        };
      case 'repost':
      case 'share':
      case 'reel_share':
        return {
          'color': Colors.green.shade500,
          'icon': Icons.repeat,
          'text': 'Someone reposted this',
        };
      default:
        return {
          'color': const Color.fromRGBO(244, 135, 6, 1),
          'icon': Icons.notifications,
          'text': 'You have a new notification',
        };
    }
  }
}

class _ReelDetailView extends StatefulWidget {
  final FeedContent post;
  final String? highlightAction;
  final Function(bool) onLikeToggled;
  final Function(bool) onFollowToggled;
  final VoidCallback? onDeleted;
  final Function(String)? onStatusUpdated;
  final VoidCallback? onCommentAdded;

  const _ReelDetailView({
    required this.post,
    this.highlightAction,
    required this.onLikeToggled,
    required this.onFollowToggled,
    this.onDeleted,
    this.onStatusUpdated,
    this.onCommentAdded,
  });

  @override
  State<_ReelDetailView> createState() => _ReelDetailViewState();
}

class _ReelDetailViewState extends State<_ReelDetailView>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _initialized = false;
  bool _isMuted = false;
  bool _isPlaying = true;
  bool _disposed = false;
  bool _showComments = false;
  bool _showControls = true;

  final ContentLikeService _likeService = ContentLikeService(
    baseUrl: 'http://36.253.137.34:8005',
  );

  String get _videoUrl {
    final videos =
        widget.post.mediaUrls.where((u) => FileTypeHelper.isVideo(u)).toList();
    return videos.isNotEmpty ? videos.first : '';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initVideo();
  }

  Future<void> _initVideo() async {
    final url = _videoUrl;
    if (url.isEmpty) return;

    _controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await _controller!.setLooping(true);
      await _controller!.setVolume(1.0);
      await _controller!.initialize();
      if (_disposed || !mounted) return;
      setState(() => _initialized = true);
      _controller!.play();
    } catch (e) {
      developer.log('[ReelDetail] video init error: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _controller?.pause();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || _disposed) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _controller!.pause();
    } else if (state == AppLifecycleState.resumed && _isPlaying) {
      _controller!.play();
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_initialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
        _showControls = true;
      } else {
        _controller!.play();
        _isPlaying = true;
        // Auto-hide controls after resume
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _isPlaying) setState(() => _showControls = false);
        });
      }
    });
  }

  void _toggleMute() {
    if (_controller == null || !_initialized) return;
    setState(() {
      _isMuted = !_isMuted;
      _controller!.setVolume(_isMuted ? 0.0 : 1.0);
    });
  }

  void _onVideoTap() {
    if (_showControls) {
      _togglePlayPause();
    } else {
      setState(() => _showControls = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted && _isPlaying) setState(() => _showControls = false);
      });
    }
  }

  void _showReactionsList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (_) => reeactionsheet(
            postId: widget.post.id,
            isreel: widget.post.isReel,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final hasVideo = _videoUrl.isNotEmpty;

    return Stack(
      children: [
        GestureDetector(
          onTap: _onVideoTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child:
                hasVideo
                    ? (_initialized && _controller != null
                        ? Center(
                          child: AspectRatio(
                            aspectRatio: _controller!.value.aspectRatio,
                            child: VideoPlayer(_controller!),
                          ),
                        )
                        : _buildThumbnailPlaceholder())
                    : _buildThumbnailPlaceholder(),
          ),
        ),

        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: size.height * 0.5,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.85), Colors.transparent],
                ),
              ),
            ),
          ),
        ),

        if (!_isPlaying)
          Center(
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: !_isPlaying ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),

        Positioned(
          right: 12,
          bottom: 100,
          child: Column(
            children: [
              // Avatar + follow
              _buildAuthorAvatar(),
              const SizedBox(height: 20),

              // Like button
              _buildActionButton(
                child: LikeButton(
                  contentId: widget.post.id,
                  initialLikeStatus: widget.post.isLiked,
                  likeService: _likeService,
                  initialReactionType: widget.post.currentUserReaction,
                  isReel: true,
                  onLikeToggled: (isLiked) {
                    widget.onLikeToggled(isLiked);
                    SoundPlayer().playlikeSound();
                  },
                ),
                label: '${widget.post.likes}',
              ),
              const SizedBox(height: 20),

              // Comment button
              _buildActionButton(
                child: GestureDetector(
                  onTap: () => setState(() => _showComments = !_showComments),
                  child: Image.asset(
                    'assets/icon/comment.png',
                    color: _showComments ? Colors.blue[300] : Colors.white,
                    width: 28,
                    height: 28,
                  ),
                ),
                label: '${widget.post.comments}',
              ),
              const SizedBox(height: 20),

              // Repost button
              _buildActionButton(
                child: RepostButton(
                  postId: widget.post.id,
                  authorName: widget.post.author.name,
                  content: widget.post.status,
                  authorAvatar:
                      widget.post.author.picture.isNotEmpty
                          ? widget.post.author.picture
                          : null,
                  onViewReposts: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => RepostsListScreen(
                              postId: widget.post.id,
                              originalAuthorName: widget.post.author.name,
                            ),
                      ),
                    );
                  },
                ),
                label: '',
              ),
              const SizedBox(height: 20),

              // Share
              _buildActionButton(
                child: GestureDetector(
                  onTap: () => _shareViaApps(),
                  child: Image.asset(
                    'assets/icon/send.png',
                    color: Colors.white,
                    width: 26,
                    height: 26,
                  ),
                ),
                label: 'Share',
              ),
              const SizedBox(height: 20),

              // Mute toggle
              GestureDetector(
                onTap: _toggleMute,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    _isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),

        Positioned(
          left: 16,
          right: 70,
          bottom: _showComments ? size.height * 0.45 + 16 : 24,
          child: AnimatedSlide(
            offset: _showComments ? const Offset(0, -0.1) : Offset.zero,
            duration: const Duration(milliseconds: 300),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Author row
                GestureDetector(
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => SpecificUserProfilePage(
                                userId: widget.post.author.id,
                              ),
                        ),
                      ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromRGBO(244, 135, 6, 1),
                              Color.fromRGBO(255, 204, 0, 1),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: ClipOval(
                          child:
                              widget.post.author.picture.isNotEmpty
                                  ? CachedNetworkImage(
                                    imageUrl: widget.post.author.picture,
                                    fit: BoxFit.cover,
                                    errorWidget:
                                        (_, __, ___) => _avatarFallback(),
                                  )
                                  : _avatarFallback(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.post.author.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          shadows: [
                            Shadow(color: Colors.black54, blurRadius: 4),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.post.status.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.post.status,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.4,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                    ),
                  ),
                ],
                // Notification banner
                if (widget.highlightAction != null) ...[
                  const SizedBox(height: 8),
                  _buildMiniHighlightBadge(widget.highlightAction!),
                ],
              ],
            ),
          ),
        ),

        if (_initialized && _controller != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: VideoProgressIndicator(
              _controller!,
              allowScrubbing: true,
              colors: VideoProgressColors(
                playedColor: const Color.fromRGBO(244, 135, 6, 1),
                bufferedColor: Colors.white30,
                backgroundColor: Colors.white12,
              ),
              padding: EdgeInsets.zero,
            ),
          ),

        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          left: 0,
          right: 0,
          bottom: _showComments ? 0 : -size.height * 0.55,
          height: size.height * 0.55,
          child: GestureDetector(
            onTap: () {}, // Prevent tap-through closing video
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag handle + close
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        const Spacer(),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _showComments = false),
                          child: Icon(
                            Icons.close,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: CommentSection(
                      contentId: widget.post.id,
                      isReel: true,
                      onCommentCountChanged: (delta) {
                        setState(() {
                          widget.post.comments = (widget.post.comments + delta)
                              .clamp(0, 999999);
                        });
                        widget.onCommentAdded?.call();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _avatarFallback() => Container(
    color: Colors.grey.shade300,
    child: Center(
      child: Text(
        widget.post.author.name.isNotEmpty
            ? widget.post.author.name[0].toUpperCase()
            : '?',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ),
  );

  Widget _buildThumbnailPlaceholder() {
    return widget.post.thumbnailUrl != null
        ? CachedNetworkImage(
          imageUrl: widget.post.thumbnailUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (_, __) => _loadingPlaceholder(),
          errorWidget: (_, __, ___) => _loadingPlaceholder(),
        )
        : _loadingPlaceholder();
  }

  Widget _loadingPlaceholder() => Container(
    color: Colors.black,
    child: Center(
      child: SizedBox(
        width: 48,
        height: 48,
        child: Image.asset('animation/IdeaBulb.gif', fit: BoxFit.contain),
      ),
    ),
  );

  Widget _buildAuthorAvatar() {
    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => SpecificUserProfilePage(userId: widget.post.author.id),
            ),
          ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: ClipOval(
              child:
                  widget.post.author.picture.isNotEmpty
                      ? CachedNetworkImage(
                        imageUrl: widget.post.author.picture,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _avatarFallback(),
                      )
                      : _avatarFallback(),
            ),
          ),
          if (!widget.post.isFollowed)
            Positioned(
              bottom: -8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(244, 135, 6, 1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required Widget child, required String label}) {
    return Column(
      children: [
        child,
        if (label.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMiniHighlightBadge(String action) {
    final config = _badgeConfig(action);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: (config['color'] as Color).withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config['icon'] as IconData, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            config['text'] as String,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _badgeConfig(String action) {
    switch (action) {
      case 'like':
        return {
          'color': Colors.red.shade500,
          'icon': Icons.favorite,
          'text': 'Liked your reel',
        };
      case 'comment':
        return {
          'color': Colors.blue.shade500,
          'icon': Icons.mode_comment,
          'text': 'Commented on your reel',
        };
      case 'reel':
        return {
          'color': Colors.purple.shade600,
          'icon': Icons.play_circle_fill,
          'text': 'New reel',
        };
      default:
        return {
          'color': const Color.fromRGBO(244, 135, 6, 1),
          'icon': Icons.notifications,
          'text': 'New activity',
        };
    }
  }

  void _shareViaApps() async {
    try {
      final shareText =
          'Check out this reel by ${widget.post.author.name}: '
          '${widget.post.status}';
      await Share.share(shareText);
    } catch (e) {
      developer.log('shareViaApps error: $e');
    }
  }
}
