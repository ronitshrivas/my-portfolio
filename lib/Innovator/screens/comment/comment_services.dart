// comment_services.dart
// All endpoints updated to http://36.253.137.34:8005

import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/constant/api_constants.dart';
import 'package:innovator/Innovator/models/comment_Model.dart';

class CommentService {
  //static const String _base = 'http://36.253.137.34:8005';

  Map<String, String> _headers({bool json = true}) {
    final token = AppData().accessToken ?? '';
    return {
      if (json) 'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── Fetch top-level comments for a post ────────────────────────────────────
  // GET /api/comments/?post=<postId>
  Future<List<Comment>> getComments(String postId, {int page = 0}) async {
    try {
      final uri = Uri.parse(ApiConstants.getcomments).replace(
        queryParameters: {
          'post': postId,
          if (page > 0) 'page': page.toString(),
        },
      );
      final response = await http.get(uri, headers: _headers(json: false));
      log('[Comment] GET $uri → ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> raw =
            decoded is List
                ? decoded
                : (decoded['results'] ?? decoded['data'] ?? []);
        return raw
            .whereType<Map<String, dynamic>>()
            .map(Comment.fromJson)
            .toList();
      } else {
        throw Exception('getComments failed: ${response.statusCode}');
      }
    } catch (e) {
      log('[Comment] getComments error: $e');
      rethrow;
    }
  }


    Future<List<Comment>> getReelComments(String reelId, {int page = 0}) async {
    try {
      final uri = Uri.parse(ApiConstants.getcomments).replace(
        queryParameters: {
          'reel': reelId,
          if (page > 0) 'page': page.toString(),
        },
      );
      final response = await http.get(uri, headers: _headers(json: false));
      log('[Comment] GET $uri → ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> raw =
            decoded is List
                ? decoded
                : (decoded['results'] ?? decoded['data'] ?? []);
        return raw
            .whereType<Map<String, dynamic>>()
            .map(Comment.fromJson)
            .toList();
      } else {
        throw Exception('getComments failed: ${response.statusCode}');
      }
    } catch (e) {
      log('[Comment] getComments error: $e');
      rethrow;
    }
  }

  // ── Fetch replies for a comment ────────────────────────────────────────────
  // GET /api/replies/?parent=<commentId>
  Future<List<Comment>> getReplies(String commentId) async {
    try {
      final uri = Uri.parse(
        ApiConstants.getcommentreplies,
      ).replace(queryParameters: {'parent': commentId});
      final response = await http.get(uri, headers: _headers(json: false));
      log('[Comment] GET $uri → ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> raw =
            decoded is List
                ? decoded
                : (decoded['results'] ?? decoded['data'] ?? []);
        return raw
            .whereType<Map<String, dynamic>>()
            .map(Comment.fromJson)
            .toList();
      } else {
        return [];
      }
    } catch (e) {
      log('[Comment] getReplies error: $e');
      return [];
    }
  }

  // ── Add a top-level comment ────────────────────────────────────────────────
  // POST /api/comments/  { "post": postId, "content": text }
  Future<Comment> addComment({
    required String postId,
    required String content,
    bool isReel = false,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConstants.addcomments),
      headers: _headers(),
      body: jsonEncode({isReel ? 'reel' : 'post': postId, 'content': content}),
    );
    log(
      '[Comment] POST /api/comments/ → ${response.statusCode}: ${response.body}',
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Comment.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('addComment failed: ${response.statusCode}');
  }

  Future<Comment> addCommentReel({
    required String postId,
    required String content,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConstants.addcomments),
      headers: _headers(),
      body: jsonEncode({'reel': postId, 'content': content}),
    );
    log(
      '[Comment] POST /api/comments/ → ${response.statusCode}: ${response.body}',
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Comment.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('addComment failed: ${response.statusCode}');
  }

  // ── Add a reply to a comment ───────────────────────────────────────────────
  // POST /api/replies/  { "parent": commentId, "content": text }
  Future<Comment> addReply({
    required String parentCommentId,
    required String content,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConstants.addcommentreplies),
      headers: _headers(),
      body: jsonEncode({'parent': parentCommentId, 'content': content}),
    );
    log(
      '[Comment] POST /api/replies/ → ${response.statusCode}: ${response.body}',
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Comment.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('addReply failed: ${response.statusCode}');
  }

  // ── Edit a top-level comment ───────────────────────────────────────────────
  // PATCH /api/comments/<id>/  { "content": newText }
  Future<Comment> updateComment({
    required String commentId,
    required String content,
  }) async {
    final response = await http.patch(
      Uri.parse('${ApiConstants.updatecomments}$commentId/'),
      headers: _headers(),
      body: jsonEncode({'content': content}),
    );
    log('[Comment] PATCH /api/comments/$commentId/ → ${response.statusCode}');
    if (response.statusCode == 200) {
      return Comment.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('updateComment failed: ${response.statusCode}');
  }

  // ── Edit a reply ───────────────────────────────────────────────────────────
  // PATCH /api/replies/<id>/  { "content": newText }
  Future<Comment> updateReply({
    required String replyId,
    required String content,
  }) async {
    final response = await http.patch(
      Uri.parse('${ApiConstants.updatecommentreplies}$replyId/'),
      headers: _headers(),
      body: jsonEncode({'content': content}),
    );
    log('[Comment] PATCH /api/replies/$replyId/ → ${response.statusCode}');
    if (response.statusCode == 200) {
      return Comment.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }
    throw Exception('updateReply failed: ${response.statusCode}');
  }

  // ── Delete a top-level comment ─────────────────────────────────────────────
  // DELETE /api/comments/<id>/
  Future<void> deleteComment(String commentId) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.deletecomment}$commentId/'),
      headers: _headers(json: false),
    );
    log('[Comment] DELETE /api/comments/$commentId/ → ${response.statusCode}');
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('deleteComment failed: ${response.statusCode}');
    }
  }

  // ── Delete a reply ─────────────────────────────────────────────────────────
  // DELETE /api/replies/<id>/
  Future<void> deleteReply(String replyId) async {
    final response = await http.delete(
      Uri.parse('${ApiConstants.deletecommentreplies}$replyId/'),
      headers: _headers(json: false),
    );
    log('[Comment] DELETE /api/replies/$replyId/ → ${response.statusCode}');
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('deleteReply failed: ${response.statusCode}');
    }
  }
}
