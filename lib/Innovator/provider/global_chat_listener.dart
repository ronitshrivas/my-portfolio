import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/provider/mutual_friend_state.dart';
import 'package:innovator/Innovator/provider/unread_count_provider.dart';
import 'package:innovator/Innovator/screens/chatrrom/screen/chatlistscreen.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

// ─────────────────────────────────────────────────────────────────────────────
// GlobalChatListener — one WS connection per friend, lives at app level
// Increments perFriendUnreadProvider when a new message arrives from any friend
// while the user is NOT inside that friend's ChatScreen.
// ─────────────────────────────────────────────────────────────────────────────

class GlobalChatListener {
  final Ref _ref;

  /// friendId → active WebSocket channel
  final Map<String, WebSocketChannel> _channels = {};

  /// friendId → stream subscription
  final Map<String, StreamSubscription> _subs = {};

  /// friendId → reconnect timer
  final Map<String, Timer> _reconnectTimers = {};

  /// Which chatScreen is currently open (set by ChatScreen on enter/exit)
  String? activeChatUserId;

  GlobalChatListener(this._ref);

  String get _token => AppData().accessToken ?? '';
  static const _wsBase = 'ws://36.253.137.34:8005';

  // ── Connect to all friends ────────────────────────────────────────────────

  void connectAll(List<String> friendIds) {
    for (final id in friendIds) {
      if (!_channels.containsKey(id)) {
        _connect(id);
      }
    }
    // Disconnect any channel no longer in the friend list
    final toRemove =
        _channels.keys.where((id) => !friendIds.contains(id)).toList();
    for (final id in toRemove) {
      _disconnect(id);
    }
  }

  void _connect(String friendId) {
    if (_token.isEmpty) return;
    try {
      final uri = Uri.parse('$_wsBase/ws/chat/$friendId/?token=$_token');
      final channel = IOWebSocketChannel.connect(
        uri,
        pingInterval: const Duration(seconds: 30),
      );
      _channels[friendId] = channel;

      _subs[friendId] = channel.stream.listen(
        (raw) => _onMessage(friendId, raw),
        onError: (_) => _scheduleReconnect(friendId),
        onDone: () => _scheduleReconnect(friendId),
        cancelOnError: false,
      );
      developer.log('[GlobalWS] Connected to $friendId');
    } catch (e) {
      developer.log('[GlobalWS] Connect error for $friendId: $e');
      _scheduleReconnect(friendId);
    }
  }

  void _onMessage(String friendId, dynamic raw) {
    try {
      final data = json.decode(raw.toString()) as Map<String, dynamic>;

      final type = data['type']?.toString() ?? '';
      if (type == 'typing' ||
          type == 'mark_as_read' ||
          type == 'messages_read') {
        return;
      }

      final msgText =
          data['message']?.toString() ??
          data['content']?.toString() ??
          data['text']?.toString() ??
          '';
      if (msgText.isEmpty) return;

      final senderId =
          data['sender']?.toString() ??
          data['sender_id']?.toString() ??
          data['from']?.toString() ??
          '';

      final myId = AppData().currentUserId ?? '';

      if (senderId.isEmpty || senderId == myId) return;

      if (senderId != friendId) return;

      if (activeChatUserId == friendId) return;

      _ref.read(perFriendUnreadProvider.notifier).increment(friendId);
      _ref.read(friendActivityProvider.notifier).markActivity(friendId);
      _ref.read(mutualFriendsProvider.notifier).bumpToTop(friendId);
      developer.log('[GlobalWS] New msg from $friendId — badge incremented');
    } catch (e) {
      developer.log('[GlobalWS] Parse error: $e');
    }
  }

  void _scheduleReconnect(String friendId) {
    _subs[friendId]?.cancel();
    _channels.remove(friendId);
    _reconnectTimers[friendId]?.cancel();
    _reconnectTimers[friendId] = Timer(const Duration(seconds: 5), () {
      if (_channels.containsKey(friendId)) return; // already reconnected
      _connect(friendId);
    });
  }

  void _disconnect(String friendId) {
    _reconnectTimers[friendId]?.cancel();
    _reconnectTimers.remove(friendId);
    _subs[friendId]?.cancel();
    _subs.remove(friendId);
    _channels[friendId]?.sink.close();
    _channels.remove(friendId);
    developer.log('[GlobalWS] Disconnected from $friendId');
  }

  void disconnectAll() {
    for (final id in List.from(_channels.keys)) {
      _disconnect(id);
    }
  }
}

// ── Provider — lives for the entire app lifetime (no autoDispose) ──────────

final globalChatListenerProvider = Provider<GlobalChatListener>((ref) {
  final listener = GlobalChatListener(ref);

  // Watch the friends list and connect/reconnect when it changes
  ref.listen<MutualFriendsState>(mutualFriendsProvider, (_, next) {
    if (next.friends.isNotEmpty) {
      final ids = next.friends.map((f) => f.id).toList();
      listener.connectAll(ids);
    }
  });

  ref.onDispose(listener.disconnectAll);
  return listener;
});

// ── Convenience provider to set/clear the active chat screen ──────────────
// Call this from ChatScreen so GlobalChatListener stops counting that friend.

final activeChatUserIdProvider = StateProvider<String?>((ref) => null);
