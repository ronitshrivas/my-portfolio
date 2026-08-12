import 'dart:async';
import 'dart:collection';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'package:innovator/innovator/data/models/feed_models.dart';

/// Disk + memory cache tuned for fast feed media.
///
/// Images are prefetched aggressively. Full video files are NOT prefetched
/// (they starve image bandwidth); videos stream on demand.
class InnovatorMediaCache {
  InnovatorMediaCache._();

  static const cacheKey = 'innovatorMediaV3';

  /// Shared manager — resized images stay small on disk. Must be an
  /// [ImageCacheManager] so `cached_network_image` can honour memCacheWidth /
  /// maxWidthDiskCache; a plain CacheManager throws an assertion on resize.
  static final _InnovatorCacheManager instance = _InnovatorCacheManager();

  /// Feed media and avatars are served as public static files, so image
  /// requests carry no auth header — attaching one makes some static hosts
  /// reject the request. Kept as a hook in case a host later needs auth.
  static Map<String, String> authHeaders(String url) => const {};

  static const _maxConcurrent = 6;
  static int _active = 0;
  static final Queue<String> _queue = Queue<String>();
  static final Set<String> _queuedOrDone = {};

  /// Warm image/avatar thumbs only — never full video bodies.
  static void prefetchPosts(
    Iterable<FeedPostDto> posts, {
    int maxImages = 36,
  }) {
    final images = <String>[];

    for (final post in posts) {
      final avatar = post.avatar?.trim();
      if (avatar != null && avatar.isNotEmpty) images.add(avatar);

      for (final m in post.media) {
        if (m.isVideo) {
          final thumb = m.thumbnail?.trim();
          if (thumb != null && thumb.isNotEmpty) {
            images.add(thumb);
          }
          // Skip .mp4 bodies — stream when the user plays.
        } else {
          // Prefer thumbnail when API provides one; else the file URL.
          final thumb = m.thumbnail?.trim();
          final file = m.file.trim();
          final url =
              (thumb != null && thumb.isNotEmpty) ? thumb : file;
          if (url.isNotEmpty) images.add(url);
        }
      }
    }

    prefetchUrls(images.take(maxImages));
  }

  static void prefetchUrls(Iterable<String> urls) {
    for (final raw in urls) {
      final url = raw.trim();
      if (url.isEmpty) continue;
      if (_isVideoUrl(url)) continue; // never queue full videos
      if (!_queuedOrDone.add(url)) continue;
      _queue.add(url);
    }
    _pump();
  }

  static void _pump() {
    while (_active < _maxConcurrent && _queue.isNotEmpty) {
      final url = _queue.removeFirst();
      _active++;
      unawaited(() async {
        try {
          await instance.downloadFile(url, authHeaders: authHeaders(url));
        } catch (_) {
          _queuedOrDone.remove(url); // allow retry later
        } finally {
          _active--;
          _pump();
        }
      }());
    }
  }

  static bool _isVideoUrl(String url) {
    final path = url.toLowerCase().split('?').first;
    return path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.webm') ||
        path.endsWith('.m4v') ||
        path.endsWith('.avi');
  }

  /// Cached file if already on disk (no network). Fast timeout-friendly.
  static Future<File?> cachedFile(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;
    try {
      final info = await instance.getFileFromCache(trimmed);
      return info?.file;
    } catch (_) {
      return null;
    }
  }

  /// Decode-size hint for feed tiles (saves GPU memory, faster paint).
  static int memCachePx(BuildContext context, double logicalPx) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    // Cap hard — feed never needs 4K decode.
    return (logicalPx * dpr * 0.85).round().clamp(64, 900);
  }
}

/// An [ImageCacheManager] so `cached_network_image` can resize decoded images.
/// A plain CacheManager trips an assertion when memCacheWidth/maxWidthDiskCache
/// are set, which was making every feed image and avatar fail to load.
class _InnovatorCacheManager extends CacheManager with ImageCacheManager {
  factory _InnovatorCacheManager() => _instance;

  _InnovatorCacheManager._()
      : super(
          Config(
            InnovatorMediaCache.cacheKey,
            stalePeriod: const Duration(days: 14),
            maxNrOfCacheObjects: 800,
          ),
        );

  static final _InnovatorCacheManager _instance = _InnovatorCacheManager._();
}
