// import 'package:flutter/material.dart';

// enum MessageStatus { sending, sent, delivered, read, failed }

// class ChatMessage {
//   final String id;
//   final String text;
//   final bool isMine;
//   final DateTime timestamp;
//   MessageStatus status;

//   ChatMessage({
//     required this.id,
//     required this.text,
//     required this.isMine,
//     required this.timestamp,
//     this.status = MessageStatus.sent,
//   });

//   /// Build from chat-history REST response
//   factory ChatMessage.fromHistory(Map<String, dynamic> json, String myId) {
//     final senderId = json['sender']?.toString() ?? '';
//     final isMine = senderId == myId;
//     return ChatMessage(
//       id: json['id']?.toString() ?? UniqueKey().toString(),
//       text: json['message']?.toString() ?? '',
//       isMine: isMine,
//       timestamp:
//           json['created_at'] != null
//               ? DateTime.tryParse(json['created_at'].toString()) ??
//                   DateTime.now()
//               : DateTime.now(),
//       status:
//           isMine
//               ? (json['is_read'] == true
//                   ? MessageStatus.read
//                   : MessageStatus.delivered)
//               : MessageStatus.delivered,
//     );
//   }

//   /// Build from incoming WebSocket frame
//   factory ChatMessage.fromWs(Map<String, dynamic> json, String myId) {
//     final senderId =
//         json['sender']?.toString() ??
//         json['sender_id']?.toString() ??
//         json['from']?.toString() ??
//         '';
//     final text =
//         json['message']?.toString() ??
//         json['content']?.toString() ??
//         json['text']?.toString() ??
//         '';
//     return ChatMessage(
//       id: json['id']?.toString() ?? UniqueKey().toString(),
//       text: text,
//       isMine: senderId == myId,
//       timestamp:
//           json['timestamp'] != null
//               ? DateTime.tryParse(json['timestamp'].toString()) ??
//                   DateTime.now()
//               : DateTime.now(),
//       status: MessageStatus.delivered,
//     );
//   }
// }

import 'package:flutter/material.dart';

enum MessageStatus { sending, sent, delivered, read, failed }

class ChatMessage {
  final String id;
  final String text;
  final bool isMine;
  final DateTime timestamp;
  MessageStatus status;

  // ── Reply support ────────────────────────────────────────────────────────
  final String? parentId;
  final String? repliedToText;
  final String? repliedToSenderName;

  // ── Attachment support ───────────────────────────────────────────────────
  final String? attachmentUrl;
  final String? attachmentType; // 'image', 'file', etc.

  ChatMessage({
    required this.id,
    required this.text,
    required this.isMine,
    required this.timestamp,
    this.status = MessageStatus.sent,
    this.parentId,
    this.repliedToText,
    this.repliedToSenderName,
    this.attachmentUrl,
    this.attachmentType,
  });

  /// Build from chat-history REST response
  factory ChatMessage.fromHistory(Map<String, dynamic> json, String myId) {
    final senderId = json['sender']?.toString() ?? '';
    final isMine = senderId == myId;

    // Parse replied_to_details if present
    final replyDetails = json['replied_to_details'] as Map<String, dynamic>?;
    final repliedToText = replyDetails?['message']?.toString();
    final repliedToSenderName = replyDetails?['sender_full_name']?.toString();
    final parentId = json['parent']?.toString();

    // Parse attachment
    final attachmentUrl = json['attachment']?.toString();
    final attachmentType =
        attachmentUrl != null
            ? ChatMessage.inferAttachmentType(attachmentUrl)
            : null;

    return ChatMessage(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      text: json['message']?.toString() ?? '',
      isMine: isMine,
      timestamp:
          json['created_at'] != null
              ? DateTime.tryParse(json['created_at'].toString()) ??
                  DateTime.now()
              : DateTime.now(),
      status:
          isMine
              ? (json['is_read'] == true
                  ? MessageStatus.read
                  : MessageStatus.delivered)
              : MessageStatus.delivered,
      parentId: parentId,
      repliedToText: repliedToText,
      repliedToSenderName: repliedToSenderName,
      attachmentUrl: attachmentUrl,
      attachmentType: attachmentType,
    );
  }

  /// Build from incoming WebSocket frame
  factory ChatMessage.fromWs(Map<String, dynamic> json, String myId) {
    final senderId =
        json['sender']?.toString() ??
        json['sender_id']?.toString() ??
        json['from']?.toString() ??
        '';
    final text =
        json['message']?.toString() ??
        json['content']?.toString() ??
        json['text']?.toString() ??
        '';

    // Reply fields from WS
    final replyDetails = json['replied_to_details'] as Map<String, dynamic>?;
    final repliedToText = replyDetails?['message']?.toString();
    final repliedToSenderName = replyDetails?['sender_full_name']?.toString();
    final parentId =
        json['parent_id']?.toString() ?? json['parent']?.toString();

    // Attachment
    final attachmentUrl = json['attachment']?.toString();
    final attachmentType =
        attachmentUrl != null
            ? ChatMessage.inferAttachmentType(attachmentUrl)
            : null;

    return ChatMessage(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      text: text,
      isMine: senderId == myId,
      timestamp:
          json['timestamp'] != null
              ? DateTime.tryParse(json['timestamp'].toString()) ??
                  DateTime.now()
              : DateTime.now(),
      status: MessageStatus.delivered,
      parentId: parentId,
      repliedToText: repliedToText,
      repliedToSenderName: repliedToSenderName,
      attachmentUrl: attachmentUrl,
      attachmentType: attachmentType,
    );
  }

  static String inferAttachmentType(String url) {
    final lower = url.toLowerCase();
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp')) {
      return 'image';
    }
    if (lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi')) {
      return 'video';
    }
    return 'file';
  }

  bool get hasAttachment => attachmentUrl != null && attachmentUrl!.isNotEmpty;
  bool get isImage => attachmentType == 'image';
  bool get hasReply =>
      parentId != null && repliedToText != null && repliedToText!.isNotEmpty;
}

// ─────────────────────────────────────────────────────────────────────────────
// MutualFriend (unchanged from original)
// ─────────────────────────────────────────────────────────────────────────────

class MutualFriend {
  final String id;
  final String username;
  final String fullName;
  final String avatar;
  final bool onlineStatus;
  final int unreadCount;
  final DateTime lastMessageAt;

  MutualFriend({
    required this.id,
    required this.username,
    required this.fullName,
    required this.avatar,
    required this.onlineStatus,
    this.unreadCount = 0,
    DateTime? lastMessageAt,
  }) : lastMessageAt = lastMessageAt ?? DateTime(2000);

  factory MutualFriend.fromJson(Map<String, dynamic> json) => MutualFriend(
    id: json['id']?.toString() ?? '',
    username: json['username']?.toString() ?? '',
    fullName: json['full_name']?.toString() ?? '',
    avatar: json['avatar']?.toString() ?? '',
    onlineStatus: json['online_status'] == true,
    lastMessageAt:
        json['last_message_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
              json['last_message_at'] * 1000,
            )
            : DateTime(2000),
  );

  MutualFriend copyWithUnread(int count) => MutualFriend(
    id: id,
    username: username,
    fullName: fullName,
    avatar: avatar,
    onlineStatus: onlineStatus,
    unreadCount: count,
    lastMessageAt: lastMessageAt,
  );

  MutualFriend copyWithLastMessageAt(DateTime t) => MutualFriend(
    id: id,
    username: username,
    fullName: fullName,
    avatar: avatar,
    onlineStatus: onlineStatus,
    unreadCount: unreadCount,
    lastMessageAt: t,
  );

  String get displayName => fullName.isNotEmpty ? fullName : username;
  String get initial =>
      displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
}
