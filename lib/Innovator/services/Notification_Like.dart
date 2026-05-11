// // FIXED: Single unified NotificationService
// import 'dart:convert';
// import 'dart:developer' as developer;
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:get/get.dart';

// class NotificationService {
//   static final NotificationService _instance = NotificationService._internal();
//   factory NotificationService() => _instance;
//   NotificationService._internal();

//   final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   bool _isInitialized = false;

//   // Notification channels
//   static const AndroidNotificationChannel highImportanceChannel =
//       AndroidNotificationChannel(
//         'high_importance_channel',
//         'High Importance Notifications',
//         description: 'Critical notifications for likes, comments, and messages',
//         importance: Importance.max,
//         playSound: true,
//         enableVibration: true,
//         showBadge: true,
//         enableLights: true,
//         ledColor: Color(0xFFF48706),
//       );

//   static const AndroidNotificationChannel chatChannel =
//       AndroidNotificationChannel(
//         'chat_messages',
//         'Chat Messages',
//         description: 'Notifications for chat messages',
//         importance: Importance.high,
//         playSound: true,
//         enableVibration: true,
//         showBadge: true,
//       );

//   static const AndroidNotificationChannel regularChannel =
//       AndroidNotificationChannel(
//         'regular_channel',
//         'Regular Notifications',
//         description: 'General app notifications',
//         importance: Importance.defaultImportance,
//         playSound: true,
//         enableVibration: true,
//       );

//   // CRITICAL: Initialize BEFORE setting up message listeners
//   Future<void> initialize() async {
//     if (_isInitialized) {
//       developer.log(' NotificationService already initialized');
//       return;
//     }

//     try {
//       developer.log('🔔 Initializing NotificationService...');

//       // Step 1: Initialize local notifications
//       await _initializeLocalNotifications();

//       // Step 2: Create notification channels
//       await _createNotificationChannels();

//       // Step 3: Request permissions
//       await _requestPermissions();

//       _isInitialized = true;
//       developer.log('NotificationService initialized successfully');
//     } catch (e) {
//       developer.log(' Error initializing notifications: $e');
//       rethrow;
//     }
//   }

//   Future<void> _initializeLocalNotifications() async {
//     const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

//     const iosInit = DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//       defaultPresentAlert: true,
//       defaultPresentBadge: true,
//       defaultPresentSound: true,
//     );

//     const initSettings = InitializationSettings(
//       android: androidInit,
//       iOS: iosInit,
//     );

//     await _flutterLocalNotificationsPlugin.initialize(
//       initSettings,
//       onDidReceiveNotificationResponse: _onNotificationTapped,
//     );

//     developer.log('Local notifications initialized');
//   }

//   Future<void> _createNotificationChannels() async {
//     final androidPlugin =
//         _flutterLocalNotificationsPlugin
//             .resolvePlatformSpecificImplementation<
//               AndroidFlutterLocalNotificationsPlugin
//             >();

//     if (androidPlugin != null) {
//       await androidPlugin.createNotificationChannel(highImportanceChannel);
//       await androidPlugin.createNotificationChannel(chatChannel);
//       await androidPlugin.createNotificationChannel(regularChannel);

//       developer.log('Notification channels created');
//     }
//   }

//   Future<void> _requestPermissions() async {
//     final messaging = FirebaseMessaging.instance;

//     final settings = await messaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//       provisional: false,
//     );

//     developer.log('🔥 FCM permission: ${settings.authorizationStatus}');
//   }

//   // CRITICAL: This must work even if called immediately after initialize()
//   Future<void> handleForegroundMessage(RemoteMessage message) async {
//     if (!_isInitialized) {
//       developer.log(' Cannot handle message - service not initialized!');
//       return;
//     }

//     try {
//       developer.log('FOREGROUND message: ${message.messageId}');
//       developer.log('Notification: ${message.notification?.toMap()}');
//       developer.log('Data: ${message.data}');

//       final data = message.data;
//       final notification = message.notification;
//       final notificationType = data['type']?.toString().toLowerCase() ?? '';

//       // Determine title and body
//       String title =
//           notification?.title ??
//           data['title'] ??
//           data['senderName'] ??
//           'New Notification';

//       String body =
//           notification?.body ??
//           data['body'] ??
//           data['message'] ??
//           'You have a new notification';

//       // Show notification immediately
//       await showNotification(
//         id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
//         title: title,
//         body: body,
//         payload: jsonEncode(data),
//         channelId: _getChannelIdForType(notificationType),
//       );

//       developer.log('Foreground notification shown');
//     } catch (e) {
//       developer.log(' Error handling foreground message: $e');
//     }
//   }

//   // CRITICAL: Core notification display method
//   Future<void> showNotification({
//     required int id,
//     required String title,
//     required String body,
//     String? payload,
//     String? channelId,
//   }) async {
//     try {
//       final channel = channelId ?? 'regular_channel';

//       developer.log('🔔 Showing notification:');
//       developer.log('   ID: $id');
//       developer.log('   Title: $title');
//       developer.log('   Body: $body');
//       developer.log('   Channel: $channel');

//       final androidDetails = AndroidNotificationDetails(
//         channel,
//         _getChannelName(channel),
//         channelDescription: _getChannelDescription(channel),
//         importance: _getChannelImportance(channel),
//         priority: Priority.high,
//         color: const Color(0xFFF48706),
//         enableVibration: true,
//         playSound: true,
//         visibility: NotificationVisibility.public,
//         autoCancel: true,
//         icon: '@mipmap/ic_launcher',
//         styleInformation: BigTextStyleInformation(body, contentTitle: title),
//       );

//       const iosDetails = DarwinNotificationDetails(
//         presentAlert: true,
//         presentBadge: true,
//         presentSound: true,
//       );

//       final notificationDetails = NotificationDetails(
//         android: androidDetails,
//         iOS: iosDetails,
//       );

//       await _flutterLocalNotificationsPlugin.show(
//         id,
//         title,
//         body,
//         notificationDetails,
//         payload: payload,
//       );

//       developer.log('Notification displayed');
//     } catch (e) {
//       developer.log(' Error showing notification: $e');
//       developer.log('Stack trace: ${StackTrace.current}');
//     }
//   }

//   // Helper methods
//   String _getChannelIdForType(String type) {
//     switch (type.toLowerCase()) {
//       case 'like':
//       case 'comment':
//       case 'follow':
//         return 'high_importance_channel';
//       case 'message':
//       case 'chat':
//         return 'chat_messages';
//       default:
//         return 'regular_channel';
//     }
//   }

//   String _getChannelName(String channelId) {
//     switch (channelId) {
//       case 'high_importance_channel':
//         return 'High Importance Notifications';
//       case 'chat_messages':
//         return 'Chat Messages';
//       default:
//         return 'Regular Notifications';
//     }
//   }

//   String _getChannelDescription(String channelId) {
//     switch (channelId) {
//       case 'high_importance_channel':
//         return 'Critical notifications for social interactions';
//       case 'chat_messages':
//         return 'Notifications for chat messages';
//       default:
//         return 'General app notifications';
//     }
//   }

//   Importance _getChannelImportance(String channelId) {
//     switch (channelId) {
//       case 'high_importance_channel':
//         return Importance.max;
//       case 'chat_messages':
//         return Importance.high;
//       default:
//         return Importance.defaultImportance;
//     }
//   }

//   void _onNotificationTapped(NotificationResponse response) {
//     developer.log('🔔 Notification tapped: ${response.payload}');

//     if (response.payload != null) {
//       try {
//         final data = jsonDecode(response.payload!);
//         _handleNotificationNavigation(data);
//       } catch (e) {
//         developer.log(' Error parsing notification payload: $e');
//       }
//     }
//   }

//   void _handleNotificationNavigation(Map<String, dynamic> data) {
//     final type = data['type']?.toString().toLowerCase() ?? '';

//     developer.log('Navigating - Type: $type');

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       switch (type) {
//         case 'message':
//         case 'chat':
//           final senderId = data['senderId'];
//           final senderName = data['senderName'];
//           final chatId = data['chatId'];

//           if (senderId != null) {
//             Get.toNamed(
//               '/chat',
//               arguments: {
//                 'receiverUser': {
//                   'id': senderId,
//                   'userId': senderId,
//                   '_id': senderId,
//                   'name': senderName ?? 'User',
//                 },
//                 'chatId': chatId,
//                 'fromNotification': true,
//               },
//             );
//           }
//           break;

//         default:
//           Get.toNamed('/home');
//       }
//     });
//   }
// }
