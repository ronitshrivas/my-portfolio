// import 'dart:async';
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:innovator/Innovator/App_data/App_data.dart';
// import 'dart:developer' as developer;

// import 'package:innovator/Innovator/services/in_app_notifcation.dart';

// class NotificationPollingService {
//   static final NotificationPollingService _instance =
//       NotificationPollingService._internal();
//   factory NotificationPollingService() => _instance;
//   NotificationPollingService._internal();

//   Timer? _pollingTimer;
//   Set<String> _shownNotificationIds = {};
//   bool _isPolling = false;
//   DateTime? _lastCheckTime;

//   // Configuration
//   static const Duration _pollingInterval = Duration(
//     seconds: 30,
//   ); // Check every 30 seconds
//   static const String _notificationsUrl =
//       'http://36.253.137.34:8005/api/notifications/';

//   /// Start polling for new notifications
//   void startPolling() {
//     if (_isPolling) {
//       developer.log('Notification polling already running');
//       return;
//     }

//     developer.log(' Starting notification polling service');
//     _isPolling = true;
//     _lastCheckTime = DateTime.now();

//     // Initial check
//     _checkForNewNotifications();

//     // Set up periodic polling
//     _pollingTimer = Timer.periodic(_pollingInterval, (_) {
//       _checkForNewNotifications();
//     });
//   }

//   /// Stop polling
//   void stopPolling() {
//     developer.log('⏹️ Stopping notification polling service');
//     _pollingTimer?.cancel();
//     _pollingTimer = null;
//     _isPolling = false;
//   }

//   /// Check for new unread notifications
//   Future<void> _checkForNewNotifications() async {
//     try {
//       final token = AppData().accessToken;
//       if (token == null) {
//         developer.log(' No auth token available for polling');
//         return;
//       }

//       final response = await http
//           .get(
//             Uri.parse(_notificationsUrl),
//             headers: {'Authorization': 'Bearer $token'},
//           )
//           .timeout(const Duration(seconds: 10));

//       if (response.statusCode == 200) {
//         final jsonData = jsonDecode(response.body);
//         final List<dynamic> notifications =
//             jsonData['data']['notifications'] ?? [];

//         // Filter unread notifications that haven't been shown yet
//         final newUnreadNotifications =
//             notifications.where((notif) {
//               final id = notif['_id'] as String;
//               final isRead = notif['read'] as bool? ?? false;
//               final createdAt = DateTime.parse(notif['createdAt'] as String);

//               // Only show notifications created after last check or in last 5 minutes
//               final isRecent =
//                   _lastCheckTime == null ||
//                   createdAt.isAfter(
//                     _lastCheckTime!.subtract(const Duration(minutes: 5)),
//                   );

//               return !isRead && !_shownNotificationIds.contains(id) && isRecent;
//             }).toList();

//         developer.log(
//           'Found ${newUnreadNotifications.length} new unread notifications',
//         );

//         // Check if notification service is ready
//         if (!InAppNotificationService().isReady) {
//           developer.log(
//             ' Notification service not ready yet, will retry later',
//           );
//           return;
//         }

//         // Show each new notification
//         for (var notif in newUnreadNotifications) {
//           await _showInAppNotification(notif);
//           _shownNotificationIds.add(notif['_id'] as String);

//           // Add small delay between notifications
//           if (newUnreadNotifications.length > 1) {
//             await Future.delayed(const Duration(milliseconds: 800));
//           }
//         }

//         _lastCheckTime = DateTime.now();

//         // Clean up old notification IDs (keep only last 100)
//         if (_shownNotificationIds.length > 100) {
//           final idsToRemove = _shownNotificationIds.length - 100;
//           _shownNotificationIds =
//               _shownNotificationIds.skip(idsToRemove).toSet();
//         }
//       }
//     } catch (e) {
//       developer.log(' Error polling notifications: $e');
//     }
//   }

//   /// Show in-app notification using the existing service
//   Future<void> _showInAppNotification(Map<String, dynamic> notification) async {
//     try {
//       final type = notification['type'] as String? ?? '';
//       final content = notification['content'] as String? ?? 'New notification';
//       final sender = notification['sender'] as Map<String, dynamic>?;

//       final title = sender?['name'] as String? ?? 'New Notification';
//       final imageUrl = sender?['picture'] as String?;

//       // Add delay to ensure overlay is ready
//       await Future.delayed(const Duration(milliseconds: 200));

//       await InAppNotificationService().showNotification(
//         title: title,
//         body: content,
//         imageUrl: imageUrl,
//         icon: type.notificationIcon,
//         backgroundColor: type.notificationColor,
//         duration: const Duration(seconds: 5),
//         onTap: () {
//           developer.log('📱 Notification tapped: ${notification['_id']}');
//           // You can add navigation logic here if needed
//           // For example, mark as read and navigate to notification details
//         },
//       );

//       developer.log('Showed in-app notification: $title');
//     } catch (e) {
//       developer.log(' Error showing in-app notification: $e');
//       // If overlay fails, just log it and continue
//     }
//   }

//   /// Force check for new notifications (manual refresh)
//   Future<void> forceCheck() async {
//     developer.log(' Force checking for new notifications');
//     await _checkForNewNotifications();
//   }

//   /// Clear all shown notification IDs (useful for logout)
//   void clearHistory() {
//     developer.log('🗑️ Clearing notification history');
//     _shownNotificationIds.clear();
//     _lastCheckTime = null;
//   }

//   /// Check if polling is active
//   bool get isPolling => _isPolling;

//   /// Get last check time
//   DateTime? get lastCheckTime => _lastCheckTime;
// }
