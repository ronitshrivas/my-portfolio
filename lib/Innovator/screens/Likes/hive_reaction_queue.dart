// import 'dart:async';
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:innovator/Innovator/screens/Likes/Content-Like-Service.dart';
import 'dart:developer' as developer;

const String _kReactionBoxName = 'pending_reactions';

/// [contentId]    — which post was synced
/// [succeeded]    — true = API accepted, false = API rejected (e.g. 400)
/// [reactionType] — the reaction that was attempted (null = "remove reaction")
/// [previousType] — what the reaction was BEFORE the offline action
///                  (used to revert UI on failure)
typedef ReactionSyncCallback =
    void Function(
      String contentId,
      bool succeeded,
      ReactionType? reactionType,
      ReactionType? previousType,
    );

class HiveReactionQueue {
  HiveReactionQueue._();
  static final HiveReactionQueue instance = HiveReactionQueue._();

  late Box<Map> _box;
  bool _initialized = false;
  ContentLikeService? _likeService;
  StreamSubscription? _connectivitySub;
  bool _flushing = false;

  // Listeners keyed by contentId
  final Map<String, ReactionSyncCallback> _listeners = {};

  void addListener(String contentId, ReactionSyncCallback cb) {
    _listeners[contentId] = cb;
  }

  void removeListener(String contentId) {
    _listeners.remove(contentId);
  }

  void _notifyListener(
    String contentId,
    bool succeeded,
    ReactionType? reactionType,
    ReactionType? previousType,
  ) {
    _listeners[contentId]?.call(
      contentId,
      succeeded,
      reactionType,
      previousType,
    );
  }

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> init({ContentLikeService? service}) async {
    if (_initialized) {
      if (service != null) _likeService = service;
      return;
    }

    _box = await Hive.openBox<Map>(_kReactionBoxName);
    _initialized = true;
    if (service != null) _likeService = service;

    developer.log(
      '[HiveReactionQueue] Ready — ${_box.length} reactions on disk',
    );

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any(
        (r) =>
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.ethernet,
      );
      if (isOnline && _box.isNotEmpty) {
        developer.log('[HiveReactionQueue] Network restored — flushing...');
        flush();
      }
    });
  }

  void setService(ContentLikeService service) {
    _likeService = service;
    if (_initialized && _box.isNotEmpty && !_flushing) {
      flush();
    }
  }

  // ── Enqueue ───────────────────────────────────────────────────────────────
  /// [previousType] is stored so on failure we can tell the UI what to revert to.
  Future<void> enqueue({
    required String contentId,
    required ReactionType? type,
    required bool isReel,
    ReactionType? previousType, // what reaction was BEFORE this action
  }) async {
    final data = {
      'type': type?.name ?? '',
      'isReel': isReel,
      'previousType': previousType?.name ?? '',
      'queuedAt': DateTime.now().toIso8601String(),
    };
    await _box.put(contentId, data);
    developer.log(
      '[HiveReactionQueue] Queued → $contentId : '
      '${type?.name ?? "remove"} (prev: ${previousType?.name ?? "none"})',
    );
  }

  Future<void> dequeue(String contentId) async {
    await _box.delete(contentId);
    developer.log('[HiveReactionQueue] Dequeued → $contentId');
  }

  bool hasPending(String contentId) =>
      _initialized && _box.containsKey(contentId);

  int get pendingCount => _initialized ? _box.length : 0;

  // ── Flush ─────────────────────────────────────────────────────────────────
  Future<void> flush() async {
    if (_flushing || _likeService == null || !_initialized) return;
    if (_box.isEmpty) return;

    _flushing = true;
    developer.log('[HiveReactionQueue] Flushing ${_box.length} reactions...');

    final keys = List<dynamic>.from(_box.keys);

    for (final key in keys) {
      final raw = _box.get(key);
      if (raw == null) continue;

      final contentId = key as String;
      final typeStr = raw['type'] as String? ?? '';
      final isReel = raw['isReel'] as bool? ?? false;
      final prevStr = raw['previousType'] as String? ?? '';
      final reactionType =
          typeStr.isEmpty ? null : _reactionFromString(typeStr);
      final previousType =
          prevStr.isEmpty ? null : _reactionFromString(prevStr);

      // Notify the LikeButton that a sync is starting so it can show spinner
      _listeners[contentId]?.call(
        contentId,
        true, // temporary — will be overwritten by real result below
        reactionType,
        previousType,
      );

      try {
        ReactionResult result;
        if (reactionType == null) {
          result =
              isReel
                  ? await _likeService!.reactReel(contentId, ReactionType.like)
                  : await _likeService!.reactPost(contentId, ReactionType.like);
        } else {
          result =
              isReel
                  ? await _likeService!.reactReel(contentId, reactionType)
                  : await _likeService!.reactPost(contentId, reactionType);
        }

        if (result.success) {
          await _box.delete(key);
          // Tell UI: sync succeeded, keep current reaction
          _notifyListener(contentId, true, reactionType, previousType);
          developer.log('[HiveReactionQueue] ✓ Synced $contentId');
        } else {
          // 5xx — keep in queue, tell UI to show syncing failed temporarily
          developer.log('[HiveReactionQueue] 5xx — will retry $contentId');
          _notifyListener(contentId, false, reactionType, previousType);
        }
      } on NonRetryableException catch (e) {
        // 4xx — discard permanently, tell UI to revert
        await _box.delete(key);
        _notifyListener(contentId, false, reactionType, previousType);
        developer.log(
          '[HiveReactionQueue] ✗ Non-retryable (${e.statusCode}) — '
          'discarded $contentId, reverting UI',
        );
      } catch (e) {
        // Network error — keep in queue, no UI change
        developer.log('[HiveReactionQueue] ✗ Network error for $contentId: $e');
      }
    }

    _flushing = false;
    developer.log('[HiveReactionQueue] Done. ${_box.length} still pending.');
  }

  ReactionType? _reactionFromString(String value) {
    try {
      return ReactionType.values.firstWhere((r) => r.name == value);
    } catch (_) {
      return null;
    }
  }

  Future<void> dispose() async {
    _connectivitySub?.cancel();
    await _box.close();
  }
}
