// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:innovator/Innovator/provider/notification_provider.dart';
// import 'package:innovator/Innovator/screens/chatrrom/sound/soundplayer.dart';

// class InAppNotificationOverlay extends ConsumerWidget {
//   final Widget child;
//   const InAppNotificationOverlay({required this.child, super.key});

//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     // Watch ONLY the current banner — nothing else causes a rebuild here
//     final current = ref.watch(currentNotificationProvider);

//     return Stack(
//       children: [
//         child,
//         if (current != null)
//           _BannerEntry(
//             // ValueKey = new key per notification → triggers fresh animation
//             key: ValueKey(current.id),
//             notification: current,
//             onDismiss:
//                 () => ref.read(notificationProvider.notifier).dismissCurrent(),
//             onTap: () {
//               ref.read(notificationProvider.notifier).markRead(current.id);
//               ref.read(notificationProvider.notifier).dismissCurrent();
//             },
//           ),
//       ],
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // BANNER WIDGET — self-contained animation + auto-dismiss
// // ─────────────────────────────────────────────────────────────────────────────

// class _BannerEntry extends StatefulWidget {
//   final AppNotification notification;
//   final VoidCallback onDismiss;
//   final VoidCallback onTap;

//   const _BannerEntry({
//     required this.notification,
//     required this.onDismiss,
//     required this.onTap,
//     super.key,
//   });

//   @override
//   State<_BannerEntry> createState() => _BannerEntryState();
// }

// class _BannerEntryState extends State<_BannerEntry>
//     with SingleTickerProviderStateMixin {
//   static const Duration _animDuration = Duration(milliseconds: 380);
//   static const Duration _displayDuration = Duration(seconds: 5);

//   late final AnimationController _ctrl;
//   late final Animation<Offset> _slide;
//   late final Animation<double> _fade;
//   Timer? _autoTimer;
//   bool _dismissed = false;

//   @override
//   void initState() {
//     super.initState();

//     _ctrl = AnimationController(vsync: this, duration: _animDuration);

//     // Slides down from above the screen
//     _slide = Tween<Offset>(
//       begin: const Offset(0, -1.3),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

//     _fade = Tween<double>(
//       begin: 0,
//       end: 1,
//     ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

//     _ctrl.forward();
//     HapticFeedback.lightImpact();

//     // Auto-dismiss after 5 seconds
//     _autoTimer = Timer(_displayDuration, _dismiss);
//     SoundPlayer().notificationsound();
//   }

//   @override
//   void dispose() {
//     _autoTimer?.cancel();
//     _ctrl.dispose();
//     super.dispose();
//   }

//   Future<void> _dismiss() async {
//     if (_dismissed || !mounted) return;
//     _dismissed = true;
//     _autoTimer?.cancel();
//     await _ctrl.reverse(); // slide back up
//     if (mounted) widget.onDismiss();
//   }

//   // ── Type → Color ───────────────────────────────────────────────────────────
//   Color _accentColor() {
//     switch (widget.notification.type.toLowerCase()) {
//       case 'like':
//         return const Color(0xFFE53935);
//       case 'comment':
//         return const Color(0xFF1E88E5);
//       case 'follow':
//         return const Color(0xFF8E24AA);
//       case 'share':
//         return const Color(0xFF43A047);
//       case 'message':
//       case 'chat':
//         return const Color(0xFF00897B);
//       default:
//         return const Color(0xFFF48706); // your app's primary orange
//     }
//   }

//   // ── Type → Icon ────────────────────────────────────────────────────────────
//   IconData _icon() {
//     switch (widget.notification.type.toLowerCase()) {
//       case 'like':
//         return Icons.favorite_rounded;
//       case 'comment':
//         return Icons.chat_bubble_rounded;
//       case 'follow':
//         return Icons.person_add_rounded;
//       case 'share':
//         return Icons.share_rounded;
//       case 'message':
//       case 'chat':
//         return Icons.chat_rounded;
//       default:
//         return Icons.notifications_active_rounded;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final color = _accentColor();
//     final safeTop = MediaQuery.of(context).padding.top;

//     return Positioned(
//       top: 0,
//       left: 0,
//       right: 0,
//       child: Material(
//         type: MaterialType.transparency,
//         child: SlideTransition(
//           position: _slide,
//           child: FadeTransition(
//             opacity: _fade,
//             child: GestureDetector(
//               // Tap anywhere on banner → mark read + dismiss
//               onTap: () {
//                 widget.onTap();
//                 _dismiss();
//               },
//               // Swipe up → dismiss
//               onVerticalDragUpdate: (d) {
//                 if (d.delta.dy < -6) _dismiss();
//               },
//               child: Container(
//                 margin: EdgeInsets.only(top: safeTop + 8, left: 12, right: 12),
//                 constraints: const BoxConstraints(maxHeight: 110),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(18),
//                   boxShadow: [
//                     BoxShadow(
//                       color: color.withAlpha(18),
//                       blurRadius: 24,
//                       offset: const Offset(0, 8),
//                     ),
//                     BoxShadow(
//                       color: Colors.black.withAlpha(6),
//                       blurRadius: 8,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(18),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       // Progress bar drains over 5 seconds
//                       TweenAnimationBuilder<double>(
//                         duration: _displayDuration,
//                         tween: Tween(begin: 1.0, end: 0.0),
//                         builder:
//                             (_, val, __) => LinearProgressIndicator(
//                               value: val,
//                               minHeight: 3,
//                               backgroundColor: Colors.transparent,
//                               valueColor: AlwaysStoppedAnimation<Color>(
//                                 color.withOpacity(0.4),
//                               ),
//                             ),
//                       ),

//                       // Content row
//                       Flexible(
//                         child: Padding(
//                           padding: const EdgeInsets.fromLTRB(14, 10, 10, 12),
//                           child: Row(
//                             crossAxisAlignment: CrossAxisAlignment.center,
//                             children: [
//                               // Avatar circle
//                               _Avatar(
//                                 imageUrl: widget.notification.imageUrl,
//                                 icon: _icon(),
//                                 color: color,
//                               ),
//                               const SizedBox(width: 12),

//                               // Title + body text
//                               Expanded(
//                                 child: Column(
//                                   mainAxisSize: MainAxisSize.min,
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       widget.notification.title,
//                                       maxLines: 1,
//                                       overflow: TextOverflow.ellipsis,
//                                       style: const TextStyle(
//                                         fontSize: 14,
//                                         fontWeight: FontWeight.w700,
//                                         color: Color(0xFF1A1A2E),
//                                         letterSpacing: -0.2,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 3),
//                                     Text(
//                                       widget.notification.body,
//                                       maxLines: 2,
//                                       overflow: TextOverflow.ellipsis,
//                                       style: TextStyle(
//                                         fontSize: 12.5,
//                                         color: Colors.grey[600],
//                                         height: 1.35,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               const SizedBox(width: 8),

//                               // X dismiss button
//                               GestureDetector(
//                                 onTap: _dismiss,
//                                 behavior: HitTestBehavior.opaque,
//                                 child: Container(
//                                   padding: const EdgeInsets.all(6),
//                                   decoration: BoxDecoration(
//                                     color: Colors.grey[100],
//                                     shape: BoxShape.circle,
//                                   ),
//                                   child: Icon(
//                                     Icons.close_rounded,
//                                     size: 16,
//                                     color: Colors.grey[500],
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────────────────────────────────────
// // AVATAR — network image with icon fallback
// // ─────────────────────────────────────────────────────────────────────────────

// class _Avatar extends StatelessWidget {
//   final String? imageUrl;
//   final IconData icon;
//   final Color color;

//   const _Avatar({this.imageUrl, required this.icon, required this.color});

//   @override
//   Widget build(BuildContext context) {
//     final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

//     return Container(
//       width: 46,
//       height: 46,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         gradient: LinearGradient(
//           colors: [color, color.withOpacity(0.65)],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: color.withOpacity(0.3),
//             blurRadius: 10,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child:
//           hasImage
//               ? ClipOval(
//                 child: Image.network(
//                   imageUrl!,
//                   width: 46,
//                   height: 46,
//                   fit: BoxFit.cover,
//                   errorBuilder: (_, __, ___) => _iconWidget(),
//                 ),
//               )
//               : _iconWidget(),
//     );
//   }

//   Widget _iconWidget() => Icon(icon, color: Colors.white, size: 24);
// }
