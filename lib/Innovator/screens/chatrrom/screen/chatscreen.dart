// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer' as developer;
// import 'dart:io';

// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:innovator/Innovator/App_data/App_data.dart';
// import 'package:http/http.dart' as http;
// import 'package:innovator/Innovator/models/Chat/chat_model.dart';
// import 'package:innovator/Innovator/provider/chat_state.dart';
// import 'package:innovator/Innovator/provider/global_chat_listener.dart';
// import 'package:innovator/Innovator/provider/unread_count_provider.dart';
// import 'package:innovator/Innovator/screens/SHow_Specific_Profile/Show_Specific_Profile.dart';
// import 'package:innovator/Innovator/screens/chatrrom/screen/chatlistscreen.dart';
// import 'package:innovator/Innovator/screens/chatrrom/sound/soundplayer.dart';
// import 'package:web_socket_channel/io.dart';
// import 'package:web_socket_channel/web_socket_channel.dart';

// // ─────────────────────────────────────────────────────────────────────────────
// // Theme constants
// // ─────────────────────────────────────────────────────────────────────────────

// const _kOrange = Color.fromRGBO(244, 135, 6, 1);
// const _kOrangeLight = Color.fromRGBO(244, 135, 6, 0.12);
// const _kBg = Color(0xFFF5F6FA);
// const _kReceivedBubble = Color(0xFFFFFFFF);
// const _kBaseUrl = 'ws://36.253.137.34:8005';
// const _kHttpBase = 'http://36.253.137.34:8005';

// String _inferAttachmentType(String url) {
//   final lower = url.toLowerCase();
//   if (lower.endsWith('.jpg') ||
//       lower.endsWith('.jpeg') ||
//       lower.endsWith('.png') ||
//       lower.endsWith('.gif') ||
//       lower.endsWith('.webp'))
//     return 'image';
//   if (lower.endsWith('.mp4') ||
//       lower.endsWith('.mov') ||
//       lower.endsWith('.avi'))
//     return 'video';
//   return 'file';
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // ChatNotifier  — FIX 1: offline message queue
// // ─────────────────────────────────────────────────────────────────────────────

// class ChatNotifier extends StateNotifier<ChatState> {
//   final String otherUserId;
//   final Ref _ref;

//   ChatNotifier(this.otherUserId, this._ref) : super(const ChatState()) {
//     _init();
//   }

//   WebSocketChannel? _channel;
//   StreamSubscription? _sub;
//   Timer? _reconnectTimer;
//   int _reconnectAttempts = 0;
//   static const _maxReconnects = 99; // keep retrying forever silently

//   /// ── FIX 1: offline queue ─────────────────────────────────────────────────
//   final List<Map<String, dynamic>> _pendingQueue = [];

//   String get _myId => AppData().currentUserId ?? '';
//   String get _token => AppData().accessToken ?? '';

//   Map<String, String> get _authHeaders => {
//     'Content-Type': 'application/json',
//     'Accept': 'application/json',
//     if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
//   };

//   Future<void> _init() async {
//     await _fetchHistory();
//     _connect();
//   }

//   Future<void> _fetchHistory() async {
//     if (_token.isEmpty) return;
//     state = state.copyWith(isLoadingHistory: true, error: null);
//     try {
//       final uri = Uri.parse('$_kHttpBase/api/chats/?with_user=$otherUserId');
//       final response = await http
//           .get(uri, headers: _authHeaders)
//           .timeout(const Duration(seconds: 15));
//       if (response.statusCode == 200) {
//         final list = json.decode(response.body) as List<dynamic>;
//         final messages =
//             list
//                 .whereType<Map<String, dynamic>>()
//                 .map((m) => ChatMessage.fromHistory(m, _myId))
//                 .toList();
//         state = state.copyWith(messages: messages, isLoadingHistory: false);
//       } else {
//         state = state.copyWith(isLoadingHistory: false);
//       }
//     } catch (e) {
//       state = state.copyWith(isLoadingHistory: false);
//     }
//   }

//   void _markAsRead() {
//     if (state.wsStatus != WsStatus.connected) return;
//     try {
//       _channel!.sink.add(json.encode({'type': 'mark_as_read'}));
//       _ref.read(perFriendUnreadProvider.notifier).reset(otherUserId);
//     } catch (_) {}
//   }

//   void markAsRead() => _markAsRead();

//   Future<void> refresh() async {
//     await _fetchHistory();
//     _markAsRead();
//   }

//   void setReply(ChatMessage msg) => state = state.copyWith(replyingTo: msg);
//   void clearReply() => state = state.copyWith(clearReply: true);

//   void _connect() {
//     if (_token.isEmpty || otherUserId.isEmpty) return;

//     // ── FIX 1: Don't update wsStatus to show UI banner ─────────────────────
//     // We connect silently — no "Reconnecting…" banner.
//     developer.log('[WS] Connecting to $otherUserId...');

//     try {
//       final uri = Uri.parse('$_kBaseUrl/ws/chat/$otherUserId/?token=$_token');
//       _channel = IOWebSocketChannel.connect(
//         uri,
//         pingInterval: const Duration(seconds: 20),
//       );

//       // Mark connected ONLY internally; don't surface errors to UI
//       state = state.copyWith(wsStatus: WsStatus.connected, error: null);
//       _reconnectAttempts = 0;
//       developer.log('[WS] Connected ✓');
//       _markAsRead();

//       // Flush any queued messages
//       _flushQueue();

//       _sub = _channel!.stream.listen(
//         _onMessage,
//         onError: (_) => _onDone(),
//         onDone: _onDone,
//         cancelOnError: false,
//       );
//     } catch (e) {
//       developer.log('[WS] Connect error: $e');
//       // Silently schedule reconnect — no UI state change
//       state = state.copyWith(wsStatus: WsStatus.disconnected);
//       _scheduleReconnect();
//     }
//   }

//   /// Flush queued messages once WS is back online
//   void _flushQueue() {
//     if (_pendingQueue.isEmpty) return;
//     final copy = List<Map<String, dynamic>>.from(_pendingQueue);
//     _pendingQueue.clear();
//     for (final payload in copy) {
//       try {
//         _channel!.sink.add(json.encode(payload));
//         developer.log('[WS] Flushed queued message');
//       } catch (e) {
//         _pendingQueue.insert(0, payload); // put back on failure
//         break;
//       }
//     }
//   }

//   void _onMessage(dynamic raw) {
//     try {
//       final data = json.decode(raw.toString()) as Map<String, dynamic>;

//       if (data['type'] == 'messages_read') {
//         final senderId = data['sender_id']?.toString() ?? '';
//         if (senderId == otherUserId) {
//           final updated =
//               state.messages.map((m) {
//                 if (m.isMine && m.status != MessageStatus.read) {
//                   return ChatMessage(
//                     id: m.id,
//                     text: m.text,
//                     isMine: true,
//                     timestamp: m.timestamp,
//                     status: MessageStatus.read,
//                     parentId: m.parentId,
//                     repliedToText: m.repliedToText,
//                     repliedToSenderName: m.repliedToSenderName,
//                     attachmentUrl: m.attachmentUrl,
//                     attachmentType: m.attachmentType,
//                   );
//                 }
//                 return m;
//               }).toList();
//           state = state.copyWith(messages: updated);
//         }
//         return;
//       }

//       if (data['type'] == 'typing') {
//         state = state.copyWith(isTyping: data['is_typing'] == true);
//         return;
//       }

//       final msgText =
//           data['message']?.toString() ??
//           data['content']?.toString() ??
//           data['text']?.toString() ??
//           '';
//       final attachmentUrl = data['attachment']?.toString();
//       final hasContent =
//           msgText.isNotEmpty ||
//           (attachmentUrl != null && attachmentUrl.isNotEmpty);
//       if (!hasContent) return;

//       final senderId =
//           data['sender']?.toString() ??
//           data['sender_id']?.toString() ??
//           data['from']?.toString() ??
//           '';
//       final isMine = senderId == _myId;
//       final serverId = data['id']?.toString();

//       if (!isMine && senderId != otherUserId) return;
//       if (serverId != null && state.messages.any((m) => m.id == serverId)) {
//         return;
//       }

//       if (isMine) {
//         final tempIndex = state.messages.lastIndexWhere(
//           (m) =>
//               m.isMine &&
//               m.id.startsWith('temp_') &&
//               (m.text == msgText ||
//                   (msgText.isEmpty && m.attachmentUrl != null)),
//         );
//         if (tempIndex != -1) {
//           final updated = [...state.messages];
//           final old = updated[tempIndex];
//           updated[tempIndex] = ChatMessage(
//             id: serverId ?? old.id,
//             text: msgText,
//             isMine: true,
//             timestamp:
//                 data['timestamp'] != null
//                     ? DateTime.tryParse(data['timestamp'].toString()) ??
//                         DateTime.now()
//                     : DateTime.now(),
//             status: MessageStatus.delivered,
//             parentId: old.parentId,
//             repliedToText: old.repliedToText,
//             repliedToSenderName: old.repliedToSenderName,
//             attachmentUrl:
//                 attachmentUrl?.isNotEmpty == true
//                     ? attachmentUrl
//                     : old.attachmentUrl,
//             attachmentType: old.attachmentType,
//           );
//           state = state.copyWith(messages: updated, isTyping: false);
//           return;
//         }
//       }

//       final msg = ChatMessage.fromWs(data, _myId);
//       state = state.copyWith(
//         messages: [...state.messages, msg],
//         isTyping: false,
//       );

//       if (!isMine) {
//         SoundPlayer().playsendreceivesound();
//         _ref.read(friendActivityProvider.notifier).markActivity(otherUserId);
//         _markAsRead();
//         _ref.read(mutualFriendsProvider.notifier).bumpToTop(otherUserId);
//         _ref.read(lastActiveFriendProvider.notifier).state = otherUserId;
//       }
//     } catch (e) {
//       developer.log('[WS] Parse error: $e');
//     }
//   }

//   void _onDone() {
//     developer.log('[WS] Connection closed — scheduling silent reconnect');
//     state = state.copyWith(wsStatus: WsStatus.disconnected);
//     _scheduleReconnect();
//   }

//   void _scheduleReconnect() {
//     _subs?.cancel();
//     _channels?.sink.close();
//     _reconnectAttempts++;
//     // Exponential backoff capped at 30 s, but never give up
//     final delay = Duration(seconds: (_reconnectAttempts * 2).clamp(2, 30));
//     developer.log('[WS] Reconnecting in ${delay.inSeconds}s...');
//     _reconnectTimer?.cancel();
//     _reconnectTimer = Timer(delay, _connect);
//   }

//   // ignore unused field warnings from renaming
//   WebSocketChannel? get _channels => _channel;
//   StreamSubscription? get _subs => _sub;

//   // ── Send text — queue if offline ──────────────────────────────────────────
//   void sendMessage(String text) {
//     if (text.trim().isEmpty) return;

//     final replyingTo = state.replyingTo;
//     final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
//     final mine = ChatMessage(
//       id: tempId,
//       text: text.trim(),
//       isMine: true,
//       timestamp: DateTime.now(),
//       status: MessageStatus.sending,
//       parentId: replyingTo?.id,
//       repliedToText: replyingTo?.text,
//       repliedToSenderName:
//           replyingTo == null
//               ? null
//               : (replyingTo.isMine ? 'You' : replyingTo.repliedToSenderName),
//     );

//     state = state.copyWith(
//       messages: [...state.messages, mine],
//       isSending: true,
//       clearReply: true,
//     );

//     final payload = <String, dynamic>{'message': text.trim()};
//     if (replyingTo != null) {
//       payload['type'] = 'reply';
//       payload['parent_id'] = replyingTo.id;
//     }

//     if (state.wsStatus == WsStatus.connected) {
//       try {
//         _channel!.sink.add(json.encode(payload));
//         _ref.read(friendActivityProvider.notifier).markActivity(otherUserId);
//         _ref.read(lastActiveFriendProvider.notifier).state = otherUserId;
//         _ref.read(mutualFriendsProvider.notifier).bumpToTop(otherUserId);
//         final updated =
//             state.messages.map((m) {
//               if (m.id == tempId) m.status = MessageStatus.sent;
//               return m;
//             }).toList();
//         state = state.copyWith(messages: updated, isSending: false);
//       } catch (e) {
//         // ── FIX 1: queue instead of fail ─────────────────────────────────
//         developer.log('[WS] Send failed, queuing message');
//         _pendingQueue.add(payload);
//         final updated =
//             state.messages.map((m) {
//               if (m.id == tempId)
//                 m.status = MessageStatus.sending; // keep pending
//               return m;
//             }).toList();
//         state = state.copyWith(messages: updated, isSending: false);
//         _scheduleReconnect();
//       }
//     } else {
//       // ── FIX 1: offline — add to queue silently ──────────────────────────
//       developer.log('[WS] Offline, queuing message');
//       _pendingQueue.add(payload);
//       final updated =
//           state.messages.map((m) {
//             if (m.id == tempId) m.status = MessageStatus.sending;
//             return m;
//           }).toList();
//       state = state.copyWith(messages: updated, isSending: false);
//       // Make sure reconnect is in progress
//       if (_reconnectTimer == null || !_reconnectTimer!.isActive) {
//         _connect();
//       }
//     }
//   }

//   Future<void> sendAttachment(File file) async {
//     if (_token.isEmpty) return;
//     final tempId = 'temp_att_${DateTime.now().millisecondsSinceEpoch}';
//     final attachmentType = _inferAttachmentType(file.path);
//     final tempMsg = ChatMessage(
//       id: tempId,
//       text: '',
//       isMine: true,
//       timestamp: DateTime.now(),
//       status: MessageStatus.sending,
//       attachmentUrl: file.path,
//       attachmentType: attachmentType,
//     );
//     state = state.copyWith(
//       messages: [...state.messages, tempMsg],
//       isSending: true,
//     );
//     try {
//       final uri = Uri.parse('$_kHttpBase/api/chats/');
//       final request =
//           http.MultipartRequest('POST', uri)
//             ..headers['Authorization'] = 'Bearer $_token'
//             ..fields['receiver'] = otherUserId
//             ..files.add(
//               await http.MultipartFile.fromPath('attachment', file.path),
//             );
//       final streamed = await request.send().timeout(
//         const Duration(seconds: 30),
//       );
//       final response = await http.Response.fromStream(streamed);
//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final data = json.decode(response.body) as Map<String, dynamic>;
//         final serverId = data['id']?.toString() ?? tempId;
//         final serverUrl = data['attachment']?.toString() ?? file.path;
//         final updated =
//             state.messages.map((m) {
//               if (m.id == tempId) {
//                 return ChatMessage(
//                   id: serverId,
//                   text: data['message']?.toString() ?? '',
//                   isMine: true,
//                   timestamp: DateTime.now(),
//                   status: MessageStatus.delivered,
//                   attachmentUrl: serverUrl,
//                   attachmentType: attachmentType,
//                 );
//               }
//               return m;
//             }).toList();
//         state = state.copyWith(messages: updated, isSending: false);
//         _ref.read(friendActivityProvider.notifier).markActivity(otherUserId);
//         _ref.read(lastActiveFriendProvider.notifier).state = otherUserId;
//         _ref.read(mutualFriendsProvider.notifier).bumpToTop(otherUserId);
//       } else {
//         _markAttachmentFailed(tempId);
//       }
//     } catch (e) {
//       _markAttachmentFailed(tempId);
//     }
//   }

//   void _markAttachmentFailed(String tempId) {
//     final updated =
//         state.messages.map((m) {
//           if (m.id == tempId) m.status = MessageStatus.failed;
//           return m;
//         }).toList();
//     state = state.copyWith(messages: updated, isSending: false);
//   }

//   void sendTyping(bool isTyping) {
//     if (state.wsStatus != WsStatus.connected) return;
//     try {
//       _channel!.sink.add(
//         json.encode({'type': 'typing', 'is_typing': isTyping}),
//       );
//     } catch (_) {}
//   }

//   Future<bool> deleteMessage({
//     required String messageId,
//     required String deleteType,
//   }) async {
//     try {
//       final uri = Uri.parse('$_kHttpBase/api/chats/$messageId/delete-message/');
//       final response = await http
//           .post(
//             uri,
//             headers: _authHeaders,
//             body: json.encode({'delete_type': deleteType}),
//           )
//           .timeout(const Duration(seconds: 10));
//       if (response.statusCode == 200) {
//         final updated = state.messages.where((m) => m.id != messageId).toList();
//         state = state.copyWith(messages: updated);
//         return true;
//       }
//       return false;
//     } catch (e) {
//       return false;
//     }
//   }

//   void reconnect() {
//     _reconnectAttempts = 0;
//     _connect();
//   }

//   @override
//   void dispose() {
//     _reconnectTimer?.cancel();
//     _sub?.cancel();
//     _channel?.sink.close();
//     super.dispose();
//   }
// }

// final chatProvider =
//     AutoDisposeStateNotifierProviderFamily<ChatNotifier, ChatState, String>(
//       (ref, otherUserId) => ChatNotifier(otherUserId, ref),
//     );

// // ─────────────────────────────────────────────────────────────────────────────
// // ChatScreen
// // ─────────────────────────────────────────────────────────────────────────────

// class ChatScreen extends ConsumerStatefulWidget {
//   final String otherUserId;
//   final String otherUserName;
//   final String otherUserAvatar;
//   final bool isOnline;

//   const ChatScreen({
//     super.key,
//     required this.otherUserId,
//     required this.otherUserName,
//     required this.otherUserAvatar,
//     this.isOnline = false,
//   });

//   @override
//   ConsumerState<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends ConsumerState<ChatScreen>
//     with WidgetsBindingObserver {
//   final TextEditingController _inputCtrl = TextEditingController();
//   final ScrollController _scrollCtrl = ScrollController();
//   final FocusNode _focusNode = FocusNode();
//   bool _isComposing = false;
//   Timer? _typingTimer;
//   late final GlobalChatListener _globalListener;
//   final ImagePicker _picker = ImagePicker();

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _inputCtrl.addListener(_onInputChanged);
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _globalListener = ref.read(globalChatListenerProvider);
//       _globalListener.activeChatUserId = widget.otherUserId;
//       ref.read(activeChatUserIdProvider.notifier).state = widget.otherUserId;
//     });
//   }

//   @override
//   void dispose() {
//     _globalListener.activeChatUserId = null;
//     WidgetsBinding.instance.removeObserver(this);
//     _inputCtrl.removeListener(_onInputChanged);
//     _inputCtrl.dispose();
//     _scrollCtrl.dispose();
//     _focusNode.dispose();
//     _typingTimer?.cancel();
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.resumed) {
//       ref.read(chatProvider(widget.otherUserId).notifier).markAsRead();
//     }
//   }

//   void _onInputChanged() {
//     final composing = _inputCtrl.text.trim().isNotEmpty;
//     if (composing != _isComposing) setState(() => _isComposing = composing);
//     ref.read(chatProvider(widget.otherUserId).notifier).sendTyping(composing);
//     _typingTimer?.cancel();
//     if (composing) {
//       _typingTimer = Timer(const Duration(seconds: 3), () {
//         ref.read(chatProvider(widget.otherUserId).notifier).sendTyping(false);
//       });
//     }
//   }

//   void _scrollToBottom({bool animated = false}) {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!mounted || !_scrollCtrl.hasClients) return;
//       if (animated) {
//         _scrollCtrl.animateTo(
//           _scrollCtrl.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       } else {
//         _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
//       }
//     });
//   }

//   void _sendMessage() {
//     SoundPlayer().playsendreceivesound();
//     final text = _inputCtrl.text.trim();
//     if (text.isEmpty) return;
//     HapticFeedback.lightImpact();
//     ref.read(chatProvider(widget.otherUserId).notifier).sendMessage(text);
//     _inputCtrl.clear();
//     setState(() => _isComposing = false);
//     _scrollToBottom();
//   }

//   void _showAttachmentOptions() {
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
//                 Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 20,
//                     vertical: 8,
//                   ),
//                   child: Row(
//                     children: [
//                       _AttachOption(
//                         icon: Icons.photo_library_rounded,
//                         label: 'Gallery',
//                         color: _kOrange,
//                         onTap: () {
//                           Navigator.pop(context);
//                           _pickImage(ImageSource.gallery);
//                         },
//                       ),
//                       const SizedBox(width: 16),
//                       _AttachOption(
//                         icon: Icons.camera_alt_rounded,
//                         label: 'Camera',
//                         color: const Color(0xFF2ECC71),
//                         onTap: () {
//                           Navigator.pop(context);
//                           _pickImage(ImageSource.camera);
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 20),
//               ],
//             ),
//           ),
//     );
//   }

//   Future<void> _pickImage(ImageSource source) async {
//     try {
//       final picked = await _picker.pickImage(
//         source: source,
//         imageQuality: 85,
//         maxWidth: 1920,
//         maxHeight: 1920,
//       );
//       if (picked == null) return;
//       if (!mounted) return;
//       HapticFeedback.lightImpact();
//       await ref
//           .read(chatProvider(widget.otherUserId).notifier)
//           .sendAttachment(File(picked.path));
//       _scrollToBottom(animated: true);
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: const Text('Could not pick image'),
//             backgroundColor: Colors.red.shade600,
//             behavior: SnackBarBehavior.floating,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//         );
//       }
//     }
//   }

//   void _triggerReply(ChatMessage msg) {
//     ref.read(chatProvider(widget.otherUserId).notifier).setReply(msg);
//     _focusNode.requestFocus();
//   }

//   // ── Build ──────────────────────────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     final state = ref.watch(chatProvider(widget.otherUserId));

//     ref.listen<ChatState>(chatProvider(widget.otherUserId), (prev, next) {
//       if ((prev?.messages.length ?? 0) < next.messages.length) {
//         _scrollToBottom(animated: true);
//       }
//       if ((prev?.isLoadingHistory ?? false) && !next.isLoadingHistory) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           WidgetsBinding.instance.addPostFrameCallback((_) {
//             if (!mounted || !_scrollCtrl.hasClients) return;
//             _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
//           });
//         });
//       }
//     });

//     return Scaffold(
//       backgroundColor: _kBg,
//       appBar: _buildAppBar(state),
//       body: Column(
//         children: [
//           // ── FIX 1: NO status banner at all — connection is fully silent ──
//           Expanded(child: _buildMessageList(state)),
//           if (state.isTyping) _buildTypingIndicator(),
//           if (state.replyingTo != null) _buildReplyBanner(state.replyingTo!),
//           _buildInputBar(),
//         ],
//       ),
//     );
//   }

//   // ── Reply banner (above input bar) ────────────────────────────────────────

//   Widget _buildReplyBanner(ChatMessage replyingTo) {
//     final senderLabel = replyingTo.isMine ? 'You' : widget.otherUserName;
//     final previewText =
//         replyingTo.hasAttachment && replyingTo.text.isEmpty
//             ? '📎 Attachment'
//             : replyingTo.text;
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         border: Border(
//           top: BorderSide(color: Colors.grey.shade200),
//           left: const BorderSide(color: _kOrange, width: 3),
//         ),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   'Replying to $senderLabel',
//                   style: const TextStyle(
//                     fontSize: 12,
//                     color: _kOrange,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//                 const SizedBox(height: 2),
//                 Text(
//                   previewText,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
//                 ),
//               ],
//             ),
//           ),
//           GestureDetector(
//             onTap:
//                 () =>
//                     ref
//                         .read(chatProvider(widget.otherUserId).notifier)
//                         .clearReply(),
//             child: Container(
//               padding: const EdgeInsets.all(4),
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade200,
//                 shape: BoxShape.circle,
//               ),
//               child: const Icon(
//                 Icons.close_rounded,
//                 size: 16,
//                 color: Colors.black54,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── AppBar ─────────────────────────────────────────────────────────────────

//   PreferredSizeWidget _buildAppBar(ChatState state) {
//     return AppBar(
//       backgroundColor: Colors.white,
//       surfaceTintColor: Colors.white,
//       elevation: 0,
//       shadowColor: Colors.black12,
//       leading: IconButton(
//         icon: const Icon(
//           Icons.arrow_back_ios_new_rounded,
//           size: 20,
//           color: Colors.black87,
//         ),
//         onPressed: () => Navigator.of(context).pop(),
//       ),
//       titleSpacing: 0,
//       title: GestureDetector(
//         onTap:
//             () => Navigator.push(
//               context,
//               MaterialPageRoute(
//                 builder:
//                     (context) =>
//                         SpecificUserProfilePage(userId: widget.otherUserId),
//               ),
//             ),
//         child: Row(
//           children: [
//             Stack(
//               children: [
//                 Container(
//                   width: 42,
//                   height: 42,
//                   decoration: const BoxDecoration(
//                     shape: BoxShape.circle,
//                     gradient: LinearGradient(
//                       colors: [_kOrange, Color(0xFFFFCC00)],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                   ),
//                   padding: const EdgeInsets.all(2),
//                   child: ClipOval(
//                     child:
//                         widget.otherUserAvatar.isNotEmpty
//                             ? CachedNetworkImage(
//                               imageUrl: widget.otherUserAvatar,
//                               fit: BoxFit.cover,
//                               errorWidget: (_, __, ___) => _avatarFallback(),
//                             )
//                             : _avatarFallback(),
//                   ),
//                 ),
//                 if (widget.isOnline)
//                   Positioned(
//                     bottom: 1,
//                     right: 1,
//                     child: Container(
//                       width: 11,
//                       height: 11,
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF2ECC71),
//                         shape: BoxShape.circle,
//                         border: Border.all(color: Colors.white, width: 2),
//                       ),
//                     ),
//                   ),
//               ],
//             ),
//             const SizedBox(width: 10),
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   widget.otherUserName,
//                   style: const TextStyle(
//                     fontSize: 15,
//                     fontWeight: FontWeight.w700,
//                     color: Colors.black87,
//                     letterSpacing: -0.2,
//                   ),
//                 ),
//                 // ── FIX 1: Always show "Active now" / "Online" — no "Reconnecting" ──
//                 Text(
//                   widget.isOnline ? 'Active now' : 'Online',
//                   style: const TextStyle(
//                     fontSize: 12,
//                     color: Color(0xFF2ECC71),
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//       bottom: PreferredSize(
//         preferredSize: const Size.fromHeight(1),
//         child: Container(height: 1, color: Colors.grey.shade100),
//       ),
//     );
//   }

//   Widget _avatarFallback() {
//     final initial =
//         widget.otherUserName.isNotEmpty
//             ? widget.otherUserName[0].toUpperCase()
//             : '?';
//     return Container(
//       color: _kOrangeLight,
//       child: Center(
//         child: Text(
//           initial,
//           style: const TextStyle(
//             fontWeight: FontWeight.bold,
//             color: _kOrange,
//             fontSize: 16,
//           ),
//         ),
//       ),
//     );
//   }

//   // ── Message list ───────────────────────────────────────────────────────────

//   Widget _buildMessageList(ChatState state) {
//     if (state.isLoadingHistory) return _buildHistorySkeleton();
//     if (state.messages.isEmpty) return _buildEmptyState();

//     return RefreshIndicator(
//       onRefresh:
//           () => ref.read(chatProvider(widget.otherUserId).notifier).refresh(),
//       color: _kOrange,
//       child: ListView.builder(
//         controller: _scrollCtrl,
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//         itemCount: state.messages.length,
//         itemBuilder: (context, i) {
//           final msg = state.messages[i];
//           final prev = i > 0 ? state.messages[i - 1] : null;
//           final next =
//               i < state.messages.length - 1 ? state.messages[i + 1] : null;
//           final showTime =
//               prev == null ||
//               msg.timestamp.difference(prev.timestamp).inMinutes > 5;
//           final isFirstInGroup = prev == null || prev.isMine != msg.isMine;
//           final isLastInGroup = next == null || next.isMine != msg.isMine;

//           return Column(
//             children: [
//               if (showTime) _buildTimeLabel(msg.timestamp),
//               // ── FIX 2: pass isMine so swipe direction is correct ────────
//               _SwipeToReply(
//                 isMine: msg.isMine,
//                 onReply: () => _triggerReply(msg),
//                 child: _MessageBubble(
//                   message: msg,
//                   isFirstInGroup: isFirstInGroup,
//                   isLastInGroup: isLastInGroup,
//                   otherAvatar: widget.otherUserAvatar,
//                   otherName: widget.otherUserName,
//                   onDelete:
//                       (messageId, deleteType) => ref
//                           .read(chatProvider(widget.otherUserId).notifier)
//                           .deleteMessage(
//                             messageId: messageId,
//                             deleteType: deleteType,
//                           ),
//                   onReply: _triggerReply,
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildHistorySkeleton() {
//     return ListView.builder(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       itemCount: 6,
//       itemBuilder: (_, i) {
//         final isMine = i % 3 != 0;
//         return Padding(
//           padding: const EdgeInsets.symmetric(vertical: 6),
//           child: Row(
//             mainAxisAlignment:
//                 isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
//             children: [
//               if (!isMine) ...[
//                 _ShimmerBox(width: 30, height: 30, radius: 15),
//                 const SizedBox(width: 8),
//               ],
//               _ShimmerBox(width: isMine ? 160 : 130, height: 44, radius: 18),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   // Widget _buildEmptyState() {
//   //   return Center(
//   //     child: Column(
//   //       mainAxisAlignment: MainAxisAlignment.center,
//   //       children: [
//   //         Container(
//   //           width: 72,
//   //           height: 72,
//   //           decoration: const BoxDecoration(
//   //             color: _kOrangeLight,
//   //             shape: BoxShape.circle,
//   //           ),
//   //           child: const Icon(
//   //             Icons.chat_bubble_outline_rounded,
//   //             color: _kOrange,
//   //             size: 36,
//   //           ),
//   //         ),
//   //         const SizedBox(height: 16),
//   //         Text(
//   //           'Start a conversation',
//   //           style: TextStyle(
//   //             fontSize: 16,
//   //             fontWeight: FontWeight.w600,
//   //             color: Colors.grey.shade600,
//   //           ),
//   //         ),
//   //         const SizedBox(height: 6),
//   //         Text(
//   //           'Say hi to ${widget.otherUserName}! 👋',
//   //           style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
//   //         ),
//   //       ],
//   //     ),
//   //   );
//   // }

//   Widget _buildEmptyState() {
//     final firstName = widget.otherUserName.split(' ').first;

//     // Quick greeting options
//     final greetings = [
//       ('👋', 'Hey $firstName!'),
//       ('😊', 'Hi there!'),
//       ('🤙', "What's up?"),
//       ('🌟', 'Hello!'),
//       ('🎉', 'Hey! Great to connect!'),
//       ('✨', "Hey $firstName, how's it going?"),
//     ];

//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 24),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             // Avatar with pulse
//             _PulsingAvatar(
//               avatar: widget.otherUserAvatar,
//               name: widget.otherUserName,
//               isOnline: widget.isOnline,
//             ),
//             const SizedBox(height: 18),

//             // Name
//             Text(
//               widget.otherUserName,
//               style: const TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.w800,
//                 color: Colors.black87,
//                 letterSpacing: -0.5,
//               ),
//             ),
//             const SizedBox(height: 4),
//             if (widget.isOnline)
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 10,
//                   vertical: 3,
//                 ),
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF2ECC71).withOpacity(0.12),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(Icons.circle, color: Color(0xFF2ECC71), size: 8),
//                     SizedBox(width: 5),
//                     Text(
//                       'Active now',
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Color(0xFF2ECC71),
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//             const SizedBox(height: 28),

//             // Say hi label
//             Text(
//               'Say hi to $firstName 👋',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w700,
//                 color: Colors.grey.shade700,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               'Start a conversation — pick a greeting or type your own',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 13,
//                 color: Colors.grey.shade400,
//                 height: 1.4,
//               ),
//             ),
//             const SizedBox(height: 20),

//             // Greeting chips — 2-column grid of tappable bubbles
//             Wrap(
//               spacing: 10,
//               runSpacing: 10,
//               alignment: WrapAlignment.center,
//               children:
//                   greetings.map((g) {
//                     final emoji = g.$1;
//                     final text = g.$2;
//                     return _GreetingChip(
//                       emoji: emoji,
//                       label: text,
//                       onTap: () {
//                         _inputCtrl.text = '$emoji $text';
//                         _sendMessage();
//                       },
//                     );
//                   }).toList(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTimeLabel(DateTime dt) {
//     final now = DateTime.now();
//     String label;
//     if (now.difference(dt).inDays == 0) {
//       label =
//           '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
//     } else {
//       label = '${dt.day}/${dt.month}/${dt.year}';
//     }
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 12),
//       child: Center(
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//           decoration: BoxDecoration(
//             color: Colors.black.withOpacity(0.06),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Text(
//             label,
//             style: TextStyle(
//               fontSize: 11,
//               color: Colors.grey.shade600,
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTypingIndicator() {
//     return Padding(
//       padding: const EdgeInsets.only(left: 16, bottom: 6),
//       child: Row(
//         children: [
//           _MiniAvatar(
//             avatar: widget.otherUserAvatar,
//             name: widget.otherUserName,
//           ),
//           const SizedBox(width: 8),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: const BorderRadius.only(
//                 topLeft: Radius.circular(18),
//                 topRight: Radius.circular(18),
//                 bottomRight: Radius.circular(18),
//                 bottomLeft: Radius.circular(4),
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.06),
//                   blurRadius: 8,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: const _TypingDots(),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInputBar() {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.06),
//             blurRadius: 12,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       padding: EdgeInsets.only(
//         left: 12,
//         right: 12,
//         top: 10,
//         bottom: MediaQuery.of(context).padding.bottom + 10,
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.end,
//         children: [
//           Padding(
//             padding: const EdgeInsets.only(bottom: 4),
//             child: GestureDetector(
//               onTap: _showAttachmentOptions,
//               child: Container(
//                 width: 38,
//                 height: 38,
//                 decoration: BoxDecoration(
//                   color: _kOrangeLight,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Icon(
//                   Icons.attach_file_rounded,
//                   color: _kOrange,
//                   size: 20,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Container(
//               constraints: const BoxConstraints(maxHeight: 120),
//               decoration: BoxDecoration(
//                 color: _kBg,
//                 borderRadius: BorderRadius.circular(24),
//                 border: Border.all(
//                   color:
//                       _isComposing
//                           ? _kOrange.withOpacity(0.4)
//                           : Colors.grey.shade200,
//                   width: 1.5,
//                 ),
//               ),
//               child: TextField(
//                 controller: _inputCtrl,
//                 focusNode: _focusNode,
//                 maxLines: null,
//                 textCapitalization: TextCapitalization.sentences,
//                 style: const TextStyle(
//                   fontSize: 15,
//                   color: Colors.black87,
//                   height: 1.4,
//                 ),
//                 decoration: InputDecoration(
//                   hintText: 'Message...',
//                   hintStyle: TextStyle(
//                     color: Colors.grey.shade400,
//                     fontSize: 15,
//                   ),
//                   border: InputBorder.none,
//                   contentPadding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 10,
//                   ),
//                 ),
//                 onSubmitted: (_) => _sendMessage(),
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           AnimatedSwitcher(
//             duration: const Duration(milliseconds: 200),
//             transitionBuilder:
//                 (child, anim) => ScaleTransition(scale: anim, child: child),
//             child:
//                 _isComposing
//                     ? GestureDetector(
//                       key: const ValueKey('send'),
//                       onTap: _sendMessage,
//                       child: Container(
//                         width: 42,
//                         height: 42,
//                         decoration: BoxDecoration(
//                           gradient: const LinearGradient(
//                             colors: [_kOrange, Color(0xFFFFAA00)],
//                             begin: Alignment.topLeft,
//                             end: Alignment.bottomRight,
//                           ),
//                           borderRadius: BorderRadius.circular(14),
//                           boxShadow: [
//                             BoxShadow(
//                               color: _kOrange.withOpacity(0.35),
//                               blurRadius: 10,
//                               offset: const Offset(0, 4),
//                             ),
//                           ],
//                         ),
//                         child: const Icon(
//                           Icons.send_rounded,
//                           color: Colors.white,
//                           size: 20,
//                         ),
//                       ),
//                     )
//                     : null,
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _SwipeToReply extends StatefulWidget {
//   final Widget child;
//   final VoidCallback onReply;
//   final bool isMine;

//   const _SwipeToReply({
//     required this.child,
//     required this.onReply,
//     required this.isMine,
//   });

//   @override
//   State<_SwipeToReply> createState() => _SwipeToReplyState();
// }

// class _SwipeToReplyState extends State<_SwipeToReply>
//     with SingleTickerProviderStateMixin {
//   double _dx = 0;
//   bool _triggered = false;
//   late AnimationController _ctrl;

//   static const double _kThreshold = 56.0;
//   static const double _kMaxDrag = 72.0;

//   @override
//   void initState() {
//     super.initState();
//     _ctrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 250),
//     );
//   }

//   @override
//   void dispose() {
//     _ctrl.dispose();
//     super.dispose();
//   }

//   void _onDragUpdate(DragUpdateDetails details) {
//     if (_ctrl.isAnimating) return;

//     double newDx;
//     if (widget.isMine) {
//       newDx = (_dx + details.delta.dx).clamp(-_kMaxDrag, 0.0);
//     } else {
//       newDx = (_dx + details.delta.dx).clamp(0.0, _kMaxDrag);
//     }
//     setState(() => _dx = newDx);

//     if (!_triggered && _dx.abs() >= _kThreshold) {
//       _triggered = true;
//       HapticFeedback.mediumImpact();
//     }
//   }

//   void _onDragEnd(DragEndDetails _) {
//     if (_triggered) widget.onReply();
//     _triggered = false;
//     _springBack();
//   }

//   void _springBack() {
//     final startDx = _dx;
//     final anim = Tween<double>(
//       begin: startDx,
//       end: 0.0,
//     ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
//     anim.addListener(() {
//       if (mounted) setState(() => _dx = anim.value);
//     });
//     _ctrl.forward(from: 0);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final progress = (_dx.abs() / _kThreshold).clamp(0.0, 1.0);

//     return GestureDetector(
//       behavior: HitTestBehavior.translucent,
//       onHorizontalDragUpdate: _onDragUpdate,
//       onHorizontalDragEnd: _onDragEnd,
//       child: Stack(
//         clipBehavior: Clip.none,
//         children: [
//           Transform.translate(offset: Offset(_dx, 0), child: widget.child),

//           // Icon appears on the trailing side of the swipe
//           Positioned(
//             left: widget.isMine ? null : 6,
//             right: widget.isMine ? 6 : null,
//             top: 0,
//             bottom: 0,
//             child: Center(
//               child: Opacity(
//                 opacity: progress,
//                 child: Transform.scale(
//                   scale: 0.5 + 0.5 * progress,
//                   child: Container(
//                     width: 34,
//                     height: 34,
//                     decoration: BoxDecoration(
//                       color: _kOrange.withOpacity(0.15),
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(
//                       Icons.reply_rounded,
//                       color: _kOrange,
//                       size: 18,
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _MessageBubble extends StatelessWidget {
//   final ChatMessage message;
//   final bool isFirstInGroup;
//   final bool isLastInGroup;
//   final String otherAvatar;
//   final String otherName;
//   final Future<bool> Function(String, String) onDelete;
//   final void Function(ChatMessage) onReply;

//   const _MessageBubble({
//     required this.message,
//     required this.isFirstInGroup,
//     required this.isLastInGroup,
//     required this.otherAvatar,
//     required this.otherName,
//     required this.onDelete,
//     required this.onReply,
//   });

//   bool get _isImageOnly =>
//       message.isImage && message.text.isEmpty && !message.hasReply;

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.only(
//         top: isFirstInGroup ? 6 : 6,
//         bottom: isLastInGroup ? 2 : 5,
//       ),
//       child: Row(
//         mainAxisAlignment:
//             message.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.end,
//         children:
//             message.isMine
//                 ? [
//                   GestureDetector(
//                     onLongPress: () => _showMessageOptions(context),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         // Separate quoted bubble above
//                         if (message.hasReply) _quotedBubble(isMine: true),
//                         _sentBubble(context),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(width: 4),
//                 ]
//                 : [
//                   const SizedBox(width: 4),
//                   _receivedAvatar(),
//                   const SizedBox(width: 6),
//                   GestureDetector(
//                     onLongPress: () => _showMessageOptions(context),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         // Separate quoted bubble above
//                         if (message.hasReply) _quotedBubble(isMine: false),
//                         _receivedBubble(context),
//                       ],
//                     ),
//                   ),
//                 ],
//       ),
//     );
//   }

//   Widget _quotedBubble({required bool isMine}) {
//     final senderName =
//         (message.repliedToSenderName?.isNotEmpty == true)
//             ? message.repliedToSenderName!
//             : (message.isMine ? otherName : 'You');
//     final replyText = message.repliedToText ?? '';
//     final previewText = replyText.isEmpty ? '📎 Attachment' : replyText;

//     return Container(
//       margin: const EdgeInsets.only(bottom: 3),
//       constraints: BoxConstraints(
//         maxWidth:
//             MediaQueryData.fromView(
//               WidgetsBinding.instance.platformDispatcher.views.first,
//             ).size.width *
//             0.65,
//       ),
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//       decoration: BoxDecoration(
//         color: Colors.grey.shade200,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Text(
//           //   senderName,
//           //   style: const TextStyle(
//           //     fontSize: 11,
//           //     fontWeight: FontWeight.w700,
//           //     color: _kOrange,
//           //   ),
//           // ),
//           // const SizedBox(height: 2),
//           Text(
//             previewText,
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//             style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _receivedAvatar() {
//     if (!isLastInGroup) return const SizedBox(width: 30);
//     final initial = otherName.isNotEmpty ? otherName[0].toUpperCase() : '?';
//     return SizedBox(
//       width: 30,
//       height: 30,
//       child: ClipOval(
//         child:
//             otherAvatar.isNotEmpty
//                 ? CachedNetworkImage(
//                   imageUrl: otherAvatar,
//                   fit: BoxFit.cover,
//                   errorWidget: (_, __, ___) => _fallbackAvatar(initial),
//                 )
//                 : _fallbackAvatar(initial),
//       ),
//     );
//   }

//   Widget _fallbackAvatar(String initial) => Container(
//     color: _kOrangeLight,
//     child: Center(
//       child: Text(
//         initial,
//         style: const TextStyle(
//           fontWeight: FontWeight.bold,
//           color: _kOrange,
//           fontSize: 12,
//         ),
//       ),
//     ),
//   );

//   Widget _sentBubble(BuildContext context) {
//     if (_isImageOnly) {
//       return _imageBubble(context, isMine: true);
//     }

//     return Container(
//       constraints: BoxConstraints(
//         maxWidth:
//             MediaQueryData.fromView(
//               WidgetsBinding.instance.platformDispatcher.views.first,
//             ).size.width *
//             0.72,
//       ),
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           colors: [_kOrange, Color(0xFFFFAA00)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.only(
//           topLeft: const Radius.circular(18),
//           topRight: Radius.circular(isFirstInGroup ? 18 : 4),
//           bottomLeft: const Radius.circular(18),
//           bottomRight: Radius.circular(isLastInGroup ? 4 : 18),
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: _kOrange.withOpacity(0.25),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.end,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           if (message.hasAttachment && message.isImage)
//             _inlineImage(context, isMine: true),
//           if (message.hasAttachment && !message.isImage)
//             _filePill(isMine: true),
//           if (message.text.isNotEmpty) _textWithTimestamp(isMine: true),
//         ],
//       ),
//     );
//   }

//   Widget _receivedBubble(BuildContext context) {
//     if (_isImageOnly) {
//       return _imageBubble(context, isMine: false);
//     }

//     return Container(
//       constraints: BoxConstraints(
//         maxWidth:
//             MediaQueryData.fromView(
//               WidgetsBinding.instance.platformDispatcher.views.first,
//             ).size.width *
//             0.72,
//       ),
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
//       decoration: BoxDecoration(
//         color: _kReceivedBubble,
//         borderRadius: BorderRadius.only(
//           topLeft: Radius.circular(isFirstInGroup ? 18 : 4),
//           topRight: const Radius.circular(18),
//           bottomLeft: Radius.circular(isLastInGroup ? 4 : 18),
//           bottomRight: const Radius.circular(18),
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withAlpha(16),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // if (message.hasReply) _replyPreview(isMine: false),
//           if (message.hasAttachment && message.isImage)
//             _inlineImage(context, isMine: false),
//           if (message.hasAttachment && !message.isImage)
//             _filePill(isMine: false),
//           if (message.text.isNotEmpty) _textWithTimestamp(isMine: false),
//         ],
//       ),
//     );
//   }

//   Widget _imageBubble(BuildContext context, {required bool isMine}) {
//     final url = message.attachmentUrl!;
//     final isLocal = !url.startsWith('http');

//     final radius = BorderRadius.only(
//       topLeft: Radius.circular(isMine || isFirstInGroup ? 18 : 4),
//       topRight: Radius.circular(!isMine || isFirstInGroup ? 18 : 4),
//       bottomLeft: Radius.circular(isMine || isLastInGroup ? 18 : 4),
//       bottomRight: Radius.circular(!isMine || isLastInGroup ? 4 : 18),
//     );

//     return GestureDetector(
//       onTap: () => _openImageFullScreen(context, url, isLocal),
//       child: Stack(
//         children: [
//           ClipRRect(
//             borderRadius: radius,
//             child: ConstrainedBox(
//               constraints: const BoxConstraints(
//                 maxWidth: 220,
//                 maxHeight: 260,
//                 minWidth: 140,
//                 minHeight: 100,
//               ),
//               child:
//                   isLocal
//                       ? Image.file(
//                         File(url),
//                         fit: BoxFit.cover,
//                         errorBuilder: (_, __, ___) => _imageError(),
//                       )
//                       : CachedNetworkImage(
//                         imageUrl: url,
//                         fit: BoxFit.cover,
//                         placeholder:
//                             (_, __) => Container(
//                               width: 200,
//                               height: 160,
//                               color: Colors.grey.shade200,
//                               child: const Center(
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 2,
//                                   color: _kOrange,
//                                 ),
//                               ),
//                             ),
//                         errorWidget: (_, __, ___) => _imageError(),
//                       ),
//             ),
//           ),
//           Positioned(
//             bottom: 6,
//             right: 8,
//             child: Container(
//               padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//               decoration: BoxDecoration(
//                 color: Colors.black.withOpacity(0.45),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Row(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text(
//                     _timeLabel(),
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 10,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   if (isMine) ...[const SizedBox(width: 3), _statusIconWhite()],
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _imageError() => Container(
//     width: 140,
//     height: 100,
//     color: Colors.grey.shade200,
//     child: const Icon(Icons.broken_image_rounded, color: Colors.grey, size: 32),
//   );

//   Widget _inlineImage(BuildContext context, {required bool isMine}) {
//     final url = message.attachmentUrl!;
//     final isLocal = !url.startsWith('http');
//     return GestureDetector(
//       onTap: () => _openImageFullScreen(context, url, isLocal),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(10),
//         child: Container(
//           margin: const EdgeInsets.only(bottom: 6),
//           constraints: const BoxConstraints(
//             maxWidth: 200,
//             maxHeight: 180,
//             minWidth: 100,
//             minHeight: 80,
//           ),
//           child:
//               isLocal
//                   ? Image.file(
//                     File(url),
//                     fit: BoxFit.cover,
//                     errorBuilder: (_, __, ___) => _imageError(),
//                   )
//                   : CachedNetworkImage(
//                     imageUrl: url,
//                     fit: BoxFit.cover,
//                     placeholder:
//                         (_, __) => Container(
//                           width: 180,
//                           height: 140,
//                           color:
//                               isMine
//                                   ? Colors.white.withOpacity(0.2)
//                                   : Colors.grey.shade200,
//                           child: const Center(
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               color: _kOrange,
//                             ),
//                           ),
//                         ),
//                     errorWidget: (_, __, ___) => _imageError(),
//                   ),
//         ),
//       ),
//     );
//   }

//   Widget _filePill({required bool isMine}) {
//     final url = message.attachmentUrl!;
//     return Container(
//       margin: const EdgeInsets.only(bottom: 6),
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
//       decoration: BoxDecoration(
//         color: isMine ? Colors.white.withOpacity(0.18) : Colors.grey.shade100,
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             Icons.insert_drive_file_rounded,
//             size: 18,
//             color: isMine ? Colors.white : _kOrange,
//           ),
//           const SizedBox(width: 6),
//           Flexible(
//             child: Text(
//               url.split('/').last,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: TextStyle(
//                 fontSize: 12,
//                 color: isMine ? Colors.white : Colors.black87,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _replyPreview({required bool isMine}) {
//     final senderName =
//         (message.repliedToSenderName?.isNotEmpty == true)
//             ? message.repliedToSenderName!
//             : (message.isMine ? otherName : 'You');
//     final replyText = message.repliedToText ?? '';
//     final previewText = replyText.isEmpty ? '📎 Attachment' : replyText;

//     return Container(
//       margin: const EdgeInsets.only(bottom: 6),
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: isMine ? Colors.black.withOpacity(0.18) : Colors.grey.shade100,
//         borderRadius: BorderRadius.circular(10),
//         border: Border(
//           left: BorderSide(
//             color: isMine ? Colors.white.withOpacity(0.7) : _kOrange,
//             width: 3,
//           ),
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(
//             senderName,
//             style: TextStyle(
//               fontSize: 11,
//               fontWeight: FontWeight.w700,
//               color: isMine ? Colors.white : _kOrange,
//             ),
//           ),
//           const SizedBox(height: 2),
//           Text(
//             previewText,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: TextStyle(
//               fontSize: 12,
//               color:
//                   isMine
//                       ? Colors.white.withOpacity(0.80)
//                       : Colors.grey.shade600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _openImageFullScreen(BuildContext context, String url, bool isLocal) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder:
//             (_) => Scaffold(
//               backgroundColor: Colors.black,
//               appBar: AppBar(
//                 backgroundColor: Colors.black,
//                 leading: IconButton(
//                   icon: const Icon(Icons.close_rounded, color: Colors.white),
//                   onPressed: () => Navigator.pop(context),
//                 ),
//               ),
//               body: Center(
//                 child: InteractiveViewer(
//                   child:
//                       isLocal
//                           ? Image.file(File(url))
//                           : CachedNetworkImage(imageUrl: url),
//                 ),
//               ),
//             ),
//       ),
//     );
//   }

//   String _timeLabel() {
//     return '${message.timestamp.hour.toString().padLeft(2, '0')}:'
//         '${message.timestamp.minute.toString().padLeft(2, '0')}';
//   }

//   Widget _textWithTimestamp({required bool isMine}) {
//     final timestampWidget = Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Text(
//           _timeLabel(),
//           style: TextStyle(
//             color: isMine ? Colors.white.withAlpha(175) : Colors.grey.shade400,
//             fontSize: 10,
//             fontWeight: FontWeight.w500,
//           ),
//         ),
//         if (isMine) ...[const SizedBox(width: 4), _statusIcon()],
//       ],
//     );

//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final textPainter = TextPainter(
//           text: TextSpan(
//             text: message.text,
//             style: const TextStyle(fontSize: 15, height: 1.35),
//           ),
//           maxLines: 1,
//           textDirection: TextDirection.ltr,
//         )..layout(maxWidth: double.infinity);

//         final timeWidth = 52.0;
//         final fitsOneLine =
//             textPainter.width + timeWidth + 8 <= constraints.maxWidth;

//         if (fitsOneLine) {
//           return Row(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.end,
//             children: [
//               Flexible(
//                 child: Text(
//                   message.text,
//                   style: TextStyle(
//                     color: isMine ? Colors.white : Colors.black87,
//                     fontSize: 15,
//                     height: 1.35,
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 6),
//               timestampWidget,
//             ],
//           );
//         } else {
//           return Column(
//             crossAxisAlignment:
//                 isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 message.text,
//                 style: TextStyle(
//                   color: isMine ? Colors.white : Colors.black87,
//                   fontSize: 15,
//                   height: 1.35,
//                 ),
//               ),
//               const SizedBox(height: 3),
//               timestampWidget,
//             ],
//           );
//         }
//       },
//     );
//   }

//   Widget _statusIcon() {
//     switch (message.status) {
//       case MessageStatus.sending:
//         return const SizedBox(
//           width: 12,
//           height: 12,
//           child: CircularProgressIndicator(
//             strokeWidth: 1.5,
//             color: Colors.white70,
//           ),
//         );
//       case MessageStatus.sent:
//         return const Icon(Icons.check_rounded, size: 13, color: Colors.white70);
//       case MessageStatus.delivered:
//         return const Icon(
//           Icons.done_all_rounded,
//           size: 13,
//           color: Colors.white70,
//         );
//       case MessageStatus.read:
//         return const Icon(
//           Icons.done_all_rounded,
//           size: 13,
//           color: Colors.lightBlueAccent,
//         );
//       case MessageStatus.failed:
//         return const Icon(
//           Icons.error_outline_rounded,
//           size: 13,
//           color: Colors.redAccent,
//         );
//     }
//   }

//   Widget _statusIconWhite() {
//     switch (message.status) {
//       case MessageStatus.sending:
//         return const SizedBox(
//           width: 10,
//           height: 10,
//           child: CircularProgressIndicator(
//             strokeWidth: 1.5,
//             color: Colors.white70,
//           ),
//         );
//       case MessageStatus.sent:
//         return const Icon(Icons.check_rounded, size: 11, color: Colors.white70);
//       case MessageStatus.delivered:
//         return const Icon(
//           Icons.done_all_rounded,
//           size: 11,
//           color: Colors.white70,
//         );
//       case MessageStatus.read:
//         return const Icon(
//           Icons.done_all_rounded,
//           size: 11,
//           color: Colors.lightBlueAccent,
//         );
//       case MessageStatus.failed:
//         return const Icon(
//           Icons.error_outline_rounded,
//           size: 11,
//           color: Colors.redAccent,
//         );
//     }
//   }

//   void _showMessageOptions(BuildContext context) {
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
//                 Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 20,
//                     vertical: 4,
//                   ),
//                   child: Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 14,
//                       vertical: 10,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.grey.shade100,
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     child: Text(
//                       message.hasAttachment && message.text.isEmpty
//                           ? '📎 Attachment'
//                           : message.text,
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         fontSize: 13,
//                         color: Colors.grey.shade700,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 const Divider(height: 1),
//                 // Reply
//                 ListTile(
//                   leading: Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: _kOrangeLight,
//                       shape: BoxShape.circle,
//                     ),
//                     child: const Icon(
//                       Icons.reply_rounded,
//                       color: _kOrange,
//                       size: 20,
//                     ),
//                   ),
//                   title: const Text(
//                     'Reply',
//                     style: TextStyle(fontWeight: FontWeight.w600),
//                   ),
//                   onTap: () {
//                     Navigator.pop(context);
//                     onReply(message);
//                   },
//                 ),
//                 // Delete for me
//                 ListTile(
//                   leading: Container(
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: Colors.orange.shade50,
//                       shape: BoxShape.circle,
//                     ),
//                     child: Icon(
//                       Icons.delete_outline_rounded,
//                       color: Colors.orange.shade700,
//                       size: 20,
//                     ),
//                   ),
//                   title: const Text(
//                     'Delete for me',
//                     style: TextStyle(fontWeight: FontWeight.w600),
//                   ),
//                   onTap: () async {
//                     Navigator.pop(context);
//                     await _confirmAndDelete(context, 'for_me');
//                   },
//                 ),
//                 if (message.isMine)
//                   ListTile(
//                     leading: Container(
//                       padding: const EdgeInsets.all(8),
//                       decoration: BoxDecoration(
//                         color: Colors.red.shade50,
//                         shape: BoxShape.circle,
//                       ),
//                       child: Icon(
//                         Icons.delete_forever_rounded,
//                         color: Colors.red.shade600,
//                         size: 20,
//                       ),
//                     ),
//                     title: const Text(
//                       'Delete for everyone',
//                       style: TextStyle(fontWeight: FontWeight.w600),
//                     ),
//                     onTap: () async {
//                       Navigator.pop(context);
//                       await _confirmAndDelete(context, 'for_everyone');
//                     },
//                   ),
//                 const SizedBox(height: 20),
//               ],
//             ),
//           ),
//     );
//   }

//   Future<void> _confirmAndDelete(
//     BuildContext context,
//     String deleteType,
//   ) async {
//     final label = deleteType == 'for_everyone' ? 'everyone' : 'you';
//     final confirm =
//         await showDialog<bool>(
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
//                         size: 20,
//                       ),
//                     ),
//                     const SizedBox(width: 12),
//                     const Text(
//                       'Delete Message',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ],
//                 ),
//                 content: Text(
//                   'This message will be deleted for $label.',
//                   style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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

//     if (!confirm || !context.mounted) return;
//     final success = await onDelete(message.id, deleteType);
//     if (!success && context.mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text('Failed to delete message'),
//           backgroundColor: Colors.red.shade600,
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(10),
//           ),
//           duration: const Duration(seconds: 2),
//         ),
//       );
//     }
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // Supporting widgets (unchanged)
// // ─────────────────────────────────────────────────────────────────────────────

// class _AttachOption extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final Color color;
//   final VoidCallback onTap;
//   const _AttachOption({
//     required this.icon,
//     required this.label,
//     required this.color,
//     required this.onTap,
//   });
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Container(
//             width: 60,
//             height: 60,
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.12),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(icon, color: color, size: 28),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: 12,
//               color: Colors.grey.shade700,
//               fontWeight: FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _ShimmerBox extends StatefulWidget {
//   final double width;
//   final double height;
//   final double radius;
//   const _ShimmerBox({
//     required this.width,
//     required this.height,
//     required this.radius,
//   });
//   @override
//   State<_ShimmerBox> createState() => _ShimmerBoxState();
// }

// class _ShimmerBoxState extends State<_ShimmerBox>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _ctrl;
//   late final Animation<double> _anim;
//   @override
//   void initState() {
//     super.initState();
//     _ctrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 900),
//     )..repeat(reverse: true);
//     _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
//   }

//   @override
//   void dispose() {
//     _ctrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) => FadeTransition(
//     opacity: _anim,
//     child: Container(
//       width: widget.width,
//       height: widget.height,
//       decoration: BoxDecoration(
//         color: Colors.grey.shade200,
//         borderRadius: BorderRadius.circular(widget.radius),
//       ),
//     ),
//   );
// }

// class _MiniAvatar extends StatelessWidget {
//   final String avatar;
//   final String name;
//   const _MiniAvatar({required this.avatar, required this.name});
//   @override
//   Widget build(BuildContext context) {
//     final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
//     return SizedBox(
//       width: 28,
//       height: 28,
//       child: ClipOval(
//         child:
//             avatar.isNotEmpty
//                 ? CachedNetworkImage(
//                   imageUrl: avatar,
//                   fit: BoxFit.cover,
//                   errorWidget: (_, __, ___) => _fb(initial),
//                 )
//                 : _fb(initial),
//       ),
//     );
//   }

//   Widget _fb(String initial) => Container(
//     color: _kOrangeLight,
//     child: Center(
//       child: Text(
//         initial,
//         style: const TextStyle(
//           fontWeight: FontWeight.bold,
//           color: _kOrange,
//           fontSize: 11,
//         ),
//       ),
//     ),
//   );
// }

// class _TypingDots extends StatefulWidget {
//   const _TypingDots();
//   @override
//   State<_TypingDots> createState() => _TypingDotsState();
// }

// class _TypingDotsState extends State<_TypingDots>
//     with TickerProviderStateMixin {
//   late final List<AnimationController> _ctrls;
//   late final List<Animation<double>> _anims;
//   @override
//   void initState() {
//     super.initState();
//     _ctrls = List.generate(
//       3,
//       (i) => AnimationController(
//         vsync: this,
//         duration: const Duration(milliseconds: 500),
//       ),
//     );
//     _anims =
//         _ctrls
//             .map(
//               (c) => Tween<double>(
//                 begin: 0,
//                 end: -6,
//               ).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)),
//             )
//             .toList();
//     for (int i = 0; i < 3; i++) {
//       Future.delayed(Duration(milliseconds: i * 160), () {
//         if (mounted) _ctrls[i].repeat(reverse: true);
//       });
//     }
//   }

//   @override
//   void dispose() {
//     for (final c in _ctrls) c.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: List.generate(3, (i) {
//         return AnimatedBuilder(
//           animation: _anims[i],
//           builder:
//               (_, __) => Transform.translate(
//                 offset: Offset(0, _anims[i].value),
//                 child: Container(
//                   width: 7,
//                   height: 7,
//                   margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade400,
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//               ),
//         );
//       }),
//     );
//   }
// }

// class _PulsingAvatar extends StatefulWidget {
//   final String avatar;
//   final String name;
//   final bool isOnline;

//   const _PulsingAvatar({
//     required this.avatar,
//     required this.name,
//     required this.isOnline,
//   });

//   @override
//   State<_PulsingAvatar> createState() => _PulsingAvatarState();
// }

// class _PulsingAvatarState extends State<_PulsingAvatar>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _ctrl;
//   late final Animation<double> _scale;

//   @override
//   void initState() {
//     super.initState();
//     _ctrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1800),
//     )..repeat(reverse: true);
//     _scale = Tween<double>(
//       begin: 1.0,
//       end: 1.06,
//     ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
//   }

//   @override
//   void dispose() {
//     _ctrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final initial = widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?';

//     return ScaleTransition(
//       scale: _scale,
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           // Outer glow ring
//           Container(
//             width: 96,
//             height: 96,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               gradient: const LinearGradient(
//                 colors: [_kOrange, Color(0xFFFFCC00)],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//             ),
//           ),
//           // Avatar
//           ClipOval(
//             child: SizedBox(
//               width: 88,
//               height: 88,
//               child:
//                   widget.avatar.isNotEmpty
//                       ? CachedNetworkImage(
//                         imageUrl: widget.avatar,
//                         fit: BoxFit.cover,
//                         errorWidget: (_, __, ___) => _fallback(initial),
//                       )
//                       : _fallback(initial),
//             ),
//           ),
//           // Online dot
//           if (widget.isOnline)
//             Positioned(
//               bottom: 4,
//               right: 4,
//               child: Container(
//                 width: 16,
//                 height: 16,
//                 decoration: BoxDecoration(
//                   color: const Color(0xFF2ECC71),
//                   shape: BoxShape.circle,
//                   border: Border.all(color: Colors.white, width: 2.5),
//                   boxShadow: [
//                     BoxShadow(
//                       color: const Color(0xFF2ECC71).withOpacity(0.5),
//                       blurRadius: 6,
//                       spreadRadius: 1,
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _fallback(String initial) => Container(
//     color: _kOrangeLight,
//     child: Center(
//       child: Text(
//         initial,
//         style: const TextStyle(
//           fontWeight: FontWeight.bold,
//           color: _kOrange,
//           fontSize: 32,
//         ),
//       ),
//     ),
//   );
// }

// /// Tappable greeting chip
// class _GreetingChip extends StatefulWidget {
//   final String emoji;
//   final String label;
//   final VoidCallback onTap;

//   const _GreetingChip({
//     required this.emoji,
//     required this.label,
//     required this.onTap,
//   });

//   @override
//   State<_GreetingChip> createState() => _GreetingChipState();
// }

// class _GreetingChipState extends State<_GreetingChip>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _ctrl;
//   late final Animation<double> _scale;

//   @override
//   void initState() {
//     super.initState();
//     _ctrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 120),
//     );
//     _scale = Tween<double>(
//       begin: 1.0,
//       end: 0.93,
//     ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
//   }

//   @override
//   void dispose() {
//     _ctrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTapDown: (_) => _ctrl.forward(),
//       onTapUp: (_) {
//         _ctrl.reverse();
//         widget.onTap();
//       },
//       onTapCancel: () => _ctrl.reverse(),
//       child: ScaleTransition(
//         scale: _scale,
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(24),
//             border: Border.all(color: const Color.fromRGBO(244, 135, 6, 0.2)),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withAlpha(8),
//                 blurRadius: 8,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(widget.emoji, style: const TextStyle(fontSize: 16)),
//               const SizedBox(width: 6),
//               Text(
//                 widget.label,
//                 style: const TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w600,
//                   color: Colors.black87,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }



import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/models/Chat/chat_model.dart';
import 'package:innovator/Innovator/provider/chat_state.dart';
import 'package:innovator/Innovator/provider/global_chat_listener.dart';
import 'package:innovator/Innovator/provider/unread_count_provider.dart';
import 'package:innovator/Innovator/screens/SHow_Specific_Profile/Show_Specific_Profile.dart';
import 'package:innovator/Innovator/provider/chat_preference_provider.dart';
import 'package:innovator/Innovator/screens/chatrrom/screen/chat_delete.dart';
import 'package:innovator/Innovator/screens/chatrrom/screen/chatlistscreen.dart';
import 'package:innovator/Innovator/screens/chatrrom/sound/soundplayer.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Theme constants
// ─────────────────────────────────────────────────────────────────────────────

const _kOrange = Color.fromRGBO(244, 135, 6, 1);
const _kOrangeLight = Color.fromRGBO(244, 135, 6, 0.12);
const _kBg = Color(0xFFF5F6FA);
const _kReceivedBubble = Color(0xFFFFFFFF);
const _kBaseUrl = 'ws://36.253.137.34:8005';
const _kHttpBase = 'http://36.253.137.34:8005';

String _inferAttachmentType(String url) {
  final lower = url.toLowerCase();
  if (lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.gif') ||
      lower.endsWith('.webp'))
    return 'image';
  if (lower.endsWith('.mp4') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.avi'))
    return 'video';
  return 'file';
}

// ─────────────────────────────────────────────────────────────────────────────
// ChatNotifier  — FIX 1: offline message queue
// ─────────────────────────────────────────────────────────────────────────────

class ChatNotifier extends StateNotifier<ChatState> {
  final String otherUserId;
  final Ref _ref;

  ChatNotifier(this.otherUserId, this._ref) : super(const ChatState()) {
    _init();
  }

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const _maxReconnects = 99; // keep retrying forever silently

  /// ── FIX 1: offline queue ─────────────────────────────────────────────────
  final List<Map<String, dynamic>> _pendingQueue = [];

  String get _myId => AppData().currentUserId ?? '';
  String get _token => AppData().accessToken ?? '';

  Map<String, String> get _authHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
  };

  Future<void> _init() async {
    await _fetchHistory();
    _connect();
  }

  Future<void> _fetchHistory() async {
    if (_token.isEmpty) return;
    state = state.copyWith(isLoadingHistory: true, error: null);
    try {
      final uri = Uri.parse('$_kHttpBase/api/chats/?with_user=$otherUserId');
      final response = await http
          .get(uri, headers: _authHeaders)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final list = json.decode(response.body) as List<dynamic>;
        final messages =
            list
                .whereType<Map<String, dynamic>>()
                .map((m) => ChatMessage.fromHistory(m, _myId))
                .toList();
        state = state.copyWith(messages: messages, isLoadingHistory: false);
      } else {
        state = state.copyWith(isLoadingHistory: false);
      }
    } catch (e) {
      state = state.copyWith(isLoadingHistory: false);
    }
  }

  void _markAsRead() {
    if (state.wsStatus != WsStatus.connected) return;
    try {
      _channel!.sink.add(json.encode({'type': 'mark_as_read'}));
      _ref.read(perFriendUnreadProvider.notifier).reset(otherUserId);
    } catch (_) {}
  }

  void markAsRead() => _markAsRead();

  Future<void> refresh() async {
    await _fetchHistory();
    _markAsRead();
  }

  void setReply(ChatMessage msg) => state = state.copyWith(replyingTo: msg);
  void clearReply() => state = state.copyWith(clearReply: true);

  void _connect() {
    if (_token.isEmpty || otherUserId.isEmpty) return;

    // ── FIX 1: Don't update wsStatus to show UI banner ─────────────────────
    // We connect silently — no "Reconnecting…" banner.
    developer.log('[WS] Connecting to $otherUserId...');

    try {
      final uri = Uri.parse('$_kBaseUrl/ws/chat/$otherUserId/?token=$_token');
      _channel = IOWebSocketChannel.connect(
        uri,
        pingInterval: const Duration(seconds: 20),
      );

      // Mark connected ONLY internally; don't surface errors to UI
      state = state.copyWith(wsStatus: WsStatus.connected, error: null);
      _reconnectAttempts = 0;
      developer.log('[WS] Connected ✓');
      _markAsRead();

      // Flush any queued messages
      _flushQueue();

      _sub = _channel!.stream.listen(
        _onMessage,
        onError: (_) => _onDone(),
        onDone: _onDone,
        cancelOnError: false,
      );
    } catch (e) {
      developer.log('[WS] Connect error: $e');
      // Silently schedule reconnect — no UI state change
      state = state.copyWith(wsStatus: WsStatus.disconnected);
      _scheduleReconnect();
    }
  }

  /// Flush queued messages once WS is back online
  void _flushQueue() {
    if (_pendingQueue.isEmpty) return;
    final copy = List<Map<String, dynamic>>.from(_pendingQueue);
    _pendingQueue.clear();
    for (final payload in copy) {
      try {
        _channel!.sink.add(json.encode(payload));
        developer.log('[WS] Flushed queued message');
      } catch (e) {
        _pendingQueue.insert(0, payload); // put back on failure
        break;
      }
    }
  }

  void _onMessage(dynamic raw) {
    try {
      final data = json.decode(raw.toString()) as Map<String, dynamic>;

      if (data['type'] == 'messages_read') {
        final senderId = data['sender_id']?.toString() ?? '';
        if (senderId == otherUserId) {
          final updated =
              state.messages.map((m) {
                if (m.isMine && m.status != MessageStatus.read) {
                  return ChatMessage(
                    id: m.id,
                    text: m.text,
                    isMine: true,
                    timestamp: m.timestamp,
                    status: MessageStatus.read,
                    parentId: m.parentId,
                    repliedToText: m.repliedToText,
                    repliedToSenderName: m.repliedToSenderName,
                    attachmentUrl: m.attachmentUrl,
                    attachmentType: m.attachmentType,
                  );
                }
                return m;
              }).toList();
          state = state.copyWith(messages: updated);
        }
        return;
      }

      if (data['type'] == 'typing') {
        state = state.copyWith(isTyping: data['is_typing'] == true);
        return;
      }

      final msgText =
          data['message']?.toString() ??
          data['content']?.toString() ??
          data['text']?.toString() ??
          '';
      final attachmentUrl = data['attachment']?.toString();
      final hasContent =
          msgText.isNotEmpty ||
          (attachmentUrl != null && attachmentUrl.isNotEmpty);
      if (!hasContent) return;

      final senderId =
          data['sender']?.toString() ??
          data['sender_id']?.toString() ??
          data['from']?.toString() ??
          '';
      final isMine = senderId == _myId;
      final serverId = data['id']?.toString();

      if (!isMine && senderId != otherUserId) return;
      if (serverId != null && state.messages.any((m) => m.id == serverId)) {
        return;
      }

      if (isMine) {
        final tempIndex = state.messages.lastIndexWhere(
          (m) =>
              m.isMine &&
              m.id.startsWith('temp_') &&
              (m.text == msgText ||
                  (msgText.isEmpty && m.attachmentUrl != null)),
        );
        if (tempIndex != -1) {
          final updated = [...state.messages];
          final old = updated[tempIndex];
          updated[tempIndex] = ChatMessage(
            id: serverId ?? old.id,
            text: msgText,
            isMine: true,
            timestamp:
                data['timestamp'] != null
                    ? DateTime.tryParse(data['timestamp'].toString()) ??
                        DateTime.now()
                    : DateTime.now(),
            status: MessageStatus.delivered,
            parentId: old.parentId,
            repliedToText: old.repliedToText,
            repliedToSenderName: old.repliedToSenderName,
            attachmentUrl:
                attachmentUrl?.isNotEmpty == true
                    ? attachmentUrl
                    : old.attachmentUrl,
            attachmentType: old.attachmentType,
          );
          state = state.copyWith(messages: updated, isTyping: false);
          return;
        }
      }

      final msg = ChatMessage.fromWs(data, _myId);
      state = state.copyWith(
        messages: [...state.messages, msg],
        isTyping: false,
      );

      if (!isMine) {
        SoundPlayer().playsendreceivesound();
        _ref.read(friendActivityProvider.notifier).markActivity(otherUserId);
        _markAsRead();
        _ref.read(mutualFriendsProvider.notifier).bumpToTop(otherUserId);
        _ref.read(lastActiveFriendProvider.notifier).state = otherUserId;
      }
    } catch (e) {
      developer.log('[WS] Parse error: $e');
    }
  }

  void _onDone() {
    developer.log('[WS] Connection closed — scheduling silent reconnect');
    state = state.copyWith(wsStatus: WsStatus.disconnected);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _subs?.cancel();
    _channels?.sink.close();
    _reconnectAttempts++;
    // Exponential backoff capped at 30 s, but never give up
    final delay = Duration(seconds: (_reconnectAttempts * 2).clamp(2, 30));
    developer.log('[WS] Reconnecting in ${delay.inSeconds}s...');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, _connect);
  }

  // ignore unused field warnings from renaming
  WebSocketChannel? get _channels => _channel;
  StreamSubscription? get _subs => _sub;

  // ── Send text — queue if offline ──────────────────────────────────────────
  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final replyingTo = state.replyingTo;
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final mine = ChatMessage(
      id: tempId,
      text: text.trim(),
      isMine: true,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      parentId: replyingTo?.id,
      repliedToText: replyingTo?.text,
      repliedToSenderName:
          replyingTo == null
              ? null
              : (replyingTo.isMine ? 'You' : replyingTo.repliedToSenderName),
    );

    state = state.copyWith(
      messages: [...state.messages, mine],
      isSending: true,
      clearReply: true,
    );

    final payload = <String, dynamic>{'message': text.trim()};
    if (replyingTo != null) {
      payload['type'] = 'reply';
      payload['parent_id'] = replyingTo.id;
    }

    if (state.wsStatus == WsStatus.connected) {
      try {
        _channel!.sink.add(json.encode(payload));
        _ref.read(friendActivityProvider.notifier).markActivity(otherUserId);
        _ref.read(lastActiveFriendProvider.notifier).state = otherUserId;
        _ref.read(mutualFriendsProvider.notifier).bumpToTop(otherUserId);
        final updated =
            state.messages.map((m) {
              if (m.id == tempId) m.status = MessageStatus.sent;
              return m;
            }).toList();
        state = state.copyWith(messages: updated, isSending: false);
      } catch (e) {
        // ── FIX 1: queue instead of fail ─────────────────────────────────
        developer.log('[WS] Send failed, queuing message');
        _pendingQueue.add(payload);
        final updated =
            state.messages.map((m) {
              if (m.id == tempId)
                m.status = MessageStatus.sending; // keep pending
              return m;
            }).toList();
        state = state.copyWith(messages: updated, isSending: false);
        _scheduleReconnect();
      }
    } else {
      // ── FIX 1: offline — add to queue silently ──────────────────────────
      developer.log('[WS] Offline, queuing message');
      _pendingQueue.add(payload);
      final updated =
          state.messages.map((m) {
            if (m.id == tempId) m.status = MessageStatus.sending;
            return m;
          }).toList();
      state = state.copyWith(messages: updated, isSending: false);
      // Make sure reconnect is in progress
      if (_reconnectTimer == null || !_reconnectTimer!.isActive) {
        _connect();
      }
    }
  }

  Future<void> sendAttachment(File file) async {
    if (_token.isEmpty) return;
    final tempId = 'temp_att_${DateTime.now().millisecondsSinceEpoch}';
    final attachmentType = _inferAttachmentType(file.path);
    final tempMsg = ChatMessage(
      id: tempId,
      text: '',
      isMine: true,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      attachmentUrl: file.path,
      attachmentType: attachmentType,
    );
    state = state.copyWith(
      messages: [...state.messages, tempMsg],
      isSending: true,
    );
    try {
      final uri = Uri.parse('$_kHttpBase/api/chats/');
      final request =
          http.MultipartRequest('POST', uri)
            ..headers['Authorization'] = 'Bearer $_token'
            ..fields['receiver'] = otherUserId
            ..files.add(
              await http.MultipartFile.fromPath('attachment', file.path),
            );
      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final serverId = data['id']?.toString() ?? tempId;
        final serverUrl = data['attachment']?.toString() ?? file.path;
        final updated =
            state.messages.map((m) {
              if (m.id == tempId) {
                return ChatMessage(
                  id: serverId,
                  text: data['message']?.toString() ?? '',
                  isMine: true,
                  timestamp: DateTime.now(),
                  status: MessageStatus.delivered,
                  attachmentUrl: serverUrl,
                  attachmentType: attachmentType,
                );
              }
              return m;
            }).toList();
        state = state.copyWith(messages: updated, isSending: false);
        _ref.read(friendActivityProvider.notifier).markActivity(otherUserId);
        _ref.read(lastActiveFriendProvider.notifier).state = otherUserId;
        _ref.read(mutualFriendsProvider.notifier).bumpToTop(otherUserId);
      } else {
        _markAttachmentFailed(tempId);
      }
    } catch (e) {
      _markAttachmentFailed(tempId);
    }
  }

  void _markAttachmentFailed(String tempId) {
    final updated =
        state.messages.map((m) {
          if (m.id == tempId) m.status = MessageStatus.failed;
          return m;
        }).toList();
    state = state.copyWith(messages: updated, isSending: false);
  }

  void sendTyping(bool isTyping) {
    if (state.wsStatus != WsStatus.connected) return;
    try {
      _channel!.sink.add(
        json.encode({'type': 'typing', 'is_typing': isTyping}),
      );
    } catch (_) {}
  }

  Future<bool> deleteMessage({
    required String messageId,
    required String deleteType,
  }) async {
    try {
      final uri = Uri.parse('$_kHttpBase/api/chats/$messageId/delete-message/');
      final response = await http
          .post(
            uri,
            headers: _authHeaders,
            body: json.encode({'delete_type': deleteType}),
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final updated = state.messages.where((m) => m.id != messageId).toList();
        state = state.copyWith(messages: updated);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void reconnect() {
    _reconnectAttempts = 0;
    _connect();
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    super.dispose();
  }
}

final chatProvider =
    AutoDisposeStateNotifierProviderFamily<ChatNotifier, ChatState, String>(
      (ref, otherUserId) => ChatNotifier(otherUserId, ref),
    );

// ─────────────────────────────────────────────────────────────────────────────
// ChatScreen
// ─────────────────────────────────────────────────────────────────────────────

class ChatScreen extends ConsumerStatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String otherUserAvatar;
  final bool isOnline;

  const ChatScreen({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserAvatar,
    this.isOnline = false,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with WidgetsBindingObserver {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;
  Timer? _typingTimer;
  late final GlobalChatListener _globalListener;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _inputCtrl.addListener(_onInputChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _globalListener = ref.read(globalChatListenerProvider);
      _globalListener.activeChatUserId = widget.otherUserId;
      ref.read(activeChatUserIdProvider.notifier).state = widget.otherUserId;
      ref
          .read(chatPreferenceProvider.notifier)
          .fetchPreference(widget.otherUserId);
    });
  }

  @override
  void dispose() {
    _globalListener.activeChatUserId = null;
    WidgetsBinding.instance.removeObserver(this);
    _inputCtrl.removeListener(_onInputChanged);
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(chatProvider(widget.otherUserId).notifier).markAsRead();
    }
  }

  void _onInputChanged() {
    final composing = _inputCtrl.text.trim().isNotEmpty;
    if (composing != _isComposing) setState(() => _isComposing = composing);
    ref.read(chatProvider(widget.otherUserId).notifier).sendTyping(composing);
    _typingTimer?.cancel();
    if (composing) {
      _typingTimer = Timer(const Duration(seconds: 3), () {
        ref.read(chatProvider(widget.otherUserId).notifier).sendTyping(false);
      });
    }
  }

  void _scrollToBottom({bool animated = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollCtrl.hasClients) return;
      if (animated) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    });
  }

  void _sendMessage() {
    SoundPlayer().playsendreceivesound();
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    HapticFeedback.lightImpact();
    ref.read(chatProvider(widget.otherUserId).notifier).sendMessage(text);
    _inputCtrl.clear();
    setState(() => _isComposing = false);
    _scrollToBottom();
  }

  void _showAttachmentOptions() {
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
                      _AttachOption(
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        color: _kOrange,
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                      const SizedBox(width: 16),
                      _AttachOption(
                        icon: Icons.camera_alt_rounded,
                        label: 'Camera',
                        color: const Color(0xFF2ECC71),
                        onTap: () {
                          Navigator.pop(context);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (picked == null) return;
      if (!mounted) return;
      HapticFeedback.lightImpact();
      await ref
          .read(chatProvider(widget.otherUserId).notifier)
          .sendAttachment(File(picked.path));
      _scrollToBottom(animated: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not pick image'),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _triggerReply(ChatMessage msg) {
    ref.read(chatProvider(widget.otherUserId).notifier).setReply(msg);
    _focusNode.requestFocus();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider(widget.otherUserId));

    ref.listen<ChatState>(chatProvider(widget.otherUserId), (prev, next) {
      if ((prev?.messages.length ?? 0) < next.messages.length) {
        _scrollToBottom(animated: true);
      }
      if ((prev?.isLoadingHistory ?? false) && !next.isLoadingHistory) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || !_scrollCtrl.hasClients) return;
            _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
          });
        });
      }
    });

    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(state),
      body: Column(
        children: [
          // ── FIX 1: NO status banner at all — connection is fully silent ──
          Expanded(child: _buildMessageList(state)),
          if (state.isTyping) _buildTypingIndicator(),
          if (state.replyingTo != null) _buildReplyBanner(state.replyingTo!),
          _buildInputBar(),
        ],
      ),
    );
  }

  // ── Reply banner (above input bar) ────────────────────────────────────────

  Widget _buildReplyBanner(ChatMessage replyingTo) {
    final senderLabel = replyingTo.isMine ? 'You' : widget.otherUserName;
    final previewText =
        replyingTo.hasAttachment && replyingTo.text.isEmpty
            ? '📎 Attachment'
            : replyingTo.text;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200),
          left: const BorderSide(color: _kOrange, width: 3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to $senderLabel',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kOrange,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  previewText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap:
                () =>
                    ref
                        .read(chatProvider(widget.otherUserId).notifier)
                        .clearReply(),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close_rounded,
                size: 16,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(ChatState state) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.black12,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: Colors.black87,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      titleSpacing: 0,

      title: GestureDetector(
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) =>
                        SpecificUserProfilePage(userId: widget.otherUserId),
              ),
            ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [_kOrange, Color(0xFFFFCC00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child:
                        widget.otherUserAvatar.isNotEmpty
                            ? CachedNetworkImage(
                              imageUrl: widget.otherUserAvatar,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => _avatarFallback(),
                            )
                            : _avatarFallback(),
                  ),
                ),
                if (widget.isOnline)
                  Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC71),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUserName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  widget.isOnline ? 'Active now' : 'Online',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF2ECC71),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Builder(
                  builder: (context) {
                    final preferences = ref.watch(chatPreferenceProvider);
                    final pref = preferences[widget.otherUserId] ?? '24_hours';
                    final label = pref == 'never'
                        ? 'Messages never deleted'
                        : 'Auto-deletes after 24h';
                    return Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w400,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDeleteScreen(
                  chatPartnerId: widget.otherUserId,
                ),
              ),
            );
          },
          icon: Icon(Icons.more_vert, color: Colors.black),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey.shade100),
      ),
    );
  }

  Widget _avatarFallback() {
    final initial =
        widget.otherUserName.isNotEmpty
            ? widget.otherUserName[0].toUpperCase()
            : '?';
    return Container(
      color: _kOrangeLight,
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: _kOrange,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // ── Message list ───────────────────────────────────────────────────────────

  Widget _buildMessageList(ChatState state) {
    if (state.isLoadingHistory) return _buildHistorySkeleton();
    if (state.messages.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh:
          () => ref.read(chatProvider(widget.otherUserId).notifier).refresh(),
      color: _kOrange,
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: state.messages.length,
        itemBuilder: (context, i) {
          final msg = state.messages[i];
          final prev = i > 0 ? state.messages[i - 1] : null;
          final next =
              i < state.messages.length - 1 ? state.messages[i + 1] : null;
          final showTime =
              prev == null ||
              msg.timestamp.difference(prev.timestamp).inMinutes > 5;
          final isFirstInGroup = prev == null || prev.isMine != msg.isMine;
          final isLastInGroup = next == null || next.isMine != msg.isMine;

          return Column(
            children: [
              if (showTime) _buildTimeLabel(msg.timestamp),
              // ── FIX 2: pass isMine so swipe direction is correct ────────
              _SwipeToReply(
                isMine: msg.isMine,
                onReply: () => _triggerReply(msg),
                child: _MessageBubble(
                  message: msg,
                  isFirstInGroup: isFirstInGroup,
                  isLastInGroup: isLastInGroup,
                  otherAvatar: widget.otherUserAvatar,
                  otherName: widget.otherUserName,
                  onDelete:
                      (messageId, deleteType) => ref
                          .read(chatProvider(widget.otherUserId).notifier)
                          .deleteMessage(
                            messageId: messageId,
                            deleteType: deleteType,
                          ),
                  onReply: _triggerReply,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHistorySkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: 6,
      itemBuilder: (_, i) {
        final isMine = i % 3 != 0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment:
                isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMine) ...[
                _ShimmerBox(width: 30, height: 30, radius: 15),
                const SizedBox(width: 8),
              ],
              _ShimmerBox(width: isMine ? 160 : 130, height: 44, radius: 18),
            ],
          ),
        );
      },
    );
  }

  // Widget _buildEmptyState() {
  //   return Center(
  //     child: Column(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         Container(
  //           width: 72,
  //           height: 72,
  //           decoration: const BoxDecoration(
  //             color: _kOrangeLight,
  //             shape: BoxShape.circle,
  //           ),
  //           child: const Icon(
  //             Icons.chat_bubble_outline_rounded,
  //             color: _kOrange,
  //             size: 36,
  //           ),
  //         ),
  //         const SizedBox(height: 16),
  //         Text(
  //           'Start a conversation',
  //           style: TextStyle(
  //             fontSize: 16,
  //             fontWeight: FontWeight.w600,
  //             color: Colors.grey.shade600,
  //           ),
  //         ),
  //         const SizedBox(height: 6),
  //         Text(
  //           'Say hi to ${widget.otherUserName}! 👋',
  //           style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildEmptyState() {
    final firstName = widget.otherUserName.split(' ').first;

    // Quick greeting options
    final greetings = [
      ('👋', 'Hey $firstName!'),
      ('😊', 'Hi there!'),
      ('🤙', "What's up?"),
      ('🌟', 'Hello!'),
      ('🎉', 'Hey! Great to connect!'),
      ('✨', "Hey $firstName, how's it going?"),
    ];

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar with pulse
            _PulsingAvatar(
              avatar: widget.otherUserAvatar,
              name: widget.otherUserName,
              isOnline: widget.isOnline,
            ),
            const SizedBox(height: 18),

            // Name
            Text(
              widget.otherUserName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            if (widget.isOnline)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Color(0xFF2ECC71), size: 8),
                    SizedBox(width: 5),
                    Text(
                      'Active now',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2ECC71),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 28),

            // Say hi label
            Text(
              'Say hi to $firstName 👋',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start a conversation — pick a greeting or type your own',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade400,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Greeting chips — 2-column grid of tappable bubbles
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children:
                  greetings.map((g) {
                    final emoji = g.$1;
                    final text = g.$2;
                    return _GreetingChip(
                      emoji: emoji,
                      label: text,
                      onTap: () {
                        _inputCtrl.text = '$emoji $text';
                        _sendMessage();
                      },
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeLabel(DateTime dt) {
    final now = DateTime.now();
    String label;
    if (now.difference(dt).inDays == 0) {
      label =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else {
      label = '${dt.day}/${dt.month}/${dt.year}';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 6),
      child: Row(
        children: [
          _MiniAvatar(
            avatar: widget.otherUserAvatar,
            name: widget.otherUserName,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: GestureDetector(
              onTap: _showAttachmentOptions,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _kOrangeLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.attach_file_rounded,
                  color: _kOrange,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color:
                      _isComposing
                          ? _kOrange.withOpacity(0.4)
                          : Colors.grey.shade200,
                  width: 1.5,
                ),
              ),
              child: TextField(
                controller: _inputCtrl,
                focusNode: _focusNode,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: 'Message...',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder:
                (child, anim) => ScaleTransition(scale: anim, child: child),
            child:
                _isComposing
                    ? GestureDetector(
                      key: const ValueKey('send'),
                      onTap: _sendMessage,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_kOrange, Color(0xFFFFAA00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _kOrange.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    )
                    : null,
          ),
        ],
      ),
    );
  }
}

class _SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback onReply;
  final bool isMine;

  const _SwipeToReply({
    required this.child,
    required this.onReply,
    required this.isMine,
  });

  @override
  State<_SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<_SwipeToReply>
    with SingleTickerProviderStateMixin {
  double _dx = 0;
  bool _triggered = false;
  late AnimationController _ctrl;

  static const double _kThreshold = 56.0;
  static const double _kMaxDrag = 72.0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_ctrl.isAnimating) return;

    double newDx;
    if (widget.isMine) {
      newDx = (_dx + details.delta.dx).clamp(-_kMaxDrag, 0.0);
    } else {
      newDx = (_dx + details.delta.dx).clamp(0.0, _kMaxDrag);
    }
    setState(() => _dx = newDx);

    if (!_triggered && _dx.abs() >= _kThreshold) {
      _triggered = true;
      HapticFeedback.mediumImpact();
    }
  }

  void _onDragEnd(DragEndDetails _) {
    if (_triggered) widget.onReply();
    _triggered = false;
    _springBack();
  }

  void _springBack() {
    final startDx = _dx;
    final anim = Tween<double>(
      begin: startDx,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    anim.addListener(() {
      if (mounted) setState(() => _dx = anim.value);
    });
    _ctrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_dx.abs() / _kThreshold).clamp(0.0, 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Transform.translate(offset: Offset(_dx, 0), child: widget.child),

          // Icon appears on the trailing side of the swipe
          Positioned(
            left: widget.isMine ? null : 6,
            right: widget.isMine ? 6 : null,
            top: 0,
            bottom: 0,
            child: Center(
              child: Opacity(
                opacity: progress,
                child: Transform.scale(
                  scale: 0.5 + 0.5 * progress,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: _kOrange.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.reply_rounded,
                      color: _kOrange,
                      size: 18,
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

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isFirstInGroup;
  final bool isLastInGroup;
  final String otherAvatar;
  final String otherName;
  final Future<bool> Function(String, String) onDelete;
  final void Function(ChatMessage) onReply;

  const _MessageBubble({
    required this.message,
    required this.isFirstInGroup,
    required this.isLastInGroup,
    required this.otherAvatar,
    required this.otherName,
    required this.onDelete,
    required this.onReply,
  });

  bool get _isImageOnly =>
      message.isImage && message.text.isEmpty && !message.hasReply;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: isFirstInGroup ? 6 : 6,
        bottom: isLastInGroup ? 2 : 5,
      ),
      child: Row(
        mainAxisAlignment:
            message.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children:
            message.isMine
                ? [
                  GestureDetector(
                    onLongPress: () => _showMessageOptions(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Separate quoted bubble above
                        if (message.hasReply) _quotedBubble(isMine: true),
                        _sentBubble(context),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                ]
                : [
                  const SizedBox(width: 4),
                  _receivedAvatar(),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onLongPress: () => _showMessageOptions(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Separate quoted bubble above
                        if (message.hasReply) _quotedBubble(isMine: false),
                        _receivedBubble(context),
                      ],
                    ),
                  ),
                ],
      ),
    );
  }

  Widget _quotedBubble({required bool isMine}) {
    final senderName =
        (message.repliedToSenderName?.isNotEmpty == true)
            ? message.repliedToSenderName!
            : (message.isMine ? otherName : 'You');
    final replyText = message.repliedToText ?? '';
    final previewText = replyText.isEmpty ? '📎 Attachment' : replyText;

    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      constraints: BoxConstraints(
        maxWidth:
            MediaQueryData.fromView(
              WidgetsBinding.instance.platformDispatcher.views.first,
            ).size.width *
            0.65,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Text(
          //   senderName,
          //   style: const TextStyle(
          //     fontSize: 11,
          //     fontWeight: FontWeight.w700,
          //     color: _kOrange,
          //   ),
          // ),
          // const SizedBox(height: 2),
          Text(
            previewText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _receivedAvatar() {
    if (!isLastInGroup) return const SizedBox(width: 30);
    final initial = otherName.isNotEmpty ? otherName[0].toUpperCase() : '?';
    return SizedBox(
      width: 30,
      height: 30,
      child: ClipOval(
        child:
            otherAvatar.isNotEmpty
                ? CachedNetworkImage(
                  imageUrl: otherAvatar,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _fallbackAvatar(initial),
                )
                : _fallbackAvatar(initial),
      ),
    );
  }

  Widget _fallbackAvatar(String initial) => Container(
    color: _kOrangeLight,
    child: Center(
      child: Text(
        initial,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: _kOrange,
          fontSize: 12,
        ),
      ),
    ),
  );

  Widget _sentBubble(BuildContext context) {
    if (_isImageOnly) {
      return _imageBubble(context, isMine: true);
    }

    return Container(
      constraints: BoxConstraints(
        maxWidth:
            MediaQueryData.fromView(
              WidgetsBinding.instance.platformDispatcher.views.first,
            ).size.width *
            0.72,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kOrange, Color(0xFFFFAA00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: Radius.circular(isFirstInGroup ? 18 : 4),
          bottomLeft: const Radius.circular(18),
          bottomRight: Radius.circular(isLastInGroup ? 4 : 18),
        ),
        boxShadow: [
          BoxShadow(
            color: _kOrange.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.hasAttachment && message.isImage)
            _inlineImage(context, isMine: true),
          if (message.hasAttachment && !message.isImage)
            _filePill(isMine: true),
          if (message.text.isNotEmpty) _textWithTimestamp(isMine: true),
        ],
      ),
    );
  }

  Widget _receivedBubble(BuildContext context) {
    if (_isImageOnly) {
      return _imageBubble(context, isMine: false);
    }

    return Container(
      constraints: BoxConstraints(
        maxWidth:
            MediaQueryData.fromView(
              WidgetsBinding.instance.platformDispatcher.views.first,
            ).size.width *
            0.72,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kReceivedBubble,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isFirstInGroup ? 18 : 4),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isLastInGroup ? 4 : 18),
          bottomRight: const Radius.circular(18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(16),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // if (message.hasReply) _replyPreview(isMine: false),
          if (message.hasAttachment && message.isImage)
            _inlineImage(context, isMine: false),
          if (message.hasAttachment && !message.isImage)
            _filePill(isMine: false),
          if (message.text.isNotEmpty) _textWithTimestamp(isMine: false),
        ],
      ),
    );
  }

  Widget _imageBubble(BuildContext context, {required bool isMine}) {
    final url = message.attachmentUrl!;
    final isLocal = !url.startsWith('http');

    final radius = BorderRadius.only(
      topLeft: Radius.circular(isMine || isFirstInGroup ? 18 : 4),
      topRight: Radius.circular(!isMine || isFirstInGroup ? 18 : 4),
      bottomLeft: Radius.circular(isMine || isLastInGroup ? 18 : 4),
      bottomRight: Radius.circular(!isMine || isLastInGroup ? 4 : 18),
    );

    return GestureDetector(
      onTap: () => _openImageFullScreen(context, url, isLocal),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: radius,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 220,
                maxHeight: 260,
                minWidth: 140,
                minHeight: 100,
              ),
              child:
                  isLocal
                      ? Image.file(
                        File(url),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imageError(),
                      )
                      : CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        placeholder:
                            (_, __) => Container(
                              width: 200,
                              height: 160,
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _kOrange,
                                ),
                              ),
                            ),
                        errorWidget: (_, __, ___) => _imageError(),
                      ),
            ),
          ),
          Positioned(
            bottom: 6,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _timeLabel(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isMine) ...[const SizedBox(width: 3), _statusIconWhite()],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imageError() => Container(
    width: 140,
    height: 100,
    color: Colors.grey.shade200,
    child: const Icon(Icons.broken_image_rounded, color: Colors.grey, size: 32),
  );

  Widget _inlineImage(BuildContext context, {required bool isMine}) {
    final url = message.attachmentUrl!;
    final isLocal = !url.startsWith('http');
    return GestureDetector(
      onTap: () => _openImageFullScreen(context, url, isLocal),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          constraints: const BoxConstraints(
            maxWidth: 200,
            maxHeight: 180,
            minWidth: 100,
            minHeight: 80,
          ),
          child:
              isLocal
                  ? Image.file(
                    File(url),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imageError(),
                  )
                  : CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder:
                        (_, __) => Container(
                          width: 180,
                          height: 140,
                          color:
                              isMine
                                  ? Colors.white.withOpacity(0.2)
                                  : Colors.grey.shade200,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: _kOrange,
                            ),
                          ),
                        ),
                    errorWidget: (_, __, ___) => _imageError(),
                  ),
        ),
      ),
    );
  }

  Widget _filePill({required bool isMine}) {
    final url = message.attachmentUrl!;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isMine ? Colors.white.withOpacity(0.18) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insert_drive_file_rounded,
            size: 18,
            color: isMine ? Colors.white : _kOrange,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              url.split('/').last,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isMine ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _replyPreview({required bool isMine}) {
    final senderName =
        (message.repliedToSenderName?.isNotEmpty == true)
            ? message.repliedToSenderName!
            : (message.isMine ? otherName : 'You');
    final replyText = message.repliedToText ?? '';
    final previewText = replyText.isEmpty ? '📎 Attachment' : replyText;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isMine ? Colors.black.withOpacity(0.18) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: isMine ? Colors.white.withOpacity(0.7) : _kOrange,
            width: 3,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            senderName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isMine ? Colors.white : _kOrange,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            previewText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color:
                  isMine
                      ? Colors.white.withOpacity(0.80)
                      : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _openImageFullScreen(BuildContext context, String url, bool isLocal) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.black,
                leading: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: Center(
                child: InteractiveViewer(
                  child:
                      isLocal
                          ? Image.file(File(url))
                          : CachedNetworkImage(imageUrl: url),
                ),
              ),
            ),
      ),
    );
  }

  String _timeLabel() {
    return '${message.timestamp.hour.toString().padLeft(2, '0')}:'
        '${message.timestamp.minute.toString().padLeft(2, '0')}';
  }

  Widget _textWithTimestamp({required bool isMine}) {
    final timestampWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _timeLabel(),
          style: TextStyle(
            color: isMine ? Colors.white.withAlpha(175) : Colors.grey.shade400,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (isMine) ...[const SizedBox(width: 4), _statusIcon()],
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: message.text,
            style: const TextStyle(fontSize: 15, height: 1.35),
          ),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: double.infinity);

        final timeWidth = 52.0;
        final fitsOneLine =
            textPainter.width + timeWidth + 8 <= constraints.maxWidth;

        if (fitsOneLine) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  message.text,
                  style: TextStyle(
                    color: isMine ? Colors.white : Colors.black87,
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              timestampWidget,
            ],
          );
        } else {
          return Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.text,
                style: TextStyle(
                  color: isMine ? Colors.white : Colors.black87,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 3),
              timestampWidget,
            ],
          );
        }
      },
    );
  }

  Widget _statusIcon() {
    switch (message.status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Colors.white70,
          ),
        );
      case MessageStatus.sent:
        return const Icon(Icons.check_rounded, size: 13, color: Colors.white70);
      case MessageStatus.delivered:
        return const Icon(
          Icons.done_all_rounded,
          size: 13,
          color: Colors.white70,
        );
      case MessageStatus.read:
        return const Icon(
          Icons.done_all_rounded,
          size: 13,
          color: Colors.lightBlueAccent,
        );
      case MessageStatus.failed:
        return const Icon(
          Icons.error_outline_rounded,
          size: 13,
          color: Colors.redAccent,
        );
    }
  }

  Widget _statusIconWhite() {
    switch (message.status) {
      case MessageStatus.sending:
        return const SizedBox(
          width: 10,
          height: 10,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Colors.white70,
          ),
        );
      case MessageStatus.sent:
        return const Icon(Icons.check_rounded, size: 11, color: Colors.white70);
      case MessageStatus.delivered:
        return const Icon(
          Icons.done_all_rounded,
          size: 11,
          color: Colors.white70,
        );
      case MessageStatus.read:
        return const Icon(
          Icons.done_all_rounded,
          size: 11,
          color: Colors.lightBlueAccent,
        );
      case MessageStatus.failed:
        return const Icon(
          Icons.error_outline_rounded,
          size: 11,
          color: Colors.redAccent,
        );
    }
  }

  void _showMessageOptions(BuildContext context) {
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
                    vertical: 4,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      message.hasAttachment && message.text.isEmpty
                          ? '📎 Attachment'
                          : message.text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                // Reply
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _kOrangeLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.reply_rounded,
                      color: _kOrange,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Reply',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    onReply(message);
                  },
                ),
                // Delete for me
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Delete for me',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await _confirmAndDelete(context, 'for_me');
                  },
                ),
                if (message.isMine)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete_forever_rounded,
                        color: Colors.red.shade600,
                        size: 20,
                      ),
                    ),
                    title: const Text(
                      'Delete for everyone',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      await _confirmAndDelete(context, 'for_everyone');
                    },
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    String deleteType,
  ) async {
    final label = deleteType == 'for_everyone' ? 'everyone' : 'you';
    final confirm =
        await showDialog<bool>(
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
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Delete Message',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                content: Text(
                  'This message will be deleted for $label.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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

    if (!confirm || !context.mounted) return;
    final success = await onDelete(message.id, deleteType);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to delete message'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Supporting widgets (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AttachOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.radius,
  });
  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _anim,
    child: Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(widget.radius),
      ),
    ),
  );
}

class _MiniAvatar extends StatelessWidget {
  final String avatar;
  final String name;
  const _MiniAvatar({required this.avatar, required this.name});
  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return SizedBox(
      width: 28,
      height: 28,
      child: ClipOval(
        child:
            avatar.isNotEmpty
                ? CachedNetworkImage(
                  imageUrl: avatar,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _fb(initial),
                )
                : _fb(initial),
      ),
    );
  }

  Widget _fb(String initial) => Container(
    color: _kOrangeLight,
    child: Center(
      child: Text(
        initial,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: _kOrange,
          fontSize: 11,
        ),
      ),
    ),
  );
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;
  late final List<Animation<double>> _anims;
  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      ),
    );
    _anims =
        _ctrls
            .map(
              (c) => Tween<double>(
                begin: 0,
                end: -6,
              ).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)),
            )
            .toList();
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) _ctrls[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _anims[i],
          builder:
              (_, __) => Transform.translate(
                offset: Offset(0, _anims[i].value),
                child: Container(
                  width: 7,
                  height: 7,
                  margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
        );
      }),
    );
  }
}

class _PulsingAvatar extends StatefulWidget {
  final String avatar;
  final String name;
  final bool isOnline;

  const _PulsingAvatar({
    required this.avatar,
    required this.name,
    required this.isOnline,
  });

  @override
  State<_PulsingAvatar> createState() => _PulsingAvatarState();
}

class _PulsingAvatarState extends State<_PulsingAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.name.isNotEmpty ? widget.name[0].toUpperCase() : '?';

    return ScaleTransition(
      scale: _scale,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_kOrange, Color(0xFFFFCC00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Avatar
          ClipOval(
            child: SizedBox(
              width: 88,
              height: 88,
              child:
                  widget.avatar.isNotEmpty
                      ? CachedNetworkImage(
                        imageUrl: widget.avatar,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _fallback(initial),
                      )
                      : _fallback(initial),
            ),
          ),
          // Online dot
          if (widget.isOnline)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2ECC71).withOpacity(0.5),
                      blurRadius: 6,
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

  Widget _fallback(String initial) => Container(
    color: _kOrangeLight,
    child: Center(
      child: Text(
        initial,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: _kOrange,
          fontSize: 32,
        ),
      ),
    ),
  );
}

/// Tappable greeting chip
class _GreetingChip extends StatefulWidget {
  final String emoji;
  final String label;
  final VoidCallback onTap;

  const _GreetingChip({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  State<_GreetingChip> createState() => _GreetingChipState();
}

class _GreetingChipState extends State<_GreetingChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.93,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color.fromRGBO(244, 135, 6, 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}