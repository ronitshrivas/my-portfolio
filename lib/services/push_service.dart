import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:innovator/innovator/data/sources/fcm_token_api.dart';

/// Background isolate handler. Must be a top-level function annotated with
/// `vm:entry-point` so it survives tree-shaking and runs when the app is dead.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No UI work here — the system tray already shows the notification. This
  // exists so data-only messages are still delivered to the isolate.
}

/// End-to-end push notifications: FCM registration, foreground display through
/// flutter_local_notifications, and tap deep-linking.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  /// Set from main() so taps can navigate from anywhere.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final _messaging = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();
  final _tokenApi = FcmTokenApi();

  // Must match the manifest's
  // com.google.firebase.messaging.default_notification_channel_id so
  // foreground (local) and background (system tray) notifications share one
  // high-importance channel.
  static const _channelId = 'high_importance_channel';
  static const _channelName = 'High Importance Notifications';
  static const _kFeedTokenId = 'fcm_feed_token_id';

  bool _localReady = false;

  /// Routes a tapped notification using its FCM data map. Assigned by the app
  /// shell (dashboard) so deep-links land on the right screen.
  void Function(Map<String, dynamic> data)? onDeepLink;

  /// One-time local-notifications setup — call from main() before runApp.
  Future<void> initLocalNotifications() async {
    if (_localReady) return;
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final data = Map<String, dynamic>.from(jsonDecode(payload) as Map);
          handleTap(data);
        } catch (_) {}
      },
    );

    // Android channel for high-importance heads-up notifications.
    final androidPlugin =
        _local.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Likes, comments, follows and messages',
        importance: Importance.high,
      ),
    );
    _localReady = true;
  }

  /// Requests permission, gets the FCM token, registers it, and wires the
  /// foreground + tap listeners. Call after a successful login.
  Future<void> init() async {
    await initLocalNotifications();

    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _registerToken(token);
    }

    _messaging.onTokenRefresh.listen((newToken) {
      _registerToken(newToken);
    });

    FirebaseMessaging.onMessage.listen(_showForeground);
    FirebaseMessaging.onMessageOpenedApp.listen((m) => handleTap(m.data));

    // App launched from a terminated state by tapping a notification.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      handleTap(initial.data);
    }
  }

  Future<void> _registerToken(String token) async {
    final deviceName = _deviceName();
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingId = prefs.getString(_kFeedTokenId);
      if (existingId != null && existingId.isNotEmpty) {
        await _tokenApi.updateFeed(
          tokenId: existingId,
          token: token,
          deviceName: deviceName,
        );
      } else {
        final id = await _tokenApi.registerFeed(
          token: token,
          deviceName: deviceName,
        );
        if (id != null && id.isNotEmpty) {
          await prefs.setString(_kFeedTokenId, id);
        }
      }
    } catch (_) {
      // Registration is best-effort; a refresh or next login retries.
    }
    try {
      await _tokenApi.registerEcommerce(token: token);
    } catch (_) {}
  }

  /// Deletes the stored token record — call on logout.
  Future<void> unregister() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(_kFeedTokenId);
      if (id != null && id.isNotEmpty) {
        await _tokenApi.deleteFeed(id);
      }
      await prefs.remove(_kFeedTokenId);
      await _messaging.deleteToken();
    } catch (_) {}
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'Innovator';
    final body = notification?.body ?? message.data['message'] ?? '';
    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  /// Central deep-link router. Reads type + related_post_id from the FCM data
  /// and hands off to the app shell via [onDeepLink].
  void handleTap(Map<String, dynamic> data) {
    if (data.isEmpty) return;
    final normalized = data.map((k, v) => MapEntry(k, v));
    final link = onDeepLink;
    if (link != null) {
      link(normalized);
    } else {
      // Route registered later — stash it so the shell can consume it on start.
      _pending = normalized;
    }
  }

  Map<String, dynamic>? _pending;

  /// Consumed by the app shell once it has registered [onDeepLink].
  Map<String, dynamic>? takePendingDeepLink() {
    final p = _pending;
    _pending = null;
    return p;
  }

  String _deviceName() {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    return defaultTargetPlatform.name;
  }
}
