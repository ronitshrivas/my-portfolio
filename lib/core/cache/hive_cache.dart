import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../config/api_config.dart';

/// Lightweight JSON cache backed by Hive.
///
/// Each feature stores decoded API payloads (maps / lists) under a string key
/// with a timestamp, so screens can render instantly from disk and refresh in
/// the background. Values are JSON-encoded so no Hive adapters are needed.
class HiveCache {
  HiveCache._(this._box);

  final Box _box;

  /// Open (or reuse) a named box. Call once per feature at startup.
  static Future<HiveCache> open(String boxName) async {
    final box = Hive.isBoxOpen(boxName)
        ? Hive.box(boxName)
        : await Hive.openBox(boxName);
    return HiveCache._(box);
  }

  /// Initialise Hive once for the whole app.
  static Future<void> init() => Hive.initFlutter();

  void put(String key, Object value) {
    _box.put(key, jsonEncode({
      'ts': DateTime.now().millisecondsSinceEpoch,
      'value': value,
    }));
  }

  /// Returns the cached value, or null if missing or older than [ttl].
  T? get<T>(String key, {Duration ttl = ApiConfig.cacheTtl}) {
    final raw = _box.get(key);
    if (raw is! String) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = decoded['ts'] as int? ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - ts;
      if (age > ttl.inMilliseconds) return null;
      return decoded['value'] as T?;
    } catch (_) {
      return null;
    }
  }

  /// Cached value regardless of age (useful for offline fallback).
  T? peek<T>(String key) => get<T>(key, ttl: const Duration(days: 3650));

  void remove(String key) => _box.delete(key);

  Future<void> clear() => _box.clear();
}
