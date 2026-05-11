// import 'package:innovator/Innovator/models/Chat/chat_model.dart';

// enum WsStatus { connecting, connected, disconnected, error }

// class ChatState {
//   final List<ChatMessage> messages;
//   final WsStatus wsStatus;
//   final bool isSending;
//   final bool isLoadingHistory;
//   final String? error;
//   final bool isTyping;

//   const ChatState({
//     this.messages = const [],
//     this.wsStatus = WsStatus.disconnected,
//     this.isSending = false,
//     this.isLoadingHistory = false,
//     this.error,
//     this.isTyping = false,
//   });

//   ChatState copyWith({
//     List<ChatMessage>? messages,
//     WsStatus? wsStatus,
//     bool? isSending,
//     bool? isLoadingHistory,
//     String? error,
//     bool? isTyping,
//   }) => ChatState(
//     messages: messages ?? this.messages,
//     wsStatus: wsStatus ?? this.wsStatus,
//     isSending: isSending ?? this.isSending,
//     isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
//     error: error,
//     isTyping: isTyping ?? this.isTyping,
//   );
// }

import 'package:innovator/Innovator/models/Chat/chat_model.dart';

enum WsStatus { connecting, connected, disconnected, error }

class ChatState {
  final List<ChatMessage> messages;
  final WsStatus wsStatus;
  final bool isSending;
  final bool isLoadingHistory;
  final String? error;
  final bool isTyping;

  // ── Reply state ────────────────────────────────────────────────────────────
  /// The message the user is currently replying to. Null = not replying.
  final ChatMessage? replyingTo;

  const ChatState({
    this.messages = const [],
    this.wsStatus = WsStatus.disconnected,
    this.isSending = false,
    this.isLoadingHistory = false,
    this.error,
    this.isTyping = false,
    this.replyingTo,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    WsStatus? wsStatus,
    bool? isSending,
    bool? isLoadingHistory,
    String? error,
    bool? isTyping,
    ChatMessage? replyingTo,
    // Pass true to explicitly clear replyingTo (since null is ambiguous above)
    bool clearReply = false,
  }) => ChatState(
    messages: messages ?? this.messages,
    wsStatus: wsStatus ?? this.wsStatus,
    isSending: isSending ?? this.isSending,
    isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
    error: error,
    isTyping: isTyping ?? this.isTyping,
    replyingTo: clearReply ? null : (replyingTo ?? this.replyingTo),
  );
}
