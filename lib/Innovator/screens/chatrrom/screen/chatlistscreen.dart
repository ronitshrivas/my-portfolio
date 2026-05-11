// import 'dart:convert';
// import 'dart:developer' as developer;
// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:http/http.dart' as http;
// import 'package:innovator/Innovator/App_data/App_data.dart';
// import 'package:innovator/Innovator/models/Chat/mutual_friend_model.dart';
// import 'package:innovator/Innovator/provider/mutual_friend_state.dart';
// import 'package:innovator/Innovator/provider/unread_count_provider.dart';
// import 'package:innovator/Innovator/screens/chatrrom/screen/chatscreen.dart';

// import '../../Feed/Optimize Media/full_screen_image_viewer.dart';

// const _kHttpBase = 'http://36.253.137.34:8005';
// const Color _orange = Color.fromRGBO(244, 135, 6, 1);
// const Color _orangeLight = Color.fromRGBO(244, 135, 6, 0.10);
// const Color _orangeMid = Color.fromRGBO(244, 135, 6, 0.18);

// class MutualFriendsNotifier extends StateNotifier<MutualFriendsState> {
//   final Ref _ref;
//   bool _mounted = true;
//   MutualFriendsNotifier(this._ref) : super(const MutualFriendsState()) {
//     Future.microtask(() => _initWhenReady());
//     fetchMutualFriends();
//     _ref.listen<Map<String, int>>(perFriendUnreadProvider, (_, realtimeMap) {
//       if (!_mounted) return;
//       final total = state.friends.fold<int>(
//         0,
//         (sum, f) => sum + (realtimeMap[f.id] ?? f.unreadCount),
//       );
//       Future.microtask(() {
//         if (!_mounted) return;
//         _ref.read(chatUnreadCountProvider.notifier).state = total;
//       });
//     });
//   }

//   Future<void> _initWhenReady() async {
//     if (!_mounted) return;
//     int attempts = 0;
//     while (attempts < 10) {
//       final token = AppData().accessToken;
//       if (token != null && token.isNotEmpty) {
//         fetchMutualFriends();
//         return;
//       }
//       await Future.delayed(const Duration(milliseconds: 300));
//       attempts++;
//     }
//     if (_mounted) {
//       _setState(
//         state.copyWith(
//           isLoading: false,
//           error: 'Session expired. Please log in again. 5',
//         ),
//       );
//     }
//   }

//   void bumpToTop(String friendId) {
//     final idx = state.friends.indexWhere((f) => f.id == friendId);
//     if (idx <= 0) return;
//     final updated = [...state.friends];
//     final friend = updated.removeAt(idx);
//     updated.insert(0, friend);
//     _setState(state.copyWith(friends: updated));
//   }

//   @override
//   void dispose() {
//     _mounted = false;
//     super.dispose();
//   }

//   void _setState(MutualFriendsState newState) {
//     if (!_mounted) return;
//     state = newState;
//     Future.microtask(() {
//       if (!_mounted) return;
//       final realtimeMap = _ref.read(perFriendUnreadProvider);
//       final combinedTotal = newState.friends.fold<int>(
//         0,
//         (sum, f) => sum + (realtimeMap[f.id] ?? f.unreadCount),
//       );
//       _ref.read(chatUnreadCountProvider.notifier).state = combinedTotal;
//     });
//   }

//   String get _token => AppData().accessToken ?? '';

//   Map<String, String> get _headers => {
//     'Content-Type': 'application/json',
//     'Accept': 'application/json',
//     if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
//   };

//   Future<void> fetchMutualFriends() async {
//     _setState(state.copyWith(isLoading: true, error: null));
//     try {
//       final response = await http
//           .get(
//             Uri.parse('$_kHttpBase/api/users/mutual-friends/'),
//             headers: _headers,
//           )
//           .timeout(const Duration(seconds: 15));

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body) as Map<String, dynamic>;
//         final count = data['mutual_friends_count'] as int? ?? 0;
//         final list =
//             (data['mutual_friends'] as List? ?? [])
//                 .whereType<Map<String, dynamic>>()
//                 .map(MutualFriend.fromJson)
//                 .toList();

//         _setState(
//           state.copyWith(
//             // ← _setState
//             friends: list,
//             totalCount: count,
//             isLoading: false,
//           ),
//         );

//         developer.log('[ChatList] Loaded ${list.length} mutual friends');
//         await _fetchAllUnreadCounts(list);
//       } else {
//         _setState(
//           state.copyWith(
//             // ← _setState
//             isLoading: false,
//             error: 'Failed to load (${response.statusCode})',
//           ),
//         );
//       }
//     } catch (e) {
//       developer.log('[ChatList] fetchMutualFriends error: $e');
//       _setState(
//         state.copyWith(
//           // ← _setState
//           isLoading: false,
//           error: 'Network error. Pull to refresh.',
//         ),
//       );
//     }
//   }

//   // ── Unread counts — parallel fetch ────────────────────────────────────────

//   Future<void> _fetchAllUnreadCounts(List<MutualFriend> friends) async {
//     final results = await Future.wait(
//       friends.map((f) => _fetchUnreadCount(f.id)),
//     );
//     final updated = List<MutualFriend>.generate(
//       friends.length,
//       (i) => friends[i].copyWithUnread(results[i]),
//     );

//     // Seed the real-time provider with REST counts
//     final seedMap = {
//       for (int i = 0; i < friends.length; i++) friends[i].id: results[i],
//     };
//     _ref
//         .read(perFriendUnreadProvider.notifier)
//         .seedFromHistory(seedMap); // ← ADD

//     _setState(state.copyWith(friends: updated));
//   }

//   Future<int> _fetchUnreadCount(String senderId) async {
//     try {
//       final response = await http
//           .get(
//             Uri.parse('$_kHttpBase/api/chats/?with_user=$senderId'),
//             headers: _headers,
//           )
//           .timeout(const Duration(seconds: 10));

//       if (response.statusCode == 200) {
//         final list = json.decode(response.body) as List<dynamic>;
//         return list
//             .whereType<Map<String, dynamic>>()
//             .where(
//               (m) =>
//                   m['sender']?.toString() == senderId && m['is_read'] == false,
//             )
//             .length;
//       }
//     } catch (e) {
//       developer.log('[ChatList] _fetchUnreadCount($senderId) error: $e');
//     }
//     return 0;
//   }

//   void clearUnread(String friendId) {
//     final updated =
//         state.friends
//             .map((f) => f.id == friendId ? f.copyWithUnread(0) : f)
//             .toList();
//     _setState(state.copyWith(friends: updated));
//     _ref.read(perFriendUnreadProvider.notifier).reset(friendId);
//   }

//   Future<bool> deleteConversation(String friendId) async {
//     try {
//       final uri = Uri.parse('$_kHttpBase/api/chats/delete-conversation/');

//       final response = await http
//           .post(
//             uri,
//             headers: {
//               'Content-Type': 'application/json',
//               'Accept': 'application/json',
//               if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
//             },
//             body: json.encode({'with_user': friendId}),
//           )
//           .timeout(const Duration(seconds: 10));

//       if (response.statusCode == 200) {
//         final updated = state.friends.where((f) => f.id != friendId).toList();
//         _setState(state.copyWith(friends: updated));
//         developer.log('[ChatList] Conversation deleted for $friendId');
//         return true;
//       }
//       developer.log(
//         '[ChatList] deleteConversation failed: ${response.statusCode}',
//       );
//       return false;
//     } catch (e) {
//       developer.log('[ChatList] deleteConversation error: $e');
//       return false;
//     }
//   }

//   void refresh() => fetchMutualFriends();
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Providers
// // ─────────────────────────────────────────────────────────────────────────────

// /// autoDispose so it refreshes when ChatListScreen is re-entered
// final mutualFriendsProvider =
//     StateNotifierProvider<MutualFriendsNotifier, MutualFriendsState>(
//       (ref) => MutualFriendsNotifier(ref),
//     );

// /// Non-autoDispose — survives navigation so the FAB on the home screen
// /// can always read the latest unread count even after ChatListScreen is popped.
// final chatUnreadCountProvider = StateProvider<int>((ref) => 0);
// // ─────────────────────────────────────────────────────────────────

// class ChatListScreen extends ConsumerStatefulWidget {
//   const ChatListScreen({super.key});
//   @override
//   ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
// }

// class _ChatListScreenState extends ConsumerState<ChatListScreen> {
//   @override
//   void initState() {
//     super.initState();
//     // When returning from ChatScreen, bump the last active friend to top
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final friendId = ref.read(lastActiveFriendProvider);
//       if (friendId != null) {
//         ref.read(mutualFriendsProvider.notifier).bumpToTop(friendId);
//         ref.read(lastActiveFriendProvider.notifier).state = null;
//       }
//       _refreshOrder();
//     });
//   }

//   void _refreshOrder() {
//     final friendId = ref.read(lastActiveFriendProvider);
//     if (friendId != null) {
//       ref.read(mutualFriendsProvider.notifier).bumpToTop(friendId);
//       ref.read(lastActiveFriendProvider.notifier).state = null;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final state = ref.watch(mutualFriendsProvider);
//     final realtimeUnread = ref.watch(perFriendUnreadProvider);
//     final activity = ref.watch(friendActivityProvider);

//     final sortedFriends =
//         state.friends.map((f) {
//             final t = activity[f.id];
//             return (t != null) ? f.copyWithLastMessageAt(t) : f;
//           }).toList()
//           ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

//     final sortedState = state.copyWith(friends: sortedFriends);

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: CustomScrollView(
//         slivers: [
//           _buildSliverAppBar(context, ref, sortedState, realtimeUnread),
//           if (sortedState.isLoading && sortedState.friends.isEmpty)
//             const SliverFillRemaining(child: _SkeletonListSliver())
//           else if (sortedState.error != null && sortedState.friends.isEmpty)
//             SliverFillRemaining(child: _buildError(ref, sortedState.error!))
//           else if (sortedState.friends.isEmpty)
//             SliverFillRemaining(child: _buildEmpty(ref))
//           else
//             ..._buildFriendSlivers(context, ref, sortedState, realtimeUnread),
//           const SliverToBoxAdapter(child: SizedBox(height: 24)),
//         ],
//       ),
//     );
//   }

//   // ── Sliver App Bar ──────────────────────────────────────────────────────────

//   Widget _buildSliverAppBar(
//     BuildContext context,
//     WidgetRef ref,
//     MutualFriendsState state,
//     Map<String, int> realtimeUnread,
//   ) {
//     final totalUnread = state.friends.fold<int>(
//       0,
//       (sum, f) => sum + (realtimeUnread[f.id] ?? f.unreadCount),
//     );

//     return SliverAppBar(
//       pinned: true,
//       backgroundColor: Colors.white,
//       leading: IconButton(
//         icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
//         color: Colors.black87,
//         onPressed: () => Navigator.of(context).pop(),
//       ),
//       // title: Row(
//       //   children: [
//       //     if (state.onlineFriends.isNotEmpty)
//       //       _Pill(
//       //         color: _orange,
//       //         dotColor: const Color(0xFF2ECC71),
//       //         label: '${state.onlineFriends.length} online',
//       //       ),
//       //     if (totalUnread > 0) ...[
//       //       const SizedBox(width: 10),
//       //       _Pill(
//       //         color: Colors.red,
//       //         dotColor: Colors.red,
//       //         label: '$totalUnread unread',
//       //       ),
//       //     ],
//       //   ],
//       // ),
//     );
//   }

//   // ── Body ────────────────────────────────────────────────────────────────────

//   List<Widget> _buildFriendSlivers(
//     BuildContext context,
//     WidgetRef ref,
//     MutualFriendsState state,
//     Map<String, int> realtimeUnread,
//   ) {
//     return [
//       SliverToBoxAdapter(
//         child: RefreshIndicator(
//           onRefresh:
//               () async => ref.read(mutualFriendsProvider.notifier).refresh(),
//           color: _orange,
//           child: const SizedBox.shrink(),
//         ),
//       ),
//       if (state.onlineFriends.isNotEmpty) ...[
//         _buildSectionHeader('Active Now', state.onlineFriends.length),
//         SliverPadding(
//           padding: const EdgeInsets.symmetric(horizontal: 12),
//           sliver: SliverList(
//             delegate: SliverChildBuilderDelegate(
//               (context, i) => _ChatCard(
//                 friend: state.onlineFriends[i],
//                 isOnline: true,
//                 realtimeUnreadCount:
//                     realtimeUnread[state.onlineFriends[i].id] ?? 0,
//                 onTap: () => _openChat(context, ref, state.onlineFriends[i]),
//                 onDelete:
//                     () => ref
//                         .read(mutualFriendsProvider.notifier)
//                         .deleteConversation(state.onlineFriends[i].id),
//               ),
//               childCount: state.onlineFriends.length,
//             ),
//           ),
//         ),
//       ],
//       if (state.offlineFriends.isNotEmpty) ...[
//         _buildSectionHeader('All Connections', state.offlineFriends.length),
//         SliverPadding(
//           padding: const EdgeInsets.symmetric(horizontal: 12),
//           sliver: SliverList(
//             delegate: SliverChildBuilderDelegate(
//               (context, i) => _ChatCard(
//                 friend: state.offlineFriends[i],
//                 isOnline: false,
//                 realtimeUnreadCount:
//                     realtimeUnread[state.offlineFriends[i].id] ?? 0,
//                 onTap: () => _openChat(context, ref, state.offlineFriends[i]),
//                 onDelete:
//                     () => ref
//                         .read(mutualFriendsProvider.notifier)
//                         .deleteConversation(state.offlineFriends[i].id),
//               ),
//               childCount: state.offlineFriends.length,
//             ),
//           ),
//         ),
//       ],
//     ];
//   }

//   void _openChat(BuildContext context, WidgetRef ref, MutualFriend friend) {
//     ref.read(mutualFriendsProvider.notifier).clearUnread(friend.id);
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder:
//             (_) => ChatScreen(
//               otherUserId: friend.id,
//               otherUserName: friend.displayName,
//               otherUserAvatar: friend.avatar,
//               isOnline: friend.onlineStatus,
//             ),
//       ),
//     ).then((_) {
//       if (context.mounted) {
//         final lastFriend = ref.read(lastActiveFriendProvider);
//         if (lastFriend != null) {
//           ref.read(mutualFriendsProvider.notifier).bumpToTop(lastFriend);
//           ref.read(lastActiveFriendProvider.notifier).state = null;
//         }
//       }
//     });
//   }

//   Widget _buildSectionHeader(String title, int count) {
//     return SliverToBoxAdapter(
//       child: Padding(
//         padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
//         child: Row(
//           children: [
//             Text(
//               title,
//               style: const TextStyle(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w700,
//                 color: Colors.black54,
//                 letterSpacing: 0.5,
//               ),
//             ),
//             const SizedBox(width: 8),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//               decoration: BoxDecoration(
//                 color: _orangeMid,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Text(
//                 '$count',
//                 style: const TextStyle(
//                   fontSize: 11,
//                   color: _orange,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSkeletonList() {
//     return ListView.builder(
//       padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
//       itemCount: 7,
//       itemBuilder: (_, i) => const _SkeletonCard(),
//     );
//   }

//   Widget _buildError(WidgetRef ref, String error) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               width: 72,
//               height: 72,
//               decoration: BoxDecoration(
//                 color: Colors.red.shade50,
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 Icons.wifi_off_rounded,
//                 color: Colors.red.shade300,
//                 size: 36,
//               ),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               error,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 15,
//                 color: Colors.grey.shade600,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             const SizedBox(height: 24),
//             ElevatedButton.icon(
//               onPressed:
//                   () => ref.read(mutualFriendsProvider.notifier).refresh(),
//               icon: const Icon(Icons.refresh_rounded, size: 18),
//               label: const Text('Try Again'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: _orange,
//                 foregroundColor: Colors.white,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 24,
//                   vertical: 12,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// Widget _buildEmpty(WidgetRef ref) {
//   return Center(
//     child: Padding(
//       padding: const EdgeInsets.all(32),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             width: 80,
//             height: 80,
//             decoration: const BoxDecoration(
//               color: _orangeLight,
//               shape: BoxShape.circle,
//             ),
//             child: const Icon(
//               Icons.people_outline_rounded,
//               color: _orange,
//               size: 40,
//             ),
//           ),
//           const SizedBox(height: 20),
//           const Text(
//             'No mutual connections yet',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.w700,
//               color: Colors.black87,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Start following people to see\nyour mutual connections here.',
//             textAlign: TextAlign.center,
//             style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
//           ),
//         ],
//       ),
//     ),
//   );
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Small reusable pill widget (used in the AppBar header)
// // ─────────────────────────────────────────────────────────────────────────────

// class _Pill extends StatelessWidget {
//   final Color color;
//   final Color dotColor;
//   final String label;

//   const _Pill({
//     required this.color,
//     required this.dotColor,
//     required this.label,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: color.withAlpha(10),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: color.withAlpha(30), width: 1),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 7,
//             height: 7,
//             decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
//           ),
//           const SizedBox(width: 6),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 12,
//               color: color,
//               fontWeight: FontWeight.w700,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // _ChatCard
// // ─────────────────────────────────────────────────────────────────────────────

// class _ChatCard extends StatelessWidget {
//   final MutualFriend friend;
//   final bool isOnline;
//   final VoidCallback onTap;
//   final Future<bool> Function() onDelete;
//   final int realtimeUnreadCount;

//   const _ChatCard({
//     required this.friend,
//     required this.isOnline,
//     required this.onTap,
//     required this.onDelete,
//     this.realtimeUnreadCount = 0,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final displayUnread =
//         realtimeUnreadCount > friend.unreadCount
//             ? realtimeUnreadCount
//             : friend.unreadCount;
//     final hasUnread = displayUnread > 0;

//     return Dismissible(
//       key: ValueKey('chat_card_${friend.id}'),
//       direction: DismissDirection.endToStart,
//       confirmDismiss: (_) async {
//         return await _showDeleteDialog(context);
//       },
//       onDismissed: (_) async {
//         final success = await onDelete();
//         if (!success && context.mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: const Text('Failed to delete conversation'),
//               backgroundColor: Colors.red.shade600,
//               behavior: SnackBarBehavior.floating,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               duration: const Duration(seconds: 2),
//             ),
//           );
//         }
//       },
//       background: Container(
//         margin: const EdgeInsets.symmetric(vertical: 4),
//         decoration: BoxDecoration(
//           color: Colors.red.shade500,
//           borderRadius: BorderRadius.circular(18),
//         ),
//         alignment: Alignment.centerRight,
//         padding: const EdgeInsets.only(right: 24),
//         child: const Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
//             SizedBox(height: 4),
//             Text(
//               'Delete',
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 12,
//                 fontWeight: FontWeight.w700,
//               ),
//             ),
//           ],
//         ),
//       ),
//       child: _buildCard(
//         context,
//         hasUnread,
//         displayUnread,
//       ), // ← pass displayUnread
//     );
//   }

//   Future<bool> _showDeleteDialog(BuildContext context) async {
//     return await showDialog<bool>(
//           context: context,
//           builder:
//               (_) => AlertDialog(
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 title: Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: Colors.red.shade50,
//                         shape: BoxShape.circle,
//                       ),
//                       child: Icon(
//                         Icons.delete_outline_rounded,
//                         color: Colors.red.shade600,
//                         size: 22,
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     const Text(
//                       'Delete Conversation',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//                 content: Text(
//                   'Delete your conversation with ${friend.displayName}? '
//                   'This cannot be undone.',
//                   style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
//                 ),
//                 actionsPadding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 12,
//                 ),
//                 actions: [
//                   TextButton(
//                     onPressed: () => Navigator.pop(context, false),
//                     child: Text(
//                       'Cancel',
//                       style: TextStyle(color: Colors.grey.shade600),
//                     ),
//                   ),
//                   ElevatedButton(
//                     onPressed: () => Navigator.pop(context, true),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.red.shade600,
//                       foregroundColor: Colors.white,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       elevation: 0,
//                     ),
//                     child: const Text(
//                       'Delete',
//                       style: TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                   ),
//                 ],
//               ),
//         ) ??
//         false;
//   }

//   Widget _buildCard(BuildContext context, bool hasUnread, int displayUnread) {
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 4),
//       decoration: BoxDecoration(
//         color: hasUnread ? const Color(0xFFFFF8F0) : Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         border:
//             hasUnread
//                 ? Border.all(color: _orange.withAlpha(25), width: 1)
//                 : null,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withAlpha(5),
//             blurRadius: 12,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(18),
//           onTap: onTap,
//           // Long press also shows delete option
//           onLongPress: () => _showLongPressMenu(context),
//           splashColor: const Color.fromRGBO(244, 135, 6, 0.08),
//           highlightColor: const Color.fromRGBO(244, 135, 6, 0.04),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//             child: Row(
//               children: [
//                 // Avatar
//                 Stack(
//                   clipBehavior: Clip.none,
//                   children: [
//                     Container(
//                       width: 52,
//                       height: 52,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         gradient:
//                             isOnline
//                                 ? const LinearGradient(
//                                   colors: [_orange, Color(0xFFFFCC00)],
//                                   begin: Alignment.topLeft,
//                                   end: Alignment.bottomRight,
//                                 )
//                                 : null,
//                         color: isOnline ? null : Colors.grey.shade200,
//                       ),
//                       padding: const EdgeInsets.all(2),
//                       child: GestureDetector(
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder:
//                                   (_) => FullScreenImageViewer(
//                                     imageUrl: friend.avatar,
//                                     tag: 'friend_avatar',
//                                   ),
//                             ),
//                           );
//                         },
//                         child: ClipOval(
//                           child:
//                               friend.avatar.isNotEmpty
//                                   ? CachedNetworkImage(
//                                     imageUrl: friend.avatar,
//                                     fit: BoxFit.cover,
//                                     placeholder:
//                                         (_, __) => _avatarPlaceholder(),
//                                     errorWidget:
//                                         (_, __, ___) => _avatarPlaceholder(),
//                                   )
//                                   : _avatarPlaceholder(),
//                         ),
//                       ),
//                     ),
//                     if (isOnline)
//                       Positioned(
//                         bottom: 1,
//                         right: 1,
//                         child: Container(
//                           width: 13,
//                           height: 13,
//                           decoration: BoxDecoration(
//                             color: const Color(0xFF2ECC71),
//                             shape: BoxShape.circle,
//                             border: Border.all(color: Colors.white, width: 2),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: const Color(0xFF2ECC71).withOpacity(0.4),
//                                 blurRadius: 4,
//                                 spreadRadius: 1,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                   ],
//                 ),

//                 const SizedBox(width: 14),

//                 // Name + username
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         friend.displayName,
//                         style: TextStyle(
//                           fontSize: 15,
//                           fontWeight:
//                               hasUnread ? FontWeight.w800 : FontWeight.w700,
//                           color: Colors.black87,
//                           letterSpacing: -0.2,
//                         ),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                       const SizedBox(height: 3),
//                       Row(
//                         children: [
//                           Text(
//                             '@${friend.username}',
//                             style: TextStyle(
//                               fontSize: 12,
//                               color: Colors.grey.shade500,
//                               fontWeight: FontWeight.w400,
//                             ),
//                           ),
//                           if (isOnline) ...[
//                             const SizedBox(width: 8),
//                             Container(
//                               width: 4,
//                               height: 4,
//                               decoration: const BoxDecoration(
//                                 color: Color(0xFF2ECC71),
//                                 shape: BoxShape.circle,
//                               ),
//                             ),
//                           ],
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),

//                 // Right: unread badge OR "Active now"
//                 if (hasUnread)
//                   _UnreadBadge(count: displayUnread)
//                 else if (isOnline)
//                   const Text(
//                     'Active now',
//                     style: TextStyle(
//                       fontSize: 12,
//                       color: Color(0xFF2ECC71),
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   void _showLongPressMenu(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder:
//           (_) => Container(
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   margin: const EdgeInsets.symmetric(vertical: 12),
//                   width: 40,
//                   height: 4,
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade300,
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//                 // User info header
//                 Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 20,
//                     vertical: 8,
//                   ),
//                   child: Row(
//                     children: [
//                       ClipOval(
//                         child:
//                             friend.avatar.isNotEmpty
//                                 ? CachedNetworkImage(
//                                   imageUrl: friend.avatar,
//                                   width: 40,
//                                   height: 40,
//                                   fit: BoxFit.cover,
//                                 )
//                                 : Container(
//                                   width: 40,
//                                   height: 40,
//                                   color: _orangeLight,
//                                   child: Center(
//                                     child: Text(
//                                       friend.initial,
//                                       style: const TextStyle(
//                                         color: _orange,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                       ),
//                       const SizedBox(width: 12),
//                       Text(
//                         friend.displayName,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.w700,
//                           fontSize: 15,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 const Divider(height: 1),
//                 ListTile(
//                   leading: Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: Colors.red.shade50,
//                       shape: BoxShape.circle,
//                     ),
//                     child: Icon(
//                       Icons.delete_outline_rounded,
//                       color: Colors.red.shade600,
//                       size: 20,
//                     ),
//                   ),
//                   title: const Text(
//                     'Delete Conversation',
//                     style: TextStyle(fontWeight: FontWeight.w600),
//                   ),
//                   subtitle: Text(
//                     'Remove this chat for you',
//                     style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
//                   ),
//                   onTap: () async {
//                     Navigator.pop(context);
//                     final confirm = await _showDeleteDialog(context);
//                     if (confirm) await onDelete();
//                   },
//                 ),
//                 const SizedBox(height: 20),
//               ],
//             ),
//           ),
//     );
//   }

//   Widget _avatarPlaceholder() => Container(
//     color: _orangeLight,
//     child: Center(
//       child: Text(
//         friend.initial,
//         style: const TextStyle(
//           fontWeight: FontWeight.bold,
//           color: _orange,
//           fontSize: 18,
//         ),
//       ),
//     ),
//   );
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // _UnreadBadge — animated red pill
// // ─────────────────────────────────────────────────────────────────────────────

// class _UnreadBadge extends StatefulWidget {
//   final int count;
//   const _UnreadBadge({required this.count});

//   @override
//   State<_UnreadBadge> createState() => _UnreadBadgeState();
// }

// class _UnreadBadgeState extends State<_UnreadBadge>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _ctrl;
//   late final Animation<double> _scale;

//   @override
//   void initState() {
//     super.initState();
//     _ctrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 400),
//     )..forward();
//     _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
//   }

//   @override
//   void dispose() {
//     _ctrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final label = widget.count > 99 ? '99+' : '${widget.count}';
//     final wide = widget.count > 9;

//     return ScaleTransition(
//       scale: _scale,
//       child: Container(
//         constraints: BoxConstraints(minWidth: wide ? 32 : 22, minHeight: 22),
//         padding: EdgeInsets.symmetric(horizontal: wide ? 8 : 0),
//         decoration: BoxDecoration(
//           color: Colors.red,
//           borderRadius: BorderRadius.circular(11),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.red.withOpacity(0.35),
//               blurRadius: 6,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Center(
//           child: Text(
//             label,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 12,
//               fontWeight: FontWeight.w800,
//               height: 1,
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Skeleton cards
// // ─────────────────────────────────────────────────────────────────────────────

// class _SkeletonCard extends StatelessWidget {
//   const _SkeletonCard();

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 4),
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//       ),
//       child: Row(
//         children: [
//           _SkeletonCircle(52),
//           const SizedBox(width: 14),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 _SkeletonBox(width: 140, height: 13),
//                 const SizedBox(height: 7),
//                 _SkeletonBox(width: 90, height: 10),
//               ],
//             ),
//           ),
//           _SkeletonBox(width: 24, height: 24, radius: 12),
//         ],
//       ),
//     );
//   }
// }

// class _SkeletonCircle extends StatelessWidget {
//   final double size;
//   const _SkeletonCircle(this.size);

//   @override
//   Widget build(BuildContext context) => Container(
//     width: size,
//     height: size,
//     decoration: BoxDecoration(
//       color: Colors.grey.shade200,
//       shape: BoxShape.circle,
//     ),
//   );
// }

// class _SkeletonBox extends StatelessWidget {
//   final double? width;
//   final double height;
//   final double radius;
//   const _SkeletonBox({this.width, required this.height, this.radius = 6});

//   @override
//   Widget build(BuildContext context) => Container(
//     width: width,
//     height: height,
//     decoration: BoxDecoration(
//       color: Colors.grey.shade200,
//       borderRadius: BorderRadius.circular(radius),
//     ),
//   );
// }

// class _SkeletonListSliver extends StatelessWidget {
//   const _SkeletonListSliver();
//   @override
//   Widget build(BuildContext context) {
//     return ListView.builder(
//       padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
//       itemCount: 7,
//       itemBuilder: (_, i) => const _SkeletonCard(),
//     );
//   }
// }

import 'dart:convert';
import 'dart:developer' as developer;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/models/Chat/mutual_friend_model.dart';
import 'package:innovator/Innovator/provider/mutual_friend_state.dart';
import 'package:innovator/Innovator/provider/unread_count_provider.dart';
import 'package:innovator/Innovator/screens/chatrrom/screen/chatscreen.dart';

const _kHttpBase = 'http://36.253.137.34:8005';
const Color _orange = Color.fromRGBO(244, 135, 6, 1);
const Color _orangeLight = Color.fromRGBO(244, 135, 6, 0.10);
const Color _orangeMid = Color.fromRGBO(244, 135, 6, 0.18);
const Color _green = Color(0xFF2ECC71);

// Tracks which friend IDs have actual message history (any message, read or unread).
// Populated during _fetchAllMessageInfo. Used to filter the chat list.
final friendsWithHistoryProvider = StateProvider<Set<String>>((ref) => {});

class MutualFriendsNotifier extends StateNotifier<MutualFriendsState> {
  final Ref _ref;
  bool _mounted = true;

  MutualFriendsNotifier(this._ref) : super(const MutualFriendsState()) {
    Future.microtask(() => _initWhenReady());
    fetchMutualFriends();
    _ref.listen<Map<String, int>>(perFriendUnreadProvider, (_, realtimeMap) {
      if (!_mounted) return;
      final total = state.friends.fold<int>(
        0,
        (sum, f) => sum + (realtimeMap[f.id] ?? f.unreadCount),
      );
      Future.microtask(() {
        if (!_mounted) return;
        _ref.read(chatUnreadCountProvider.notifier).state = total;
      });
    });
  }

  Future<void> _initWhenReady() async {
    if (!_mounted) return;
    int attempts = 0;
    while (attempts < 10) {
      final token = AppData().accessToken;
      if (token != null && token.isNotEmpty) {
        fetchMutualFriends();
        return;
      }
      await Future.delayed(const Duration(milliseconds: 300));
      attempts++;
    }
    if (_mounted)
      _setState(
        state.copyWith(
          isLoading: false,
          error: 'Session expired. Please log in again.',
        ),
      );
  }

  void bumpToTop(String friendId) {
    final idx = state.friends.indexWhere((f) => f.id == friendId);
    if (idx <= 0) return;
    final updated = [...state.friends];
    final friend = updated.removeAt(idx);
    updated.insert(0, friend);
    _setState(state.copyWith(friends: updated));
    // Mark as having history when bumped (message was just sent/received)
    final current = Set<String>.from(_ref.read(friendsWithHistoryProvider));
    current.add(friendId);
    _ref.read(friendsWithHistoryProvider.notifier).state = current;
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  void _setState(MutualFriendsState newState) {
    if (!_mounted) return;
    state = newState;
    Future.microtask(() {
      if (!_mounted) return;
      final realtimeMap = _ref.read(perFriendUnreadProvider);
      final combinedTotal = newState.friends.fold<int>(
        0,
        (sum, f) => sum + (realtimeMap[f.id] ?? f.unreadCount),
      );
      _ref.read(chatUnreadCountProvider.notifier).state = combinedTotal;
    });
  }

  String get _token => AppData().accessToken ?? '';
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
  };

  Future<void> fetchMutualFriends() async {
    _setState(state.copyWith(isLoading: true, error: null));
    try {
      final response = await http
          .get(
            Uri.parse('$_kHttpBase/api/users/mutual-friends/'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final count = data['mutual_friends_count'] as int? ?? 0;
        final list =
            (data['mutual_friends'] as List? ?? [])
                .whereType<Map<String, dynamic>>()
                .map(MutualFriend.fromJson)
                .toList();
        _setState(
          state.copyWith(friends: list, totalCount: count, isLoading: false),
        );
        developer.log('[ChatList] Loaded ${list.length} mutual friends');
        await _fetchAllMessageInfo(list);
      } else {
        _setState(
          state.copyWith(
            isLoading: false,
            error: 'Failed to load (${response.statusCode})',
          ),
        );
      }
    } catch (e) {
      developer.log('[ChatList] fetchMutualFriends error: $e');
      _setState(
        state.copyWith(
          isLoading: false,
          error: 'Network error. Pull to refresh.',
        ),
      );
    }
  }

  // KEY FIX: Returns both unread count AND whether ANY messages exist.
  Future<(int, bool)> _fetchMessageInfo(String senderId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_kHttpBase/api/chats/?with_user=$senderId'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final list = json.decode(response.body) as List<dynamic>;
        final msgs = list.whereType<Map<String, dynamic>>().toList();
        final unread =
            msgs
                .where(
                  (m) =>
                      m['sender']?.toString() == senderId &&
                      m['is_read'] == false,
                )
                .length;
        return (unread, msgs.isNotEmpty); // hasAnyMessage = msgs.isNotEmpty
      }
    } catch (e) {
      developer.log('[ChatList] _fetchMessageInfo($senderId) error: $e');
    }
    return (0, false);
  }

  Future<void> _fetchAllMessageInfo(List<MutualFriend> friends) async {
    final results = await Future.wait(
      friends.map((f) => _fetchMessageInfo(f.id)),
    );

    final updated = List<MutualFriend>.generate(
      friends.length,
      (i) => friends[i].copyWithUnread(results[i].$1),
    );
    final seedMap = {
      for (int i = 0; i < friends.length; i++) friends[i].id: results[i].$1,
    };
    _ref.read(perFriendUnreadProvider.notifier).seedFromHistory(seedMap);

    // Build the set of friends with any message history
    final historyIds = <String>{};
    for (int i = 0; i < friends.length; i++) {
      if (results[i].$2) historyIds.add(friends[i].id);
    }
    // Merge with existing (e.g. bumpToTop may have already added some)
    final existing = _ref.read(friendsWithHistoryProvider);
    _ref.read(friendsWithHistoryProvider.notifier).state = {
      ...existing,
      ...historyIds,
    };

    _setState(state.copyWith(friends: updated));
  }

  void clearUnread(String friendId) {
    final updated =
        state.friends
            .map((f) => f.id == friendId ? f.copyWithUnread(0) : f)
            .toList();
    _setState(state.copyWith(friends: updated));
    _ref.read(perFriendUnreadProvider.notifier).reset(friendId);
  }

  Future<bool> deleteConversation(String friendId) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_kHttpBase/api/chats/delete-conversation/'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
            },
            body: json.encode({'with_user': friendId}),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final updated = state.friends.where((f) => f.id != friendId).toList();
        _setState(state.copyWith(friends: updated));
        // Remove from history
        final current = Set<String>.from(_ref.read(friendsWithHistoryProvider));
        current.remove(friendId);
        _ref.read(friendsWithHistoryProvider.notifier).state = current;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void refresh() => fetchMutualFriends();
}

final mutualFriendsProvider =
    StateNotifierProvider<MutualFriendsNotifier, MutualFriendsState>(
      (ref) => MutualFriendsNotifier(ref),
    );
final chatUnreadCountProvider = StateProvider<int>((ref) => 0);

// =============================================================================
// ChatListScreen
// =============================================================================

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key});
  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final friendId = ref.read(lastActiveFriendProvider);
      if (friendId != null) {
        ref.read(mutualFriendsProvider.notifier).bumpToTop(friendId);
        ref.read(lastActiveFriendProvider.notifier).state = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mutualFriendsProvider);
    final realtimeUnread = ref.watch(perFriendUnreadProvider);
    final activity = ref.watch(friendActivityProvider);
    final historyIds = ref.watch(friendsWithHistoryProvider);

    final sortedFriends =
        state.friends.map((f) {
            final t = activity[f.id];
            return (t != null) ? f.copyWithLastMessageAt(t) : f;
          }).toList()
          ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

    final activeNow = sortedFriends.where((f) => f.onlineStatus).toList();

    // Chat list: only friends with confirmed message history OR live unread
    final chatFriends =
        sortedFriends.where((f) {
          return historyIds.contains(f.id) || (realtimeUnread[f.id] ?? 0) > 0;
        }).toList();

    // Are we still fetching history counts? (friends loaded but historyIds empty and no error)
    final stillFetchingHistory =
        !state.isLoading &&
        state.friends.isNotEmpty &&
        historyIds.isEmpty &&
        state.error == null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: RefreshIndicator(
        onRefresh:
            () async => ref.read(mutualFriendsProvider.notifier).refresh(),
        color: _orange,
        child: CustomScrollView(
          slivers: [
            // ── App Bar
            SliverAppBar(
              pinned: true,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                color: Colors.black87,
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text(
                'Messages',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: -0.5,
                ),
              ),
              centerTitle: true,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: Colors.grey.shade100),
              ),
            ),

            // ── Active Now strip
            if (activeNow.isNotEmpty)
              SliverToBoxAdapter(
                child: _ActiveNowStrip(
                  friends: activeNow,
                  onTap: (f) => _openChat(context, ref, f),
                ),
              ),

            // ── Initial full-screen loading
            if (state.isLoading && state.friends.isEmpty)
              const SliverFillRemaining(child: _SkeletonListSliver()),

            // ── Error
            if (state.error != null && state.friends.isEmpty)
              SliverFillRemaining(child: _buildError(ref, state.error!)),

            // ── Chat list
            if (chatFriends.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
                  child: Row(
                    children: [
                      const Text(
                        'Messages',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.black54,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _orangeMid,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${chatFriends.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: _orange,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final f = chatFriends[i];
                    return _ChatCard(
                      friend: f,
                      isOnline: f.onlineStatus,
                      realtimeUnreadCount: realtimeUnread[f.id] ?? 0,
                      onTap: () => _openChat(context, ref, f),
                      onDelete:
                          () => ref
                              .read(mutualFriendsProvider.notifier)
                              .deleteConversation(f.id),
                    );
                  }, childCount: chatFriends.length),
                ),
              ),
            ],

            // ── Skeleton while history counts are being fetched (not a full loading state)
            if (stillFetchingHistory)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 20, 14, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: _SkeletonCard(),
                    ),
                    childCount: 4,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildError(WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                color: Colors.red.shade300,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed:
                  () => ref.read(mutualFriendsProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChat(BuildContext context, WidgetRef ref, MutualFriend friend) {
    ref.read(mutualFriendsProvider.notifier).clearUnread(friend.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ChatScreen(
              otherUserId: friend.id,
              otherUserName: friend.displayName,
              otherUserAvatar: friend.avatar,
              isOnline: friend.onlineStatus,
            ),
      ),
    ).then((_) {
      if (context.mounted) {
        final lastFriend = ref.read(lastActiveFriendProvider);
        if (lastFriend != null) {
          ref.read(mutualFriendsProvider.notifier).bumpToTop(lastFriend);
          ref.read(lastActiveFriendProvider.notifier).state = null;
        }
      }
    });
  }
}

// =============================================================================
// Active Now Strip
// =============================================================================

class _ActiveNowStrip extends StatelessWidget {
  final List<MutualFriend> friends;
  final void Function(MutualFriend) onTap;
  const _ActiveNowStrip({required this.friends, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _green.withOpacity(0.45),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                'Active Now',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${friends.length}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _green,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 96,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: friends.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder:
                (_, i) => _ActiveNowItem(
                  friend: friends[i],
                  onTap: () => onTap(friends[i]),
                ),
          ),
        ),
        const SizedBox(height: 6),
        Divider(color: Colors.grey.shade100, thickness: 1, height: 1),
      ],
    );
  }
}

class _ActiveNowItem extends StatelessWidget {
  final MutualFriend friend;
  final VoidCallback onTap;
  const _ActiveNowItem({required this.friend, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _OnlineAvatar(friend: friend, size: 58),
            const SizedBox(height: 5),
            Text(
              friend.displayName.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnlineAvatar extends StatefulWidget {
  final MutualFriend friend;
  final double size;
  const _OnlineAvatar({required this.friend, required this.size});
  @override
  State<_OnlineAvatar> createState() => _OnlineAvatarState();
}

class _OnlineAvatarState extends State<_OnlineAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulse = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotSize = widget.size * 0.22;
    return ScaleTransition(
      scale: _pulse,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: widget.size,
            height: widget.size,
            padding: const EdgeInsets.all(2.5),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [_orange, Color(0xFFFFCC00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: ClipOval(
              child:
                  widget.friend.avatar.isNotEmpty
                      ? CachedNetworkImage(
                        imageUrl: widget.friend.avatar,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _ph(),
                        errorWidget: (_, __, ___) => _ph(),
                      )
                      : _ph(),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: _green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _green.withOpacity(0.5),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ph() => Container(
    color: _orangeLight,
    child: Center(
      child: Text(
        widget.friend.initial,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: _orange,
          fontSize: widget.size * 0.35,
        ),
      ),
    ),
  );
}

// =============================================================================
// _ChatCard
// =============================================================================

class _ChatCard extends StatelessWidget {
  final MutualFriend friend;
  final bool isOnline;
  final VoidCallback onTap;
  final Future<bool> Function() onDelete;
  final int realtimeUnreadCount;

  const _ChatCard({
    required this.friend,
    required this.isOnline,
    required this.onTap,
    required this.onDelete,
    this.realtimeUnreadCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final displayUnread =
        realtimeUnreadCount > friend.unreadCount
            ? realtimeUnreadCount
            : friend.unreadCount;
    final hasUnread = displayUnread > 0;

    return Dismissible(
      key: ValueKey('chat_card_${friend.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => await _showDeleteDialog(context),
      onDismissed: (_) async {
        final success = await onDelete();
        if (!success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to delete conversation'),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.shade500,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 26),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: hasUnread ? const Color(0xFFFFF8F0) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border:
              hasUnread
                  ? Border.all(color: _orange.withAlpha(25), width: 1)
                  : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTap,
            onLongPress: () => _showLongPressMenu(context),
            splashColor: const Color.fromRGBO(244, 135, 6, 0.08),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient:
                              isOnline
                                  ? const LinearGradient(
                                    colors: [_orange, Color(0xFFFFCC00)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                  : null,
                          color: isOnline ? null : Colors.grey.shade200,
                        ),
                        child: ClipOval(
                          child:
                              friend.avatar.isNotEmpty
                                  ? CachedNetworkImage(
                                    imageUrl: friend.avatar,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => _avatarPh(),
                                    errorWidget: (_, __, ___) => _avatarPh(),
                                  )
                                  : _avatarPh(),
                        ),
                      ),
                      if (isOnline)
                        Positioned(
                          bottom: 1,
                          right: 1,
                          child: Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              color: _green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: _green.withOpacity(0.4),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          friend.displayName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                hasUnread ? FontWeight.w800 : FontWeight.w700,
                            color: Colors.black87,
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              '@${friend.username}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            if (isOnline) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: const BoxDecoration(
                                  color: _green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (hasUnread)
                    _UnreadBadge(count: displayUnread)
                  else if (isOnline)
                    const Text(
                      'Active now',
                      style: TextStyle(
                        fontSize: 12,
                        color: _green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _showDeleteDialog(BuildContext context) async {
    return await showDialog<bool>(
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
                        Icons.delete_outline_rounded,
                        color: Colors.red.shade600,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Delete Conversation',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  'Delete your conversation with ${friend.displayName}? This cannot be undone.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
        ) ??
        false;
  }

  void _showLongPressMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (_) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      ClipOval(
                        child:
                            friend.avatar.isNotEmpty
                                ? CachedNetworkImage(
                                  imageUrl: friend.avatar,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                )
                                : Container(
                                  width: 40,
                                  height: 40,
                                  color: _orangeLight,
                                  child: Center(
                                    child: Text(
                                      friend.initial,
                                      style: const TextStyle(
                                        color: _orange,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        friend.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.red.shade600,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Delete Conversation',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Remove this chat for you',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    final c = await _showDeleteDialog(context);
                    if (c) await onDelete();
                  },
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Widget _avatarPh() => Container(
    color: _orangeLight,
    child: Center(
      child: Text(
        friend.initial,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: _orange,
          fontSize: 18,
        ),
      ),
    ),
  );
}

class _UnreadBadge extends StatefulWidget {
  final int count;
  const _UnreadBadge({required this.count});
  @override
  State<_UnreadBadge> createState() => _UnreadBadgeState();
}

class _UnreadBadgeState extends State<_UnreadBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.count > 99 ? '99+' : '${widget.count}';
    final wide = widget.count > 9;
    return ScaleTransition(
      scale: _scale,
      child: Container(
        constraints: BoxConstraints(minWidth: wide ? 32 : 22, minHeight: 22),
        padding: EdgeInsets.symmetric(horizontal: wide ? 8 : 0),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(11),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.35),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonListSliver extends StatelessWidget {
  const _SkeletonListSliver();
  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
    itemCount: 7,
    itemBuilder: (_, i) => const _SkeletonCard(),
  );
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(vertical: 4),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        _SkeletonCircle(52),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SkeletonBox(width: 140, height: 13),
              const SizedBox(height: 7),
              _SkeletonBox(width: 90, height: 10),
            ],
          ),
        ),
        _SkeletonBox(width: 24, height: 24, radius: 12),
      ],
    ),
  );
}

class _SkeletonCircle extends StatelessWidget {
  final double size;
  const _SkeletonCircle(this.size);
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      shape: BoxShape.circle,
    ),
  );
}

class _SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const _SkeletonBox({this.width, required this.height, this.radius = 6});
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}
