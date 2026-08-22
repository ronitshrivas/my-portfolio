import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:innovator/core/config/api_config.dart';
import 'package:innovator/services/auth_session.dart';

/// A realtime chat event from the ChatService WebSocket (`/ws/chat`).
/// The server sends `{ "event": <type>, "data": {...} }`.
class ChatSocketEvent {
  const ChatSocketEvent(this.event, this.data);
  final String event;
  final Map<String, dynamic> data;
}

/// backoff. Call [connect] after login and [dispose] on logout.
class ChatSocket {
  ChatSocket._();
  static final ChatSocket instance = ChatSocket._();

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _ping;
  Timer? _reconnect;
  bool _wantConnected = false;
  int _attempt = 0;

  final _controller = StreamController<ChatSocketEvent>.broadcast();

  /// Stream of all incoming events (e.g. `new_message`).
  Stream<ChatSocketEvent> get events => _controller.stream;

  /// Convenience: only `new_message` events.
  Stream<Map<String, dynamic>> get messages => _controller.stream
      .where((e) => e.event == 'new_message')
      .map((e) => e.data);

  /// Convenience: `messages_read` events (the other side read your messages).
  Stream<Map<String, dynamic>> get reads => _controller.stream
      .where((e) => e.event == 'messages_read')
      .map((e) => e.data);

  bool get isConnected => _channel != null;

  void connect() {
    _wantConnected = true;
    _open();
  }

  void _open() {
    final token = AuthSession.instance.accessToken;
    if (token == null || token.isEmpty) {
      debugPrint('[ChatSocket] no access token; not connecting');
      return;
    }

    // http -> ws, https -> wss.
    final base = ApiConfig.chatBaseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    final uri = Uri.parse('$base/ws/chat?token=$token');
    debugPrint('[ChatSocket] connecting to $base/ws/chat');

    try {
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      _sub = channel.stream.listen(
        _onData,
        onDone: () {
          debugPrint('[ChatSocket] closed (onDone)');
          _onClosed();
        },
        onError: (Object e) {
          debugPrint('[ChatSocket] error: $e');
          _onClosed();
        },
        cancelOnError: true,
      );
      _attempt = 0;
      _startPing();
      debugPrint('[ChatSocket] connected, listening');
    } catch (e) {
      debugPrint('[ChatSocket] connect threw: $e');
      _scheduleReconnect();
    }
  }

  void _onData(dynamic raw) {
    try {
      debugPrint('[ChatSocket] frame: $raw');
      final map = jsonDecode(raw as String) as Map<String, dynamic>;
      final event = (map['event'] ?? map['@event'] ?? '').toString();
      final data = map['data'] is Map
          ? Map<String, dynamic>.from(map['data'] as Map)
          : <String, dynamic>{};
      if (event.isNotEmpty) {
        _controller.add(ChatSocketEvent(event, data));
      }
    } catch (_) {
      // Ignore malformed frames.
    }
  }

  void _startPing() {
    _ping?.cancel();
    _ping = Timer.periodic(const Duration(seconds: 25), (_) {
      final ch = _channel;
      if (ch == null) return;
      try {
        ch.sink.add(jsonEncode({'event': 'ping'}));
      } catch (_) {}
    });
  }

  void _onClosed() {
    _cleanupSocket();
    if (_wantConnected) _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnect?.cancel();
    _attempt = (_attempt + 1).clamp(1, 6);
    final delay = Duration(seconds: _attempt * 2); // 2,4,…,12s
    _reconnect = Timer(delay, () {
      if (_wantConnected) _open();
    });
  }

  void _cleanupSocket() {
    _ping?.cancel();
    _ping = null;
    _sub?.cancel();
    _sub = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  /// Closes the connection and stops reconnecting (call on logout).
  void dispose() {
    _wantConnected = false;
    _reconnect?.cancel();
    _reconnect = null;
    _cleanupSocket();
  }
}
