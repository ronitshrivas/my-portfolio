// // daily_notification_service.dart
// // Automatic daily notifications with predefined times

// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:innovator/main.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest.dart' as tz;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:math';
// import 'dart:developer' as developer;

// class DailyNotificationService {
//   static const String _channelId = 'daily_innovator_thoughts';
//   static const String _channelName = 'Daily Innovator Thoughts';
//   static const String _prefKey = 'daily_notifications_enabled';
  
//   // AUTOMATIC NOTIFICATION TIMES - No user input needed
//   static const List<Map<String, dynamic>> _notificationTimes = [
//     {'hour': 9, 'minute': 0, 'id': 1001, 'label': 'Morning Motivation'},
//     {'hour': 14, 'minute': 32, 'id': 1002, 'label': 'Afternoon Inspiration'},
//     {'hour': 19, 'minute': 0, 'id': 1003, 'label': 'Evening Reflection'},
//   ];
  
//   // Use your existing notification plugin instance
//   static FlutterLocalNotificationsPlugin get _notifications => flutterLocalNotificationsPlugin;
  
//   // Engaging thoughts for innovators
//   static final List<String> _innovatorThoughts = [
//     "💡 Every problem is an opportunity for innovation waiting to be discovered!",
//     "Today's crazy idea could be tomorrow's breakthrough technology.",
//     "🌟 Innovation starts with questioning 'What if we did this differently?'",
//     "🔥 The best time to plant a tree was 20 years ago. The second best time is now!",
//     "💎 Your unique perspective is your superpower in the innovation game.",
//     "⚡ Failure is just feedback in disguise - embrace it and iterate!",
//     "🎯 Small consistent actions compound into revolutionary changes.",
//     "🌈 Innovation happens at the intersection of different ideas and disciplines.",
//     "🏆 Don't wait for inspiration - start creating and inspiration will follow!",
//     "🔬 Every expert was once a beginner who refused to give up.",
//     "💪 The future belongs to those who believe in the beauty of their dreams.",
//     "🎨 Creativity is intelligence having fun - let your mind play today!",
//     "🌱 Innovation is 1% inspiration and 99% perspiration - keep pushing!",
//     "🎪 Think outside the box? There is no box in innovation!",
//     "🔋 Your energy and passion are the fuel for groundbreaking ideas.",
//     "🌍 Change the world by starting with changing yourself.",
//     "🎭 Innovation requires the courage to be different and stand out.",
//     "🏃‍♂️ Speed of implementation beats perfection of planning.",
//     "🎪 Make mistakes faster than anyone else - that's how you win!",
//     "🌊 Ride the wave of change instead of fighting against it.",
//     "🎯 Focus on solutions, not problems - that's the innovator's mindset!",
//     "🚪 When one door closes, an innovator builds a new entrance!",
//     "💡 Ideas without execution are just dreams - make yours reality!",
//     "🔥 Be so good at what you do that they can't ignore you!",
//     "🌟 Innovation is the bridge between imagination and impact."
//   ];

//   // Initialize the daily notification service
//   static Future<void> initialize() async {
//     try {
//       // Initialize timezone data
//       tz.initializeTimeZones();
      
//       // Create the daily notifications channel
//       await _createNotificationChannel();
      
//       // Check if notifications should be auto-enabled
//       await _checkAndAutoEnable();
      
//       developer.log('Daily notification service initialized with automatic scheduling');
//     } catch (e) {
//       developer.log('Daily notification service initialization failed: $e');
//     }
//   }

//   // Auto-enable notifications if not explicitly disabled
//   static Future<void> _checkAndAutoEnable() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final hasBeenSet = prefs.containsKey(_prefKey);
      
//       if (!hasBeenSet) {
//         // First time - automatically enable daily notifications
//         await enableDailyNotifications();
//         developer.log('Auto-enabled daily notifications for new user');
//       } else {
//         final isEnabled = prefs.getBool(_prefKey) ?? false;
//         if (isEnabled) {
//           // Re-schedule notifications on app start
//           await enableDailyNotifications();
//           developer.log('Re-scheduled existing daily notifications');
//         }
//       }
//     } catch (e) {
//       developer.log('Auto-enable check failed: $e');
//     }
//   }

//   // Create notification channel for daily thoughts
//   static Future<void> _createNotificationChannel() async {
//     try {
//       final androidPlugin = _notifications
//           .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
//       if (androidPlugin != null) {
//         await androidPlugin.createNotificationChannel(
//           const AndroidNotificationChannel(
//             _channelId,
//             _channelName,
//             description: 'Daily inspiring thoughts for innovators',
//             importance: Importance.defaultImportance,
//             enableVibration: true,
//             playSound: true,
//             showBadge: true,
//           ),
//         );
//       }
//     } catch (e) {
//       developer.log('Failed to create daily notification channel: $e');
//     }
//   }

//   // Enable daily notifications with automatic times
//   static Future<bool> enableDailyNotifications() async {
//     try {
//       // Schedule all automatic notifications
//       for (final timeData in _notificationTimes) {
//         await _scheduleNotification(
//           id: timeData['id'],
//           hour: timeData['hour'],
//           minute: timeData['minute'],
//           label: timeData['label'],
//         );
//       }
      
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setBool(_prefKey, true);
      
//       developer.log('Daily notifications enabled at automatic times: 9:00 AM, 2:30 PM, 7:00 PM');
//       return true;
//     } catch (e) {
//       developer.log('Failed to enable daily notifications: $e');
//       return false;
//     }
//   }

//   // Disable daily notifications
//   static Future<bool> disableDailyNotifications() async {
//     try {
//       // Cancel all scheduled notifications
//       for (final timeData in _notificationTimes) {
//         await _notifications.cancel(timeData['id']);
//       }
      
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setBool(_prefKey, false);
      
//       developer.log('Daily notifications disabled');
//       return true;
//     } catch (e) {
//       developer.log('Failed to disable daily notifications: $e');
//       return false;
//     }
//   }

//   // Schedule specific notification
//   static Future<void> _scheduleNotification({
//     required int id,
//     required int hour,
//     required int minute,
//     required String label,
//   }) async {
//     try {
//       // Cancel existing notification with this ID
//       await _notifications.cancel(id);
      
//       // Create notification details
//       const androidDetails = AndroidNotificationDetails(
//         _channelId,
//         _channelName,
//         channelDescription: 'Daily inspiring thoughts for innovators',
//         importance: Importance.defaultImportance,
//         priority: Priority.defaultPriority,
//         showWhen: true,
//         icon: '@mipmap/ic_launcher',
//         playSound: true,
//         enableVibration: true,
//         styleInformation: BigTextStyleInformation(
//           '',
//           htmlFormatBigText: true,
//           contentTitle: 'Innovator Social 🚀',
//         ),
//       );

//       const iosDetails = DarwinNotificationDetails(
//         presentAlert: true,
//         presentBadge: true,
//         presentSound: true,
//       );

//       const notificationDetails = NotificationDetails(
//         android: androidDetails,
//         iOS: iosDetails,
//       );

//       // Get random thought
//       final randomThought = _getRandomThought();

//       // Schedule the notification
//       await _notifications.zonedSchedule(
//         id,
//         'Innovator Social 🚀',
//         randomThought,
//         _getNextDailyTime(hour, minute),
//         notificationDetails,
//         androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//         uiLocalNotificationDateInterpretation:
//             UILocalNotificationDateInterpretation.absoluteTime,
//         matchDateTimeComponents: DateTimeComponents.time,
//         payload: 'daily_thought_$id',
//       );

//       developer.log('Scheduled $label notification for $hour:${minute.toString().padLeft(2, '0')}');
//     } catch (e) {
//       developer.log('Failed to schedule $label notification: $e');
//     }
//   }

//   // Get next daily notification time
//   static tz.TZDateTime _getNextDailyTime(int hour, int minute) {
//     final now = tz.TZDateTime.now(tz.local);
//     tz.TZDateTime scheduledTime = tz.TZDateTime(
//       tz.local,
//       now.year,
//       now.month,
//       now.day,
//       hour,
//       minute,
//     );

//     // If scheduled time has passed today, schedule for tomorrow
//     if (scheduledTime.isBefore(now)) {
//       scheduledTime = scheduledTime.add(const Duration(days: 1));
//     }

//     return scheduledTime;
//   }

//   // Get random engaging thought
//   static String _getRandomThought() {
//     final random = Random();
//     return _innovatorThoughts[random.nextInt(_innovatorThoughts.length)];
//   }

//   // Show test notification
//   // Show test notification
// static Future<void> showTestNotification() async {
//   try {
//     // Create the test notification channel (similar to _createNotificationChannel)
//     final androidPlugin = _notifications
//         .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
//     if (androidPlugin != null) {
//       await androidPlugin.createNotificationChannel(
//         const AndroidNotificationChannel(
//           'test_thoughts',
//           'Test Thoughts',
//           description: 'Test notifications for daily thoughts',
//           importance: Importance.high,
//           enableVibration: true,
//           playSound: true,
//           showBadge: true,
//         ),
//       );
//     }

//     const androidDetails = AndroidNotificationDetails(
//       'test_thoughts',
//       'Test Thoughts',
//       channelDescription: 'Test notifications for daily thoughts',
//       importance: Importance.high,
//       priority: Priority.high,
//       showWhen: true,
//       icon: '@mipmap/ic_launcher',
//     );

//     const iosDetails = DarwinNotificationDetails(
//       presentAlert: true,
//       presentBadge: true,
//       presentSound: true,
//     );

//     const notificationDetails = NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );

//     final randomThought = _getRandomThought();

//     await _notifications.show(
//       1999, // Test notification ID
//       'Innovator Social 🚀',
//       randomThought,
//       notificationDetails,
//       payload: 'test_thought',
//     );

//     developer.log('Test notification sent');
//   } catch (e) {
//     developer.log('Failed to send test notification: $e');
//   }
// }

//   // Check if daily notifications are enabled
//   static Future<bool> areNotificationsEnabled() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       return prefs.getBool(_prefKey) ?? false;
//     } catch (e) {
//       developer.log('Failed to check notification status: $e');
//       return false;
//     }
//   }

//   // Get notification schedule info
//   static List<String> getNotificationSchedule() {
//     return _notificationTimes.map((time) {
//       final hour = time['hour'].toString();
//       final minute = time['minute'].toString().padLeft(2, '0');
//       return '${time['label']}: $hour:$minute';
//     }).toList();
//   }

//   // Force refresh all notifications (useful after app update)
//   static Future<void> refreshAllNotifications() async {
//     try {
//       final isEnabled = await areNotificationsEnabled();
//       if (isEnabled) {
//         await disableDailyNotifications();
//         await enableDailyNotifications();
//         developer.log('All daily notifications refreshed');
//       }
//     } catch (e) {
//       developer.log('Failed to refresh notifications: $e');
//     }
//   }
// }

// // Simple Settings Widget (only enable/disable)

// // Integration with your existing main.dart
// /*
// Add this to your _initializeApp() function:

// try {
//   await DailyNotificationService.initialize();
//   developer.log('Daily notification service initialized with automatic scheduling');
// } catch (e) {
//   developer.log('Daily notification service failed: $e');
// }

// Add this to your notification handler in _onNotificationTapped:

// if (response.payload != null && 
//     (response.payload == 'daily_thought' || response.payload!.startsWith('daily_thought_'))) {
//   // User tapped daily notification - could navigate to motivation screen or just dismiss
//   Get.snackbar(
//     'Daily Motivation',
//     'Keep innovating!',
//     backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
//     colorText: AppColors.whitecolor,
//   );
//   return;
// }
// */