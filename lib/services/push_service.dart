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
  // The backend sends data-only messages, so the system tray no longer shows
  // anything on its own — this isolate must render the notification itself.
  await PushService.instance.showFromMessage(message);
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

  /// Fires whenever a push arrives while the app is in the foreground. The shell
  /// uses this to refresh badges (chat / notifications) live.
  void Function(Map<String, dynamic> data)? onForegroundMessage;

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

    final androidPlugin =
        _local.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Android 13+: the local-notifications plugin needs the POST_NOTIFICATIONS
    // runtime permission granted, otherwise show() silently does nothing.
    final granted = await androidPlugin?.requestNotificationsPermission();
    debugPrint('[Push] POST_NOTIFICATIONS granted=$granted');

    // Recreate the channel at MAX importance. Android caches channel settings,
    // so if it was ever created at a lower importance the heads-up pop-up won't
    // appear — deleting first forces the new importance to take effect.
    await androidPlugin?.deleteNotificationChannel(_channelId);
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'Likes, comments, follows and messages',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );
    _localReady = true;
  }

  bool _listenersAttached = false;

  /// Attaches the foreground-message + tap listeners exactly once. Safe to call
  /// from main() at launch, before login, so foreground pushes always show.
  void attachForegroundListener() {
    if (_listenersAttached) return;
    _listenersAttached = true;
    debugPrint('[Push] foreground listener attached');
    FirebaseMessaging.onMessage.listen(_showForeground);
    FirebaseMessaging.onMessageOpenedApp.listen((m) => handleTap(m.data));
  }

  bool _permissionsRequested = false;

  /// Prompts for notification permission (FCM + local plugin) exactly once, and
  /// enables foreground presentation. Safe to call at launch before login.
  Future<void> ensurePermissions() async {
    if (_permissionsRequested) return;
    _permissionsRequested = true;
    final settings =
        await _messaging.requestPermission(alert: true, badge: true, sound: true);
    debugPrint('[Push] FCM authorizationStatus=${settings.authorizationStatus}');
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  /// Requests permission, gets the FCM token, registers it, and wires the
  /// tap-from-cold-start handler. Call after a successful login.
  Future<void> init() async {
    await initLocalNotifications();
    attachForegroundListener();
    await ensurePermissions();

    // getToken can throw SERVICE_NOT_AVAILABLE when Play Services / the network
    // is briefly unreachable. Don't let that abort init — retry a few times with
    // backoff, and rely on onTokenRefresh to catch up if it never succeeds now.
    await _fetchAndRegisterToken();

    _messaging.onTokenRefresh.listen((newToken) {
      _registerToken(newToken);
    });

    // App launched from a terminated state by tapping a notification.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      handleTap(initial.data);
    }
  }

  /// Fetches the FCM token with retries. Survives transient
  /// SERVICE_NOT_AVAILABLE errors so push setup doesn't abort.
  Future<void> _fetchAndRegisterToken() async {
    for (var attempt = 1; attempt <= 4; attempt++) {
      try {
        final token = await _messaging.getToken();
        if (token != null && token.isNotEmpty) {
          debugPrint('[Push] FCM token acquired (attempt $attempt)');
          await _registerToken(token);
          return;
        }
      } catch (e) {
        debugPrint('[Push] getToken attempt $attempt failed: $e');
      }
      await Future<void>.delayed(Duration(seconds: attempt * 3));
    }
    debugPrint('[Push] getToken gave up; onTokenRefresh will retry later');
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
    debugPrint('[Push] onMessage fired — data=${message.data}');
    await showFromMessage(message);
  }

  /// Renders a heads-up notification from an FCM message. Works from both the
  /// foreground listener and the background isolate, since the backend now
  /// sends data-only payloads that never auto-display in the tray.
  Future<void> showFromMessage(RemoteMessage message) async {
    // Make sure the channel exists even if init() hasn't run yet in this
    // isolate, so the notification always has a place to land.
    await initLocalNotifications();

    // Let the shell refresh its badges live (chat / notifications).
    onForegroundMessage?.call(message.data);

    final notification = message.notification;
    final data = message.data;
    final title = notification?.title ??
        (data['title']?.toString().trim().isNotEmpty == true
            ? data['title'].toString().trim()
            : (data['sender_username']?.toString().trim().isNotEmpty == true
                ? data['sender_username'].toString().trim()
                : 'Innovator'));
    final body = notification?.body ??
        (data['body']?.toString().trim().isNotEmpty == true
            ? data['body'].toString().trim()
            : (data['message']?.toString().trim().isNotEmpty == true
                ? data['message'].toString().trim()
                : 'You have a new notification'));

    await showLocal(title: title, body: body, data: data);
  }

  /// Shows a heads-up local notification. Reused by the FCM foreground path and
  /// the notification poller. [id] lets callers avoid duplicate notifications
  /// (e.g. the same server notification id); defaults to a time-based id.
  Future<void> showLocal({
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
    int? id,
  }) async {
    await initLocalNotifications();
    final notifId = id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
    debugPrint('[Push] showing local notification — title="$title" body="$body"');
    try {
      await _local.show(
        notifId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: 'Likes, comments, follows and messages',
            importance: Importance.max,
            priority: Priority.high,
            // Bare resource name — flutter_local_notifications resolves this
            // against res/; the '@mipmap/' prefix makes show() fail silently.
            icon: 'ic_launcher',
            ticker: title,
            visibility: NotificationVisibility.public,
            styleInformation: BigTextStyleInformation(body, contentTitle: title),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(data),
      );
      debugPrint('[Push] _local.show() completed');
    } catch (e, st) {
      debugPrint('[Push] _local.show() FAILED: $e\n$st');
    }
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
