import 'dart:async';

import 'package:innovator/innovator/data/sources/feed_api.dart';

/// Buffers the ids of feed posts the user has actually seen and batch-reports
/// them to the backend so the ranked feed stops re-showing them.
///
/// Safe to call rapidly during scrolling: [record] is O(1) and never triggers
/// a network call directly. The buffer flushes to `POST /api/feed/views` after
/// ~5s of inactivity OR once it reaches ~20 ids, whichever comes first, and on
/// [dispose]. Ids reported once in a session are never sent again.
class ViewReporter {
  ViewReporter({FeedApi? api}) : _api = api ?? FeedApi();

  final FeedApi _api;

  static const _flushEvery = Duration(seconds: 5);
  static const _flushAt = 20;

  final Set<String> _buffer = {};
  final Set<String> _reported = {};
  Timer? _timer;
  bool _disposed = false;

  /// Records a seen post id. Deduped within the session; ignores empties.
  void record(String postId) {
    if (_disposed || postId.isEmpty) return;
    if (_reported.contains(postId) || _buffer.contains(postId)) return;
    _buffer.add(postId);
    if (_buffer.length >= _flushAt) {
      flush();
    } else {
      _timer ??= Timer(_flushEvery, flush);
    }
  }

  /// Sends the buffered ids now (fire-and-forget). Called by the timer, the
  /// size trigger, and on dispose / leaving the feed.
  void flush() {
    _timer?.cancel();
    _timer = null;
    if (_buffer.isEmpty) return;
    final ids = _buffer.toList();
    _buffer.clear();
    _reported.addAll(ids);
    // Fire-and-forget; reportViews swallows its own errors.
    unawaited(_api.reportViews(ids));
  }

  void dispose() {
    if (_disposed) return;
    flush();
    _disposed = true;
    _timer?.cancel();
    _timer = null;
  }
}
