import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

import 'package:innovator/core/config/api_config.dart';
import 'package:innovator/core/network/dio_client.dart';
import 'package:innovator/models/api_response.dart';
import 'package:innovator/innovator/data/models/feed_models.dart';
import 'package:innovator/innovator/data/models/search_models.dart';
import 'package:innovator/services/feed_cache.dart';
import 'package:innovator/services/memory_cache.dart';
import 'package:innovator/innovator/data/sources/search_api.dart';

/// Feed / posts / comments / reactions / notifications
/// — http://36.253.137.34:8012/swagger
class FeedApi {
  FeedApi({DioClient? client}) : _client = client ?? DioClient.shared;

  final DioClient _client;

  static const _categoriesKey = 'feed.categories';

  // ----------------------------------------------------------------- feed

  Future<FeedPage> getFeed({
    int page = 1,
    int pageSize = ApiConfig.feedPageSize,
    String? sessionId,
  }) async {
    final envelope = await _client.get<FeedPage>(
      ApiConfig.feedBaseUrl,
      '/api/feed',
      query: {
        'page': '$page',
        'pageSize': '$pageSize',
        // Seeds the ranked order: same sessionId = stable pages, a new one =
        // fresh ordering (generated on each pull-to-refresh).
        if (sessionId != null && sessionId.isNotEmpty) 'sessionId': sessionId,
      },
      parse: (raw) => FeedPage.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    return envelope.data ?? const FeedPage(results: []);
  }

  /// Total number of posts by an author — the "Innovation" stat.
  /// `GET /api/feed/users/{authorId}/posts/count` → { data: <int> }.
  Future<int> postsCountByAuthor(String authorId) async {
    final envelope = await _client.get<int>(
      ApiConfig.feedBaseUrl,
      '/api/feed/users/$authorId/posts/count',
      parse: (raw) {
        if (raw is num) return raw.toInt();
        if (raw is Map && raw['count'] is num) {
          return (raw['count'] as num).toInt();
        }
        return int.tryParse(raw?.toString() ?? '') ?? 0;
      },
    );
    return envelope.data ?? 0;
  }

  Future<FeedPage> postsByAuthor(
    String authorId, {
    int page = 1,
    int pageSize = ApiConfig.feedPageSize,
  }) async {
    final envelope = await _client.get<FeedPage>(
      ApiConfig.feedBaseUrl,
      '/api/users/$authorId/posts',
      query: {
        'page': '$page',
        'pageSize': '$pageSize',
      },
      parse: (raw) => FeedPage.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    return envelope.data ?? const FeedPage(results: []);
  }

  Future<FeedPage> getReels({
    int page = 1,
    int pageSize = ApiConfig.feedPageSize,
  }) async {
    final envelope = await _client.get<FeedPage>(
      ApiConfig.feedBaseUrl,
      '/api/reels',
      query: {
        'page': '$page',
        'pageSize': '$pageSize',
      },
      parse: (raw) => FeedPage.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    return envelope.data ?? const FeedPage(results: []);
  }

  Future<FeedPostDto> getPost(String postId) async {
    final envelope = await _client.get<FeedPostDto>(
      ApiConfig.feedBaseUrl,
      '/api/posts/$postId',
      parse: (raw) => FeedPostDto.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) throw ApiException(envelope.message ?? 'Post not found');
    return data;
  }

  Future<FeedPostDto> createPost({
    required String content,
    List<String> categoryIds = const [],
    String? sharedPostId,
    List<({Uint8List bytes, String filename})> media = const [],
  }) async {
    final formData = FormData();
    formData.fields.add(MapEntry('content', content));
    if (sharedPostId != null && sharedPostId.isNotEmpty) {
      formData.fields.add(MapEntry('sharedPostId', sharedPostId));
    }
    for (final id in categoryIds) {
      formData.fields.add(MapEntry('categoryIds', id));
    }
    for (final m in media) {
      final type = _mediaContentType(m.filename, m.bytes);
      formData.files.add(MapEntry(
        'media',
        MultipartFile.fromBytes(
          m.bytes,
          filename: _ensureExtension(m.filename, type),
          contentType: type,
        ),
      ));
    }

    final envelope = await _client.upload<FeedPostDto>(
      ApiConfig.feedBaseUrl,
      '/api/posts',
      formData: formData,
      parse: (raw) => FeedPostDto.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'Could not create post');
    }
    FeedCache.invalidate();
    MemoryCache.invalidate('feed.page1');
    // Don't block publish on search indexing.
    unawaited(_indexPost(data));
    return data;
  }

  Future<void> deletePost(String postId) async {
    await _client.delete<Object?>(
      ApiConfig.feedBaseUrl,
      '/api/posts/$postId',
      parse: (_) => null,
    );
    FeedCache.invalidate();
    MemoryCache.invalidate('feed.page1');
    unawaited(() async {
      try {
        await SearchApi().deletePost(postId);
      } catch (_) {}
    }());
  }

  Future<int> recordView(String postId) async {
    final envelope = await _client.post<int>(
      ApiConfig.feedBaseUrl,
      '/api/posts/$postId/view',
      parse: (raw) => (raw as num?)?.toInt() ?? 0,
    );
    return envelope.data ?? 0;
  }

  /// Batch-reports the top-level feed post ids the user actually saw so the
  /// ranked feed stops re-showing them. Idempotent + fire-and-forget: failures
  /// are swallowed and never surfaced to the UI.
  Future<void> reportViews(List<String> postIds) async {
    if (postIds.isEmpty) return;
    try {
      await _client.post<Object?>(
        ApiConfig.feedBaseUrl,
        '/api/feed/views',
        body: {'post_ids': postIds},
        parse: (_) => null,
      );
    } catch (_) {
      // Silent — view reporting must never affect the user.
    }
  }

  Future<List<FeedCategory>> categories({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = MemoryCache.get<List<FeedCategory>>(_categoriesKey);
      if (cached != null) return cached;
    }
    final envelope = await _client.get<List<FeedCategory>>(
      ApiConfig.feedBaseUrl,
      '/api/categories',
      parse: (raw) {
        if (raw is! List) return <FeedCategory>[];
        return raw
            .whereType<Map>()
            .map((e) => FeedCategory.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      },
    );
    final list = envelope.data ?? const <FeedCategory>[];
    MemoryCache.set(_categoriesKey, list);
    return list;
  }

  // ------------------------------------------------------------- reactions

  /// Toggle / set reaction. Sending the same type again often clears it (204).
  Future<FeedReaction?> react({
    required String postId,
    String type = 'like',
  }) async {
    final envelope = await _client.post<FeedReaction?>(
      ApiConfig.feedBaseUrl,
      '/api/reactions',
      body: {'post': postId, 'type': type},
      parse: (raw) {
        if (raw == null) return null;
        if (raw is! Map) return null;
        return FeedReaction.fromJson(Map<String, dynamic>.from(raw));
      },
    );
    return envelope.data;
  }

  Future<List<FeedReaction>> reactionsForPost(String postId) async {
    final envelope = await _client.get<List<FeedReaction>>(
      ApiConfig.feedBaseUrl,
      '/api/reactions/posts/$postId',
      parse: (raw) {
        if (raw is! List) return <FeedReaction>[];
        return raw
            .whereType<Map>()
            .map((e) => FeedReaction.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      },
    );
    return envelope.data ?? const [];
  }

  // --------------------------------------------------------------- reposts

  /// Posts that reposted [postId] (each is a normal post with a shared parent).
  Future<FeedPage> repostsForPost(
    String postId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final envelope = await _client.get<FeedPage>(
      ApiConfig.feedBaseUrl,
      '/api/posts/$postId/reposts',
      query: {'page': '$page', 'pageSize': '$pageSize'},
      parse: (raw) => FeedPage.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    return envelope.data ?? const FeedPage(results: []);
  }

  /// Direct repost (no added text) or repost-with-thought (non-empty [thought]).
  /// Backend represents both as a new post referencing [sharedPostId].
  Future<FeedPostDto> repost({
    required String sharedPostId,
    String thought = '',
  }) {
    // The backend rejects a post with no text and no media, so a direct
    // repost still needs minimal content.
    final content = thought.trim().isEmpty ? 'Reposted' : thought.trim();
    return createPost(content: content, sharedPostId: sharedPostId);
  }

  // -------------------------------------------------------------- comments

  Future<List<FeedComment>> comments({
    String? postId,
    String? reelId,
    int page = 1,
  }) async {
    final query = <String, String>{
      'page': '$page',
      if (postId != null && postId.isNotEmpty) 'post': postId,
      if (reelId != null && reelId.isNotEmpty) 'reel': reelId,
    };
    final envelope = await _client.get<List<FeedComment>>(
      ApiConfig.feedBaseUrl,
      '/api/comments',
      query: query,
      parse: _parseComments,
    );
    return envelope.data ?? const [];
  }

  Future<FeedComment> createComment({
    required String content,
    String? postId,
    String? reelId,
  }) async {
    final envelope = await _client.post<FeedComment>(
      ApiConfig.feedBaseUrl,
      '/api/comments',
      body: {
        'content': content,
        'post': postId,
        'reel': reelId,
      },
      parse: (raw) => FeedComment.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'Could not comment');
    }
    return data;
  }

  Future<FeedComment> updateComment(String commentId, String content) async {
    final envelope = await _client.patch<FeedComment>(
      ApiConfig.feedBaseUrl,
      '/api/comments/$commentId',
      body: {'content': content},
      parse: (raw) => FeedComment.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'Could not update comment');
    }
    return data;
  }

  Future<void> deleteComment(String commentId) async {
    await _client.delete<Object?>(
      ApiConfig.feedBaseUrl,
      '/api/comments/$commentId',
      parse: (_) => null,
    );
  }

  Future<List<FeedComment>> replies(String parentId) async {
    final envelope = await _client.get<List<FeedComment>>(
      ApiConfig.feedBaseUrl,
      '/api/replies',
      query: {'parent': parentId},
      parse: _parseComments,
    );
    return envelope.data ?? const [];
  }

  Future<FeedComment> createReply({
    required String parentId,
    required String content,
  }) async {
    final envelope = await _client.post<FeedComment>(
      ApiConfig.feedBaseUrl,
      '/api/replies',
      body: {'parent': parentId, 'content': content},
      parse: (raw) => FeedComment.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'Could not reply');
    }
    return data;
  }

  Future<void> deleteReply(String replyId) async {
    await _client.delete<Object?>(
      ApiConfig.feedBaseUrl,
      '/api/replies/$replyId',
      parse: (_) => null,
    );
  }

  // --------------------------------------------------------- notifications

  Future<List<FeedNotification>> notifications() async {
    final envelope = await _client.get<List<FeedNotification>>(
      ApiConfig.feedBaseUrl,
      '/api/notifications',
      parse: (raw) {
        if (raw is! List) return <FeedNotification>[];
        return raw
            .whereType<Map>()
            .map(
              (e) => FeedNotification.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList();
      },
    );
    return envelope.data ?? const [];
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _client.post<Object?>(
      ApiConfig.feedBaseUrl,
      '/api/notifications/$notificationId/mark-as-read',
      parse: (_) => null,
    );
  }

  Future<void> markAllNotificationsRead() async {
    await _client.post<Object?>(
      ApiConfig.feedBaseUrl,
      '/api/notifications/mark-all-as-read',
      parse: (_) => null,
    );
  }

  Future<void> deleteNotification(String notificationId) async {
    await _client.delete<Object?>(
      ApiConfig.feedBaseUrl,
      '/api/notifications/$notificationId',
      parse: (_) => null,
    );
  }

  Future<void> registerFcmToken({
    required String token,
    String? deviceName,
  }) async {
    await _client.post<Object?>(
      ApiConfig.feedBaseUrl,
      '/api/fcm-tokens',
      body: {'token': token, 'device_name': deviceName},
      parse: (_) => null,
    );
  }

  List<FeedComment> _parseComments(Object? raw) {
    if (raw is! List) return <FeedComment>[];
    return raw
        .whereType<Map>()
        .map((e) => FeedComment.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> _indexPost(FeedPostDto post) async {
    try {
      final tags = RegExp(r'#(\w+)')
          .allMatches(post.content ?? '')
          .map((m) => m.group(1)!)
          .toList();
      await SearchApi().upsertPost(
        UpsertPostIndexRequest(
          postId: post.id,
          authorId: post.userId,
          username: post.username,
          avatar: post.avatar,
          content: post.content,
          type: post.type,
          hashtags: tags,
          categories: post.categories.map((c) => c.name).toList(),
          reactionsCount: post.reactionsCount,
          commentsCount: post.commentsCount,
          viewsCount: post.viewsCount,
          isReel: post.isReel,
        ),
      );
    } catch (_) {}
  }
}

MediaType _mediaContentType(String filename, [Uint8List? bytes]) {
  final name = filename.toLowerCase().split('?').first;
  if (name.endsWith('.mp4')) return MediaType('video', 'mp4');
  if (name.endsWith('.mov')) return MediaType('video', 'quicktime');
  if (name.endsWith('.webm')) return MediaType('video', 'webm');
  if (name.endsWith('.m4v')) return MediaType('video', 'x-m4v');
  if (name.endsWith('.png')) return MediaType('image', 'png');
  if (name.endsWith('.gif')) return MediaType('image', 'gif');
  if (name.endsWith('.webp')) return MediaType('image', 'webp');
  if (name.endsWith('.jpg') || name.endsWith('.jpeg')) {
    return MediaType('image', 'jpeg');
  }
  // Some OEM pickers (Vivo/FuntouchOS, Xiaomi/MIUI) hand back filenames with no
  // usable extension. Sniff the leading bytes so the upload still gets a real
  // image/video content-type instead of octet-stream (which the API rejects).
  final sniffed = _sniffMediaType(bytes);
  if (sniffed != null) return sniffed;
  return MediaType('application', 'octet-stream');
}

/// Detects common image/video types from magic-number byte signatures.
MediaType? _sniffMediaType(Uint8List? bytes) {
  if (bytes == null || bytes.length < 12) return null;
  int b(int i) => bytes[i];
  // JPEG: FF D8 FF
  if (b(0) == 0xFF && b(1) == 0xD8 && b(2) == 0xFF) {
    return MediaType('image', 'jpeg');
  }
  // PNG: 89 50 4E 47
  if (b(0) == 0x89 && b(1) == 0x50 && b(2) == 0x4E && b(3) == 0x47) {
    return MediaType('image', 'png');
  }
  // GIF: 47 49 46 38
  if (b(0) == 0x47 && b(1) == 0x49 && b(2) == 0x46 && b(3) == 0x38) {
    return MediaType('image', 'gif');
  }
  // WEBP: RIFF....WEBP
  if (b(0) == 0x52 && b(1) == 0x49 && b(2) == 0x46 && b(3) == 0x46 &&
      b(8) == 0x57 && b(9) == 0x45 && b(10) == 0x42 && b(11) == 0x50) {
    return MediaType('image', 'webp');
  }
  // MP4 / MOV / M4V: bytes 4-7 spell "ftyp"
  if (b(4) == 0x66 && b(5) == 0x74 && b(6) == 0x79 && b(7) == 0x70) {
    return MediaType('video', 'mp4');
  }
  // WEBM / Matroska: 1A 45 DF A3
  if (b(0) == 0x1A && b(1) == 0x45 && b(2) == 0xDF && b(3) == 0xA3) {
    return MediaType('video', 'webm');
  }
  return null;
}

/// Ensures the upload filename carries an extension matching its content type,
/// so servers that key off the extension accept OEM-picker files.
String _ensureExtension(String filename, MediaType type) {
  const knownExts = {
    '.mp4', '.mov', '.webm', '.m4v',
    '.png', '.gif', '.webp', '.jpg', '.jpeg',
  };
  final lower = filename.toLowerCase().split('?').first;
  final hasKnownExt = knownExts.any(lower.endsWith);
  if (hasKnownExt) return filename;
  final ext = switch ('${type.type}/${type.subtype}') {
    'image/jpeg' => '.jpg',
    'image/png' => '.png',
    'image/gif' => '.gif',
    'image/webp' => '.webp',
    'video/mp4' => '.mp4',
    'video/quicktime' => '.mov',
    'video/webm' => '.webm',
    'video/x-m4v' => '.m4v',
    _ => '',
  };
  if (ext.isEmpty) return filename;
  final base = filename.trim().isEmpty ? 'upload' : filename;
  return '$base$ext';
}
