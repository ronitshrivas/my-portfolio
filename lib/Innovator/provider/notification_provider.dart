// import 'dart:async';
// import 'dart:collection';
// import 'dart:convert';
// import 'dart:isolate';
// import 'dart:developer' as developer;

// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:http/http.dart' as http;
// import 'package:innovator/Innovator/App_data/App_data.dart';

// class AppNotification {
//   final String id;
//   final String title;
//   final String body;
//   final String type;
//   final String? imageUrl;
//   final String? senderUsername;
//   final String? relatedPostId;
//   final DateTime createdAt;
//   final bool isRead;

//   const AppNotification({
//     required this.id,
//     required this.title,
//     required this.body,
//     required this.type,
//     this.imageUrl,
//     this.senderUsername,
//     this.relatedPostId,
//     required this.createdAt,
//     this.isRead = false,
//   });

//   factory AppNotification.fromJson(Map<String, dynamic> json) {
//     return AppNotification(
//       id: json['id'] as String? ?? '',
//       title:
//           json['title'] as String? ??
//           json['sender_username'] as String? ??
//           'New Notification',
//       body: json['message'] as String? ?? '',
//       type: json['type'] as String? ?? '',
//       imageUrl: json['sender_avatar'] as String?,
//       senderUsername: json['sender_username'] as String?,
//       relatedPostId: json['related_post_id'] as String?,
//       createdAt:
//           DateTime.tryParse(json['created_at'] as String? ?? '') ??
//           DateTime.now(),
//       isRead: json['is_read'] as bool? ?? false,
//     );
//   }

//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) || (other is AppNotification && other.id == id);

//   @override
//   int get hashCode => id.hashCode;
// }

// class _PollRequest {
//   final SendPort replyPort;
//   final String authToken;
//   final String url;
//   _PollRequest(this.replyPort, this.authToken, this.url);
// }

// class _PollResult {
//   final List<Map<String, dynamic>> notifications;
//   final String? error;
//   _PollResult({this.notifications = const [], this.error});
// }

// Future<void> _pollIsolateEntry(SendPort mainPort) async {
//   final receivePort = ReceivePort();
//   mainPort.send(receivePort.sendPort);

//   await for (final msg in receivePort) {
//     if (msg is _PollRequest) {
//       try {
//         final response = await http
//             .get(
//               Uri.parse(msg.url),
//               headers: {'Authorization': 'Bearer ${msg.authToken}'},
//             )
//             .timeout(const Duration(seconds: 10));

//         if (response.statusCode == 200) {
//           final decoded = jsonDecode(response.body);
//           final List<dynamic> list =
//               decoded is List
//                   ? decoded
//                   : (decoded as Map<String, dynamic>?)?['results']
//                           as List<dynamic>? ??
//                       [];
//           msg.replyPort.send(
//             _PollResult(
//               notifications: list.whereType<Map<String, dynamic>>().toList(
//                 growable: false,
//               ),
//             ),
//           );
//         } else {
//           msg.replyPort.send(_PollResult(error: 'HTTP ${response.statusCode}'));
//         }
//       } catch (e) {
//         msg.replyPort.send(_PollResult(error: e.toString()));
//       }
//     }
//   }
// }

// final FlutterLocalNotificationsPlugin _plugin =
//     FlutterLocalNotificationsPlugin();

// class NotificationState {
//   final Queue<AppNotification> displayQueue;
//   final AppNotification? current;
//   final int unreadCount;

//   NotificationState({
//     Queue<AppNotification>? displayQueue,
//     this.current,
//     this.unreadCount = 0,
//   }) : displayQueue = displayQueue ?? Queue<AppNotification>();

//   NotificationState copyWith({
//     Queue<AppNotification>? displayQueue,
//     AppNotification? current,
//     bool clearCurrent = false,
//     int? unreadCount,
//   }) {
//     return NotificationState(
//       displayQueue: displayQueue ?? this.displayQueue,
//       current: clearCurrent ? null : (current ?? this.current),
//       unreadCount: unreadCount ?? this.unreadCount,
//     );
//   }
// }

// class NotificationNotifier extends Notifier<NotificationState> {
//   static const String _apiUrl = 'http://36.253.137.34:8005/api/notifications/';
//   static const Duration _foregroundInterval = Duration(seconds: 8);
//   static const Duration _backgroundInterval = Duration(seconds: 30);

//   Isolate? _isolate;
//   SendPort? _isolateSendPort;
//   ReceivePort? _mainReceivePort;
//   Timer? _pollingTimer;

//   final LinkedHashSet<String> _seenIds = LinkedHashSet();

//   @override
//   NotificationState build() {
//     ref.onDispose(_teardown);
//     return NotificationState();
//   }

//   Future<void> startPolling() async {
//     await _spawnIsolate();
//     _startTimer(_foregroundInterval);
//     _triggerPoll();
//   }

//   void setAppActive(bool isActive) {
//     _startTimer(isActive ? _foregroundInterval : _backgroundInterval);
//     if (isActive) _triggerPoll();
//   }

//   void stopPolling() => _teardown();

//   void dismissCurrent() {
//     final queue = Queue<AppNotification>.from(state.displayQueue);
//     if (queue.isEmpty) {
//       state = state.copyWith(clearCurrent: true);
//       return;
//     }
//     final next = queue.removeFirst();
//     state = state.copyWith(current: next, displayQueue: queue);
//   }

//   void markRead(String id) {
//     if (state.unreadCount > 0) {
//       state = state.copyWith(unreadCount: state.unreadCount - 1);
//     }
//   }

//   void injectNotification(AppNotification notification) {
//     if (_seenIds.contains(notification.id)) return;
//     _seenIds.add(notification.id);
//     if (_seenIds.length > 200) _seenIds.remove(_seenIds.first);

//     final queue = Queue<AppNotification>.from(state.displayQueue);
//     AppNotification? current = state.current;

//     if (current == null) {
//       current = notification;
//     } else {
//       queue.addLast(notification);
//     }

//     state = state.copyWith(
//       current: current,
//       displayQueue: queue,
//       unreadCount: state.unreadCount + 1,
//     );
//   }

//   void clearAll() {
//     _seenIds.clear();
//     state = NotificationState();
//   }

//   Future<void> _spawnIsolate() async {
//     if (_isolate != null) return;

//     _mainReceivePort = ReceivePort();
//     _isolate = await Isolate.spawn(
//       _pollIsolateEntry,
//       _mainReceivePort!.sendPort,
//       debugName: 'NotificationPollIsolate',
//     );

//     final completer = Completer<SendPort>();
//     final sub = _mainReceivePort!.listen((msg) {
//       if (msg is SendPort && !completer.isCompleted) {
//         completer.complete(msg);
//       } else if (msg is _PollResult) {
//         _handlePollResult(msg);
//       }
//     });
//     ref.onDispose(sub.cancel);

//     _isolateSendPort = await completer.future;
//     developer.log('[NotificationProvider] Isolate spawned ✓');
//   }

//   void _startTimer(Duration interval) {
//     _pollingTimer?.cancel();
//     _pollingTimer = Timer.periodic(interval, (_) => _triggerPoll());
//     developer.log(
//       '[NotificationProvider] Polling every ${interval.inSeconds}s',
//     );
//   }

//   void _triggerPoll() {
//     final token = AppData().accessToken;
//     if (token == null || token.isEmpty || _isolateSendPort == null) return;

//     final replyPort = ReceivePort();
//     replyPort.listen((msg) {
//       if (msg is _PollResult) _handlePollResult(msg);
//       replyPort.close();
//     });

//     _isolateSendPort!.send(_PollRequest(replyPort.sendPort, token, _apiUrl));
//   }

//   void _handlePollResult(_PollResult result) {
//     if (result.error != null) {
//       developer.log('[NotificationProvider] Poll error: ${result.error}');
//       return;
//     }

//     final cutoff = DateTime.now().subtract(const Duration(minutes: 5));

//     final newOnes = result.notifications
//         .map((j) => AppNotification.fromJson(j))
//         .where(
//           (n) =>
//               !n.isRead &&
//               !_seenIds.contains(n.id) &&
//               n.createdAt.isAfter(cutoff),
//         )
//         .toList(growable: false);

//     if (newOnes.isEmpty) return;

//     for (final n in newOnes) {
//       _seenIds.add(n.id);
//     }

//     while (_seenIds.length > 200) {
//       _seenIds.remove(_seenIds.first);
//     }

//     for (final n in newOnes) {
//       _showSystemNotification(n);
//     }

//     final queue = Queue<AppNotification>.from(state.displayQueue);
//     AppNotification? current = state.current;

//     for (final n in newOnes) {
//       if (current == null) {
//         current = n;
//       } else {
//         queue.addLast(n);
//       }
//     }

//     state = state.copyWith(
//       current: current,
//       displayQueue: queue,
//       unreadCount: state.unreadCount + newOnes.length,
//     );

//     developer.log(
//       '[NotificationProvider] ${newOnes.length} new notification(s)',
//     );
//   }

//   void _teardown() {
//     _pollingTimer?.cancel();
//     _pollingTimer = null;
//     _isolate?.kill(priority: Isolate.immediate);
//     _isolate = null;
//     _mainReceivePort?.close();
//     _mainReceivePort = null;
//     _isolateSendPort = null;
//     developer.log('[NotificationProvider] Torn down');
//   }
// }

// final notificationProvider =
//     NotifierProvider<NotificationNotifier, NotificationState>(
//       NotificationNotifier.new,
//     );

// final currentNotificationProvider = Provider<AppNotification?>((ref) {
//   return ref.watch(notificationProvider.select((s) => s.current));
// });

// final notificationBadgeProvider = Provider<int>((ref) {
//   return ref.watch(notificationProvider.select((s) => s.unreadCount));
// });





// final Map<String, List<String>> _groupedMessages = {};

// Future<void> _showSystemNotification(AppNotification n) async {
//   try {
//     const groupKey = 'chat_messages';

//     final sender = n.senderUsername ?? 'User';

//     _groupedMessages.putIfAbsent(sender, () => []);
//     _groupedMessages[sender]!.add(n.body);

//     final messages = _groupedMessages[sender]!;

//     final inboxStyle = InboxStyleInformation(
//       messages,
//       contentTitle: sender,
//       summaryText: '${messages.length} messages',
//     );

//     final androidDetails = AndroidNotificationDetails(
//       'high_importance_channel',
//       'High Importance Notifications',
//       importance: Importance.max,
//       priority: Priority.max,

//       styleInformation: inboxStyle,
//       groupKey: groupKey,
//       setAsGroupSummary: false,

//       largeIcon:
//           n.imageUrl != null
//               ? await _getBitmapFromUrl(n.imageUrl!)
//               : const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),

//       icon: '@mipmap/ic_launcher',
//     );

//     await _plugin.show(
//       sender.hashCode, 
//       sender,
//       n.body,
//       NotificationDetails(android: androidDetails),
//       payload: jsonEncode({'id': n.id, 'type': n.type}),
//     );

//     // ✅ GROUP SUMMARY (like Facebook header)
//     final summaryDetails = AndroidNotificationDetails(
//       'high_importance_channel',
//       'High Importance Notifications',
//       importance: Importance.max,
//       priority: Priority.max,
//       groupKey: groupKey,
//       setAsGroupSummary: true,
//       styleInformation: const InboxStyleInformation([]),
//     );

//     await _plugin.show(
//       0,
//       'Messages',
//       'You have ${_groupedMessages.length} conversations',
//       NotificationDetails(android: summaryDetails),
//     );
//   } catch (e) {
//     developer.log('Notification error: $e');
//   }
// }

// Future<AndroidBitmap<Object>> _getBitmapFromUrl(String url) async {
//   final response = await http.get(Uri.parse(url));
//   return ByteArrayAndroidBitmap.fromBase64String(
//     base64Encode(response.bodyBytes),
//   );
// }



// lib/Innovator/provider/notification_provider.dart
//
// Changes vs original:
// 1. _showSystemNotification now attaches a JSON payload so tapping a
//    polled/local notification navigates correctly (same path as FCM tap).
// 2. Chat/message notifications get an Android "Reply" quick-action that
//    opens the ChatScreen with the sender pre-filled.
// 3. Mark-as-read is called via the navigation service when the user taps.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:isolate';
import 'dart:developer' as developer;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/App_data/App_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final String? imageUrl;
  final String? senderUsername;
  final String? senderId;
  final String? relatedPostId;
  final DateTime createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.imageUrl,
    this.senderUsername,
    this.senderId,
    this.relatedPostId,
    required this.createdAt,
    this.isRead = false,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? '',
      title:
          json['title'] as String? ??
          json['sender_username'] as String? ??
          'New Notification',
      body: json['message'] as String? ?? '',
      type: json['type'] as String? ?? '',
      imageUrl: json['sender_avatar'] as String?,
      senderUsername: json['sender_username'] as String?,
      senderId: json['sender'] as String?,
      relatedPostId: json['related_post_id'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is AppNotification && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

// ─────────────────────────────────────────────────────────────────────────────
// Isolate polling helpers (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _PollRequest {
  final SendPort replyPort;
  final String authToken;
  final String url;
  _PollRequest(this.replyPort, this.authToken, this.url);
}

class _PollResult {
  final List<Map<String, dynamic>> notifications;
  final String? error;
  _PollResult({this.notifications = const [], this.error});
}

Future<void> _pollIsolateEntry(SendPort mainPort) async {
  final receivePort = ReceivePort();
  mainPort.send(receivePort.sendPort);

  await for (final msg in receivePort) {
    if (msg is _PollRequest) {
      try {
        final response = await http
            .get(
              Uri.parse(msg.url),
              headers: {'Authorization': 'Bearer ${msg.authToken}'},
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          final List<dynamic> list =
              decoded is List
                  ? decoded
                  : (decoded as Map<String, dynamic>?)?['results']
                          as List<dynamic>? ??
                      [];
          msg.replyPort.send(
            _PollResult(
              notifications: list.whereType<Map<String, dynamic>>().toList(
                growable: false,
              ),
            ),
          );
        } else {
          msg.replyPort.send(_PollResult(error: 'HTTP ${response.statusCode}'));
        }
      } catch (e) {
        msg.replyPort.send(_PollResult(error: e.toString()));
      }
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Plugin instance (module-level so _showSystemNotification can use it)
// ─────────────────────────────────────────────────────────────────────────────

final FlutterLocalNotificationsPlugin _plugin =
    FlutterLocalNotificationsPlugin();

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class NotificationState {
  final Queue<AppNotification> displayQueue;
  final AppNotification? current;
  final int unreadCount;

  NotificationState({
    Queue<AppNotification>? displayQueue,
    this.current,
    this.unreadCount = 0,
  }) : displayQueue = displayQueue ?? Queue<AppNotification>();

  NotificationState copyWith({
    Queue<AppNotification>? displayQueue,
    AppNotification? current,
    bool clearCurrent = false,
    int? unreadCount,
  }) {
    return NotificationState(
      displayQueue: displayQueue ?? this.displayQueue,
      current: clearCurrent ? null : (current ?? this.current),
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class NotificationNotifier extends Notifier<NotificationState> {
  static const String _apiUrl = 'http://36.253.137.34:8005/api/notifications/';
  static const Duration _foregroundInterval = Duration(seconds: 8);
  static const Duration _backgroundInterval = Duration(seconds: 30);

  Isolate? _isolate;
  SendPort? _isolateSendPort;
  ReceivePort? _mainReceivePort;
  Timer? _pollingTimer;

  final LinkedHashSet<String> _seenIds = LinkedHashSet();

  @override
  NotificationState build() {
    ref.onDispose(_teardown);
    return NotificationState();
  }

  Future<void> startPolling() async {
    await _spawnIsolate();
    _startTimer(_foregroundInterval);
    _triggerPoll();
  }

  void setAppActive(bool isActive) {
    _startTimer(isActive ? _foregroundInterval : _backgroundInterval);
    if (isActive) _triggerPoll();
  }

  void stopPolling() => _teardown();

  void dismissCurrent() {
    final queue = Queue<AppNotification>.from(state.displayQueue);
    if (queue.isEmpty) {
      state = state.copyWith(clearCurrent: true);
      return;
    }
    final next = queue.removeFirst();
    state = state.copyWith(current: next, displayQueue: queue);
  }

  void markRead(String id) {
    if (state.unreadCount > 0) {
      state = state.copyWith(unreadCount: state.unreadCount - 1);
    }
  }

  void injectNotification(AppNotification notification) {
    if (_seenIds.contains(notification.id)) return;
    _seenIds.add(notification.id);
    if (_seenIds.length > 200) _seenIds.remove(_seenIds.first);

    final queue = Queue<AppNotification>.from(state.displayQueue);
    AppNotification? current = state.current;

    if (current == null) {
      current = notification;
    } else {
      queue.addLast(notification);
    }

    state = state.copyWith(
      current: current,
      displayQueue: queue,
      unreadCount: state.unreadCount + 1,
    );
  }

  void clearAll() {
    _seenIds.clear();
    state = NotificationState();
  }

  Future<void> _spawnIsolate() async {
    if (_isolate != null) return;

    _mainReceivePort = ReceivePort();
    _isolate = await Isolate.spawn(
      _pollIsolateEntry,
      _mainReceivePort!.sendPort,
      debugName: 'NotificationPollIsolate',
    );

    final completer = Completer<SendPort>();
    final sub = _mainReceivePort!.listen((msg) {
      if (msg is SendPort && !completer.isCompleted) {
        completer.complete(msg);
      } else if (msg is _PollResult) {
        _handlePollResult(msg);
      }
    });
    ref.onDispose(sub.cancel);

    _isolateSendPort = await completer.future;
    developer.log('[NotificationProvider] Isolate spawned ✓');
  }

  void _startTimer(Duration interval) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) => _triggerPoll());
    developer.log(
      '[NotificationProvider] Polling every ${interval.inSeconds}s',
    );
  }

  void _triggerPoll() {
    final token = AppData().accessToken;
    if (token == null || token.isEmpty || _isolateSendPort == null) return;

    final replyPort = ReceivePort();
    replyPort.listen((msg) {
      if (msg is _PollResult) _handlePollResult(msg);
      replyPort.close();
    });

    _isolateSendPort!.send(_PollRequest(replyPort.sendPort, token, _apiUrl));
  }

  void _handlePollResult(_PollResult result) {
    if (result.error != null) {
      developer.log('[NotificationProvider] Poll error: ${result.error}');
      return;
    }

    final cutoff = DateTime.now().subtract(const Duration(minutes: 5));

    final newOnes = result.notifications
        .map((j) => AppNotification.fromJson(j))
        .where(
          (n) =>
              !n.isRead &&
              !_seenIds.contains(n.id) &&
              n.createdAt.isAfter(cutoff),
        )
        .toList(growable: false);

    if (newOnes.isEmpty) return;

    for (final n in newOnes) {
      _seenIds.add(n.id);
    }

    while (_seenIds.length > 200) {
      _seenIds.remove(_seenIds.first);
    }

    for (final n in newOnes) {
      _showSystemNotification(n);
    }

    final queue = Queue<AppNotification>.from(state.displayQueue);
    AppNotification? current = state.current;

    for (final n in newOnes) {
      if (current == null) {
        current = n;
      } else {
        queue.addLast(n);
      }
    }

    state = state.copyWith(
      current: current,
      displayQueue: queue,
      unreadCount: state.unreadCount + newOnes.length,
    );

    developer.log(
      '[NotificationProvider] ${newOnes.length} new notification(s)',
    );
  }

  void _teardown() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _mainReceivePort?.close();
    _mainReceivePort = null;
    _isolateSendPort = null;
    developer.log('[NotificationProvider] Torn down');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(
      NotificationNotifier.new,
    );

final currentNotificationProvider = Provider<AppNotification?>((ref) {
  return ref.watch(notificationProvider.select((s) => s.current));
});

final notificationBadgeProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider.select((s) => s.unreadCount));
});

// ─────────────────────────────────────────────────────────────────────────────
// Local notification display (with payload + reply action for chat)
// ─────────────────────────────────────────────────────────────────────────────

final Map<String, List<String>> _groupedMessages = {};

Future<void> _showSystemNotification(AppNotification n) async {
  try {
    const groupKey = 'chat_messages';
    final sender = n.senderUsername ?? 'User';

    _groupedMessages.putIfAbsent(sender, () => []);
    _groupedMessages[sender]!.add(n.body);

    final messages = _groupedMessages[sender]!;

    final inboxStyle = InboxStyleInformation(
      messages,
      contentTitle: sender,
      summaryText: '${messages.length} messages',
    );

    // FIX: build a proper payload so tapping this notification navigates
    final payload = jsonEncode({
      'id': n.id,
      'type': n.type,
      'senderId': n.senderId ?? '',
      'senderName': sender,
      'senderAvatar': n.imageUrl ?? '',
      'relatedPostId': n.relatedPostId ?? '',
    });

    // FIX: Add a "Reply" quick-action for chat/message notifications
    final bool isChat = _isChatType(n.type);
    final List<AndroidNotificationAction> actions =
        isChat
            ? [
              const AndroidNotificationAction(
                'reply_action',      // id
                'Reply',             // label
                showsUserInterface: true, // opens the app → ChatScreen
                cancelNotification: true,
              ),
            ]
            : [];

    final androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.max,
      styleInformation: inboxStyle,
      groupKey: groupKey,
      setAsGroupSummary: false,
      largeIcon:
          n.imageUrl != null
              ? await _getBitmapFromUrl(n.imageUrl!)
              : const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      icon: '@mipmap/ic_launcher',
      actions: actions, // ← Reply button for chat notifications
    );

    await _plugin.show(
      sender.hashCode,
      sender,
      n.body,
      NotificationDetails(android: androidDetails),
      payload: payload, // ← FIX: was only {id, type}, now has all nav data
    );

    // Group summary
    final summaryDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.max,
      groupKey: groupKey,
      setAsGroupSummary: true,
      styleInformation: const InboxStyleInformation([]),
    );

    await _plugin.show(
      0,
      'Messages',
      'You have ${_groupedMessages.length} conversations',
      NotificationDetails(android: summaryDetails),
    );
  } catch (e) {
    developer.log('Notification error: $e');
  }
}

bool _isChatType(String type) {
  final t = type.toLowerCase();
  return t == 'chat' || t == 'message' || t == 'chat_message' || t == 'new_message';
}

Future<AndroidBitmap<Object>> _getBitmapFromUrl(String url) async {
  final response = await http.get(Uri.parse(url));
  return ByteArrayAndroidBitmap.fromBase64String(
    base64Encode(response.bodyBytes),
  );
}