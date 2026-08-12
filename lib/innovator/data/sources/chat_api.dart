import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:innovator/core/config/api_config.dart';
import 'package:innovator/models/api_response.dart';
import 'package:innovator/core/network/dio_client.dart';
import 'package:innovator/innovator/data/models/chat_models.dart';

/// Chat service — http://36.253.137.34:8014/swagger
class ChatApi {
  ChatApi({DioClient? client}) : _client = client ?? DioClient.shared;

  final DioClient _client;

  Future<List<ChatConversation>> listConversations() async {
    final envelope = await _client.get<List<ChatConversation>>(
      ApiConfig.chatBaseUrl,
      '/api/chat/conversations',
      parse: (raw) {
        if (raw is! List) return <ChatConversation>[];
        return raw
            .whereType<Map>()
            .map((e) => ChatConversation.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      },
    );
    return envelope.data ?? const [];
  }

  Future<ChatConversation> getConversation(String conversationId) async {
    final envelope = await _client.get<ChatConversation>(
      ApiConfig.chatBaseUrl,
      '/api/chat/conversations/$conversationId',
      parse: (raw) => ChatConversation.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'Conversation not found');
    }
    return data;
  }

  Future<ChatConversation> createConversation({
    required String participantUserId,
    String? participantUsername,
    String? participantAvatar,
  }) async {
    final envelope = await _client.post<ChatConversation>(
      ApiConfig.chatBaseUrl,
      '/api/chat/conversations',
      body: {
        'participant_user_id': participantUserId,
        'participant_username': participantUsername,
        'participant_avatar': participantAvatar,
      },
      parse: (raw) => ChatConversation.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'Could not create conversation');
    }
    return data;
  }

  Future<void> deleteConversation(String conversationId) async {
    await _client.delete<Object?>(
      ApiConfig.chatBaseUrl,
      '/api/chat/conversations/$conversationId',
      parse: (_) => null,
    );
  }

  Future<List<ChatMessage>> listMessages(
    String conversationId, {
    int page = 1,
  }) async {
    final envelope = await _client.get<List<ChatMessage>>(
      ApiConfig.chatBaseUrl,
      '/api/chat/conversations/$conversationId/messages',
      query: {'page': '$page'},
      parse: (raw) {
        if (raw is! List) return <ChatMessage>[];
        return raw
            .whereType<Map>()
            .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      },
    );
    return envelope.data ?? const [];
  }

  Future<ChatMessage> sendMessage(
    String conversationId, {
    required String content,
    String messageType = 'text',
    String? mediaUrl,
    String? replyToId,
  }) async {
    final envelope = await _client.post<ChatMessage>(
      ApiConfig.chatBaseUrl,
      '/api/chat/conversations/$conversationId/messages',
      body: {
        'content': content,
        'message_type': messageType,
        'media_url': mediaUrl,
        'reply_to_id': replyToId,
      },
      parse: (raw) => ChatMessage.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'Could not send message');
    }
    return data;
  }

  Future<ChatMessage> updateMessage(
    String messageId, {
    required String content,
  }) async {
    final envelope = await _client.patch<ChatMessage>(
      ApiConfig.chatBaseUrl,
      '/api/chat/messages/$messageId',
      body: {'content': content},
      parse: (raw) => ChatMessage.fromJson(
        Map<String, dynamic>.from(raw as Map? ?? const {}),
      ),
    );
    final data = envelope.data;
    if (data == null) {
      throw ApiException(envelope.message ?? 'Could not update message');
    }
    return data;
  }

  Future<void> deleteMessage(String messageId) async {
    await _client.delete<Object?>(
      ApiConfig.chatBaseUrl,
      '/api/chat/messages/$messageId',
      parse: (_) => null,
    );
  }

  /// Uploads an image for a chat message and returns the stored media URL.
  /// Backend: POST /api/chat/media (multipart, field name `file`) → { url }.
  Future<String> uploadMedia(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        filePath,
        contentType: _imageContentType(filePath),
      ),
    });
    final envelope = await _client.upload<String>(
      ApiConfig.chatBaseUrl,
      '/api/chat/media',
      formData: formData,
      parse: (raw) {
        if (raw is Map) {
          final map = Map<String, dynamic>.from(raw);
          final url = map['url'] ?? map['media_url'] ?? map['mediaUrl'];
          if (url is String && url.isNotEmpty) return url;
        }
        if (raw is String && raw.isNotEmpty) return raw;
        return '';
      },
    );
    final url = envelope.data;
    if (url == null || url.isEmpty) {
      throw ApiException(envelope.message ?? 'Could not upload photo');
    }
    return url;
  }

  Future<void> markRead(String conversationId) async {
    await _client.post<Object?>(
      ApiConfig.chatBaseUrl,
      '/api/chat/conversations/$conversationId/read',
      parse: (_) => null,
    );
  }

  MediaType _imageContentType(String path) {
    final ext = path.toLowerCase();
    if (ext.endsWith('.png')) return MediaType('image', 'png');
    if (ext.endsWith('.gif')) return MediaType('image', 'gif');
    if (ext.endsWith('.webp')) return MediaType('image', 'webp');
    if (ext.endsWith('.heic')) return MediaType('image', 'heic');
    return MediaType('image', 'jpeg');
  }
}
