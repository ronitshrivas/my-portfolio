import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/Authorization/Login.dart';

class ApiService {
  static const String _base = 'http://36.253.137.34:8012';

  static Map<String, String> _authHeader() {
    final token = AppData().accessToken ?? '';
    return {
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Map<String, String> _jsonHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ..._authHeader(),
    };
  }

  static Future<bool> updateContent(
    String postId,
    String content, {
    File? mediaFile,
    BuildContext? context,
  }) async {
    try {
      debugPrint('[ApiService] PATCH /api/posts/$postId/');

      final uri = Uri.parse('$_base/api/posts/$postId/');
      final request =
          http.MultipartRequest('PATCH', uri)
            ..headers.addAll(_authHeader())
            ..fields['content'] = content;

      if (mediaFile != null) {
        final filename = path.basename(mediaFile.path);
        final ext = filename.split('.').last.toLowerCase();
        final mimeType = _mimeType(ext);

        request.files.add(
          http.MultipartFile(
            'uploaded_media',
            http.ByteStream(mediaFile.openRead()),
            await mediaFile.length(),
            filename: filename,
            contentType: MediaType.parse(mimeType),
          ),
        );

        debugPrint('[ApiService] Attaching media: $filename ($mimeType)');
      }

      final streamed = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamed);

      debugPrint(
        '[ApiService] Update ${response.statusCode}: ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 401) {
        _redirectToLogin(context);
        return false;
      } else {
        debugPrint('[ApiService] Update failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[ApiService] updateContent error: $e');
      return false;
    }
  }

  static Future<bool> deleteFiles(
    String postId, {
    BuildContext? context,
  }) async {
    try {
      debugPrint('[ApiService] DELETE /api/posts/$postId/');

      final response = await http
          .delete(
            Uri.parse('$_base/api/posts/$postId/'),
            headers: _authHeader(),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint(
        '[ApiService] Delete ${response.statusCode}: ${response.body}',
      );

      if (response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 202) {
        return true;
      } else if (response.statusCode == 401) {
        _redirectToLogin(context);
        return false;
      } else {
        debugPrint('[ApiService] Delete failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[ApiService] deleteFiles error: $e');
      return false;
    }
  }

  static Future<bool> updateReel(
    String reelId,
    String caption, {
    BuildContext? context,
  }) async {
    try {
      debugPrint('[ApiService] PATCH /api/reels/$reelId/');

      final response = await http
          .patch(
            Uri.parse('$_base/api/reels/$reelId/'),
            headers: _jsonHeaders(),
            body: jsonEncode({'caption': caption}),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint(
        '[ApiService] Reel update ${response.statusCode}: ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 401) {
        _redirectToLogin(context);
        return false;
      } else {
        debugPrint('[ApiService] Reel update failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[ApiService] updateReel error: $e');
      return false;
    }
  }

  static Future<bool> deleteReel(String reelId, {BuildContext? context}) async {
    try {
      debugPrint('[ApiService] DELETE /api/reels/$reelId/');

      final response = await http
          .delete(
            Uri.parse('$_base/api/reels/$reelId/'),
            headers: _authHeader(),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint(
        '[ApiService] Reel delete ${response.statusCode}: ${response.body}',
      );

      if (response.statusCode == 200 ||
          response.statusCode == 204 ||
          response.statusCode == 202) {
        return true;
      } else if (response.statusCode == 401) {
        _redirectToLogin(context);
        return false;
      } else {
        debugPrint('[ApiService] Reel delete failed: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[ApiService] deleteReel error: $e');
      return false;
    }
  }

  static String _mimeType(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      default:
        return 'image/jpeg';
    }
  }

  static void _redirectToLogin(BuildContext? context) {
    if (context != null && context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
        (route) => false,
      );
    }
  }
}
