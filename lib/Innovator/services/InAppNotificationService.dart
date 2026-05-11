// // File: lib/Innovator/services/InAppNotificationService.dart
// // COMPLETE REPLACEMENT - Works with GetX's lazy navigator

// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
// import 'dart:developer' as developer;

// import 'package:innovator/Innovator/constant/app_colors.dart';

// class InAppNotificationService {
//   static final InAppNotificationService _instance =
//       InAppNotificationService._internal();
//   factory InAppNotificationService() => _instance;
//   InAppNotificationService._internal();

//   final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
//   OverlayEntry? _currentOverlay;
//   Timer? _dismissTimer;

//   /// Show a custom in-app notification using GetX overlay
//   Future<void> showNotification({
//     required String title,
//     required String body,
//     String? imageUrl,
//     IconData? icon,
//     Color? backgroundColor,
//     VoidCallback? onTap,
//     Duration duration = const Duration(seconds: 4),
//   }) async {
//     try {
//       developer.log('🔔 Attempting to show notification: $title');

//       // Remove any existing notification first
//       _removeCurrentNotification();

//       // FIX: Use Get.overlayContext instead of navigatorKey
//       // This works better with GetX's lazy initialization
//       final context = Get.overlayContext;

//       if (context == null) {
//         developer.log(' Get.overlayContext not available, trying Get.context');

//         // Fallback to Get.context
//         final fallbackContext = Get.context;
//         if (fallbackContext == null) {
//           developer.log(' No context available at all');

//           // Last resort: Use GetX snackbar
//           _showGetXFallback(title, body, icon, backgroundColor, onTap);
//           return;
//         }

//         // Try with fallback context
//         _tryShowWithContext(
//           fallbackContext,
//           title,
//           body,
//           imageUrl,
//           icon,
//           backgroundColor,
//           onTap,
//           duration,
//         );
//         return;
//       }

//       // Try to show with overlay context
//       _tryShowWithContext(
//         context,
//         title,
//         body,
//         imageUrl,
//         icon,
//         backgroundColor,
//         onTap,
//         duration,
//       );
//     } catch (e, stackTrace) {
//       developer.log(' Failed to show notification: $e');
//       developer.log('Stack: $stackTrace');

//       // Fallback to GetX snackbar
//       _showGetXFallback(title, body, icon, backgroundColor, onTap);
//     }
//   }

//   void _tryShowWithContext(
//     BuildContext context,
//     String title,
//     String body,
//     String? imageUrl,
//     IconData? icon,
//     Color? backgroundColor,
//     VoidCallback? onTap,
//     Duration duration,
//   ) {
//     try {
//       // Check if overlay is available
//       final overlay = Overlay.maybeOf(context);

//       if (overlay == null) {
//         developer.log(' Overlay not ready, using GetX snackbar');
//         _showGetXFallback(title, body, icon, backgroundColor, onTap);
//         return;
//       }

//       developer.log('Overlay available, inserting notification');

//       // Create and insert overlay entry
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
//             ),
//       );

//       overlay.insert(_currentOverlay!);
//       HapticFeedback.mediumImpact();

//       // Auto-dismiss after duration
//       _dismissTimer = Timer(duration, _removeCurrentNotification);

//       developer.log('Notification overlay inserted successfully');
//     } catch (e) {
//       developer.log(' Error with overlay: $e, falling back to GetX snackbar');
//       _showGetXFallback(title, body, icon, backgroundColor, onTap);
//     }
//   }

//   void _showGetXFallback(
//     String title,
//     String body,
//     IconData? icon,
//     Color? backgroundColor,
//     VoidCallback? onTap,
//   ) {
//     developer.log('📱 Using GetX snackbar as fallback');

//     try {
//       Get.snackbar(
//         title,
//         body,
//         snackPosition: SnackPosition.TOP,
//         backgroundColor: backgroundColor ?? const Color(0xFFF48706),
//         colorText: AppColors.whitecolor,
//         duration: const Duration(seconds: 4),
//         margin: const EdgeInsets.all(16),
//         borderRadius: 12,
//         icon: Icon(
//           icon ?? Icons.notifications_active,
//           color: AppColors.whitecolor,
//           size: 28,
//         ),
//         shouldIconPulse: true,
//         barBlur: 15,
//         isDismissible: true,
//         dismissDirection: DismissDirection.horizontal,
//         mainButton:
//             onTap != null
//                 ? TextButton(
//                   onPressed: () {
//                     Get.back();
//                     onTap();
//                   },
//                   child: const Text(
//                     'View',
//                     style: TextStyle(
//                       color: AppColors.whitecolor,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 )
//                 : null,
//       );

//       HapticFeedback.mediumImpact();
//     } catch (e) {
//       developer.log(' Even GetX snackbar failed: $e');
//     }
//   }

//   void _removeCurrentNotification() {
//     _dismissTimer?.cancel();
//     _dismissTimer = null;

//     if (_currentOverlay != null) {
//       try {
//         _currentOverlay?.remove();
//         developer.log('Notification removed');
//       } catch (e) {
//         developer.log(' Error removing overlay: $e');
//       }
//       _currentOverlay = null;
//     }
//   }

//   /// Clear all notifications
//   void clearAll() {
//     _removeCurrentNotification();
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

//   const _NotificationWidget({
//     required this.title,
//     required this.body,
//     this.imageUrl,
//     this.icon,
//     this.backgroundColor,
//     required this.onTap,
//     required this.onDismiss,
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
//     await _controller.reverse();
//     widget.onDismiss();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bgColor = widget.backgroundColor ?? const Color(0xFFF48706);

//     return Positioned(
//       top: 0,
//       left: 0,
//       right: 0,
//       child: SafeArea(
//         child: FadeTransition(
//           opacity: _fadeAnimation,
//           child: SlideTransition(
//             position: _slideAnimation,
//             child: GestureDetector(
//               onTap: widget.onTap,
//               onVerticalDragUpdate: (details) {
//                 // Swipe up to dismiss
//                 if (details.delta.dy < -5) {
//                   _dismiss();
//                 }
//               },
//               child: Container(
//                 margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                 decoration: BoxDecoration(
//                   color: AppColors.whitecolor,
//                   borderRadius: BorderRadius.circular(20),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.15),
//                       blurRadius: 20,
//                       offset: const Offset(0, 10),
//                     ),
//                   ],
//                 ),
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(20),
//                   child: Container(
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         begin: Alignment.topLeft,
//                         end: Alignment.bottomRight,
//                         colors: [
//                           bgColor.withOpacity(0.05),
//                           AppColors.whitecolor,
//                         ],
//                       ),
//                     ),
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         // Progress indicator
//                         TweenAnimationBuilder<double>(
//                           duration: const Duration(seconds: 4),
//                           tween: Tween(begin: 1.0, end: 0.0),
//                           builder: (context, value, child) {
//                             return LinearProgressIndicator(
//                               value: value,
//                               backgroundColor: Colors.transparent,
//                               valueColor: AlwaysStoppedAnimation<Color>(
//                                 bgColor.withOpacity(0.3),
//                               ),
//                               minHeight: 3,
//                             );
//                           },
//                         ),

//                         // Content
//                         Padding(
//                           padding: const EdgeInsets.all(16),
//                           child: Row(
//                             children: [
//                               // Avatar/Icon
//                               _buildLeadingWidget(bgColor),

//                               const SizedBox(width: 14),

//                               // Text content
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       widget.title,
//                                       style: const TextStyle(
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.bold,
//                                         color: Colors.black87,
//                                       ),
//                                       maxLines: 1,
//                                       overflow: TextOverflow.ellipsis,
//                                     ),
//                                     const SizedBox(height: 4),
//                                     Text(
//                                       widget.body,
//                                       style: TextStyle(
//                                         fontSize: 14,
//                                         color: Colors.grey[700],
//                                         height: 1.3,
//                                       ),
//                                       maxLines: 2,
//                                       overflow: TextOverflow.ellipsis,
//                                     ),
//                                   ],
//                                 ),
//                               ),

//                               const SizedBox(width: 8),

//                               // Dismiss button
//                               GestureDetector(
//                                 onTap: _dismiss,
//                                 child: Container(
//                                   padding: const EdgeInsets.all(6),
//                                   decoration: BoxDecoration(
//                                     color: Colors.grey[100],
//                                     shape: BoxShape.circle,
//                                   ),
//                                   child: Icon(
//                                     Icons.close,
//                                     size: 18,
//                                     color: Colors.grey[600],
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
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
