// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'package:audioplayers/audioplayers.dart';
// import 'dart:developer' as developer;

// import 'package:innovator/Innovator/constant/app_colors.dart';

// class InAppNotificationService {
//   static final InAppNotificationService _instance =
//       InAppNotificationService._internal();
//   factory InAppNotificationService() => _instance;
//   InAppNotificationService._internal();

//   // FIX: Don't create own navigatorKey - use Get.key instead
//   GlobalKey<NavigatorState> get navigatorKey => Get.key;

//   OverlayEntry? _currentOverlay;
//   Timer? _dismissTimer;
//   bool _isShowing = false;
//   final AudioPlayer _audioPlayer = AudioPlayer();

//   /// Show a custom in-app notification
//   Future<void> showNotification({
//     required String title,
//     required String body,
//     String? imageUrl,
//     IconData? icon,
//     Color? backgroundColor,
//     VoidCallback? onTap,
//     Duration duration = const Duration(seconds: 4),
//     bool playSound = true,
//   }) async {
//     // FIX: Prevent showing multiple notifications simultaneously
//     if (_isShowing) {
//       developer.log(' Notification already showing, queuing this one');
//       await Future.delayed(const Duration(milliseconds: 500));
//       if (_isShowing) return; // Still showing, skip
//     }

//     try {
//       _isShowing = true;

//       // Remove any existing notification first
//       _removeCurrentNotification();

//       // Play notification sound
//       if (playSound) {
//         _playNotificationSound();
//       }

//       // FIX: Use Get.context which is more reliable than navigatorKey.currentContext
//       final context = Get.context;
//       if (context == null || !context.mounted) {
//         developer.log(' Context not available or not mounted');
//         _isShowing = false;
//         return;
//       }

//       // Wait a bit to ensure the widget tree is ready
//       await Future.delayed(const Duration(milliseconds: 150));

//       // FIX: Use Get.overlayContext for better reliability
//       final overlayContext = Get.overlayContext;
//       if (overlayContext == null || !overlayContext.mounted) {
//         developer.log(' Overlay context not available');
//         _isShowing = false;
//         return;
//       }

//       // Try to get overlay state
//       OverlayState? overlayState;
//       try {
//         overlayState = Overlay.of(overlayContext, rootOverlay: true);
//       } catch (e) {
//         developer.log(' Could not get overlay: $e');
//         _isShowing = false;
//         return;
//       }

//       // Create the overlay entry
//       _currentOverlay = OverlayEntry(
//         builder:
//             (context) => _NotificationWidget(
//               title: title,
//               body: body,
//               imageUrl: imageUrl,
//               icon: icon,
//               backgroundColor: backgroundColor,
//               onTap: () {
//                 _removeCurrentNotification();
//                 onTap?.call();
//               },
//               onDismiss: _removeCurrentNotification,
//               duration: duration,
//             ),
//       );

//       // Insert the overlay
//       overlayState.insert(_currentOverlay!);

//       // Haptic feedback
//       HapticFeedback.mediumImpact();

//       // Auto-dismiss after duration
//       _dismissTimer = Timer(duration, () {
//         _removeCurrentNotification();
//       });

//       developer.log('In-app notification shown: $title');
//     } catch (e, stackTrace) {
//       developer.log(' Failed to show notification: $e\n$stackTrace');
//       _currentOverlay = null;
//       _isShowing = false;
//     }
//   }

//   /// Play notification sound
//   Future<void> _playNotificationSound() async {
//     try {
//       // Try to play the sound from assets
//       await _audioPlayer.play(AssetSource('icon/notification_sound.mp3'));
//       developer.log('🔊 Notification sound played');
//     } catch (e) {
//       developer.log(' Could not play notification sound: $e');
//       // Fallback to system sound if custom sound fails
//       try {
//         await SystemSound.play(SystemSoundType.alert);
//       } catch (e2) {
//         developer.log(' System sound also failed: $e2');
//       }
//     }
//   }

//   void _removeCurrentNotification() {
//     try {
//       _dismissTimer?.cancel();
//       _dismissTimer = null;

//       if (_currentOverlay != null) {
//         _currentOverlay?.remove();
//         _currentOverlay?.dispose();
//         _currentOverlay = null;
//       }

//       _isShowing = false;
//     } catch (e) {
//       developer.log(' Error removing notification: $e');
//       _currentOverlay = null;
//       _isShowing = false;
//     }
//   }

//   /// Clear all notifications
//   void clearAll() {
//     _removeCurrentNotification();
//   }

//   /// Dispose audio player
//   void dispose() {
//     _audioPlayer.dispose();
//   }

//   /// Check if notification service is ready
//   bool get isReady {
//     try {
//       // FIX: Check multiple conditions for readiness
//       final getContext = Get.context;
//       final overlayContext = Get.overlayContext;
//       final hasContext = getContext != null && getContext.mounted;
//       final hasOverlay = overlayContext != null && overlayContext.mounted;

//       return hasContext && hasOverlay;
//     } catch (e) {
//       developer.log(' Error checking if ready: $e');
//       return false;
//     }
//   }
// }

// class _NotificationWidget extends StatefulWidget {
//   final String title;
//   final String body;
//   final String? imageUrl;
//   final IconData? icon;
//   final Color? backgroundColor;
//   final VoidCallback onTap;
//   final VoidCallback onDismiss;
//   final Duration duration;

//   const _NotificationWidget({
//     required this.title,
//     required this.body,
//     this.imageUrl,
//     this.icon,
//     this.backgroundColor,
//     required this.onTap,
//     required this.onDismiss,
//     required this.duration,
//   });

//   @override
//   State<_NotificationWidget> createState() => _NotificationWidgetState();
// }

// class _NotificationWidgetState extends State<_NotificationWidget>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<Offset> _slideAnimation;
//   late Animation<double> _fadeAnimation;

//   @override
//   void initState() {
//     super.initState();

//     _controller = AnimationController(
//       duration: const Duration(milliseconds: 400),
//       vsync: this,
//     );

//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, -1.2),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

//     // Start animation
//     _controller.forward();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   Future<void> _dismiss() async {
//     try {
//       await _controller.reverse();
//       widget.onDismiss();
//     } catch (e) {
//       widget.onDismiss();
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bgColor = widget.backgroundColor ?? const Color(0xFFF48706);

//     return Positioned(
//       top: 0,
//       left: 0,
//       right: 0,
//       child: Material(
//         type: MaterialType.transparency,
//         child: SafeArea(
//           child: FadeTransition(
//             opacity: _fadeAnimation,
//             child: SlideTransition(
//               position: _slideAnimation,
//               child: GestureDetector(
//                 onTap: widget.onTap,
//                 onVerticalDragUpdate: (details) {
//                   // Swipe up to dismiss
//                   if (details.delta.dy < -5) {
//                     _dismiss();
//                   }
//                 },
//                 child: Container(
//                   margin: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 8,
//                   ),
//                   constraints: const BoxConstraints(
//                     maxHeight: 120, // Limit maximum height
//                   ),
//                   decoration: BoxDecoration(
//                     color: AppColors.whitecolor,
//                     borderRadius: BorderRadius.circular(20),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.15),
//                         blurRadius: 20,
//                         offset: const Offset(0, 10),
//                       ),
//                     ],
//                   ),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(20),
//                     child: Container(
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                           colors: [
//                             bgColor.withOpacity(0.05),
//                             AppColors.whitecolor,
//                           ],
//                         ),
//                       ),
//                       child: Column(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           // Progress indicator
//                           TweenAnimationBuilder<double>(
//                             duration: widget.duration,
//                             tween: Tween(begin: 1.0, end: 0.0),
//                             builder: (context, value, child) {
//                               return LinearProgressIndicator(
//                                 value: value,
//                                 backgroundColor: Colors.transparent,
//                                 valueColor: AlwaysStoppedAnimation<Color>(
//                                   bgColor.withOpacity(0.3),
//                                 ),
//                                 minHeight: 3,
//                               );
//                             },
//                           ),

//                           // Content
//                           Flexible(
//                             child: Padding(
//                               padding: const EdgeInsets.all(16),
//                               child: Row(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   // Avatar/Icon
//                                   _buildLeadingWidget(bgColor),

//                                   const SizedBox(width: 14),

//                                   // Text content - wrapped with Flexible
//                                   Flexible(
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       mainAxisSize: MainAxisSize.min,
//                                       mainAxisAlignment:
//                                           MainAxisAlignment.center,
//                                       children: [
//                                         Text(
//                                           widget.title,
//                                           style: const TextStyle(
//                                             fontSize: 15,
//                                             fontWeight: FontWeight.bold,
//                                             color: Colors.black87,
//                                             letterSpacing: -0.2,
//                                           ),
//                                           maxLines: 1,
//                                           overflow: TextOverflow.ellipsis,
//                                           softWrap: false,
//                                         ),
//                                         const SizedBox(height: 4),
//                                         Text(
//                                           widget.body,
//                                           style: TextStyle(
//                                             fontSize: 13,
//                                             color: Colors.grey[700],
//                                             height: 1.3,
//                                             letterSpacing: -0.1,
//                                           ),
//                                           maxLines: 2,
//                                           overflow: TextOverflow.ellipsis,
//                                         ),
//                                       ],
//                                     ),
//                                   ),

//                                   const SizedBox(width: 8),

//                                   // Dismiss button
//                                   GestureDetector(
//                                     onTap: _dismiss,
//                                     child: Container(
//                                       padding: const EdgeInsets.all(6),
//                                       decoration: BoxDecoration(
//                                         color: Colors.grey[100],
//                                         shape: BoxShape.circle,
//                                       ),
//                                       child: Icon(
//                                         Icons.close,
//                                         size: 18,
//                                         color: Colors.grey[600],
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildLeadingWidget(Color bgColor) {
//     if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
//       return Container(
//         width: 50,
//         height: 50,
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           border: Border.all(color: bgColor.withOpacity(0.3), width: 2),
//         ),
//         child: ClipOval(
//           child: Image.network(
//             widget.imageUrl!,
//             width: 50,
//             height: 50,
//             fit: BoxFit.cover,
//             errorBuilder:
//                 (context, error, stackTrace) => _buildDefaultIcon(bgColor),
//           ),
//         ),
//       );
//     }

//     return _buildDefaultIcon(bgColor);
//   }

//   Widget _buildDefaultIcon(Color bgColor) {
//     return Container(
//       width: 50,
//       height: 50,
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [bgColor, bgColor.withOpacity(0.7)],
//         ),
//         shape: BoxShape.circle,
//         boxShadow: [
//           BoxShadow(
//             color: bgColor.withOpacity(0.3),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Icon(
//         widget.icon ?? Icons.notifications_active,
//         color: AppColors.whitecolor,
//         size: 26,
//       ),
//     );
//   }
// }

// // Helper extension for notification types
// extension NotificationTypeHelper on String {
//   IconData get notificationIcon {
//     switch (toLowerCase()) {
//       case 'like':
//         return Icons.favorite;
//       case 'comment':
//         return Icons.comment;
//       case 'follow':
//         return Icons.person_add;
//       case 'mention':
//         return Icons.alternate_email;
//       case 'share':
//         return Icons.share;
//       case 'message':
//         return Icons.chat_bubble;
//       default:
//         return Icons.notifications_active;
//     }
//   }

//   Color get notificationColor {
//     switch (toLowerCase()) {
//       case 'like':
//         return Colors.red;
//       case 'comment':
//         return Colors.blue;
//       case 'follow':
//         return Colors.purple;
//       case 'mention':
//         return const Color(0xFFF48706);
//       case 'share':
//         return Colors.green;
//       case 'message':
//         return Colors.teal;
//       default:
//         return const Color(0xFFF48706);
//     }
//   }
// }
