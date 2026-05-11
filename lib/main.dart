// import 'dart:async';
// import 'dart:convert';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:get/get.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:innovator/Innovator/App_data/App_data.dart';
// import 'package:innovator/Innovator/constant/app_colors.dart';
// import 'package:innovator/Innovator/hive/feed_cache_service.dart';
// import 'package:innovator/Innovator/provider/global_chat_listener.dart';
// import 'package:innovator/Innovator/provider/notification_provider.dart';
// import 'package:innovator/Innovator/screens/Likes/hive_reaction_queue.dart';
// import 'package:innovator/Innovator/screens/Splash_Screen/splash_screen.dart';
// import 'package:innovator/Innovator/services/fcm_services.dart';
// import 'package:innovator/KMS/screens/auth/login_screen.dart';
// import 'package:innovator/KMS/screens/dashboard/admin_dashboard_screen.dart';
// import 'package:innovator/KMS/screens/dashboard/teacher_dashboard_screen.dart';
// import 'package:innovator/KMS/screens/student/student_attendance_screen.dart';
// import 'package:innovator/ecommerce/provider/notificationProvider.dart';
// import 'dart:developer' as developer;
// import 'package:innovator/ecommerce/screens/Shop/Shop_Page.dart';
// import 'package:innovator/elearning/provider/notificationProvider.dart';

// late Size mq;
// GlobalKey<NavigatorState> get navigatorKey => Get.key;

// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp();
//   developer.log('Background notification: ${message.notification?.title}');
// }

// void main() async {
//   runZonedGuarded(
//     () async {
//       try {
//         developer.log('App starting...');
//         WidgetsFlutterBinding.ensureInitialized();
//         await Hive.initFlutter();
//         await HiveReactionQueue.instance.init();
//         await FeedCacheService.instance.init();
//         SystemChrome.setSystemUIOverlayStyle(
//           const SystemUiOverlayStyle(
//             statusBarColor: Colors.transparent,
//             statusBarIconBrightness: Brightness.dark,
//           ),
//         );

//         await Firebase.initializeApp();
//         FirebaseMessaging.onBackgroundMessage(
//           _firebaseMessagingBackgroundHandler,
//         );
//         developer.log(' Starting UI...');
//         // runApp(ProviderScope(child: InnovatorHomePage()));
//         runApp(ProviderScope(child: InnovatorHomePage()));
//         developer.log('App started successfully');
//       } catch (e, stackTrace) {
//         developer.log('Critical error in main: $e\n$stackTrace');
//         runApp(const ProviderScope(child: InnovatorHomePage()));
//       }
//     },
//     (error, stackTrace) {
//       developer.log('Uncaught error: $error\n$stackTrace');
//     },
//   );
// }

// class InnovatorHomePage extends ConsumerStatefulWidget {
//   const InnovatorHomePage({super.key});

//   @override
//   ConsumerState<InnovatorHomePage> createState() => _InnovatorHomePageState();
// }

// class _InnovatorHomePageState extends ConsumerState<InnovatorHomePage>
//     with WidgetsBindingObserver {
//   final FlutterLocalNotificationsPlugin _localNotifications =
//       FlutterLocalNotificationsPlugin();
//   bool _localNotificationsInitialized = false;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     developer.log('InnovatorHomePage initialized');
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       _setupFCM();
//       ref.read(notificationProvider.notifier).startPolling();
//       final fcmToken = await FirebaseMessaging.instance.getToken();
//       ref
//           .read(elearningNotificationServiceProvider)
//           .registerFcmToken(fcmToken ?? '');
//       ref
//           .read(ecommerceNotificationServiceProvider)
//           .registerFcmToken(fcmToken ?? '');
//     });
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       ref.read(globalChatListenerProvider);
//     });
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   Future<void> _setupFCM() async {
//     try {
//       const androidSettings = AndroidInitializationSettings(
//         '@mipmap/ic_launcher',
//       );
//       const iosSettings = DarwinInitializationSettings(
//         requestAlertPermission: true,
//         requestBadgePermission: true,
//         requestSoundPermission: true,
//       );
//       const initSettings = InitializationSettings(
//         android: androidSettings,
//         iOS: iosSettings,
//       );
//       await _localNotifications.initialize(
//         initSettings,
//         onDidReceiveNotificationResponse: (NotificationResponse details) {
//           developer.log('Local notification tapped: ${details.payload}');
//           if (details.payload != null) {
//             try {
//               final data = jsonDecode(details.payload!) as Map<String, dynamic>;
//               _handleNotificationData(data);
//             } catch (e) {
//               developer.log('Payload parse error: $e');
//             }
//           }
//         },
//       );
//       const AndroidNotificationChannel channel = AndroidNotificationChannel(
//         'high_importance_channel',
//         'High Importance Notifications',
//         description: 'This channel is used for important notifications',
//         importance: Importance.max,
//         playSound: true,
//         enableVibration: true,
//         showBadge: true,
//       );
//       await _localNotifications
//           .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin
//           >()
//           ?.createNotificationChannel(channel);
//       _localNotificationsInitialized = true;
//       developer.log('Local notifications initialized');

//       NotificationSettings settings = await FirebaseMessaging.instance
//           .requestPermission(alert: true, badge: true, sound: true);
//       developer.log('FCM permission: ${settings.authorizationStatus}');
//       if (settings.authorizationStatus == AuthorizationStatus.denied) {
//         developer.log('User denied notification permission');
//         return;
//       }
//       await FirebaseMessaging.instance
//           .setForegroundNotificationPresentationOptions(
//             alert: true,
//             badge: true,
//             sound: true,
//           );

//       final accessToken = AppData().accessToken;
//       if (accessToken != null && accessToken.isNotEmpty) {
//         final fcmToken = await FirebaseMessaging.instance.getToken();
//         if (fcmToken != null) {
//           await Future.wait([
//             FCMService().registerToken(),
//             ref
//                 .read(elearningNotificationServiceProvider)
//                 .registerFcmToken(fcmToken),
//             ref
//                 .read(ecommerceNotificationServiceProvider)
//                 .registerFcmToken(fcmToken),
//           ]);
//         }
//       } else {
//         developer.log('FCM: Skipping — user not logged in');
//       }
//       FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
//         developer.log('FCM Token refreshed: $newToken');
//         await Future.wait([
//           FCMService().registerToken(),
//           ref
//               .read(elearningNotificationServiceProvider)
//               .registerFcmToken(newToken),
//           ref
//               .read(ecommerceNotificationServiceProvider)
//               .registerFcmToken(newToken),
//         ]);
//       });

//       FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//         _showForegroundNotification(message);
//       });

//       FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
//         developer.log('Notification tapped from background');
//         _handleNotificationTap(message);
//       });
//       RemoteMessage? initialMessage =
//           await FirebaseMessaging.instance.getInitialMessage();
//       if (initialMessage != null) {
//         developer.log('App opened from killed state via notification');
//         await Future.delayed(const Duration(milliseconds: 500));
//         _handleNotificationTap(initialMessage);
//       }
//       developer.log('FCM setup completed');
//     } catch (e) {
//       developer.log('FCM setup error: $e');
//     }
//   }

//   void _showForegroundNotification(RemoteMessage message) {
//     try {
//       if (!_localNotificationsInitialized) {
//         developer.log('Local notifications not initialized yet');
//         return;
//       }
//       final title =
//           message.notification?.title ??
//           message.data['title']?.toString() ??
//           message.data['senderName']?.toString() ??
//           'New Notification';
//       final body =
//           message.notification?.body ??
//           message.data['body']?.toString() ??
//           message.data['message']?.toString() ??
//           '';
//       developer.log('Showing local notification — title: $title, body: $body');
//       final androidDetails = AndroidNotificationDetails(
//         'high_importance_channel',
//         'High Importance Notifications',
//         channelDescription: 'This channel is used for important notifications',
//         importance: Importance.max,
//         priority: Priority.max,
//         playSound: true,
//         enableVibration: true,
//         visibility: NotificationVisibility.public,
//         icon: '@mipmap/ic_launcher',
//         fullScreenIntent: false,
//         ticker: title,
//       );
//       const iosDetails = DarwinNotificationDetails(
//         presentAlert: true,
//         presentBadge: true,
//         presentSound: true,
//       );
//       _localNotifications.show(
//         DateTime.now().millisecondsSinceEpoch ~/ 1000,
//         title,
//         body,
//         NotificationDetails(android: androidDetails, iOS: iosDetails),
//         payload: jsonEncode(message.data),
//       );
//       developer.log('Local notification shown');
//     } catch (e) {
//       developer.log('Show foreground notification error: $e');
//     }
//   }

//   void _handleNotificationTap(RemoteMessage message) {
//     _handleNotificationData(message.data);
//   }

//   void _handleNotificationData(Map<String, dynamic> data) {
//     try {
//       final type = data['type']?.toString() ?? '';
//       developer.log('Handling notification type: $type');
//       switch (type) {
//         case 'follow':
//           break;
//         case 'reaction':
//         case 'comment':
//           break;
//         case 'chat':
//         case 'message':
//           break;
//         default:
//           break;
//       }
//     } catch (e) {
//       developer.log('Handle notification data error: $e');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     mq = MediaQuery.of(context).size;

//     return GetMaterialApp(
//       navigatorKey: navigatorKey,
//       home: SplashScreen(),
//       routes: {
//         '/kms/login': (_) => KmsLoginScreen(),
//         '/kms/adminDasboard': (_) => AdminDashboardScreen(),
//         '/kms/partnerDashboard': (_) => TeacherDashboardScreen(),
//         '/kms/studentDashboard': (_) => StudentAttendanceScreen(),
//       },
//       title: 'Innovator',
//       theme: _buildAppTheme(),
//       debugShowCheckedModeBanner: false,

//       getPages: [GetPage(name: '/shop', page: () => const ShopPage())],
//     );
//   }

//   ThemeData _buildAppTheme() {
//     return ThemeData(
//       fontFamily: 'InterThin',
//       primarySwatch: Colors.orange,
//       primaryColor: const Color.fromRGBO(244, 135, 6, 1),
//       appBarTheme: const AppBarTheme(
//         elevation: 1,
//         centerTitle: true,
//         titleTextStyle: TextStyle(
//           color: AppColors.whitecolor,
//           fontWeight: FontWeight.bold,
//           fontSize: 19,
//         ),
//         backgroundColor: Color.fromRGBO(244, 135, 6, 1),
//         iconTheme: IconThemeData(color: AppColors.whitecolor),
//       ),
//       elevatedButtonTheme: ElevatedButtonThemeData(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
//           foregroundColor: AppColors.whitecolor,
//         ),
//       ),
//       floatingActionButtonTheme: const FloatingActionButtonThemeData(
//         backgroundColor: Color.fromRGBO(244, 135, 6, 1),
//         foregroundColor: AppColors.whitecolor,
//       ),
//     );
//   }
// }



import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/constant/app_colors.dart';
import 'package:innovator/Innovator/hive/feed_cache_service.dart';
import 'package:innovator/Innovator/provider/global_chat_listener.dart';
import 'package:innovator/Innovator/provider/notification_provider.dart';
import 'package:innovator/Innovator/screens/Likes/hive_reaction_queue.dart';
import 'package:innovator/Innovator/screens/Splash_Screen/splash_screen.dart';
import 'package:innovator/Innovator/services/fcm_services.dart';
import 'package:innovator/Innovator/services/notification_navigation_service.dart'; // ← NEW
import 'package:innovator/KMS/screens/auth/login_screen.dart';
import 'package:innovator/KMS/screens/dashboard/admin_dashboard_screen.dart';
import 'package:innovator/KMS/screens/dashboard/teacher_dashboard_screen.dart';
import 'package:innovator/KMS/screens/student/student_attendance_screen.dart';
import 'package:innovator/ecommerce/provider/notificationProvider.dart';
import 'dart:developer' as developer;
import 'package:innovator/ecommerce/screens/Shop/Shop_Page.dart';
import 'package:innovator/elearning/provider/notificationProvider.dart';

late Size mq;
GlobalKey<NavigatorState> get navigatorKey => Get.key;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  developer.log('Background notification: ${message.notification?.title}');
}

void main() async {
  runZonedGuarded(
    () async {
      try {
        developer.log('App starting...');
        WidgetsFlutterBinding.ensureInitialized();
        await Hive.initFlutter();
        await HiveReactionQueue.instance.init();
        await FeedCacheService.instance.init();
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
        );

        await Firebase.initializeApp();
        FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler,
        );
        developer.log(' Starting UI...');
        runApp(ProviderScope(child: InnovatorHomePage()));
        developer.log('App started successfully');
      } catch (e, stackTrace) {
        developer.log('Critical error in main: $e\n$stackTrace');
        runApp(const ProviderScope(child: InnovatorHomePage()));
      }
    },
    (error, stackTrace) {
      developer.log('Uncaught error: $error\n$stackTrace');
    },
  );
}

class InnovatorHomePage extends ConsumerStatefulWidget {
  const InnovatorHomePage({super.key});

  @override
  ConsumerState<InnovatorHomePage> createState() => _InnovatorHomePageState();
}

class _InnovatorHomePageState extends ConsumerState<InnovatorHomePage>
    with WidgetsBindingObserver {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _localNotificationsInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    developer.log('InnovatorHomePage initialized');
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _setupFCM();
      ref.read(notificationProvider.notifier).startPolling();
      final fcmToken = await FirebaseMessaging.instance.getToken();
      ref
          .read(elearningNotificationServiceProvider)
          .registerFcmToken(fcmToken ?? '');
      ref
          .read(ecommerceNotificationServiceProvider)
          .registerFcmToken(fcmToken ?? '');
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(globalChatListenerProvider);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _setupFCM() async {
    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        // FIX: Foreground notification tap now properly navigates
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          developer.log('Local notification tapped: ${details.payload}');
          if (details.payload != null) {
            try {
              final data =
                  jsonDecode(details.payload!) as Map<String, dynamic>;
              // Use a small delay so the navigator is ready
              Future.delayed(
                const Duration(milliseconds: 300),
                () => NotificationNavigationService.handlePayload(data),
              );
            } catch (e) {
              developer.log('Payload parse error: $e');
            }
          }
        },
      );

      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      _localNotificationsInitialized = true;
      developer.log('Local notifications initialized');

      NotificationSettings settings = await FirebaseMessaging.instance
          .requestPermission(alert: true, badge: true, sound: true);
      developer.log('FCM permission: ${settings.authorizationStatus}');
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        developer.log('User denied notification permission');
        return;
      }
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: true,
            badge: true,
            sound: true,
          );

      final accessToken = AppData().accessToken;
      if (accessToken != null && accessToken.isNotEmpty) {
        final fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await Future.wait([
            FCMService().registerToken(),
            ref
                .read(elearningNotificationServiceProvider)
                .registerFcmToken(fcmToken),
            ref
                .read(ecommerceNotificationServiceProvider)
                .registerFcmToken(fcmToken),
          ]);
        }
      } else {
        developer.log('FCM: Skipping — user not logged in');
      }

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
        developer.log('FCM Token refreshed: $newToken');
        await Future.wait([
          FCMService().registerToken(),
          ref
              .read(elearningNotificationServiceProvider)
              .registerFcmToken(newToken),
          ref
              .read(ecommerceNotificationServiceProvider)
              .registerFcmToken(newToken),
        ]);
      });

      // FIX: Foreground FCM messages now show with full payload
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showForegroundNotification(message);
      });

      // FIX: Background tap (app was in background) now navigates
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        developer.log('Notification tapped from background');
        _handleNotificationTap(message);
      });

      // FIX: Killed-state tap (app was terminated) now navigates
      RemoteMessage? initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        developer.log('App opened from killed state via notification');
        // Longer delay for killed state — navigator needs more time to mount
        await Future.delayed(const Duration(milliseconds: 1000));
        _handleNotificationTap(initialMessage);
      }

      developer.log('FCM setup completed');
    } catch (e) {
      developer.log('FCM setup error: $e');
    }
  }

  void _showForegroundNotification(RemoteMessage message) {
    try {
      if (!_localNotificationsInitialized) {
        developer.log('Local notifications not initialized yet');
        return;
      }
      final title =
          message.notification?.title ??
          message.data['title']?.toString() ??
          message.data['senderName']?.toString() ??
          'New Notification';
      final body =
          message.notification?.body ??
          message.data['body']?.toString() ??
          message.data['message']?.toString() ??
          '';

      developer.log('Showing local notification — title: $title, body: $body');

      // Build the payload from ALL data fields so navigation works
      final payload = Map<String, dynamic>.from(message.data);

      final androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'High Importance Notifications',
        channelDescription:
            'This channel is used for important notifications',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        icon: '@mipmap/ic_launcher',
        fullScreenIntent: false,
        ticker: title,
      );
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        NotificationDetails(android: androidDetails, iOS: iosDetails),
        // FIX: pass the full data map so tapping can navigate
        payload: jsonEncode(payload),
      );
      developer.log('Local notification shown');
    } catch (e) {
      developer.log('Show foreground notification error: $e');
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    _handleNotificationData(message.data);
  }

  /// FIX: was completely empty — now delegates to NotificationNavigationService
  void _handleNotificationData(Map<String, dynamic> data) {
    try {
      developer.log('_handleNotificationData: $data');
      NotificationNavigationService.handlePayload(data);
    } catch (e) {
      developer.log('Handle notification data error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    mq = MediaQuery.of(context).size;

    return GetMaterialApp(
      navigatorKey: navigatorKey,
      home: SplashScreen(),
      routes: {
        '/kms/login': (_) => KmsLoginScreen(),
        '/kms/adminDasboard': (_) => AdminDashboardScreen(),
        '/kms/partnerDashboard': (_) => TeacherDashboardScreen(),
        '/kms/studentDashboard': (_) => StudentAttendanceScreen(),
      },
      title: 'Innovator',
      theme: _buildAppTheme(),
      debugShowCheckedModeBanner: false,
      getPages: [GetPage(name: '/shop', page: () => const ShopPage())],
    );
  }

  ThemeData _buildAppTheme() {
    return ThemeData(
      fontFamily: 'InterThin',
      primarySwatch: Colors.orange,
      primaryColor: const Color.fromRGBO(244, 135, 6, 1),
      appBarTheme: const AppBarTheme(
        elevation: 1,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.whitecolor,
          fontWeight: FontWeight.bold,
          fontSize: 19,
        ),
        backgroundColor: Color.fromRGBO(244, 135, 6, 1),
        iconTheme: IconThemeData(color: AppColors.whitecolor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
          foregroundColor: AppColors.whitecolor,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color.fromRGBO(244, 135, 6, 1),
        foregroundColor: AppColors.whitecolor,
      ),
    );
  }
}