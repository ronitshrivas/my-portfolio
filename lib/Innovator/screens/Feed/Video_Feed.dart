// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer' as developer;
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:http/http.dart' as http;
// import 'package:share_plus/share_plus.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:innovator/Innovator/App_data/App_data.dart';
// import 'package:innovator/Innovator/screens/comment/comment_section.dart';
// import 'package:innovator/Innovator/screens/Follow/follow_Button.dart';
// import 'package:innovator/Innovator/screens/Likes/Content-Like-Service.dart';
// import 'package:innovator/Innovator/screens/SHow_Specific_Profile/Show_Specific_Profile.dart';
// import 'reels_player.dart';

// // ════════════════════════════════════════════════════════════════════════════
// // MODELS
// // ════════════════════════════════════════════════════════════════════════════

// class ReelModel {
//   final String id;
//   final String userId;
//   final String username;
//   final String avatar;
//   String caption;
//   final String? videoUrl;
//   final String? hlsUrl;
//   final String? thumbnail;
//   int viewsCount;
//   int reactionsCount;
//   String? currentUserReaction;
//   bool isFollowed;
//   int commentsCount;
//   final DateTime createdAt;
//   final String? sharedReelId;
//   final ReelModel? sharedReelDetails;

//   ReelModel({
//     required this.id,
//     required this.userId,
//     required this.username,
//     required this.avatar,
//     required this.caption,
//     this.videoUrl,
//     this.hlsUrl,
//     this.thumbnail,
//     required this.viewsCount,
//     required this.reactionsCount,
//     this.currentUserReaction,
//     required this.isFollowed,
//     required this.commentsCount,
//     required this.createdAt,
//     this.sharedReelId,
//     this.sharedReelDetails,
//   });

//   bool get hasVideo =>
//       (hlsUrl != null && hlsUrl!.isNotEmpty) ||
//       (videoUrl != null && videoUrl!.isNotEmpty);

//   String? get bestVideoUrl =>
//       (hlsUrl != null && hlsUrl!.isNotEmpty) ? hlsUrl : videoUrl;

//   bool get isLiked => currentUserReaction != null;
//   bool get isRepost => sharedReelId != null;
//   ReactionType? get currentReactionType =>
//       ReactionTypeExtension.fromValue(currentUserReaction);

//   factory ReelModel.fromJson(Map<String, dynamic> j) => ReelModel(
//     id: j['id']?.toString() ?? '',
//     userId: j['user_id']?.toString() ?? '',
//     username: j['username']?.toString() ?? '',
//     avatar: j['avatar']?.toString() ?? '',
//     caption: j['caption']?.toString() ?? '',
//     videoUrl: j['video']?.toString(),
//     hlsUrl: j['hls_playlist_url']?.toString(),
//     thumbnail: j['thumbnail']?.toString(),
//     viewsCount: (j['views_count'] as num?)?.toInt() ?? 0,
//     reactionsCount:
//         (j['reactions_count'] as num?)?.toInt() ??
//         (j['like_count'] as num?)?.toInt() ??
//         0,
//     currentUserReaction: j['current_user_reaction']?.toString(),
//     isFollowed: j['is_followed'] == true,
//     commentsCount: (j['comments_count'] as num?)?.toInt() ?? 0,
//     createdAt:
//         DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
//     sharedReelId: j['shared_reel']?.toString(),
//     sharedReelDetails:
//         j['shared_reel_details'] != null
//             ? ReelModel.fromJson(
//               j['shared_reel_details'] as Map<String, dynamic>,
//             )
//             : null,
//   );
// }

// class ReelOperationResult {
//   final bool success;
//   final String? errorMessage;
//   final ReelModel? data;
//   const ReelOperationResult({
//     required this.success,
//     this.errorMessage,
//     this.data,
//   });
// }

// // ════════════════════════════════════════════════════════════════════════════
// // API SERVICE
// // ════════════════════════════════════════════════════════════════════════════

// class ReelsApiService {
//   static const _base = 'http://36.253.137.34:8012';
//   static const _reelsUrl = '$_base/api/reels/';

//   static Map<String, String> _headers() {
//     final token = AppData().accessToken ?? '';
//     return {
//       'Content-Type': 'application/json',
//       'Accept': 'application/json',
//       if (token.isNotEmpty) 'Authorization': 'Bearer $token',
//     };
//   }

//   static Future<Map<String, dynamic>> fetchReels({String? cursor}) async {
//     final uri =
//         (cursor != null && cursor.isNotEmpty)
//             ? Uri.parse(cursor)
//             : Uri.parse(_reelsUrl);
//     final res = await http
//         .get(uri, headers: _headers())
//         .timeout(const Duration(seconds: 20));
//     // if (res.statusCode == 200) {
//     //   final data = json.decode(res.body) as Map<String, dynamic>;
//     //   return (data['results'] as List<dynamic>? ?? [])
//     //       .whereType<Map<String, dynamic>>()
//     //       .map(ReelModel.fromJson)
//     //       .where((r) => r.hasVideo)
//     //       .toList();
//     // }
//     if (res.statusCode == 200) {
//       final data = json.decode(res.body) as Map<String, dynamic>;
//       final reels =
//           (data['results'] as List<dynamic>? ?? [])
//               .whereType<Map<String, dynamic>>()
//               .map(ReelModel.fromJson)
//               .where((r) => r.hasVideo)
//               .toList();
//       return {'reels': reels, 'next': data['next']}; // ADD next
//     }
//     throw Exception('Fetch failed: ${res.statusCode}');
//   }

//   static Future<void> recordView(String reelId) async {
//     try {
//       await http
//           .post(Uri.parse('$_reelsUrl$reelId/view/'), headers: _headers())
//           .timeout(const Duration(seconds: 5));
//     } catch (_) {}
//   }

//   static Future<ReelOperationResult> editReel({
//     required String reelId,
//     required String caption,
//   }) async {
//     try {
//       final res = await http
//           .patch(
//             Uri.parse('$_reelsUrl$reelId/'),
//             headers: _headers(),
//             body: json.encode({'caption': caption}),
//           )
//           .timeout(const Duration(seconds: 15));
//       if (res.statusCode == 200) {
//         return ReelOperationResult(
//           success: true,
//           data: ReelModel.fromJson(
//             json.decode(res.body) as Map<String, dynamic>,
//           ),
//         );
//       }
//       return ReelOperationResult(
//         success: false,
//         errorMessage: _err(res.body, res.statusCode),
//       );
//     } catch (_) {
//       return const ReelOperationResult(
//         success: false,
//         errorMessage: 'Network error.',
//       );
//     }
//   }

//   static Future<ReelOperationResult> deleteReel(String reelId) async {
//     try {
//       final res = await http
//           .delete(Uri.parse('$_reelsUrl$reelId/'), headers: _headers())
//           .timeout(const Duration(seconds: 15));
//       if (res.statusCode == 204 || res.statusCode == 200) {
//         return const ReelOperationResult(success: true);
//       }
//       return ReelOperationResult(
//         success: false,
//         errorMessage: _err(res.body, res.statusCode),
//       );
//     } catch (_) {
//       return const ReelOperationResult(
//         success: false,
//         errorMessage: 'Network error.',
//       );
//     }
//   }

//   static Future<ReelOperationResult> repostReel(String reelId) async {
//     try {
//       final res = await http
//           .post(Uri.parse('$_reelsUrl$reelId/repost/'), headers: _headers())
//           .timeout(const Duration(seconds: 15));
//       if (res.statusCode == 200 || res.statusCode == 201) {
//         return ReelOperationResult(
//           success: true,
//           data: ReelModel.fromJson(
//             json.decode(res.body) as Map<String, dynamic>,
//           ),
//         );
//       }
//       return ReelOperationResult(
//         success: false,
//         errorMessage: _err(res.body, res.statusCode),
//       );
//     } catch (_) {
//       return const ReelOperationResult(
//         success: false,
//         errorMessage: 'Network error.',
//       );
//     }
//   }

//   static String _err(String body, int code) {
//     try {
//       final d = json.decode(body);
//       if (d is Map) {
//         final v = d['detail'] ?? d['message'] ?? d['error'];
//         if (v != null) return v.toString();
//       }
//     } catch (_) {}
//     return 'Error ($code)';
//   }
// }

// // ════════════════════════════════════════════════════════════════════════════
// // RIVERPOD STATE
// // ════════════════════════════════════════════════════════════════════════════

// final activeReelIndexProvider = StateProvider<int>((ref) => 0);

// class ReelsFeedNotifier extends StateNotifier<AsyncValue<List<ReelModel>>> {
//   ReelsFeedNotifier() : super(const AsyncValue.loading()) {
//     _load();
//   }

//   String? _next;
//   bool _hasMore = true;
//   bool _busy = false;

//   // Future<void> _load() async {
//   //   try {
//   //     state = AsyncValue.data(await ReelsApiService.fetchReels());
//   //   } catch (e, st) {
//   //     state = AsyncValue.error(e, st);
//   //   }
//   // }

//   Future<void> _load() async {
//     try {
//       final result = await ReelsApiService.fetchReels();
//       _next = result['next'] as String?; // ADD THIS
//       _hasMore = _next != null; // ADD THIS
//       state = AsyncValue.data(result['reels'] as List<ReelModel>);
//     } catch (e, st) {
//       state = AsyncValue.error(e, st);
//     }
//   }

//   Future<void> refresh() async {
//     _next = null;
//     _hasMore = true;
//     state = const AsyncValue.loading();
//     await _load();
//   }

//   // Future<void> loadMore() async {
//   //   if (_busy || !_hasMore || _next == null) return;
//   //   _busy = true;
//   //   try {
//   //     final more = await ReelsApiService.fetchReels(cursor: _next);
//   //     state = AsyncValue.data([...(state.value ?? []), ...more]);
//   //   } catch (_) {
//   //   } finally {
//   //     _busy = false;
//   //   }
//   // }

//   Future<void> loadMore() async {
//     if (_busy || !_hasMore || _next == null) return;
//     _busy = true;
//     try {
//       final result = await ReelsApiService.fetchReels(cursor: _next);
//       _next = result['next'] as String?; // ADD THIS
//       _hasMore = _next != null; // ADD THIS
//       final more = result['reels'] as List<ReelModel>;
//       state = AsyncValue.data([...(state.value ?? []), ...more]);
//     } catch (_) {
//     } finally {
//       _busy = false;
//     }
//   }

//   void applyReaction(String id, String? r) {
//     final list = state.value;
//     if (list == null) return;
//     final i = list.indexWhere((x) => x.id == id);
//     if (i < 0) return;
//     final had = list[i].currentUserReaction != null;
//     list[i].currentUserReaction = r;
//     if (!had && r != null) list[i].reactionsCount++;
//     if (had && r == null)
//       list[i].reactionsCount = (list[i].reactionsCount - 1).clamp(0, 999999);
//     state = AsyncValue.data(List.from(list));
//   }

//   void updateFollow(String userId, bool v) {
//     final list = state.value;
//     if (list == null) return;
//     for (final r in list) if (r.userId == userId) r.isFollowed = v;
//     state = AsyncValue.data(List.from(list));
//   }

//   void incrementComments(String reelId) {
//     final list = state.value;
//     if (list == null) return;
//     final idx = list.indexWhere((r) => r.id == reelId);
//     if (idx != -1) list[idx].commentsCount++;
//     state = AsyncValue.data(List.from(list));
//   }

//   void decrementComments(String reelId) {
//     final list = state.value;
//     if (list == null) return;
//     final idx = list.indexWhere((r) => r.id == reelId);
//     if (idx != -1) {
//       list[idx].commentsCount = (list[idx].commentsCount - 1).clamp(0, 999999);
//     }
//     state = AsyncValue.data(List.from(list));
//   }

//   Future<String?> editReel(String id, String caption) async {
//     final list = state.value;
//     if (list == null) return 'No data';
//     final i = list.indexWhere((x) => x.id == id);
//     if (i < 0) return 'Not found';
//     final old = list[i].caption;
//     list[i].caption = caption;
//     state = AsyncValue.data(List.from(list));
//     final res = await ReelsApiService.editReel(reelId: id, caption: caption);
//     if (res.success) {
//       if (res.data != null) list[i].caption = res.data!.caption;
//       state = AsyncValue.data(List.from(list));
//       return null;
//     }
//     list[i].caption = old;
//     state = AsyncValue.data(List.from(list));
//     return res.errorMessage;
//   }

//   Future<String?> deleteReel(String id) async {
//     final res = await ReelsApiService.deleteReel(id);
//     if (res.success) {
//       state = AsyncValue.data(
//         (state.value ?? []).where((r) => r.id != id).toList(),
//       );
//       return null;
//     }
//     return res.errorMessage;
//   }

//   Future<String?> repostReel(String id) async {
//     final res = await ReelsApiService.repostReel(id);
//     if (res.success && res.data != null) {
//       state = AsyncValue.data([res.data!, ...(state.value ?? [])]);
//       return null;
//     }
//     return res.errorMessage;
//   }
// }

// final reelsFeedProvider =
//     StateNotifierProvider<ReelsFeedNotifier, AsyncValue<List<ReelModel>>>(
//       (ref) => ReelsFeedNotifier(),
//     );

// // ════════════════════════════════════════════════════════════════════════════
// // SLOT MANAGER
// //
// // THE BUG THIS FIXES:
// // ─────────────────────────────────────────────────────────────────────────
// // The old code used `pageIndex % 3` for slot assignment.
// //
// //   Page 0 → slot 0 (User A)
// //   Page 1 → slot 1 (User B)
// //   Page 2 → slot 2 (User C)
// //   Page 3 → slot 0 ← REUSED! Still has User A's video initially!
// //
// // When you swiped to page 3, switchSurface(0) would briefly play USER A's
// // video behind USER D's overlay (correct name/avatar shown, wrong video).
// //
// // THE FIX — Ring-buffer rotation:
// // ─────────────────────────────────────────────────────────────────────────
// // We maintain 3 logical roles that rotate between the 3 physical slots:
// //   • curSlot  = slot currently playing (has the display surface)
// //   • nextSlot = slot pre-buffering the NEXT reel
// //   • prevSlot = slot pre-buffering the PREVIOUS reel (for back-swipe)
// //
// // On forward swipe: prevSlot ← curSlot ← nextSlot ← (recycled prevSlot)
// // On backward swipe: nextSlot ← curSlot ← prevSlot ← (recycled nextSlot)
// //
// // The recycled slot gets prepared with the new reel's URL.
// // This guarantees: curSlot ALWAYS has the correct reel's video. No mismatch.
// // ════════════════════════════════════════════════════════════════════════════

// class _SlotManager {
//   // Physical slot numbers (0, 1, 2). These roles rotate.
//   int curSlot = 0; // Currently playing
//   int nextSlot = 1; // Pre-buffering next reel
//   int prevSlot = 2; // Pre-buffering previous reel

//   // Rotate forward (user swiped to next reel)
//   // Returns the recycled slot that needs to be prepared with the new next URL.
//   int rotateForward() {
//     final recycled = prevSlot;
//     prevSlot = curSlot;
//     curSlot = nextSlot;
//     nextSlot = recycled;
//     return nextSlot; // caller should prepare this slot with reels[newIndex+1]
//   }

//   // Rotate backward (user swiped to previous reel)
//   // Returns the recycled slot that needs to be prepared with the new prev URL.
//   int rotateBackward() {
//     final recycled = nextSlot;
//     nextSlot = curSlot;
//     curSlot = prevSlot;
//     prevSlot = recycled;
//     return prevSlot; // caller should prepare this slot with reels[newIndex-1]
//   }
// }

// // ════════════════════════════════════════════════════════════════════════════
// // REELS SCREEN
// // ════════════════════════════════════════════════════════════════════════════

// class ReelsScreen extends ConsumerStatefulWidget {
//   const ReelsScreen({Key? key}) : super(key: key);

//   @override
//   ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
// }

// class _ReelsScreenState extends ConsumerState<ReelsScreen>
//     with WidgetsBindingObserver {
//   late final PageController _pageCtrl;

//   int _currentPage = 0;
//   bool _isMuted = false;
//   bool _feedReady = false;

//   // Slot manager: guarantees curSlot always has the correct reel's video
//   final _slots = _SlotManager();

//   String get _token => AppData().accessToken ?? '';

//   // ── lifecycle ─────────────────────────────────────────────────────────────

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _pageCtrl = PageController();
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
//     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     ReelsPlayer.releaseAll();
//     _pageCtrl.dispose();
//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//     SystemChrome.setPreferredOrientations(DeviceOrientation.values);
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState s) {
//     if (s == AppLifecycleState.paused || s == AppLifecycleState.inactive) {
//       ReelsPlayer.pause(_slots.curSlot);
//     } else if (s == AppLifecycleState.resumed) {
//       ReelsPlayer.play(_slots.curSlot);
//     }
//   }

//   // ── Feed init ─────────────────────────────────────────────────────────────

//   // void _onFeedReady(List<ReelModel> reels) {
//   //   if (_feedReady || reels.isEmpty) return;
//   //   _feedReady = true;

//   //   // Initial slot assignment:
//   //   //   curSlot  (0) = page 0 (first reel)
//   //   //   nextSlot (1) = page 1 (second reel, pre-buffering)
//   //   //   prevSlot (2) = empty  (no previous reel yet)
//   //   _prepareIndex(0, reels, _slots.curSlot);
//   //   if (reels.length > 1) _prepareIndex(1, reels, _slots.nextSlot);

//   //   // Wait for SurfaceView to be created, then connect + play
//   //   Future.delayed(const Duration(milliseconds: 400), () {
//   //     if (!mounted) return;
//   //     ReelsPlayer.switchSurface(_slots.curSlot);
//   //     Future.delayed(const Duration(milliseconds: 60), () {
//   //       if (!mounted) return;
//   //       ReelsPlayer.play(_slots.curSlot);
//   //       ReelsApiService.recordView(reels[0].id);
//   //     });
//   //   });
//   // }

//   void _onFeedReady(List<ReelModel> reels) {
//     if (_feedReady || reels.isEmpty) return;
//     _feedReady = true;

//     _prepareIndex(0, reels, _slots.curSlot);
//     if (reels.length > 1) _prepareIndex(1, reels, _slots.nextSlot);

//     // Wait for the SurfaceView's surfaceCreated() callback, then hand the
//     // surface to slot 0 and start playing.
//     Future.delayed(const Duration(milliseconds: 300), () {
//       if (!mounted) return;
//       ReelsPlayer.switchSurface(_slots.curSlot);

//       // Hide loading overlay only when the FIRST real frame is decoded.
//       // listenFirstFrame fires onRenderedFirstFrame() from ExoPlayer.
//       ReelsPlayer.listenFirstFrame(_slots.curSlot, () {
//         if (mounted)
//           setState(() {
//             /* triggers overlay fade-out */
//           });
//       });

//       Future.delayed(const Duration(milliseconds: 60), () {
//         if (!mounted) return;
//         ReelsPlayer.play(_slots.curSlot);
//         ReelsApiService.recordView(reels[0].id);
//       });
//     });
//   }

//   /// Prepare a specific physical slot with the reel at [reelIndex].
//   // void _prepareIndex(int reelIndex, List<ReelModel> reels, int physicalSlot) {
//   //   if (reelIndex < 0 || reelIndex >= reels.length) return;
//   //   final url = reels[reelIndex].bestVideoUrl;
//   //   if (url == null || url.isEmpty) return;
//   //   developer.log(
//   //     '[Reels] prepare slot=$physicalSlot for reelIndex=$reelIndex (${reels[reelIndex].username})',
//   //   );
//   //   ReelsPlayer.prepare(physicalSlot, url, _token);
//   // }

//   // void _prepareIndex(int reelIndex, List<ReelModel> reels, int physicalSlot) {
//   //   if (reelIndex < 0 || reelIndex >= reels.length) return;
//   //   final reel = reels[reelIndex];
//   //   final url = reel.bestVideoUrl; // HLS preferred
//   //   if (url == null || url.isEmpty) return;

//   //   // fallbackUrl = direct .mp4, used when HLS codec is unsupported on device
//   //   final fallbackUrl =
//   //       (reel.videoUrl != null &&
//   //               reel.videoUrl!.isNotEmpty &&
//   //               reel.videoUrl != url)
//   //           ? reel.videoUrl
//   //           : null;

//   //   developer.log(
//   //     '[Reels] prepare slot=$physicalSlot for reelIndex=$reelIndex'
//   //     ' (${reel.username}) hls=${url.contains(".m3u8")}'
//   //     ' fallback=${fallbackUrl != null}',
//   //   );

//   //   ReelsPlayer.prepare(
//   //     physicalSlot,
//   //     url,
//   //     _token,
//   //     fallbackUrl: fallbackUrl, // <── new param
//   //   );
//   // }

//   void _prepareIndex(int reelIndex, List<ReelModel> reels, int physicalSlot) {
//     if (reelIndex < 0 || reelIndex >= reels.length) return;
//     final url = reels[reelIndex].bestVideoUrl;
//     if (url == null || url.isEmpty) return;

//     developer.log(
//       '[Reels] prepare slot=$physicalSlot '
//       'reelIndex=$reelIndex (${reels[reelIndex].username})',
//     );

//     ReelsPlayer.prepare(physicalSlot, url, _token); // no fallbackUrl needed
//   }

//   // ── Page change ───────────────────────────────────────────────────────────

//   void _onPageChanged(int newIndex, List<ReelModel> reels) {
//     final goingForward = newIndex > _currentPage;

//     // 1. Pause current
//     ReelsPlayer.pause(_slots.curSlot);

//     // 2. Rotate slots — curSlot now points to the pre-buffered reel
//     final int recycledSlot;
//     if (goingForward) {
//       recycledSlot = _slots.rotateForward();
//       // Prepare the recycled slot with the reel after the new current
//       _prepareIndex(newIndex + 1, reels, recycledSlot);
//     } else {
//       recycledSlot = _slots.rotateBackward();
//       // Prepare the recycled slot with the reel before the new current
//       _prepareIndex(newIndex - 1, reels, recycledSlot);
//     }

//     // 3. Update page state
//     setState(() => _currentPage = newIndex);
//     ref.read(activeReelIndexProvider.notifier).state = newIndex;

//     // 4. Switch surface to the new curSlot (which already has the correct video)
//     //    and play immediately — no mismatch because curSlot was pre-buffered
//     //    with exactly this reel's URL.
//     ReelsPlayer.switchSurface(_slots.curSlot).then((_) {
//       Future.delayed(const Duration(milliseconds: 50), () {
//         if (!mounted) return;
//         ReelsPlayer.play(_slots.curSlot);
//         if (_isMuted) ReelsPlayer.setVolume(_slots.curSlot, 0.0);
//       });
//     });

//     // 5. Record view
//     ReelsApiService.recordView(reels[newIndex].id);

//     // 6. Load more if approaching end
//     if (newIndex >= reels.length - 3) {
//       ref.read(reelsFeedProvider.notifier).loadMore();
//     }

//     developer.log(
//       '[Reels] page=$newIndex | cur=${_slots.curSlot} next=${_slots.nextSlot} prev=${_slots.prevSlot}',
//     );
//   }

//   void _toggleMute() {
//     setState(() => _isMuted = !_isMuted);
//     ReelsPlayer.setVolume(_slots.curSlot, _isMuted ? 0.0 : 1.0);
//   }

//   // ── Build ─────────────────────────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     final feedState = ref.watch(reelsFeedProvider);
//     return PopScope(
//       onPopInvoked: (_) => ReelsPlayer.releaseAll(),
//       child: Scaffold(
//         backgroundColor: Colors.black,
//         body: feedState.when(
//           loading: () => const _ReelsShimmer(),
//           error:
//               (e, _) => _ReelsError(
//                 onRetry: () => ref.read(reelsFeedProvider.notifier).refresh(),
//               ),
//           data: (reels) {
//             if (reels.isEmpty) return _buildEmpty();

//             WidgetsBinding.instance.addPostFrameCallback(
//               (_) => _onFeedReady(reels),
//             );

//             return Stack(
//               fit: StackFit.expand,
//               children: [
//                 // ── Single shared SurfaceView (never leaves the tree) ──────
//                 const ColoredBox(color: Colors.black),

//                 // Surface confined to natural video aspect ratio (9:16 for standard reels)
//                 // FittedBox with contain means: fill the screen height, preserve ratio.
//                 // For landscape clips this adds side bars; for portrait clips (standard)
//                 // it fills edge-to-edge on a portrait phone — identical to Instagram Reels.
//                 Center(
//                   child: AspectRatio(
//                     aspectRatio: 9 / 16,
//                     child: const ReelsSurfaceWidget(),
//                   ),
//                 ),

//                 // ── PageView: transparent, handles swipe + overlays ────────
//                 // Each page renders its OWN reel's avatar/name/caption/buttons.
//                 // The active overlay also knows the current physical slot for
//                 // play/pause control.
//                 PageView.builder(
//                   controller: _pageCtrl,
//                   scrollDirection: Axis.vertical,
//                   onPageChanged: (i) => _onPageChanged(i, reels),
//                   itemCount: reels.length,
//                   itemBuilder: (ctx, i) {
//                     final isActive = i == _currentPage;
//                     return _ReelOverlay(
//                       key: ValueKey(reels[i].id),
//                       // ↓ Each overlay gets its OWN reel data — always correct
//                       reel: reels[i],
//                       isActive: isActive,
//                       isMuted: _isMuted,
//                       onMuteToggle: _toggleMute,
//                       // ↓ Only the ACTIVE overlay needs the slot for controls
//                       activeSlot: _slots.curSlot,
//                     );
//                   },
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }

//   Widget _buildEmpty() => Center(
//     child: Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         const Icon(
//           Icons.video_library_outlined,
//           color: Colors.white54,
//           size: 64,
//         ),
//         const SizedBox(height: 16),
//         const Text(
//           'No reels yet',
//           style: TextStyle(color: Colors.white70, fontSize: 18),
//         ),
//         const SizedBox(height: 20),
//         TextButton(
//           onPressed: () => ref.read(reelsFeedProvider.notifier).refresh(),
//           child: const Text('Refresh', style: TextStyle(color: Colors.orange)),
//         ),
//       ],
//     ),
//   );
// }

// // ════════════════════════════════════════════════════════════════════════════
// // REEL OVERLAY
// //
// // Each page in the PageView has its own _ReelOverlay with its own reel data.
// // This means avatar, username, caption, like count, comment count etc. always
// // show the correct user's info — independent of which video slot is active.
// //
// // `activeSlot` is passed from the parent and only used for play/pause controls
// // when this overlay is the active one (isActive == true).
// // ════════════════════════════════════════════════════════════════════════════

// class _ReelOverlay extends ConsumerStatefulWidget {
//   final ReelModel reel;
//   final bool isActive;
//   final bool isMuted;
//   final VoidCallback onMuteToggle;
//   final int activeSlot;

//   const _ReelOverlay({
//     Key? key,
//     required this.reel,
//     required this.isActive,
//     required this.isMuted,
//     required this.onMuteToggle,
//     required this.activeSlot,
//   }) : super(key: key);

//   @override
//   ConsumerState<_ReelOverlay> createState() => _ReelOverlayState();
// }

// class _ReelOverlayState extends ConsumerState<_ReelOverlay>
//     with SingleTickerProviderStateMixin {
//   bool _isPlaying = false;
//   bool _isLoading = true;
//   bool _showControls = false;
//   bool _showComments = false;
//   bool _viewRecorded = false;

//   Timer? _loadingTimer;

//   late AnimationController _heartCtrl;
//   late Animation<double> _heartScale, _heartOpacity;
//   bool _showHeart = false;
//   Offset _heartPos = Offset.zero;

//   // ── reaction overlay ──────────────────────────────────────────────────────
//   OverlayEntry? _reactionOverlay;
//   final LayerLink _reactionLink = LayerLink();
//   final ContentLikeService _likeService = ContentLikeService(
//     baseUrl: 'http://36.253.137.34:8012',
//   );

//   @override
//   void initState() {
//     super.initState();
//     _initHeart();
//     if (widget.isActive) _scheduleVideoReveal();
//   }

//   @override
//   void didUpdateWidget(_ReelOverlay old) {
//     super.didUpdateWidget(old);
//     if (widget.isActive && !old.isActive) {
//       // This reel just became active (user swiped to it)
//       setState(() {
//         _isLoading = true;
//         _isPlaying = true;
//       });
//       _scheduleVideoReveal();
//     } else if (!widget.isActive && old.isActive) {
//       _loadingTimer?.cancel();
//       setState(() {
//         _isPlaying = false;
//         _isLoading = true;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _loadingTimer?.cancel();
//     _heartCtrl.dispose();
//     _removeOverlay();
//     super.dispose();
//   }

//   void _scheduleVideoReveal() {
//     _loadingTimer?.cancel();
//     _isPlaying = true;
//     _loadingTimer = Timer(const Duration(milliseconds: 600), () {
//       if (mounted && widget.isActive) {
//         setState(() => _isLoading = false);
//       }
//     });
//   }

//   void _initHeart() {
//     _heartCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 700),
//     );
//     _heartScale = TweenSequence([
//       TweenSequenceItem(
//         tween: Tween<double>(
//           begin: 0,
//           end: 1.6,
//         ).chain(CurveTween(curve: Curves.easeOut)),
//         weight: 40,
//       ),
//       TweenSequenceItem(
//         tween: Tween<double>(
//           begin: 1.6,
//           end: 1.0,
//         ).chain(CurveTween(curve: Curves.elasticOut)),
//         weight: 40,
//       ),
//       TweenSequenceItem(
//         tween: Tween<double>(
//           begin: 1.0,
//           end: 0,
//         ).chain(CurveTween(curve: Curves.easeIn)),
//         weight: 20,
//       ),
//     ]).animate(_heartCtrl);
//     _heartOpacity = TweenSequence([
//       TweenSequenceItem(tween: ConstantTween(1.0), weight: 80),
//       TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
//     ]).animate(_heartCtrl);
//   }

//   // ── gestures ──────────────────────────────────────────────────────────────

//   void _onTap() {
//     _removeOverlay();
//     if (!widget.isActive) return;
//     setState(() {
//       _isPlaying = !_isPlaying;
//       _showControls = true;
//     });
//     _isPlaying
//         ? ReelsPlayer.play(widget.activeSlot)
//         : ReelsPlayer.pause(widget.activeSlot);
//     Future.delayed(const Duration(seconds: 2), () {
//       if (mounted) setState(() => _showControls = false);
//     });
//   }

//   void _onDoubleTap(TapDownDetails d) {
//     HapticFeedback.mediumImpact();
//     _removeOverlay();
//     setState(() {
//       _heartPos = d.localPosition;
//       _showHeart = true;
//     });
//     _heartCtrl.forward(from: 0).then((_) {
//       if (mounted) setState(() => _showHeart = false);
//     });
//     if (!widget.reel.isLiked) _react(ReactionType.like);
//   }

//   void _onLPS(LongPressStartDetails _) {
//     if (widget.isActive) ReelsPlayer.pause(widget.activeSlot);
//   }

//   void _onLPE(LongPressEndDetails _) {
//     if (widget.isActive && _isPlaying) ReelsPlayer.play(widget.activeSlot);
//   }

//   // ── Reactions ─────────────────────────────────────────────────────────────

//   Future<void> _react(ReactionType type) async {
//     final r = widget.reel;
//     final same = r.currentUserReaction == type.value;
//     final n = ref.read(reelsFeedProvider.notifier);
//     n.applyReaction(r.id, (r.isLiked && same) ? null : type.value);
//     final res = await _likeService.reactReel(r.id, type);
//     n.applyReaction(
//       r.id,
//       res.success ? res.reactionType?.value : r.currentUserReaction,
//     );
//   }

//   void _showPicker() {
//     if (_reactionOverlay != null) {
//       _removeOverlay();
//       return;
//     }
//     HapticFeedback.mediumImpact();
//     _reactionOverlay = OverlayEntry(
//       builder:
//           (_) => _VerticalReactionPicker(
//             layerLink: _reactionLink,
//             currentReaction: widget.reel.currentReactionType,
//             onSelect: (t) {
//               _removeOverlay();
//               _react(t);
//             },
//             onDismiss: _removeOverlay,
//           ),
//     );
//     Overlay.of(context).insert(_reactionOverlay!);
//   }

//   void _removeOverlay() {
//     _reactionOverlay?.remove();
//     _reactionOverlay = null;
//   }

//   bool _isMe() =>
//       AppData().isMe(widget.reel.userId) ||
//       AppData().isMe(widget.reel.username);

//   void _options() {
//     if (widget.isActive) ReelsPlayer.pause(widget.activeSlot);
//     _removeOverlay();
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder:
//           (_) => _ReelOptionsSheet(
//             isOwner: _isMe(),
//             reel: widget.reel,
//             onEdit: _isMe() ? _editDialog : null,
//             onDelete: _isMe() ? _deleteDialog : null,
//             onRepost: !_isMe() ? _doRepost : null,
//           ),
//     ).then((_) {
//       if (widget.isActive && mounted && _isPlaying)
//         ReelsPlayer.play(widget.activeSlot);
//     });
//   }

//   void _editDialog() {
//     final tc = TextEditingController(text: widget.reel.caption);
//     showDialog(
//       context: context,
//       builder:
//           (_) => AlertDialog(
//             backgroundColor: const Color(0xFF1C1C1E),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//             title: const Text(
//               'Edit Caption',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//             content: TextField(
//               controller: tc,
//               maxLines: 4,
//               minLines: 1,
//               style: const TextStyle(color: Colors.white),
//               decoration: InputDecoration(
//                 hintText: 'Write a caption…',
//                 hintStyle: const TextStyle(color: Colors.white38),
//                 filled: true,
//                 fillColor: Colors.white10,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10),
//                   borderSide: BorderSide.none,
//                 ),
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text(
//                   'Cancel',
//                   style: TextStyle(color: Colors.white54),
//                 ),
//               ),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFFF48706),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//                 onPressed: () async {
//                   final cap = tc.text.trim();
//                   Navigator.pop(context);
//                   final err = await ref
//                       .read(reelsFeedProvider.notifier)
//                       .editReel(widget.reel.id, cap);
//                   if (mounted)
//                     _snack(err ?? 'Caption updated!', err: err != null);
//                 },
//                 child: const Text(
//                   'Save',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//     );
//   }

//   void _deleteDialog() {
//     showDialog(
//       context: context,
//       builder:
//           (_) => AlertDialog(
//             backgroundColor: const Color(0xFF1C1C1E),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//             ),
//             title: const Text(
//               'Delete Reel',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//             content: const Text(
//               'This reel will be permanently deleted.',
//               style: TextStyle(color: Colors.white70),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text(
//                   'Cancel',
//                   style: TextStyle(color: Colors.white54),
//                 ),
//               ),
//               ElevatedButton(
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.redAccent,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                 ),
//                 onPressed: () async {
//                   Navigator.pop(context);
//                   final err = await ref
//                       .read(reelsFeedProvider.notifier)
//                       .deleteReel(widget.reel.id);
//                   if (err != null && mounted) _snack(err, err: true);
//                 },
//                 child: const Text(
//                   'Delete',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//     );
//   }

//   Future<void> _doRepost() async {
//     _snack('Reposting…');
//     final err = await ref
//         .read(reelsFeedProvider.notifier)
//         .repostReel(widget.reel.id);
//     if (mounted) _snack(err ?? 'Reposted!', err: err != null);
//   }

//   void _share() => Share.share(
//     'Check out this reel by @${widget.reel.username}!\n${widget.reel.bestVideoUrl ?? ''}',
//   );

//   void _snack(String msg, {bool err = false}) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(msg),
//         backgroundColor: err ? Colors.redAccent : const Color(0xFFF48706),
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   // String _fmt(int n) {
//   //   if (n >= 1_000_000) return '${(n / 1_000_000).toStringAsFixed(1)}M';
//   //   if (n >= 1_000) return '${(n / 1_000).toStringAsFixed(1)}K';
//   //   return n > 0 ? '$n' : '';
//   // }

//   String _fmt(int n) {
//     if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
//     if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
//     return n > 0 ? '$n' : '';
//   }
//   // ── Build ─────────────────────────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery.of(context).size;
//     // final ctrl = _ctrl;

//     // if (ctrl != null) {
//     //   return NativeVideoPlayer(
//     //     controller: ctrl,
//     //     overlayBuilder: (_, __) => _buildOverlay(size),
//     //   );
//     // }
//     return Stack(
//       fit: StackFit.expand,
//       children: [
//         // Loading overlay — covers the surface while video is buffering.
//         // Prevents seeing a previous reel's final frame during transition.
//         if (widget.isActive)
//           AnimatedOpacity(
//             opacity: _isLoading ? 1.0 : 0.0,
//             duration: const Duration(milliseconds: 300),
//             child: _buildLoadingOverlay(),
//           ),

//         // Gesture layer (transparent)
//         Positioned.fill(
//           child: GestureDetector(
//             onTap: _onTap,
//             onDoubleTapDown: _onDoubleTap,
//             onDoubleTap: () {},
//             onLongPressStart: _onLPS,
//             onLongPressEnd: _onLPE,
//             behavior: HitTestBehavior.translucent,
//             child: Container(color: Colors.transparent),
//           ),
//         ),

//         _buildGradients(),
//         _buildTopBar(),
//         // ↓ This always shows THIS reel's info — never the wrong user
//         _buildBottomLeft(size),
//         _buildActions(),
//         if (_showControls) _buildPauseHint(),
//         if (_showHeart) _buildHeartBurst(),
//         if (_showComments) _buildCommentsSheet(),
//       ],
//     );
//   }

//   Widget _buildLoadingOverlay() => Stack(
//     fit: StackFit.expand,
//     children: [
//       Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Color(0xFF0D0D0D), Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
//           ),
//         ),
//       ),
//       Shimmer.fromColors(
//         baseColor: Colors.white.withOpacity(0.03),
//         highlightColor: Colors.white.withOpacity(0.08),
//         period: const Duration(milliseconds: 1200),
//         child: Container(color: Colors.white.withOpacity(0.03)),
//       ),
//       const Center(
//         child: SizedBox(
//           width: 36,
//           height: 36,
//           child: CircularProgressIndicator(
//             color: Colors.white54,
//             strokeWidth: 2.5,
//           ),
//         ),
//       ),
//     ],
//   );

//   Widget _buildGradients() => Stack(
//     children: [
//       Positioned(
//         top: 0,
//         left: 0,
//         right: 0,
//         height: 140,
//         child: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: [Colors.black.withOpacity(0.6), Colors.transparent],
//             ),
//           ),
//         ),
//       ),
//       Positioned(
//         bottom: 0,
//         left: 0,
//         right: 0,
//         height: 340,
//         child: Container(
//           decoration: BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.bottomCenter,
//               end: Alignment.topCenter,
//               colors: [Colors.black.withOpacity(0.85), Colors.transparent],
//             ),
//           ),
//         ),
//       ),
//     ],
//   );

//   Widget _buildTopBar() => Positioned(
//     top: MediaQuery.of(context).padding.top + 8,
//     left: 8,
//     right: 16,
//     child: Row(
//       children: [
//         IconButton(
//           icon: const Icon(
//             Icons.arrow_back_ios_new_rounded,
//             color: Colors.white,
//             size: 22,
//           ),
//           onPressed: () {
//             ReelsPlayer.releaseAll();
//             Navigator.maybePop(context);
//           },
//         ),
//         const Spacer(),
//         const Text(
//           'Reels',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 18,
//             fontWeight: FontWeight.w700,
//             letterSpacing: 0.3,
//           ),
//         ),
//         const Spacer(),
//       ],
//     ),
//   );

//   /// Bottom-left overlay: avatar, username, follow button, caption.
//   /// Uses widget.reel — always THIS page's reel data, never another user's.
//   Widget _buildBottomLeft(Size size) => Positioned(
//     bottom: 80,
//     left: 14,
//     right: 88,
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         if (widget.reel.isRepost && widget.reel.sharedReelDetails != null)
//           Padding(
//             padding: const EdgeInsets.only(bottom: 6),
//             child: Row(
//               children: [
//                 const Icon(
//                   Icons.repeat_rounded,
//                   color: Colors.white70,
//                   size: 14,
//                 ),
//                 const SizedBox(width: 4),
//                 Text(
//                   'Reposted from @${widget.reel.sharedReelDetails!.username}',
//                   style: const TextStyle(
//                     color: Colors.white70,
//                     fontSize: 12,
//                     shadows: [Shadow(blurRadius: 3)],
//                   ),
//                 ),
//               ],
//             ),
//           ),

//         // Avatar + username + follow
//         GestureDetector(
//           onTap:
//               () => Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                   builder:
//                       (_) =>
//                           SpecificUserProfilePage(userId: widget.reel.userId),
//                 ),
//               ),
//           child: Row(
//             children: [
//               _buildAvatar(),
//               const SizedBox(width: 10),
//               Flexible(
//                 child: Text(
//                   widget.reel.username,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontWeight: FontWeight.w700,
//                     fontSize: 15,
//                     shadows: [Shadow(blurRadius: 4)],
//                   ),
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               const SizedBox(width: 10),
//               if (!_isMe())
//                 FollowButton(
//                   targetUserId: widget.reel.userId,
//                   initialFollowStatus: widget.reel.isFollowed,
//                   onFollowSuccess: () {
//                     widget.reel.isFollowed = true;
//                     ref
//                         .read(reelsFeedProvider.notifier)
//                         .updateFollow(widget.reel.userId, true);
//                   },
//                   onUnfollowSuccess: () {
//                     widget.reel.isFollowed = false;
//                     ref
//                         .read(reelsFeedProvider.notifier)
//                         .updateFollow(widget.reel.userId, false);
//                   },
//                 ),
//             ],
//           ),
//         ),

//         // Caption
//         if (widget.reel.caption.isNotEmpty) ...[
//           const SizedBox(height: 8),
//           _ExpandableCaption(caption: widget.reel.caption),
//         ],
//       ],
//     ),
//   );

//   Widget _buildAvatar() {
//     final url = widget.reel.avatar;
//     final init =
//         widget.reel.username.isNotEmpty
//             ? widget.reel.username[0].toUpperCase()
//             : '?';
//     Widget fb = Container(
//       color: Colors.grey.shade700,
//       alignment: Alignment.center,
//       child: Text(
//         init,
//         style: const TextStyle(
//           color: Colors.white,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//     return Container(
//       width: 40,
//       height: 40,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         border: Border.all(color: Colors.white, width: 1.5),
//       ),
//       child: ClipOval(
//         child:
//             (url != null && url.isNotEmpty)
//                 ? CachedNetworkImage(
//                   imageUrl: url,
//                   fit: BoxFit.cover,
//                   placeholder: (_, __) => fb,
//                   errorWidget: (_, __, ___) => fb,
//                 )
//                 : fb,
//       ),
//     );
//   }

//   /// Right-side action buttons: like, comment, repost, share, mute.
//   /// Uses widget.reel for counts — always THIS reel's data.
//   Widget _buildActions() {
//     final reel = widget.reel;
//     final reaction = reel.currentReactionType;
//     return Positioned(
//       right: 8,
//       bottom: 88,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Like / reaction
//           CompositedTransformTarget(
//             link: _reactionLink,
//             child: GestureDetector(
//               onTap: () => _react(reaction ?? ReactionType.like),
//               onLongPress: _showPicker,
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   SizedBox(
//                     width: 44,
//                     height: 44,
//                     child: Center(
//                       child:
//                           reaction != null
//                               ? Text(
//                                 reaction.emoji,
//                                 style: const TextStyle(fontSize: 28),
//                               )
//                               : const Icon(
//                                 Icons.favorite_border_rounded,
//                                 color: Colors.white,
//                                 size: 30,
//                                 shadows: [Shadow(blurRadius: 6)],
//                               ),
//                     ),
//                   ),
//                   Text(
//                     _fmt(reel.reactionsCount),
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                       shadows: [Shadow(blurRadius: 4)],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 20),

//           // Comments
//           _ActionButton(
//             icon: Icons.chat_bubble_outline_rounded,
//             label: _fmt(reel.commentsCount),
//             onTap: () => setState(() => _showComments = !_showComments),
//           ),
//           const SizedBox(height: 20),

//           // Repost (not own reel)
//           if (!_isMe()) ...[
//             _ActionButton(
//               icon: Icons.repeat_rounded,
//               label: 'Repost',
//               onTap: _doRepost,
//             ),
//             const SizedBox(height: 20),
//           ],

//           // Share
//           _ActionButton(
//             icon: Icons.send_rounded,
//             label: 'Share',
//             onTap: _share,
//           ),

//           // More options
//           IconButton(
//             icon: const Icon(
//               Icons.more_vert_rounded,
//               color: Colors.white,
//               size: 24,
//             ),
//             onPressed: _options,
//           ),
//           const SizedBox(height: 12),

//           // Mute
//           _ActionButton(
//             icon:
//                 widget.isMuted
//                     ? Icons.volume_off_rounded
//                     : Icons.volume_up_rounded,
//             label: '',
//             onTap: widget.onMuteToggle,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPauseHint() => Center(
//     child: AnimatedOpacity(
//       opacity: _showControls ? 1.0 : 0.0,
//       duration: const Duration(milliseconds: 200),
//       child: Container(
//         width: 72,
//         height: 72,
//         decoration: BoxDecoration(
//           color: Colors.black.withOpacity(0.55),
//           shape: BoxShape.circle,
//         ),
//         child: Icon(
//           _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
//           color: Colors.white,
//           size: 42,
//         ),
//       ),
//     ),
//   );

//   Widget _buildHeartBurst() => Positioned(
//     left: _heartPos.dx - 48,
//     top: _heartPos.dy - 48,
//     child: IgnorePointer(
//       child: AnimatedBuilder(
//         animation: _heartCtrl,
//         builder:
//             (_, __) => Opacity(
//               opacity: _heartOpacity.value,
//               child: Transform.scale(
//                 scale: _heartScale.value,
//                 child: const Icon(
//                   Icons.favorite_rounded,
//                   color: Colors.white,
//                   size: 96,
//                   shadows: [
//                     Shadow(color: Colors.red, blurRadius: 20),
//                     Shadow(blurRadius: 8),
//                   ],
//                 ),
//               ),
//             ),
//       ),
//     ),
//   );

//   Widget _buildCommentsSheet() => Positioned(
//     bottom: 0,
//     left: 0,
//     right: 0,
//     height: MediaQuery.of(context).size.height * 0.6,
//     child: GestureDetector(
//       onTap: () {},
//       child: Container(
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//               child: Row(
//                 children: [
//                   const Spacer(),
//                   Container(
//                     width: 36,
//                     height: 4,
//                     decoration: BoxDecoration(
//                       color: Colors.grey.shade300,
//                       borderRadius: BorderRadius.circular(2),
//                     ),
//                   ),
//                   const Spacer(),
//                   GestureDetector(
//                     onTap: () => setState(() => _showComments = false),
//                     child: const Icon(Icons.close, size: 20),
//                   ),
//                 ],
//               ),
//             ),
//             Expanded(
//               child: CommentSection(
//                 contentId: widget.reel.id,
//                 isReel: true,

//                 onCommentCountChanged: (delta) {
//                   if (delta > 0) {
//                     ref
//                         .read(reelsFeedProvider.notifier)
//                         .incrementComments(widget.reel.id);
//                   } else {
//                     ref
//                         .read(reelsFeedProvider.notifier)
//                         .decrementComments(widget.reel.id);
//                   }
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     ),
//   );

//   // String _fmt(int n) {
//   //   if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
//   //   if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
//   //   return n > 0 ? '$n' : '';
//   // }
// }

// // ════════════════════════════════════════════════════════════════════════════
// // OPTIONS SHEET
// // ════════════════════════════════════════════════════════════════════════════

// class _ReelOptionsSheet extends StatelessWidget {
//   final bool isOwner;
//   final ReelModel reel;
//   final VoidCallback? onEdit, onDelete, onRepost;

//   const _ReelOptionsSheet({
//     required this.isOwner,
//     required this.reel,
//     this.onEdit,
//     this.onDelete,
//     this.onRepost,
//   });

//   @override
//   Widget build(BuildContext context) => Container(
//     decoration: const BoxDecoration(
//       color: Color(0xFF1C1C1E),
//       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//     ),
//     padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
//     child: Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Container(
//           width: 36,
//           height: 4,
//           margin: const EdgeInsets.only(bottom: 16),
//           decoration: BoxDecoration(
//             color: Colors.white24,
//             borderRadius: BorderRadius.circular(2),
//           ),
//         ),
//         if (isOwner) ...[
//           _Tile(
//             icon: Icons.edit_rounded,
//             label: 'Edit Caption',
//             onTap: () {
//               Navigator.pop(context);
//               onEdit?.call();
//             },
//           ),
//           _Tile(
//             icon: Icons.delete_outline_rounded,
//             label: 'Delete Reel',
//             color: Colors.redAccent,
//             onTap: () {
//               Navigator.pop(context);
//               onDelete?.call();
//             },
//           ),
//         ] else
//           _Tile(
//             icon: Icons.repeat_rounded,
//             label: 'Repost',
//             onTap: () {
//               Navigator.pop(context);
//               onRepost?.call();
//             },
//           ),
//         _Tile(
//           icon: Icons.close_rounded,
//           label: 'Cancel',
//           color: Colors.white54,
//           onTap: () => Navigator.pop(context),
//         ),
//       ],
//     ),
//   );
// }

// class _Tile extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final Color color;
//   final VoidCallback onTap;

//   const _Tile({
//     required this.icon,
//     required this.label,
//     this.color = Colors.white,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) => InkWell(
//     onTap: onTap,
//     child: Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
//       child: Row(
//         children: [
//           Icon(icon, color: color, size: 22),
//           const SizedBox(width: 16),
//           Text(
//             label,
//             style: TextStyle(
//               color: color,
//               fontSize: 16,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }

// // ════════════════════════════════════════════════════════════════════════════
// // REACTION PICKER
// // ════════════════════════════════════════════════════════════════════════════

// class _VerticalReactionPicker extends StatefulWidget {
//   final LayerLink layerLink;
//   final ReactionType? currentReaction;
//   final void Function(ReactionType) onSelect;
//   final VoidCallback onDismiss;

//   const _VerticalReactionPicker({
//     required this.layerLink,
//     required this.currentReaction,
//     required this.onSelect,
//     required this.onDismiss,
//   });

//   @override
//   State<_VerticalReactionPicker> createState() => _VRPState();
// }

// class _VRPState extends State<_VerticalReactionPicker>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _ctrl;
//   late Animation<double> _sc, _fa;
//   ReactionType? _hov;

//   @override
//   void initState() {
//     super.initState();
//     _ctrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 250),
//     );
//     _sc = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
//     _fa = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
//     _ctrl.forward();
//   }

//   @override
//   void dispose() {
//     _ctrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     const h = 52.0;
//     final ph = ReactionType.values.length * h + 16;
//     return Stack(
//       children: [
//         Positioned.fill(
//           child: GestureDetector(
//             onTap: widget.onDismiss,
//             behavior: HitTestBehavior.translucent,
//             child: Container(color: Colors.transparent),
//           ),
//         ),
//         CompositedTransformFollower(
//           link: widget.layerLink,
//           showWhenUnlinked: false,
//           offset: Offset(-68, -(ph / 2) + 22),
//           child: FadeTransition(
//             opacity: _fa,
//             child: ScaleTransition(
//               scale: _sc,
//               alignment: Alignment.centerRight,
//               child: Material(
//                 color: Colors.transparent,
//                 child: Container(
//                   width: 56,
//                   padding: const EdgeInsets.symmetric(vertical: 8),
//                   decoration: BoxDecoration(
//                     color: Colors.black.withOpacity(0.75),
//                     borderRadius: BorderRadius.circular(28),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.4),
//                         blurRadius: 16,
//                         offset: const Offset(0, 4),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children:
//                         ReactionType.values.map((r) {
//                           final active = widget.currentReaction == r;
//                           final hov = _hov == r;
//                           return GestureDetector(
//                             onTap: () => widget.onSelect(r),
//                             onTapDown: (_) => setState(() => _hov = r),
//                             onTapCancel: () => setState(() => _hov = null),
//                             child: SizedBox(
//                               width: 56,
//                               height: h,
//                               child: Stack(
//                                 alignment: Alignment.center,
//                                 clipBehavior: Clip.none,
//                                 children: [
//                                   if (active)
//                                     Container(
//                                       width: 40,
//                                       height: 40,
//                                       decoration: BoxDecoration(
//                                         color: Colors.white.withOpacity(0.15),
//                                         shape: BoxShape.circle,
//                                       ),
//                                     ),
//                                   TweenAnimationBuilder<double>(
//                                     tween: Tween(
//                                       begin: 1.0,
//                                       end: hov ? 1.4 : (active ? 1.15 : 1.0),
//                                     ),
//                                     duration: const Duration(milliseconds: 200),
//                                     curve: Curves.easeOutBack,
//                                     builder:
//                                         (_, s, c) =>
//                                             Transform.scale(scale: s, child: c),
//                                     child: Text(
//                                       r.emoji,

//                                       style: const TextStyle(
//                                         fontSize: 26,
//                                         inherit: false,
//                                       ),
//                                     ),
//                                   ),
//                                   if (hov)
//                                     Positioned(
//                                       left: -72,
//                                       child: Container(
//                                         padding: const EdgeInsets.symmetric(
//                                           horizontal: 8,
//                                           vertical: 4,
//                                         ),
//                                         decoration: BoxDecoration(
//                                           color: Colors.black87,
//                                           borderRadius: BorderRadius.circular(
//                                             8,
//                                           ),
//                                         ),
//                                         child: Text(
//                                           r.label,
//                                           style: const TextStyle(
//                                             color: Colors.white,
//                                             fontSize: 11,
//                                             fontWeight: FontWeight.w600,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         }).toList(),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ════════════════════════════════════════════════════════════════════════════
// // ACTION BUTTON
// // ════════════════════════════════════════════════════════════════════════════

// class _ActionButton extends StatefulWidget {
//   final IconData icon;
//   final Color iconColor;
//   final String label;
//   final VoidCallback onTap;

//   const _ActionButton({
//     required this.icon,
//     this.iconColor = Colors.white,
//     required this.label,
//     required this.onTap,
//   });

//   @override
//   State<_ActionButton> createState() => _ABState();
// }

// class _ABState extends State<_ActionButton>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _ctrl;

//   @override
//   void initState() {
//     super.initState();
//     _ctrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 120),
//       lowerBound: 0.88,
//       upperBound: 1.0,
//       value: 1.0,
//     );
//   }

//   @override
//   void dispose() {
//     _ctrl.dispose();
//     super.dispose();
//   }

//   Future<void> _tap() async {
//     await _ctrl.reverse();
//     _ctrl.forward();
//     HapticFeedback.lightImpact();
//     widget.onTap();
//   }

//   @override
//   Widget build(BuildContext context) => GestureDetector(
//     onTap: _tap,
//     behavior: HitTestBehavior.opaque,
//     child: ScaleTransition(
//       scale: _ctrl,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             widget.icon,
//             color: widget.iconColor,
//             size: 30,
//             shadows: const [Shadow(blurRadius: 6)],
//           ),
//           if (widget.label.isNotEmpty) ...[
//             const SizedBox(height: 3),
//             Text(
//               widget.label,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 12,
//                 fontWeight: FontWeight.w600,
//                 shadows: [Shadow(blurRadius: 4)],
//               ),
//             ),
//           ],
//         ],
//       ),
//     ),
//   );
// }

// // ════════════════════════════════════════════════════════════════════════════
// // EXPANDABLE CAPTION
// // ════════════════════════════════════════════════════════════════════════════

// class _ExpandableCaption extends StatefulWidget {
//   final String caption;
//   const _ExpandableCaption({required this.caption});
//   @override
//   State<_ExpandableCaption> createState() => _ECState();
// }

// class _ECState extends State<_ExpandableCaption> {
//   bool _exp = false;
//   @override
//   Widget build(BuildContext context) => GestureDetector(
//     onTap: () => setState(() => _exp = !_exp),
//     child: AnimatedSize(
//       duration: const Duration(milliseconds: 250),
//       curve: Curves.easeInOut,
//       child: RichText(
//         maxLines: _exp ? null : 2,
//         overflow: _exp ? TextOverflow.visible : TextOverflow.ellipsis,
//         text: TextSpan(
//           children: [
//             TextSpan(
//               text: widget.caption,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 13,
//                 height: 1.45,
//                 shadows: [Shadow(blurRadius: 4)],
//               ),
//             ),
//             if (!_exp)
//               const TextSpan(
//                 text: ' more',
//                 style: TextStyle(
//                   color: Colors.white70,
//                   fontSize: 12,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//           ],
//         ),
//       ),
//     ),
//   );
// }

// // ════════════════════════════════════════════════════════════════════════════
// // SHIMMER + ERROR
// // ════════════════════════════════════════════════════════════════════════════

// class _ReelsShimmer extends StatelessWidget {
//   const _ReelsShimmer();
//   @override
//   Widget build(BuildContext context) => Shimmer.fromColors(
//     baseColor: Colors.grey.shade900,
//     highlightColor: Colors.grey.shade800,
//     period: const Duration(milliseconds: 1400),
//     child: Container(color: Colors.black),
//   );
// }

// class _ReelsError extends StatelessWidget {
//   final VoidCallback onRetry;
//   const _ReelsError({required this.onRetry});
//   @override
//   Widget build(BuildContext context) => Center(
//     child: Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         const Icon(Icons.error_outline, color: Colors.white54, size: 56),
//         const SizedBox(height: 16),
//         const Text(
//           'Could not load reels',
//           style: TextStyle(color: Colors.white70, fontSize: 16),
//         ),
//         const SizedBox(height: 20),
//         ElevatedButton.icon(
//           onPressed: onRetry,
//           icon: const Icon(Icons.refresh),
//           label: const Text('Retry'),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: const Color(0xFFF48706),
//             foregroundColor: Colors.white,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),
//           ),
//         ),
//       ],
//     ),
//   );
// }

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/utils/routing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shimmer/shimmer.dart';
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/screens/comment/comment_section.dart';
import 'package:innovator/Innovator/screens/Follow/follow_Button.dart';
import 'package:innovator/Innovator/screens/Likes/Content-Like-Service.dart';
import 'package:innovator/Innovator/screens/SHow_Specific_Profile/Show_Specific_Profile.dart';
import 'reels_player.dart';

class ReelModel {
  final String id;
  final String userId;
  final String username;
  final String avatar;
  String caption;
  final String? videoUrl;
  final String? hlsUrl;
  final String? thumbnail;
  int viewsCount;
  int reactionsCount;
  String? currentUserReaction;
  bool isFollowed;
  int commentsCount;
  final DateTime createdAt;
  final String? sharedReelId;
  final ReelModel? sharedReelDetails;

  ReelModel({
    required this.id,
    required this.userId,
    required this.username,
    required this.avatar,
    required this.caption,
    this.videoUrl,
    this.hlsUrl,
    this.thumbnail,
    required this.viewsCount,
    required this.reactionsCount,
    this.currentUserReaction,
    required this.isFollowed,
    required this.commentsCount,
    required this.createdAt,
    this.sharedReelId,
    this.sharedReelDetails,
  });

  bool get hasVideo =>
      (hlsUrl != null && hlsUrl!.isNotEmpty) ||
      (videoUrl != null && videoUrl!.isNotEmpty);

  String? get bestVideoUrl =>
      (hlsUrl != null && hlsUrl!.isNotEmpty) ? hlsUrl : videoUrl;

  bool get isLiked => currentUserReaction != null;
  bool get isRepost => sharedReelId != null;
  ReactionType? get currentReactionType =>
      ReactionTypeExtension.fromValue(currentUserReaction);

  factory ReelModel.fromJson(Map<String, dynamic> j) => ReelModel(
    id: j['id']?.toString() ?? '',
    userId: j['user_id']?.toString() ?? '',
    username: j['username']?.toString() ?? '',
    avatar: j['avatar']?.toString() ?? '',
    caption: j['caption']?.toString() ?? '',
    videoUrl: j['video']?.toString(),
    hlsUrl: j['hls_playlist_url']?.toString(),
    thumbnail: j['thumbnail']?.toString(),
    viewsCount: (j['views_count'] as num?)?.toInt() ?? 0,
    reactionsCount:
        (j['reactions_count'] as num?)?.toInt() ??
        (j['like_count'] as num?)?.toInt() ??
        0,
    currentUserReaction: j['current_user_reaction']?.toString(),
    isFollowed: j['is_followed'] == true,
    commentsCount: (j['comments_count'] as num?)?.toInt() ?? 0,
    createdAt:
        DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
    sharedReelId: j['shared_reel']?.toString(),
    sharedReelDetails:
        j['shared_reel_details'] != null
            ? ReelModel.fromJson(
              j['shared_reel_details'] as Map<String, dynamic>,
            )
            : null,
  );
}

class ReelOperationResult {
  final bool success;
  final String? errorMessage;
  final ReelModel? data;
  const ReelOperationResult({
    required this.success,
    this.errorMessage,
    this.data,
  });
}

class ReelsApiService {
  static const _base = 'http://36.253.137.34:8012';
  static const _reelsUrl = '$_base/api/reels/';

  static Map<String, String> _headers() {
    final token = AppData().accessToken ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> fetchReels({String? cursor}) async {
    final uri =
        (cursor != null && cursor.isNotEmpty)
            ? Uri.parse(cursor)
            : Uri.parse(_reelsUrl);
    final res = await http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 20));
    if (res.statusCode == 200) {
      final data = json.decode(res.body) as Map<String, dynamic>;
      final reels =
          (data['results'] as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>()
              .map(ReelModel.fromJson)
              .where((r) => r.hasVideo)
              .toList();
      return {'reels': reels, 'next': data['next']};
    }
    throw Exception('Fetch failed: ${res.statusCode}');
  }

  static Future<void> recordView(String reelId) async {
    try {
      await http
          .post(Uri.parse('$_reelsUrl$reelId/view/'), headers: _headers())
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  static Future<ReelOperationResult> editReel({
    required String reelId,
    required String caption,
  }) async {
    try {
      final res = await http
          .patch(
            Uri.parse('$_reelsUrl$reelId/'),
            headers: _headers(),
            body: json.encode({'caption': caption}),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return ReelOperationResult(
          success: true,
          data: ReelModel.fromJson(
            json.decode(res.body) as Map<String, dynamic>,
          ),
        );
      }
      return ReelOperationResult(
        success: false,
        errorMessage: _err(res.body, res.statusCode),
      );
    } catch (_) {
      return const ReelOperationResult(
        success: false,
        errorMessage: 'Network error.',
      );
    }
  }

  static Future<ReelOperationResult> deleteReel(String reelId) async {
    try {
      final res = await http
          .delete(Uri.parse('$_reelsUrl$reelId/'), headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 204 || res.statusCode == 200) {
        return const ReelOperationResult(success: true);
      }
      return ReelOperationResult(
        success: false,
        errorMessage: _err(res.body, res.statusCode),
      );
    } catch (_) {
      return const ReelOperationResult(
        success: false,
        errorMessage: 'Network error.',
      );
    }
  }

  static Future<ReelOperationResult> repostReel(String reelId) async {
    try {
      final res = await http
          .post(Uri.parse('$_reelsUrl$reelId/repost/'), headers: _headers())
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 200 || res.statusCode == 201) {
        return ReelOperationResult(
          success: true,
          data: ReelModel.fromJson(
            json.decode(res.body) as Map<String, dynamic>,
          ),
        );
      }
      return ReelOperationResult(
        success: false,
        errorMessage: _err(res.body, res.statusCode),
      );
    } catch (_) {
      return const ReelOperationResult(
        success: false,
        errorMessage: 'Network error.',
      );
    }
  }

  static String _err(String body, int code) {
    try {
      final d = json.decode(body);
      if (d is Map) {
        final v = d['detail'] ?? d['message'] ?? d['error'];
        if (v != null) return v.toString();
      }
    } catch (_) {}
    return 'Error ($code)';
  }
}

final activeReelIndexProvider = StateProvider<int>((ref) => 0);

class ReelsFeedNotifier extends StateNotifier<AsyncValue<List<ReelModel>>> {
  ReelsFeedNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  String? _next;
  bool _hasMore = true;
  bool _busy = false;

  Future<void> _load() async {
    try {
      final result = await ReelsApiService.fetchReels();
      _next = result['next'] as String?;
      _hasMore = _next != null;
      state = AsyncValue.data(result['reels'] as List<ReelModel>);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    _next = null;
    _hasMore = true;
    state = const AsyncValue.loading();
    await _load();
  }

  Future<void> loadMore() async {
    if (_busy || !_hasMore || _next == null) return;
    _busy = true;
    try {
      final result = await ReelsApiService.fetchReels(cursor: _next);
      _next = result['next'] as String?;
      _hasMore = _next != null;
      final more = result['reels'] as List<ReelModel>;
      state = AsyncValue.data([...(state.value ?? []), ...more]);
    } catch (_) {
    } finally {
      _busy = false;
    }
  }

  void applyReaction(String id, String? reaction) {
    final list = state.value;
    if (list == null) return;
    final index = list.indexWhere((x) => x.id == id);
    if (index < 0) return;

    final hadReaction = list[index].currentUserReaction != null;
    list[index].currentUserReaction = reaction;

    // Only adjust count when actually adding or removing, not when switching between types
    if (!hadReaction && reaction != null) {
      list[index].reactionsCount++;
    } else if (hadReaction && reaction == null) {
      list[index].reactionsCount = (list[index].reactionsCount - 1).clamp(
        0,
        999999,
      );
    }

    state = AsyncValue.data(List.from(list));
  }

  void updateFollow(String userId, bool value) {
    final list = state.value;
    if (list == null) return;
    for (final r in list) {
      if (r.userId == userId) r.isFollowed = value;
    }
    state = AsyncValue.data(List.from(list));
  }

  void incrementComments(String reelId) {
    final list = state.value;
    if (list == null) return;
    final idx = list.indexWhere((r) => r.id == reelId);
    if (idx != -1) list[idx].commentsCount++;
    state = AsyncValue.data(List.from(list));
  }

  void decrementComments(String reelId) {
    final list = state.value;
    if (list == null) return;
    final idx = list.indexWhere((r) => r.id == reelId);
    if (idx != -1) {
      list[idx].commentsCount = (list[idx].commentsCount - 1).clamp(0, 999999);
    }
    state = AsyncValue.data(List.from(list));
  }

  Future<String?> editReel(String id, String caption) async {
    final list = state.value;
    if (list == null) return 'No data';
    final i = list.indexWhere((x) => x.id == id);
    if (i < 0) return 'Not found';
    final oldCaption = list[i].caption;
    list[i].caption = caption;
    state = AsyncValue.data(List.from(list));
    final res = await ReelsApiService.editReel(reelId: id, caption: caption);
    if (res.success) {
      if (res.data != null) list[i].caption = res.data!.caption;
      state = AsyncValue.data(List.from(list));
      return null;
    }
    list[i].caption = oldCaption;
    state = AsyncValue.data(List.from(list));
    return res.errorMessage;
  }

  Future<String?> deleteReel(String id) async {
    final res = await ReelsApiService.deleteReel(id);
    if (res.success) {
      state = AsyncValue.data(
        (state.value ?? []).where((r) => r.id != id).toList(),
      );
      return null;
    }
    return res.errorMessage;
  }

  Future<String?> repostReel(String id) async {
    final res = await ReelsApiService.repostReel(id);
    if (res.success && res.data != null) {
      state = AsyncValue.data([res.data!, ...(state.value ?? [])]);
      return null;
    }
    return res.errorMessage;
  }
}

final reelsFeedProvider =
    StateNotifierProvider<ReelsFeedNotifier, AsyncValue<List<ReelModel>>>(
      (ref) => ReelsFeedNotifier(),
    );

// Ring-buffer slot manager — guarantees curSlot always holds the correct reel's video.
// On forward swipe: prevSlot ← curSlot ← nextSlot ← (recycled prevSlot)
// On backward swipe: nextSlot ← curSlot ← prevSlot ← (recycled nextSlot)
class _SlotManager {
  int curSlot = 0;
  int nextSlot = 1;
  int prevSlot = 2;

  int rotateForward() {
    final recycled = prevSlot;
    prevSlot = curSlot;
    curSlot = nextSlot;
    nextSlot = recycled;
    return nextSlot;
  }

  int rotateBackward() {
    final recycled = nextSlot;
    nextSlot = curSlot;
    curSlot = prevSlot;
    prevSlot = recycled;
    return prevSlot;
  }
}

class ReelsScreen extends ConsumerStatefulWidget {
  const ReelsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends ConsumerState<ReelsScreen>
    with WidgetsBindingObserver, RouteAware {
  late final PageController _pageCtrl;

  int _currentPage = 0;
  bool _isMuted = false;
  bool _feedReady = false;

  final _slots = _SlotManager();

  String get _token => AppData().accessToken ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageCtrl = PageController();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  // ADD these two methods:
  @override
  void didPushNext() {
    // Another screen pushed on top → pause immediately
    ReelsPlayer.pause(_slots.curSlot);
  }

  @override
  void didPopNext() {
    // Returned back to reels → resume
    ReelsPlayer.play(_slots.curSlot);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    ReelsPlayer.releaseAll();
    _pageCtrl.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused || s == AppLifecycleState.inactive) {
      ReelsPlayer.pause(_slots.curSlot);
    } else if (s == AppLifecycleState.resumed) {
      ReelsPlayer.play(_slots.curSlot);
    }
  }

  void _onFeedReady(List<ReelModel> reels) {
    if (_feedReady || reels.isEmpty) return;
    _feedReady = true;

    _prepareIndex(0, reels, _slots.curSlot);
    if (reels.length > 1) _prepareIndex(1, reels, _slots.nextSlot);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      ReelsPlayer.switchSurface(_slots.curSlot);
      ReelsPlayer.listenFirstFrame(_slots.curSlot, () {
        if (mounted) setState(() {});
      });
      Future.delayed(const Duration(milliseconds: 60), () {
        if (!mounted) return;
        ReelsPlayer.play(_slots.curSlot);
        ReelsApiService.recordView(reels[0].id);
      });
    });
  }

  void _prepareIndex(int reelIndex, List<ReelModel> reels, int physicalSlot) {
    if (reelIndex < 0 || reelIndex >= reels.length) return;
    final url = reels[reelIndex].bestVideoUrl;
    if (url == null || url.isEmpty) return;
    developer.log(
      '[Reels] prepare slot=$physicalSlot reelIndex=$reelIndex (${reels[reelIndex].username})',
    );
    ReelsPlayer.prepare(physicalSlot, url, _token);
  }

  void _onPageChanged(int newIndex, List<ReelModel> reels) {
    final goingForward = newIndex > _currentPage;
    ReelsPlayer.pause(_slots.curSlot);

    final int recycledSlot;
    if (goingForward) {
      recycledSlot = _slots.rotateForward();
      _prepareIndex(newIndex + 1, reels, recycledSlot);
    } else {
      recycledSlot = _slots.rotateBackward();
      _prepareIndex(newIndex - 1, reels, recycledSlot);
    }

    setState(() => _currentPage = newIndex);
    ref.read(activeReelIndexProvider.notifier).state = newIndex;

    ReelsPlayer.switchSurface(_slots.curSlot).then((_) {
      Future.delayed(const Duration(milliseconds: 50), () {
        if (!mounted) return;
        ReelsPlayer.play(_slots.curSlot);
        if (_isMuted) ReelsPlayer.setVolume(_slots.curSlot, 0.0);
      });
    });

    ReelsApiService.recordView(reels[newIndex].id);

    if (newIndex >= reels.length - 3) {
      ref.read(reelsFeedProvider.notifier).loadMore();
    }

    developer.log(
      '[Reels] page=$newIndex | cur=${_slots.curSlot} next=${_slots.nextSlot} prev=${_slots.prevSlot}',
    );
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    ReelsPlayer.setVolume(_slots.curSlot, _isMuted ? 0.0 : 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(reelsFeedProvider);
    return PopScope(
      onPopInvoked: (_) => ReelsPlayer.releaseAll(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: feedState.when(
          loading: () => const ReelsShimmer(),
          error:
              (e, _) => ReelsError(
                onRetry: () => ref.read(reelsFeedProvider.notifier).refresh(),
              ),
          data: (reels) {
            if (reels.isEmpty) return _buildEmpty();

            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _onFeedReady(reels),
            );

            return Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Colors.black),
                Center(
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: const ReelsSurfaceWidget(),
                  ),
                ),
                PageView.builder(
                  controller: _pageCtrl,
                  scrollDirection: Axis.vertical,
                  onPageChanged: (i) => _onPageChanged(i, reels),
                  itemCount: reels.length,
                  itemBuilder: (ctx, i) {
                    final isActive = i == _currentPage;
                    return _ReelOverlay(
                      key: ValueKey(reels[i].id),
                      reel: reels[i],
                      isActive: isActive,
                      isMuted: _isMuted,
                      onMuteToggle: _toggleMute,
                      activeSlot: _slots.curSlot,
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.video_library_outlined,
          color: Colors.white54,
          size: 64,
        ),
        const SizedBox(height: 16),
        const Text(
          'No reels yet',
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () => ref.read(reelsFeedProvider.notifier).refresh(),
          child: const Text('Refresh', style: TextStyle(color: Colors.orange)),
        ),
      ],
    ),
  );
}

class _ReelOverlay extends ConsumerStatefulWidget {
  final ReelModel reel;
  final bool isActive;
  final bool isMuted;
  final VoidCallback onMuteToggle;
  final int activeSlot;

  const _ReelOverlay({
    Key? key,
    required this.reel,
    required this.isActive,
    required this.isMuted,
    required this.onMuteToggle,
    required this.activeSlot,
  }) : super(key: key);

  @override
  ConsumerState<_ReelOverlay> createState() => _ReelOverlayState();
}

class _ReelOverlayState extends ConsumerState<_ReelOverlay>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _showControls = false;
  bool _showComments = false;

  Timer? _loadingTimer;

  late AnimationController _heartCtrl;
  late Animation<double> _heartScale;
  late Animation<double> _heartOpacity;
  bool _showHeart = false;
  Offset _heartPos = Offset.zero;

  OverlayEntry? _reactionOverlay;
  final LayerLink _reactionLink = LayerLink();
  final ContentLikeService _likeService = ContentLikeService(
    baseUrl: 'http://36.253.137.34:8012',
  );

  @override
  void initState() {
    super.initState();
    _initHeart();
    if (widget.isActive) _scheduleVideoReveal();
  }

  @override
  void didUpdateWidget(_ReelOverlay old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      setState(() {
        _isLoading = true;
        _isPlaying = true;
      });
      _scheduleVideoReveal();
    } else if (!widget.isActive && old.isActive) {
      _loadingTimer?.cancel();
      setState(() {
        _isPlaying = false;
        _isLoading = true;
      });
    }
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _heartCtrl.dispose();
    _removeReactionOverlay();
    super.dispose();
  }

  void _scheduleVideoReveal() {
    _loadingTimer?.cancel();
    _isPlaying = true;
    _loadingTimer = Timer(const Duration(milliseconds: 600), () {
      if (mounted && widget.isActive) {
        setState(() => _isLoading = false);
      }
    });
  }

  void _initHeart() {
    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _heartScale = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: 1.6,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.6,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
    ]).animate(_heartCtrl);
    _heartOpacity = TweenSequence([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 80),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20),
    ]).animate(_heartCtrl);
  }

  void _onTap() {
    _removeReactionOverlay();
    if (!widget.isActive) return;
    setState(() {
      _isPlaying = !_isPlaying;
      _showControls = true;
    });
    _isPlaying
        ? ReelsPlayer.play(widget.activeSlot)
        : ReelsPlayer.pause(widget.activeSlot);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _onDoubleTap(TapDownDetails d) {
    HapticFeedback.mediumImpact();
    _removeReactionOverlay();
    setState(() {
      _heartPos = d.localPosition;
      _showHeart = true;
    });
    _heartCtrl.forward(from: 0).then((_) {
      if (mounted) setState(() => _showHeart = false);
    });
    if (!widget.reel.isLiked) _react(ReactionType.like);
  }

  void _onLongPressStart(LongPressStartDetails _) {
    if (widget.isActive) ReelsPlayer.pause(widget.activeSlot);
  }

  void _onLongPressEnd(LongPressEndDetails _) {
    if (widget.isActive && _isPlaying) ReelsPlayer.play(widget.activeSlot);
  }

  // Fixed: capture oldReaction BEFORE the optimistic mutation so we can
  // correctly revert on failure and avoid the stale-reference bug.
  Future<void> _react(ReactionType type) async {
    final reel = widget.reel;
    final oldReaction =
        reel.currentUserReaction; // snapshot before any mutation
    final isSame = oldReaction == type.value;
    final notifier = ref.read(reelsFeedProvider.notifier);

    // Optimistic update: toggle off if same reaction, otherwise switch to new
    final optimisticReaction =
        (oldReaction != null && isSame) ? null : type.value;
    notifier.applyReaction(reel.id, optimisticReaction);

    final res = await _likeService.reactReel(reel.id, type);

    if (!res.success) {
      // Revert to the original reaction the user had before tapping
      notifier.applyReaction(reel.id, oldReaction);
    } else if (res.reactionType != null) {
      // Server confirmed a specific reaction — trust it
      notifier.applyReaction(reel.id, res.reactionType!.value);
    }
    // Success with no reactionType returned: keep the optimistic value as-is
  }

  void _showReactionPicker() {
    if (_reactionOverlay != null) {
      _removeReactionOverlay();
      return;
    }
    HapticFeedback.mediumImpact();
    _reactionOverlay = OverlayEntry(
      builder:
          (_) => ReactionPicker(
            layerLink: _reactionLink,
            currentReaction: widget.reel.currentReactionType,
            onSelect: (t) {
              _removeReactionOverlay();
              _react(t);
            },
            onDismiss: _removeReactionOverlay,
          ),
    );
    Overlay.of(context).insert(_reactionOverlay!);
  }

  void _removeReactionOverlay() {
    _reactionOverlay?.remove();
    _reactionOverlay = null;
  }

  bool _isMe() =>
      AppData().isMe(widget.reel.userId) ||
      AppData().isMe(widget.reel.username);

  void _openOptions() {
    if (widget.isActive) ReelsPlayer.pause(widget.activeSlot);
    _removeReactionOverlay();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (_) => ReelOptionsSheet(
            isOwner: _isMe(),
            reel: widget.reel,
            onEdit: _isMe() ? _editDialog : null,
            onDelete: _isMe() ? _deleteDialog : null,
            onRepost: !_isMe() ? _doRepost : null,
          ),
    ).then((_) {
      if (widget.isActive && mounted && _isPlaying) {
        ReelsPlayer.play(widget.activeSlot);
      }
    });
  }

  void _editDialog() {
    final tc = TextEditingController(text: widget.reel.caption);
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFF1C1C1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Edit Caption',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: TextField(
              controller: tc,
              maxLines: 4,
              minLines: 1,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Write a caption…',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF48706),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  final cap = tc.text.trim();
                  Navigator.pop(context);
                  final err = await ref
                      .read(reelsFeedProvider.notifier)
                      .editReel(widget.reel.id, cap);
                  if (mounted)
                    _snack(err ?? 'Caption updated!', err: err != null);
                },
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _deleteDialog() {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: const Color(0xFF1C1C1E),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Delete Reel',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: const Text(
              'This reel will be permanently deleted.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () async {
                  Navigator.pop(context);
                  final err = await ref
                      .read(reelsFeedProvider.notifier)
                      .deleteReel(widget.reel.id);
                  if (err != null && mounted) _snack(err, err: true);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _doRepost() async {
    _snack('Reposting…');
    final err = await ref
        .read(reelsFeedProvider.notifier)
        .repostReel(widget.reel.id);
    if (mounted) _snack(err ?? 'Reposted!', err: err != null);
  }

  void _share() => Share.share(
    'Download Now \n https://play.google.com/store/apps/details?id=com.innovation.innovator&pcampaignid=web_share',
  );

  void _snack(String msg, {bool err = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: err ? Colors.redAccent : const Color(0xFFF48706),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n > 0 ? '$n' : '';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (widget.isActive)
          AnimatedOpacity(
            opacity: _isLoading ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: _buildLoadingOverlay(),
          ),
        Positioned.fill(
          child: GestureDetector(
            onTap: _onTap,
            onDoubleTapDown: _onDoubleTap,
            onDoubleTap: () {},
            onLongPressStart: _onLongPressStart,
            onLongPressEnd: _onLongPressEnd,
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
        ),
        _buildGradients(),
        _buildTopBar(),
        _buildBottomLeft(size),
        _buildActions(),
        if (_showControls) _buildPauseHint(),
        if (_showHeart) _buildHeartBurst(),
        if (_showComments) _buildCommentsSheet(),
      ],
    );
  }

  Widget _buildLoadingOverlay() => Stack(
    fit: StackFit.expand,
    children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D0D0D), Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
          ),
        ),
      ),
      Shimmer.fromColors(
        baseColor: Color.fromRGBO(255, 255, 255, 0.03),
        highlightColor: Color.fromRGBO(255, 255, 255, 0.08),
        period: const Duration(milliseconds: 1200),
        child: Container(color: Color.fromRGBO(255, 255, 255, 0.03)),
      ),
      const Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(
            color: Colors.white54,
            strokeWidth: 2.5,
          ),
        ),
      ),
    ],
  );

  Widget _buildGradients() => Stack(
    children: [
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: 140,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.fromRGBO(0, 0, 0, 0.6), Colors.transparent],
            ),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        height: 340,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color.fromRGBO(0, 0, 0, 0.85), Colors.transparent],
            ),
          ),
        ),
      ),
    ],
  );

  Widget _buildTopBar() => Positioned(
    top: MediaQuery.of(context).padding.top + 8,
    left: 8,
    right: 16,
    child: Row(
      children: [
        IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 22,
          ),
          onPressed: () {
            ReelsPlayer.releaseAll();
            Navigator.maybePop(context);
          },
        ),
        const Spacer(),
        const Text(
          'Reels',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const Spacer(),
      ],
    ),
  );

  Widget _buildBottomLeft(Size size) => Positioned(
    bottom: 80,
    left: 14,
    right: 88,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.reel.isRepost && widget.reel.sharedReelDetails != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Icon(
                  Icons.repeat_rounded,
                  color: Colors.white70,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  'Reposted from @${widget.reel.sharedReelDetails!.username}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    shadows: [Shadow(blurRadius: 3)],
                  ),
                ),
              ],
            ),
          ),
        GestureDetector(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) =>
                          SpecificUserProfilePage(userId: widget.reel.userId),
                ),
              ),
          child: Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  widget.reel.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    shadows: [Shadow(blurRadius: 4)],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              if (!_isMe())
                FollowButton(
                  targetUserId: widget.reel.userId,
                  initialFollowStatus: widget.reel.isFollowed,
                  onFollowSuccess: () {
                    widget.reel.isFollowed = true;
                    ref
                        .read(reelsFeedProvider.notifier)
                        .updateFollow(widget.reel.userId, true);
                  },
                  onUnfollowSuccess: () {
                    widget.reel.isFollowed = false;
                    ref
                        .read(reelsFeedProvider.notifier)
                        .updateFollow(widget.reel.userId, false);
                  },
                ),
            ],
          ),
        ),
        if (widget.reel.caption.isNotEmpty) ...[
          const SizedBox(height: 8),
          ExpandableCaption(caption: widget.reel.caption),
        ],
      ],
    ),
  );

  Widget _buildAvatar() {
    final url = widget.reel.avatar;
    final initial =
        widget.reel.username.isNotEmpty
            ? widget.reel.username[0].toUpperCase()
            : '?';
    final fallback = Container(
      color: Colors.grey.shade700,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: ClipOval(
        child:
            (url != null && url.isNotEmpty)
                ? CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => fallback,
                  errorWidget: (_, __, ___) => fallback,
                )
                : fallback,
      ),
    );
  }

  Widget _buildActions() {
    final reel = widget.reel;
    final reaction = reel.currentReactionType;
    return Positioned(
      right: 8,
      bottom: 88,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CompositedTransformTarget(
            link: _reactionLink,
            child: GestureDetector(
              onTap: () => _react(reaction ?? ReactionType.like),
              onLongPress: _showReactionPicker,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child:
                          reaction != null
                              ? reaction == ReactionType.like
                                  ? Image.asset(
                                    'animation/IdeaBulb_Filled.gif',
                                    width: 32,
                                    height: 32,
                                  )
                                  : Text(
                                    reaction.emoji,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      inherit: false,
                                    ),
                                  )
                              : const Icon(
                                Icons.lightbulb_outline,
                                color: Colors.white,
                                size: 30,
                                shadows: [Shadow(blurRadius: 6)],
                              ),
                    ),
                  ),
                  Text(
                    _fmt(reel.reactionsCount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(blurRadius: 4)],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ActionButton(
            icon: Icons.chat_bubble_outline_rounded,
            label: _fmt(reel.commentsCount),
            onTap: () => setState(() => _showComments = !_showComments),
          ),
          const SizedBox(height: 20),
          if (!_isMe()) ...[
            ActionButton(
              icon: Icons.repeat_rounded,
              label: 'Repost',
              onTap: _doRepost,
            ),
            const SizedBox(height: 20),
          ],
          ActionButton(icon: Icons.send_rounded, label: 'Share', onTap: _share),
          IconButton(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Colors.white,
              size: 24,
            ),
            onPressed: _openOptions,
          ),
          const SizedBox(height: 12),
          ActionButton(
            icon:
                widget.isMuted
                    ? Icons.volume_off_rounded
                    : Icons.volume_up_rounded,
            label: '',
            onTap: widget.onMuteToggle,
          ),
        ],
      ),
    );
  }

  Widget _buildPauseHint() => Center(
    child: AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Color.fromRGBO(0, 0, 0, 0.55),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 42,
        ),
      ),
    ),
  );

  Widget _buildHeartBurst() => Positioned(
    left: _heartPos.dx - 48,
    top: _heartPos.dy - 48,
    child: IgnorePointer(
      child: AnimatedBuilder(
        animation: _heartCtrl,
        builder:
            (_, __) => Opacity(
              opacity: _heartOpacity.value,
              child: Transform.scale(
                scale: _heartScale.value,
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 96,
                  shadows: [
                    Shadow(color: Colors.red, blurRadius: 20),
                    Shadow(blurRadius: 8),
                  ],
                ),
              ),
            ),
      ),
    ),
  );

  Widget _buildCommentsSheet() => Positioned(
    bottom: 0,
    left: 0,
    right: 0,
    height: MediaQuery.of(context).size.height * 0.6,
    child: GestureDetector(
      onTap: () {},
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Spacer(),
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _showComments = false),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CommentSection(
                contentId: widget.reel.id,
                isReel: true,
                onCommentCountChanged: (delta) {
                  if (delta > 0) {
                    ref
                        .read(reelsFeedProvider.notifier)
                        .incrementComments(widget.reel.id);
                  } else {
                    ref
                        .read(reelsFeedProvider.notifier)
                        .decrementComments(widget.reel.id);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ReelOptionsSheet extends StatelessWidget {
  final bool isOwner;
  final ReelModel reel;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRepost;

  const ReelOptionsSheet({
    Key? key,
    required this.isOwner,
    required this.reel,
    this.onEdit,
    this.onDelete,
    this.onRepost,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      color: Color(0xFF1C1C1E),
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 4,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        if (isOwner) ...[
          OptionTile(
            icon: Icons.edit_rounded,
            label: 'Edit Caption',
            onTap: () {
              Navigator.pop(context);
              onEdit?.call();
            },
          ),
          OptionTile(
            icon: Icons.delete_outline_rounded,
            label: 'Delete Reel',
            color: Colors.redAccent,
            onTap: () {
              Navigator.pop(context);
              onDelete?.call();
            },
          ),
        ] else
          OptionTile(
            icon: Icons.repeat_rounded,
            label: 'Repost',
            onTap: () {
              Navigator.pop(context);
              onRepost?.call();
            },
          ),
        OptionTile(
          icon: Icons.close_rounded,
          label: 'Cancel',
          color: Colors.white54,
          onTap: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}

class OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const OptionTile({
    Key? key,
    required this.icon,
    required this.label,
    this.color = Colors.white,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 16),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

class ReactionPicker extends StatefulWidget {
  final LayerLink layerLink;
  final ReactionType? currentReaction;
  final void Function(ReactionType) onSelect;
  final VoidCallback onDismiss;

  const ReactionPicker({
    Key? key,
    required this.layerLink,
    required this.currentReaction,
    required this.onSelect,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<ReactionPicker> createState() => _ReactionPickerState();
}

class _ReactionPickerState extends State<ReactionPicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
  ReactionType? _hovered;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const itemHeight = 52.0;
    final pickerHeight = ReactionType.values.length * itemHeight + 16;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
        ),
        CompositedTransformFollower(
          link: widget.layerLink,
          showWhenUnlinked: false,
          offset: Offset(-68, -(pickerHeight / 2) + 22),
          child: FadeTransition(
            opacity: _fade,
            child: ScaleTransition(
              scale: _scale,
              alignment: Alignment.centerRight,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: 56,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(0, 0, 0, 0.75),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children:
                        ReactionType.values.map((reaction) {
                          final isActive = widget.currentReaction == reaction;
                          final isHovered = _hovered == reaction;
                          return GestureDetector(
                            onTap: () => widget.onSelect(reaction),
                            onTapDown:
                                (_) => setState(() => _hovered = reaction),
                            onTapCancel: () => setState(() => _hovered = null),
                            child: SizedBox(
                              width: 56,
                              height: itemHeight,
                              child: Stack(
                                alignment: Alignment.center,
                                clipBehavior: Clip.none,
                                children: [
                                  if (isActive)
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Color.fromRGBO(
                                          255,
                                          255,
                                          255,
                                          0.15,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(
                                      begin: 1.0,
                                      end:
                                          isHovered
                                              ? 1.4
                                              : (isActive ? 1.15 : 1.0),
                                    ),
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOutBack,
                                    builder:
                                        (_, s, c) =>
                                            Transform.scale(scale: s, child: c),
                                    child:
                                        reaction == ReactionType.like
                                            ? Image.asset(
                                              'animation/IdeaBulb_Filled.gif',
                                              width: isActive ? 30 : 26,
                                              height: isActive ? 30 : 26,
                                            )
                                            : Text(
                                              reaction.emoji,
                                              style: const TextStyle(
                                                fontSize: 26,
                                                inherit: false,
                                              ),
                                            ),
                                  ),
                                  if (isHovered)
                                    Positioned(
                                      left: -72,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black87,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          reaction.label,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
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
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ActionButton extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const ActionButton({
    Key? key,
    required this.icon,
    this.iconColor = Colors.white,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.88,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    await _ctrl.reverse();
    _ctrl.forward();
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: _tap,
    behavior: HitTestBehavior.opaque,
    child: ScaleTransition(
      scale: _ctrl,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.icon,
            color: widget.iconColor,
            size: 30,
            shadows: const [Shadow(blurRadius: 6)],
          ),
          if (widget.label.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                shadows: [Shadow(blurRadius: 4)],
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class ExpandableCaption extends StatefulWidget {
  final String caption;
  const ExpandableCaption({Key? key, required this.caption}) : super(key: key);

  @override
  State<ExpandableCaption> createState() => _ExpandableCaptionState();
}

class _ExpandableCaptionState extends State<ExpandableCaption> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => _expanded = !_expanded),
    child: AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: RichText(
        maxLines: _expanded ? null : 2,
        overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
        text: TextSpan(
          children: [
            TextSpan(
              text: widget.caption,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.45,
                shadows: [Shadow(blurRadius: 4)],
              ),
            ),
            if (!_expanded)
              const TextSpan(
                text: ' more',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class ReelsShimmer extends StatelessWidget {
  const ReelsShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: Colors.grey.shade900,
    highlightColor: Colors.grey.shade800,
    period: const Duration(milliseconds: 1400),
    child: Container(color: Colors.black),
  );
}

class ReelsError extends StatelessWidget {
  final VoidCallback onRetry;
  const ReelsError({Key? key, required this.onRetry}) : super(key: key);

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: Colors.white54, size: 56),
        const SizedBox(height: 16),
        const Text(
          'Could not load reels',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF48706),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    ),
  );
}
