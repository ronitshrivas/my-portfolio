import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/constant/api_constants.dart';

enum ReactionType { like, love, haha, wow, sad, angry, dislike, celebrate }

extension ReactionTypeExtension on ReactionType {
  String get value {
    switch (this) {
      case ReactionType.like:
        return 'like';
      case ReactionType.love:
        return 'love';
      case ReactionType.haha:
        return 'haha';
      case ReactionType.wow:
        return 'wow';
      case ReactionType.sad:
        return 'sad';
      case ReactionType.angry:
        return 'angry';
      case ReactionType.dislike:
        return 'dislike';
      case ReactionType.celebrate:
        return 'celebrate';
    }
  }

  String get emoji {
    switch (this) {
      case ReactionType.like:
        return '👍';
      case ReactionType.love:
        return '❤️';
      case ReactionType.haha:
        return '😂';
      case ReactionType.wow:
        return '😮';
      case ReactionType.sad:
        return '😢';
      case ReactionType.angry:
        return '😡';
      case ReactionType.dislike:
        return '👎';
      case ReactionType.celebrate:
        return '🎉';
    }
  }

  String get label {
    switch (this) {
      case ReactionType.like:
        return 'Like';
      case ReactionType.love:
        return 'Love';
      case ReactionType.haha:
        return 'Haha';
      case ReactionType.wow:
        return 'Wow';
      case ReactionType.sad:
        return 'Sad';
      case ReactionType.angry:
        return 'Angry';
      case ReactionType.dislike:
        return 'Dislike';
      case ReactionType.celebrate:
        return 'Celebrate';
    }
  }

  static ReactionType? fromValue(String? value) {
    if (value == null) return null;
    for (final r in ReactionType.values) {
      if (r.value == value) return r;
    }
    return null;
  }
}

class NonRetryableException implements Exception {
  final int statusCode;
  final String message;

  const NonRetryableException(this.statusCode, this.message);

  @override
  String toString() => 'NonRetryableException($statusCode): $message';
}

class ReactionResult {
  final bool success;
  final ReactionType? reactionType;
  final String? reactionId;

  final bool shouldDiscard;

  const ReactionResult({
    required this.success,
    this.reactionType,
    this.reactionId,
    this.shouldDiscard = false,
  });
}

class ContentLikeService {
  final AppData _appData = AppData();

  ContentLikeService({String? baseUrl});

  Future<ReactionResult> reactPost(String postId, ReactionType type) async {
    final token = _appData.accessToken;
    if (token == null || token.isEmpty) {
      log('[Reaction] No auth token');
      throw const NonRetryableException(401, 'No auth token');
    }

    final response = await http.post(
      Uri.parse(ApiConstants.sendreaction),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'post': postId, 'type': type.value}),
    );

    log(
      '[Reaction] POST /api/reactions/ → ${response.statusCode}: ${response.body}',
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return ReactionResult(
        success: true,
        reactionType: ReactionTypeExtension.fromValue(
          data['type']?.toString(),
        ),
        reactionId: data['id']?.toString(),
      );
    } else if (response.statusCode == 204) {
      return const ReactionResult(success: true, reactionType: null);
    } else if (response.statusCode >= 400 && response.statusCode < 500) {
      throw NonRetryableException(
        response.statusCode,
        response.body.isNotEmpty ? response.body : 'HTTP ${response.statusCode}',
      );
    } else {
      log('[Reaction] Server error ${response.statusCode} — will retry later');
      return const ReactionResult(success: false, shouldDiscard: false);
    }
  }

  Future<ReactionResult> reactReel(String reelId, ReactionType type) async {
    final token = _appData.accessToken;
    if (token == null || token.isEmpty) {
      log('[Reaction] No auth token');
      throw const NonRetryableException(401, 'No auth token');
    }

    final response = await http.post(
      Uri.parse(ApiConstants.sendreaction),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'reel': reelId, 'type': type.value}),
    );

    log(
      '[Reaction] POST /api/reactions/ (reel) → ${response.statusCode}: ${response.body}',
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return ReactionResult(
        success: true,
        reactionType: ReactionTypeExtension.fromValue(
          data['type']?.toString(),
        ),
        reactionId: data['id']?.toString(),
      );
    } else if (response.statusCode == 204) {
      return const ReactionResult(success: true, reactionType: null);
    } else if (response.statusCode >= 400 && response.statusCode < 500) {
      throw NonRetryableException(
        response.statusCode,
        response.body.isNotEmpty ? response.body : 'HTTP ${response.statusCode}',
      );
    } else {
      log('[Reaction] Server error ${response.statusCode} — will retry later');
      return const ReactionResult(success: false, shouldDiscard: false);
    }
  }
  // ── Remove reaction ──────────────────────────────────────────────────────────
  /// DELETE /api/reactions/{reactionId}/
  // Future<bool> removeReaction(String reactionId) async {
  //   final token = _appData.accessToken;
  //   if (token == null || token.isEmpty) return false;

  //   try {
  //     final response = await http.delete(
  //       Uri.parse('${ApiConstants.sendreaction}$reactionId/'),
  //       headers: {
  //         'Authorization': 'Bearer $token',
  //         'Accept': 'application/json',
  //       },
  //     );
  //     log(
  //       '[Reaction] DELETE /api/reactions/$reactionId/ → ${response.statusCode}',
  //     );
  //     return response.statusCode == 204 || response.statusCode == 200;
  //   } catch (e) {
  //     log('[Reaction] removeReaction error: $e');
  //     return false;
  //   }
  // }

  Future<bool> toggleLike(String postId, bool isLiking) async {
    try {
      final r = await reactPost(postId, ReactionType.like);
      return r.success;
    } on NonRetryableException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> likeContent(String postId) => toggleLike(postId, true);
  Future<bool> unlikeContent(String postId) => toggleLike(postId, false);
}



