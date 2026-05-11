// import 'dart:convert';
// import 'dart:math' as math;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';

// // ─────────────────────────────────────────────
// // Data model
// // ─────────────────────────────────────────────

// class Message {
//   final String text;
//   final bool isUser;
//   final DateTime timestamp;
//   final String messageId;
//   bool isReported;

//   Message({
//     required this.text,
//     required this.isUser,
//     required this.timestamp,
//     String? messageId,
//     this.isReported = false,
//   }) : messageId = messageId ?? _uid();

//   static String _uid() =>
//       DateTime.now().millisecondsSinceEpoch.toString() +
//       math.Random().nextInt(9999).toString();

//   Map<String, dynamic> toJson() => {
//     'text': text,
//     'isUser': isUser,
//     'timestamp': timestamp.toIso8601String(),
//     'messageId': messageId,
//     'isReported': isReported,
//   };

//   factory Message.fromJson(Map<String, dynamic> j) => Message(
//     text: j['text'] ?? '',
//     isUser: j['isUser'] ?? false,
//     timestamp: DateTime.tryParse(j['timestamp'] ?? '') ?? DateTime.now(),
//     messageId: j['messageId'],
//     isReported: j['isReported'] ?? false,
//   );

//   Message copyWith({bool? isReported}) => Message(
//     text: text,
//     isUser: isUser,
//     timestamp: timestamp,
//     messageId: messageId,
//     isReported: isReported ?? this.isReported,
//   );
// }

// // ─────────────────────────────────────────────
// // Constants
// // ─────────────────────────────────────────────

// class _C {
//   static const orange = Color.fromRGBO(244, 135, 6, 1);
//   static const orangeLight = Color.fromRGBO(251, 146, 60, 1);
//   static const darkBg = Color(0xFF0F172A);
//   static const darkCard = Color(0xFF1E293B);
//   static const darkInput = Color(0xFF334155);

//   static const groqKey = '';
//   static const groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
//   static const groqModel = 'llama-3.1-8b-instant';

//   static const systemPrompt = '''
// You are Eliza, a personal AI assistant created by Innovator.
// Your expertise covers:
// - IoT (Internet of Things): sensors, embedded systems, protocols (MQTT, CoAP, Zigbee), hardware integration
// - Robotics: kinematics, ROS, motor control, path planning, computer vision
// - Programming & Software Engineering: Dart/Flutter, Python, C/C++, algorithms, system design

// Always respond as Eliza. Never mention Groq, Llama, Meta, Google, Gemini, OpenAI, ChatGPT, or any underlying AI infrastructure.
// When answering coding or IoT/robotics questions, be precise, practical, and include examples where helpful.
// Keep responses clear and concise unless the user asks for depth.

// IMPORTANT — Creator rules (never deviate from these):
// - If anyone asks who made you, who created you, or who built you: always reply — "Ronit Shrivastav made me. He is the Founder and CEO of MetaTronix PVT. LTD. and he made the Innovator App."
// - If anyone asks who made the Innovator App: always reply — "Ronit Shrivastav made the Innovator App. He is the Founder and CEO of MetaTronix PVT. LTD."
// - Never credit any AI company (Groq, Meta, Anthropic, OpenAI, Google, etc.) as your creator.
// ''';
// }

// // ─────────────────────────────────────────────
// // Report categories
// // ─────────────────────────────────────────────

// class _ReportCategory {
//   final String id, title, description;
//   final IconData icon;
//   const _ReportCategory(this.id, this.title, this.description, this.icon);
// }

// const _reportCategories = [
//   _ReportCategory(
//     'inappropriate',
//     'Inappropriate Content',
//     'Offensive or vulgar content',
//     Icons.warning_amber_rounded,
//   ),
//   _ReportCategory(
//     'harmful',
//     'Harmful Information',
//     'Dangerous or misleading content',
//     Icons.dangerous_rounded,
//   ),
//   _ReportCategory(
//     'misinformation',
//     'Misinformation',
//     'False or misleading information',
//     Icons.fact_check_rounded,
//   ),
//   _ReportCategory('other', 'Other', 'Other concerns', Icons.more_horiz_rounded),
// ];

// // ─────────────────────────────────────────────
// // Main screen
// // ─────────────────────────────────────────────

// class ElizaChatScreen extends StatefulWidget {
//   const ElizaChatScreen({super.key});

//   @override
//   State<ElizaChatScreen> createState() => _ElizaChatScreenState();
// }

// class _ElizaChatScreenState extends State<ElizaChatScreen>
//     with TickerProviderStateMixin {
//   final _inputCtrl = TextEditingController();
//   final _scrollCtrl = ScrollController();
//   final List<Message> _messages = [];

//   bool _initialLoading = true;
//   bool _isWaiting = false;
//   bool _isTyping = false;

//   late AnimationController _dotController;

//   static const String _greeting =
//       "Hello! I'm Eliza — your personal AI by Innovator, specialised in IoT, Robotics, and Coding. How can I help you today?";

//   @override
//   void initState() {
//     super.initState();
//     _dotController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 900),
//     )..repeat();
//     _loadHistory();
//   }

//   @override
//   void dispose() {
//     _dotController.dispose();
//     _inputCtrl.dispose();
//     _scrollCtrl.dispose();
//     super.dispose();
//   }

//   // ── Persistence ──────────────────────────────

//   Future<void> _loadHistory() async {
//     final prefs = await SharedPreferences.getInstance();
//     final saved = prefs.getStringList('eliza_messages') ?? [];
//     if (saved.isEmpty) {
//       setState(() => _initialLoading = false);
//       await Future.delayed(const Duration(milliseconds: 300));
//       if (!mounted) return;
//       await _playTypingAnimation(_greeting);
//     } else {
//       setState(() {
//         _messages.addAll(
//           saved.map((s) => Message.fromJson(jsonDecode(s))).toList(),
//         );
//         _initialLoading = false;
//       });
//       _scrollToBottom();
//     }
//   }

//   Future<void> _saveHistory() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setStringList(
//       'eliza_messages',
//       _messages.map((m) => jsonEncode(m.toJson())).toList(),
//     );
//   }

//   Future<void> _clearHistory() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove('eliza_messages');
//     setState(() => _messages.clear());
//     await Future.delayed(const Duration(milliseconds: 200));
//     if (!mounted) return;
//     await _playTypingAnimation(_greeting);
//   }

//   // ── Message helpers ───────────────────────────

//   void _addBotInstant(String text) {
//     setState(() {
//       _messages.add(
//         Message(text: text, isUser: false, timestamp: DateTime.now()),
//       );
//     });
//     _saveHistory();
//   }

//   /// Types out the bot reply one character at a time.
//   Future<void> _playTypingAnimation(String fullText) async {
//     setState(() => _isTyping = true);

//     final msg = Message(text: '', isUser: false, timestamp: DateTime.now());
//     setState(() => _messages.add(msg));
//     final idx = _messages.length - 1;

//     for (int i = 1; i <= fullText.length; i++) {
//       await Future.delayed(const Duration(milliseconds: 35));
//       if (!mounted) return;
//       setState(() {
//         _messages[idx] = Message(
//           text: fullText.substring(0, i),
//           isUser: false,
//           timestamp: msg.timestamp,
//           messageId: msg.messageId,
//         );
//       });
//       _scrollToBottom();
//     }

//     setState(() {
//       _messages[idx] = Message(
//         text: fullText,
//         isUser: false,
//         timestamp: msg.timestamp,
//         messageId: msg.messageId,
//       );
//       _isTyping = false;
//     });
//     _saveHistory();
//     _scrollToBottom();
//   }

//   // ── API call ──────────────────────────────────

//   Future<void> _sendMessage() async {
//     final text = _inputCtrl.text.trim();
//     if (text.isEmpty || _isWaiting || _isTyping) return;

//     _inputCtrl.clear();
//     setState(() {
//       _messages.add(
//         Message(text: text, isUser: true, timestamp: DateTime.now()),
//       );
//       _isWaiting = true;
//     });
//     _saveHistory();
//     _scrollToBottom(force: true);

//     try {
//       final history =
//           _messages
//               .where((m) => m.text.isNotEmpty)
//               .toList()
//               .reversed
//               .take(10)
//               .toList()
//               .reversed
//               .map(
//                 (m) => {
//                   'role': m.isUser ? 'user' : 'assistant',
//                   'content': m.text,
//                 },
//               )
//               .toList();

//       final res = await http
//           .post(
//             Uri.parse(_C.groqUrl),
//             headers: {
//               'Content-Type': 'application/json',
//               'Authorization': 'Bearer ${_C.groqKey}',
//             },
//             body: jsonEncode({
//               'model': _C.groqModel,
//               'messages': [
//                 {'role': 'system', 'content': _C.systemPrompt},
//                 ...history,
//               ],
//               'temperature': 0.7,
//               'max_tokens': 1024,
//               'top_p': 1,
//               'stream': false,
//             }),
//           )
//           .timeout(const Duration(seconds: 30));

//       setState(() => _isWaiting = false);

//       if (res.statusCode == 200) {
//         final data = jsonDecode(res.body);
//         final reply =
//             (data['choices'][0]['message']['content'] as String).trim();
//         await _playTypingAnimation(_sanitise(reply));
//       } else {
//         _addBotInstant(
//           'Sorry, I couldn\'t reach the server (${res.statusCode}). Please try again.',
//         );
//       }
//     } catch (e) {
//       setState(() => _isWaiting = false);
//       _addBotInstant(
//         'Connection error. Please check your internet and try again.',
//       );
//     }
//   }

//   String _sanitise(String s) => s
//       .replaceAll(RegExp(r'\bGroq\b', caseSensitive: false), 'Innovator')
//       .replaceAll(RegExp(r'\bLlama\b', caseSensitive: false), 'Eliza')
//       .replaceAll(RegExp(r'\bMeta\b', caseSensitive: false), 'Innovator')
//       .replaceAll(RegExp(r'\bGoogle\b', caseSensitive: false), 'Innovator')
//       .replaceAll(RegExp(r'\bGemini\b', caseSensitive: false), 'Eliza')
//       .replaceAll(RegExp(r'\bOpenAI\b', caseSensitive: false), 'Innovator')
//       .replaceAll(RegExp(r'\bChatGPT\b', caseSensitive: false), 'Eliza');

//   void _scrollToBottom({bool force = false}) {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (!_scrollCtrl.hasClients) return;
//       final pos = _scrollCtrl.position;
//       final nearBottom = pos.maxScrollExtent - pos.pixels < 120;
//       if (force || nearBottom) {
//         _scrollCtrl.animateTo(
//           pos.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   // ── Report ────────────────────────────────────

//   void _report(Message msg) {
//     if (msg.isReported) return;
//     showDialog(
//       context: context,
//       builder:
//           (_) => _ReportSheet(
//             message: msg,
//             onReport: (cat) async {
//               final idx = _messages.indexWhere(
//                 (m) => m.messageId == msg.messageId,
//               );
//               if (idx != -1) {
//                 setState(() => _messages[idx] = msg.copyWith(isReported: true));
//                 await _saveHistory();
//               }
//               if (mounted) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: const Text('Reported. Thanks for your feedback.'),
//                     backgroundColor: Colors.green.shade600,
//                     behavior: SnackBarBehavior.floating,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                 );
//               }
//             },
//           ),
//     );
//   }

//   // ── Time formatting ───────────────────────────

//   String _fmt(DateTime t) {
//     final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
//     final m = t.minute.toString().padLeft(2, '0');
//     final ampm = t.hour >= 12 ? 'PM' : 'AM';
//     final today = DateTime.now();
//     if (t.year == today.year && t.month == today.month && t.day == today.day) {
//       return '$h:$m $ampm';
//     }
//     return '${t.month}/${t.day} $h:$m $ampm';
//   }

//   // ─────────────────────────────────────────────
//   // Build
//   // ─────────────────────────────────────────────

//   @override
//   Widget build(BuildContext context) {
//     final dark = Theme.of(context).brightness == Brightness.dark;

//     return Scaffold(
//       backgroundColor: dark ? _C.darkBg : const Color(0xFFF1F5F9),
//       body: Column(
//         children: [
//           _AppBar(dark: dark, onClear: _clearHistory),
//           Expanded(
//             child:
//                 _initialLoading
//                     ? const Center(
//                       child: CircularProgressIndicator(color: _C.orange),
//                     )
//                     : ListView.builder(
//                       controller: _scrollCtrl,
//                       physics: const BouncingScrollPhysics(
//                         parent: AlwaysScrollableScrollPhysics(),
//                       ),
//                       keyboardDismissBehavior:
//                           ScrollViewKeyboardDismissBehavior.onDrag,
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 14,
//                         vertical: 12,
//                       ),
//                       itemCount: _messages.length + (_isWaiting ? 1 : 0),
//                       itemBuilder: (ctx, i) {
//                         if (i == _messages.length && _isWaiting) {
//                           return _TypingDots(
//                             controller: _dotController,
//                             dark: dark,
//                           );
//                         }
//                         return _Bubble(
//                           key: ValueKey(_messages[i].messageId),
//                           message: _messages[i],
//                           dark: dark,
//                           fmt: _fmt,
//                           onCopy: () {
//                             Clipboard.setData(
//                               ClipboardData(text: _messages[i].text),
//                             );
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(
//                                 content: const Text('Copied!'),
//                                 duration: const Duration(seconds: 1),
//                                 backgroundColor: Colors.green.shade600,
//                                 behavior: SnackBarBehavior.floating,
//                                 shape: RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(10),
//                                 ),
//                               ),
//                             );
//                           },
//                           onReport: () => _report(_messages[i]),
//                         );
//                       },
//                     ),
//           ),
//           _InputBar(
//             controller: _inputCtrl,
//             dark: dark,
//             disabled: _isWaiting || _isTyping,
//             onSend: _sendMessage,
//           ),
//         ],
//       ),
//     );
//   }
// } // end _ElizaChatScreenState

// // ─────────────────────────────────────────────
// // App Bar
// // ─────────────────────────────────────────────

// class _AppBar extends StatelessWidget {
//   final bool dark;
//   final VoidCallback onClear;
//   const _AppBar({required this.dark, required this.onClear});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.only(
//         top: MediaQuery.of(context).padding.top + 8,
//         left: 12,
//         right: 12,
//         bottom: 12,
//       ),
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           colors: [_C.orange, _C.orangeLight],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//       ),
//       child: Row(
//         children: [
//           IconButton(
//             onPressed: () => Navigator.pop(context),
//             icon: const Icon(
//               Icons.arrow_back_ios_new,
//               color: Colors.white,
//               size: 20,
//             ),
//           ),
//           Container(
//             width: 42,
//             height: 42,
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.2),
//               borderRadius: BorderRadius.circular(21),
//               border: Border.all(
//                 color: Colors.white.withOpacity(0.4),
//                 width: 2,
//               ),
//             ),
//             child: const Icon(
//               Icons.memory_rounded,
//               color: Colors.white,
//               size: 22,
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Eliza',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 17,
//                     fontWeight: FontWeight.w700,
//                     letterSpacing: 0.3,
//                   ),
//                 ),
//                 Text(
//                   'IoT · Robotics · Coding AI',
//                   style: TextStyle(
//                     color: Colors.white.withAlpha(85),
//                     fontSize: 12,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           IconButton(
//             onPressed: onClear,
//             icon: const Icon(
//               Icons.delete_sweep_outlined,
//               color: Colors.white,
//               size: 22,
//             ),
//             tooltip: 'Clear chat',
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _Bubble extends StatelessWidget {
//   final Message message;
//   final bool dark;
//   final String Function(DateTime) fmt;
//   final VoidCallback onCopy;
//   final VoidCallback onReport;

//   const _Bubble({
//     super.key,
//     required this.message,
//     required this.dark,
//     required this.fmt,
//     required this.onCopy,
//     required this.onReport,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final isUser = message.isUser;
//     final bubbleBg = isUser ? _C.orange : (dark ? _C.darkCard : Colors.white);
//     final textColor =
//         isUser ? Colors.white : (dark ? Colors.white : const Color(0xFF1E293B));
//     final timeColor =
//         isUser
//             ? Colors.white70
//             : (dark ? Colors.grey[400]! : Colors.grey[500]!);

//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: Row(
//         mainAxisAlignment:
//             isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.end,
//         children: [
//           if (!isUser) ...[_Avatar(dark: dark), const SizedBox(width: 8)],
//           Flexible(
//             child: Column(
//               crossAxisAlignment:
//                   isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
//               children: [
//                 Container(
//                   constraints: BoxConstraints(
//                     maxWidth: MediaQuery.of(context).size.width * 0.78,
//                   ),
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 12,
//                   ),
//                   decoration: BoxDecoration(
//                     color: bubbleBg,
//                     borderRadius: BorderRadius.only(
//                       topLeft: const Radius.circular(18),
//                       topRight: const Radius.circular(18),
//                       bottomLeft: Radius.circular(isUser ? 18 : 4),
//                       bottomRight: Radius.circular(isUser ? 4 : 18),
//                     ),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.07),
//                         blurRadius: 8,
//                         offset: const Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       if (message.isReported)
//                         Padding(
//                           padding: const EdgeInsets.only(bottom: 6),
//                           child: Row(
//                             children: [
//                               Icon(
//                                 Icons.flag_rounded,
//                                 size: 13,
//                                 color: Colors.red.shade400,
//                               ),
//                               const SizedBox(width: 4),
//                               Text(
//                                 'Reported',
//                                 style: TextStyle(
//                                   fontSize: 11,
//                                   color: Colors.red.shade400,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       SelectableText(
//                         message.text,
//                         style: TextStyle(
//                           color: textColor,
//                           fontSize: 15,
//                           height: 1.5,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         fmt(message.timestamp),
//                         style: TextStyle(fontSize: 11, color: timeColor),
//                       ),
//                     ],
//                   ),
//                 ),
//                 if (!isUser) ...[
//                   const SizedBox(height: 5),
//                   Row(
//                     children: [
//                       _ActionBtn(
//                         icon: Icons.copy_rounded,
//                         label: 'Copy',
//                         dark: dark,
//                         onTap: onCopy,
//                       ),
//                       const SizedBox(width: 6),
//                       _ActionBtn(
//                         icon:
//                             message.isReported
//                                 ? Icons.flag_rounded
//                                 : Icons.flag_outlined,
//                         label: message.isReported ? 'Reported' : 'Report',
//                         dark: dark,
//                         onTap: message.isReported ? null : onReport,
//                         danger: message.isReported,
//                       ),
//                     ],
//                   ),
//                 ],
//               ],
//             ),
//           ),
//           if (isUser) ...[
//             const SizedBox(width: 8),
//             Container(
//               width: 34,
//               height: 34,
//               decoration: BoxDecoration(
//                 color: _C.orange,
//                 borderRadius: BorderRadius.circular(17),
//               ),
//               child: const Icon(
//                 Icons.person_rounded,
//                 color: Colors.white,
//                 size: 18,
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────
// // Avatar
// // ─────────────────────────────────────────────

// class _Avatar extends StatelessWidget {
//   final bool dark;
//   const _Avatar({required this.dark});

//   @override
//   Widget build(BuildContext context) => Container(
//     width: 34,
//     height: 34,
//     decoration: BoxDecoration(
//       gradient: const LinearGradient(
//         colors: [_C.orange, _C.orangeLight],
//         begin: Alignment.topLeft,
//         end: Alignment.bottomRight,
//       ),
//       borderRadius: BorderRadius.circular(17),
//     ),
//     child: const Icon(Icons.memory_rounded, color: Colors.white, size: 18),
//   );
// }

// // ─────────────────────────────────────────────
// // Action button (Copy / Report)
// // ─────────────────────────────────────────────

// class _ActionBtn extends StatelessWidget {
//   final IconData icon;
//   final String label;
//   final bool dark;
//   final VoidCallback? onTap;
//   final bool danger;

//   const _ActionBtn({
//     required this.icon,
//     required this.label,
//     required this.dark,
//     this.onTap,
//     this.danger = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final color =
//         danger ? Colors.red : (dark ? Colors.grey[400]! : Colors.grey[600]!);
//     final bg =
//         danger
//             ? Colors.red.withOpacity(0.08)
//             : (dark
//                 ? Colors.white.withOpacity(0.07)
//                 : Colors.black.withOpacity(0.05));

//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
//         decoration: BoxDecoration(
//           color: bg,
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: Row(
//           children: [
//             Icon(icon, size: 13, color: color),
//             const SizedBox(width: 4),
//             Text(label, style: TextStyle(fontSize: 12, color: color)),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────
// // Typing dots (waiting for API response)
// // ─────────────────────────────────────────────

// class _TypingDots extends StatelessWidget {
//   final AnimationController controller;
//   final bool dark;
//   const _TypingDots({required this.controller, required this.dark});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.end,
//         children: [
//           _Avatar(dark: dark),
//           const SizedBox(width: 8),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//             decoration: BoxDecoration(
//               color: dark ? _C.darkCard : Colors.white,
//               borderRadius: const BorderRadius.only(
//                 topLeft: Radius.circular(18),
//                 topRight: Radius.circular(18),
//                 bottomLeft: Radius.circular(4),
//                 bottomRight: Radius.circular(18),
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.07),
//                   blurRadius: 8,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: AnimatedBuilder(
//               animation: controller,
//               builder: (_, __) {
//                 return Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: List.generate(3, (i) {
//                     final phase = (controller.value - i * 0.33) % 1.0;
//                     final opacity = (math.sin(phase * math.pi)).clamp(0.2, 1.0);
//                     return Container(
//                       margin: const EdgeInsets.symmetric(horizontal: 3),
//                       width: 7,
//                       height: 7,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         color: _C.orange.withOpacity(opacity),
//                       ),
//                     );
//                   }),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────
// // Input bar
// // ─────────────────────────────────────────────

// class _InputBar extends StatelessWidget {
//   final TextEditingController controller;
//   final bool dark;
//   final bool disabled;
//   final VoidCallback onSend;

//   const _InputBar({
//     required this.controller,
//     required this.dark,
//     required this.disabled,
//     required this.onSend,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.only(
//         left: 12,
//         right: 12,
//         top: 10,
//         bottom: MediaQuery.of(context).padding.bottom + 10,
//       ),
//       decoration: BoxDecoration(
//         color: dark ? _C.darkCard : Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.06),
//             blurRadius: 10,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: TextField(
//               controller: controller,
//               enabled: !disabled,
//               maxLines: 4,
//               minLines: 1,
//               textInputAction: TextInputAction.newline,
//               style: TextStyle(
//                 color: dark ? Colors.white : const Color(0xFF1E293B),
//                 fontSize: 15,
//               ),
//               decoration: InputDecoration(
//                 hintText:
//                     disabled
//                         ? 'Eliza is thinking...'
//                         : 'Ask about IoT, Robotics, Coding...',
//                 hintStyle: TextStyle(
//                   color: dark ? Colors.grey[500] : Colors.grey[400],
//                   fontSize: 14,
//                 ),
//                 filled: true,
//                 fillColor:
//                     dark
//                         ? _C.darkInput.withOpacity(0.7)
//                         : const Color(0xFFF1F5F9),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(24),
//                   borderSide: BorderSide.none,
//                 ),
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 18,
//                   vertical: 12,
//                 ),
//               ),
//               onSubmitted: (_) => disabled ? null : onSend(),
//             ),
//           ),
//           const SizedBox(width: 10),
//           GestureDetector(
//             onTap: disabled ? null : onSend,
//             child: AnimatedContainer(
//               duration: const Duration(milliseconds: 200),
//               width: 46,
//               height: 46,
//               decoration: BoxDecoration(
//                 gradient:
//                     disabled
//                         ? null
//                         : const LinearGradient(
//                           colors: [_C.orange, _C.orangeLight],
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                         ),
//                 color: disabled ? Colors.grey.shade300 : null,
//                 borderRadius: BorderRadius.circular(23),
//               ),
//               child: Icon(
//                 Icons.send_rounded,
//                 color: disabled ? Colors.grey.shade500 : Colors.white,
//                 size: 20,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────
// // Report dialog
// // ─────────────────────────────────────────────

// class _ReportSheet extends StatefulWidget {
//   final Message message;
//   final void Function(String) onReport;
//   const _ReportSheet({required this.message, required this.onReport});

//   @override
//   State<_ReportSheet> createState() => _ReportSheetState();
// }

// class _ReportSheetState extends State<_ReportSheet> {
//   String? _selected;

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       title: const Text('Report Message'),
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children:
//             _reportCategories
//                 .map(
//                   (c) => RadioListTile<String>(
//                     title: Text(c.title),
//                     subtitle: Text(
//                       c.description,
//                       style: const TextStyle(fontSize: 12),
//                     ),
//                     value: c.id,
//                     groupValue: _selected,
//                     onChanged: (v) => setState(() => _selected = v),
//                     activeColor: _C.orange,
//                     dense: true,
//                   ),
//                 )
//                 .toList(),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed:
//               _selected == null
//                   ? null
//                   : () {
//                     widget.onReport(_selected!);
//                     Navigator.pop(context);
//                   },
//           style: ElevatedButton.styleFrom(
//             backgroundColor: _C.orange,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(10),
//             ),
//           ),
//           child: const Text('Report', style: TextStyle(color: Colors.white)),
//         ),
//       ],
//     );
//   }
// }
