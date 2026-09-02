import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:innovator/innovator/data/models/feed_models.dart';
import 'package:innovator/innovator/data/sources/feed_api.dart';
import 'package:innovator/services/auth_session.dart';
import 'package:innovator/services/push_service.dart';

/// Polls the notifications endpoint on an interval and shows a local heads-up
/// notification for anything new that arrived since the last check. This is a
/// reliable fallback for foreground alerts that doesn't depend on FCM delivery
/// (which some OEM ROMs drop while the app is open).
///
/// It runs only while the app is in the foreground and the user is signed in.
class NotificationPoller {
  NotificationPoller._();
  static final NotificationPoller instance = NotificationPoller._();

  final _api = FeedApi();
  Timer? _timer;
  bool _running = false;

  /// Ids we've already surfaced this session, so a notification is shown once.
  final Set<String> _seenIds = {};

  /// The newest notification time we've seen. Only notifications strictly newer
  /// than this trigger a local alert (so the first poll doesn't spam history).
  DateTime? _highWaterMark;
  bool _primed = false;

  /// Called by the shell to trigger the badge refresh when new items arrive.
  void Function()? onNewNotifications;

  static const _interval = Duration(seconds: 20);

  /// Starts polling (idempotent). Safe to call whenever the app resumes.
  void start() {
    if (_running) return;
    _running = true;
    // First tick primes the high-water mark without alerting on history.
    _poll(prime: !_primed);
    _timer = Timer.periodic(_interval, (_) => _poll());
  }

  /// Stops polling (call when the app backgrounds or the user logs out).
  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  /// Clears state on logout so the next user starts fresh.
  void reset() {
    stop();
    _seenIds.clear();
    _highWaterMark = null;
    _primed = false;
  }

  Future<void> _poll({bool prime = false}) async {
    if (!AuthSession.instance.isSignedIn) return;
    List<FeedNotification> items;
    try {
      items = await _api.notifications();
    } catch (_) {
      return; // offline or transient — try again next tick
    }
    if (items.isEmpty) {
      _primed = true;
      return;
    }

    // Newest first isn't guaranteed; find the max time ourselves.
    DateTime maxTime = _highWaterMark ?? DateTime.fromMillisecondsSinceEpoch(0);

    // On the priming poll we only record state, we don't alert — otherwise the
    // user would get a burst of notifications for their whole history on launch.
    if (prime || !_primed) {
      for (final n in items) {
        _seenIds.add(n.id);
        final t = n.createdAt;
        if (t != null && t.isAfter(maxTime)) maxTime = t;
      }
      _highWaterMark = maxTime;
      _primed = true;
      return;
    }

    // Newest-first so multiple new items show in a sensible order.
    final sorted = [...items]..sort((a, b) {
        final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return at.compareTo(bt); // ascending; show oldest-new first
      });

    var sawNew = false;
    for (final n in sorted) {
      if (n.id.isEmpty || _seenIds.contains(n.id)) continue;
      final t = n.createdAt;
      // Only alert on genuinely new + unread notifications.
      final isNew = t == null || _highWaterMark == null || t.isAfter(_highWaterMark!);
      _seenIds.add(n.id);
      if (t != null && t.isAfter(maxTime)) maxTime = t;
      if (!isNew || n.isRead) continue;

      sawNew = true;
      final title = _titleFor(n);
      final body = _bodyFor(n);
      await PushService.instance.showLocal(
        title: title,
        body: body,
        id: n.id.hashCode & 0x7fffffff,
        data: {
          'type': n.type ?? '',
          'notification_id': n.id,
          'related_post_id': n.relatedPostId ?? '',
        },
      );
    }

    _highWaterMark = maxTime;
    if (sawNew) {
      onNewNotifications?.call();
      debugPrint('[Poller] surfaced new notification(s)');
    }
  }

  String _titleFor(FeedNotification n) {
    final sender = n.senderUsername?.trim();
    if (sender != null && sender.isNotEmpty) return sender;
    final t = n.title?.trim();
    return (t != null && t.isNotEmpty) ? t : 'Innovator';
  }

  String _bodyFor(FeedNotification n) {
    final m = n.message?.trim();
    if (m != null && m.isNotEmpty) return m;
    // Fall back to a friendly line from the type.
    return switch ((n.type ?? '').toLowerCase()) {
      'like' => 'reacted to your post',
      'comment' => 'commented on your post',
      'follow' => 'started following you',
      'repost' => 'reposted your post',
      'message' => 'sent you a message',
      _ => 'You have a new notification',
    };
  }
}
