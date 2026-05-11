// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:innovator/Innovator/widget/Custom_refresh_Indicator.dart';
// import 'package:innovator/elearning/model/notification_model.dart';
// import 'package:innovator/elearning/provider/notificationProvider.dart';

// class NotificationScreen extends ConsumerStatefulWidget {
//   const NotificationScreen({super.key});

//   @override
//   ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
// }

// class _NotificationScreenState extends ConsumerState<NotificationScreen> {
//   @override
//   void initState() {
//     super.initState();
//     ref.read(elearningNotificationListProvider.notifier).refresh();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final state = ref.watch(elearningNotificationListProvider);
//     final notifications = state.notifications;

//     return Material(
//       child: CustomRefreshIndicator(
//         onRefresh:
//             () =>
//                 ref.read(elearningNotificationListProvider.notifier).refresh(),
//         child: Scaffold(
//           backgroundColor: Colors.white,
//           appBar: AppBar(
//             elevation: 0,
//             scrolledUnderElevation: 0,
//             backgroundColor: Colors.transparent,
//             title: const Text(
//               'Notifications',
//               style: TextStyle(color: Colors.black87),
//             ),
//             leading: IconButton(
//               onPressed: () => Navigator.of(context).pop(),
//               icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
//             ),
//             actions: [
//               PopupMenuButton(
//                 iconColor: Colors.black87,
//                 color: Colors.white,
//                 itemBuilder:
//                     (context) => [
//                       const PopupMenuItem(
//                         value: 'mark_all_read',
//                         child: Text('Mark all as read'),
//                       ),
//                     ],
//                 onSelected: (value) {
//                   if (value == 'mark_all_read') {
//                     ref.read(elearningMarkAllAsReadProvider)();
//                   }
//                 },
//               ),
//             ],
//           ),
//           body:
//               notifications.isEmpty
//                   ? const _EmptyView()
//                   : _NotificationList(notifications: notifications),
//         ),
//       ),
//     );
//   }
// }

// class _NotificationList extends StatelessWidget {
//   const _NotificationList({required this.notifications});
//   final List<ElearningNotificationModel> notifications;

//   @override
//   Widget build(BuildContext context) {
//     return ListView.separated(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       itemCount: notifications.length,
//       separatorBuilder: (_, __) => const Divider(height: 0, indent: 72),
//       itemBuilder: (context, index) {
//         return _NotificationTile(notification: notifications[index]);
//       },
//     );
//   }
// }

// class _NotificationTile extends ConsumerStatefulWidget {
//   const _NotificationTile({required this.notification});
//   final ElearningNotificationModel notification;

//   @override
//   ConsumerState<_NotificationTile> createState() => _NotificationTileState();
// }

// class _NotificationTileState extends ConsumerState<_NotificationTile> {
//   @override
//   ConsumerState<_NotificationTile> createState() => _NotificationTileState();

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     return ListTile(
//       tileColor:
//           widget.notification.isRead ? null : colorScheme.primary.withAlpha(13),
//       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       leading: Stack(
//         children: [
//           CircleAvatar(
//             radius: 22,
//             backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
//             child: Icon(
//               _iconForType(widget.notification.data.type),
//               color: Colors.white,
//               size: 20,
//             ),
//           ),
//           if (!widget.notification.isRead)
//             Positioned(
//               top: 0,
//               right: 0,
//               child: Container(
//                 width: 10,
//                 height: 10,
//                 decoration: BoxDecoration(
//                   color: colorScheme.primary,
//                   shape: BoxShape.circle,
//                   border: Border.all(
//                     color: theme.scaffoldBackgroundColor,
//                     width: 1.5,
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//       title: Text(
//         widget.notification.title,
//         style: theme.textTheme.bodyMedium?.copyWith(
//           fontWeight:
//               widget.notification.isRead ? FontWeight.normal : FontWeight.w600,
//         ),
//       ),
//       subtitle: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const SizedBox(height: 2),
//           Text(
//             widget.notification.message,
//             style: theme.textTheme.bodySmall?.copyWith(
//               color: colorScheme.onSurfaceVariant,
//             ),
//             maxLines: 2,
//             overflow: TextOverflow.ellipsis,
//           ),
//           const SizedBox(height: 4),
//           Text(
//             _timeAgo(widget.notification.createdAt),
//             style: theme.textTheme.labelSmall?.copyWith(
//               color: colorScheme.outline,
//             ),
//           ),
//         ],
//       ),
//       onTap: () {
//         ref.read(elearningMarkAsReadProvider(widget.notification.id));
//       },
//     );
//   }

//   IconData _iconForType(String type) {
//     switch (type) {
//       case 'enrollment':
//         return Icons.school_outlined;
//       case 'announcement':
//         return Icons.campaign_outlined;
//       case 'reminder':
//         return Icons.alarm_outlined;
//       default:
//         return Icons.notifications_outlined;
//     }
//   }

//   String _timeAgo(DateTime dateTime) {
//     final diff = DateTime.now().difference(dateTime);
//     if (diff.inSeconds < 60) return 'Just now';
//     if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
//     if (diff.inHours < 24) return '${diff.inHours}h ago';
//     return '${diff.inDays}d ago';
//   }
// }

// class _EmptyView extends StatelessWidget {
//   const _EmptyView();

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             Icons.notifications_none_outlined,
//             size: 56,
//             color: Theme.of(context).colorScheme.outline,
//           ),
//           const SizedBox(height: 12),
//           Text(
//             'No notifications yet',
//             style: Theme.of(context).textTheme.titleMedium,
//           ),
//         ],
//       ),
//     );
//   }
// }




// lib/elearning/screens/notifications_screen.dart
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/widget/Custom_refresh_Indicator.dart';
import 'package:innovator/elearning/model/course_list_model.dart';
import 'package:innovator/elearning/model/notification_model.dart';
import 'package:innovator/elearning/provider/notificationProvider.dart';
import 'package:innovator/elearning/screens/course_details_screen.dart';
import 'package:innovator/elearning/screens/course_list_screen.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(elearningNotificationListProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(elearningNotificationListProvider);
    final notifications = state.notifications;

    return Material(
      child: CustomRefreshIndicator(
        onRefresh:
            () =>
                ref.read(elearningNotificationListProvider.notifier).refresh(),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            title: const Text(
              'Notifications',
              style: TextStyle(color: Colors.black87),
            ),
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
            ),
            actions: [
              PopupMenuButton(
                iconColor: Colors.black87,
                color: Colors.white,
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'mark_all_read',
                        child: Text('Mark all as read'),
                      ),
                    ],
                onSelected: (value) {
                  if (value == 'mark_all_read') {
                    ref.read(elearningMarkAllAsReadProvider)();
                  }
                },
              ),
            ],
          ),
          body:
              notifications.isEmpty
                  ? const _EmptyView()
                  : _NotificationList(notifications: notifications),
        ),
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({required this.notifications});
  final List<ElearningNotificationModel> notifications;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: notifications.length,
      separatorBuilder: (_, __) => const Divider(height: 0, indent: 72),
      itemBuilder: (context, index) {
        return _NotificationTile(notification: notifications[index]);
      },
    );
  }
}

class _NotificationTile extends ConsumerStatefulWidget {
  const _NotificationTile({required this.notification});
  final ElearningNotificationModel notification;

  @override
  ConsumerState<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends ConsumerState<_NotificationTile> {
  bool _isNavigating = false;

  // FIX: Fetch the course by ID then navigate to CourseDetailScreen
  Future<void> _navigateToCourse(String courseId) async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    // Mark as read first (fire and forget)
    ref.read(elearningMarkAsReadProvider(widget.notification.id));

    try {
      final token = AppData().accessToken;
      if (token == null || token.isEmpty) throw Exception('Not authenticated');

      final response = await http
          .get(
            Uri.parse('http://36.253.137.34:8003/api/courses/'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> list =
            jsonDecode(response.body) as List<dynamic>;
        final courseJson = list
            .cast<Map<String, dynamic>>()
            .where((c) => c['id']?.toString() == courseId)
            .firstOrNull;

        if (courseJson != null && mounted) {
          final course = CourseListModel.fromJson(courseJson);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CourseDetailScreen(course: course),
            ),
          );
          return;
        }
      }
    } catch (e) {
      developer.log('[ElearningNotif] course fetch error: $e');
    } finally {
      if (mounted) setState(() => _isNavigating = false);
    }

    // Fallback: go to course list if individual course not found
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CourseListScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      tileColor:
          widget.notification.isRead
              ? null
              : colorScheme.primary.withAlpha(13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
            child:
                _isNavigating
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : Icon(
                      _iconForType(widget.notification.data.type),
                      color: Colors.white,
                      size: 20,
                    ),
          ),
          if (!widget.notification.isRead)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.scaffoldBackgroundColor,
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        widget.notification.title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight:
              widget.notification.isRead
                  ? FontWeight.normal
                  : FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(
            widget.notification.message,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            _timeAgo(widget.notification.createdAt),
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.outline,
            ),
          ),
        ],
      ),
      // FIX: actually navigate to the course detail screen
      onTap: () => _navigateToCourse(widget.notification.data.courseId),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'enrollment':
        return Icons.school_outlined;
      case 'announcement':
        return Icons.campaign_outlined;
      case 'reminder':
        return Icons.alarm_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text(
            'No notifications yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}