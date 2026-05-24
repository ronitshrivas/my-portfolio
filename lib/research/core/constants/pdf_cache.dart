import 'dart:typed_data';
import 'package:http/http.dart' as http;

class PdfBytesCache {
  PdfBytesCache._();

  static final Map<String, Uint8List> _stored = {};
  static final Map<String, Future<Uint8List?>> _inflight = {};

  static Future<Uint8List?> fetch(String url) {
    final hit = _stored[url];
    if (hit != null) return Future.value(hit);
    return _inflight.putIfAbsent(url, () => _download(url));
  }

  static Future<Uint8List?> _download(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        _stored[url] = response.bodyBytes;
        _inflight.remove(url);
        return response.bodyBytes;
      }
    } catch (_) {}
    _inflight.remove(url);
    return null;
  }

  static bool isCached(String url) => _stored.containsKey(url);
  static void evict(String url) => _stored.remove(url);

  static void clear() {
    _stored.clear();
    _inflight.clear();
  }
}
