// import 'dart:async';
// import 'dart:developer' as developer;

// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:innovator/elearning/api_calling_service/notification_service.dart';
// import 'package:innovator/elearning/model/notification_model.dart';

// final elearningNotificationServiceProvider = Provider<ElearningNotificationService>(
//   (ref) => ElearningNotificationService(),
// );

// class ElearningNotificationState {
//   final List<ElearningNotificationModel> notifications;
//   const ElearningNotificationState({required this.notifications});

//   ElearningNotificationState copyWith({List<ElearningNotificationModel>? notifications}) {
//     return ElearningNotificationState(
//       notifications: notifications ?? this.notifications,
//     );
//   }
// }

// class ElearningNotificationNotifier extends StateNotifier<ElearningNotificationState> {
//   final ElearningNotificationService service;
//   Timer? _timer;

//   static final Set<String> _seenIds = {};
//   static final List<String> _enrollmentMessages = [];

//   ElearningNotificationNotifier(this.service)
//     : super(const ElearningNotificationState(notifications: []));

//   final _plugin = FlutterLocalNotificationsPlugin();

//   Future<void> init() async {
//     const androidSettings = AndroidInitializationSettings(
//       '@mipmap/ic_launcher',
//     );
//     const initSettings = InitializationSettings(android: androidSettings);
//     await _plugin.initialize(initSettings);

//     const androidChannel = AndroidNotificationChannel(
//       'high_importance_channel',
//       'High Importance Notifications',
//       importance: Importance.max,
//     );
//     await _plugin
//         .resolvePlatformSpecificImplementation<
//           AndroidFlutterLocalNotificationsPlugin
//         >()
//         ?.createNotificationChannel(androidChannel);

//     await refresh();
//     _startPolling();
//   }

//   void _startPolling() {
//     _timer?.cancel();
//     _timer = Timer.periodic(const Duration(seconds: 15), (_) => refresh());
//   }

//   @override
//   void dispose() {
//     _timer?.cancel();
//     super.dispose();
//   }

//   Future<void> refresh() async {
//     try {
//       final newList = await service.getNotifications();

//       final cutoff = DateTime.now().subtract(const Duration(minutes: 5));

//       final newItems = newList.where(
//         (n) =>
//             !_seenIds.contains(n.id) &&
//             !n.isRead &&
//             n.createdAt.isAfter(cutoff),
//       );

//       for (final n in newItems) {
//         _seenIds.add(n.id);
//         _showSystemNotification(n);
//       }

//       if (_seenIds.length > 200) {
//         final overflow = _seenIds.length - 200;
//         _seenIds.removeAll(_seenIds.take(overflow).toList());
//       }

//       state = state.copyWith(notifications: newList);
//     } catch (e) {
//       developer.log('Notification refresh error: $e');
//     }
//   }

//   void _showSystemNotification(ElearningNotificationModel n) {
//     const groupKey = 'course_enrollment_group';

//     _enrollmentMessages.add(n.message);

//     final inboxStyle = InboxStyleInformation(
//       _enrollmentMessages,
//       contentTitle: 'Course Enrollments',
//       summaryText:
//           '${_enrollmentMessages.length} enrollment${_enrollmentMessages.length > 1 ? 's' : ''}',
//     );

//     final androidDetails = AndroidNotificationDetails(
//       'high_importance_channel',
//       'High Importance Notifications',
//       importance: Importance.max,
//       priority: Priority.max,
//       styleInformation: inboxStyle,
//       groupKey: groupKey,
//       setAsGroupSummary: false,
//       largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
//       icon: '@mipmap/ic_launcher',
//     );

//     _plugin.show(
//       groupKey.hashCode,
//       n.title,
//       n.message,
//       NotificationDetails(android: androidDetails),
//     );
//     final summaryDetails = AndroidNotificationDetails(
//       'high_importance_channel',
//       'High Importance Notifications',
//       importance: Importance.max,
//       priority: Priority.max,
//       groupKey: groupKey,
//       setAsGroupSummary: true,
//       styleInformation: InboxStyleInformation(
//         _enrollmentMessages,
//         summaryText:
//             '${_enrollmentMessages.length} enrollment${_enrollmentMessages.length > 1 ? 's' : ''}',
//       ),
//     );

//     _plugin.show(
//       0,
//       'Course Enrollments',
//       '${_enrollmentMessages.length} new enrollment${_enrollmentMessages.length > 1 ? 's' : ''}',
//       NotificationDetails(android: summaryDetails),
//     );

//     developer.log(
//       'Notification shown: ${n.title} | type: ${n.notificationType} | course: ${n.data.courseId}',
//     );
//   }
// }

// final elearningNotificationListProvider =
//     StateNotifierProvider<ElearningNotificationNotifier, ElearningNotificationState>((ref) {
//       final service = ref.watch(elearningNotificationServiceProvider);
//       final notifier = ElearningNotificationNotifier(service);
//       notifier.init();
//       return notifier;
//     });

// final elearningUnreadCountProvider = Provider<int>((ref) {
//   final state = ref.watch(elearningNotificationListProvider);
//   return state.notifications.where((n) => !n.isRead).length;
// });

// final elearningMarkAsReadProvider = Provider.family((ref, String notificationId) async {
//   await ref.read(elearningNotificationServiceProvider).markAsRead(notificationId);
//   await ref.read(elearningNotificationListProvider.notifier).refresh();
// });

// final elearningMarkAllAsReadProvider = Provider((ref) {
//   final service = ref.watch(elearningNotificationServiceProvider);
//   return () async {
//     await service.markAllAsRead();
//     await ref.read(elearningNotificationListProvider.notifier).refresh();
//   };
// });



// lib/elearning/provider/notificationProvider.dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/elearning/api_calling_service/notification_service.dart';
import 'package:innovator/elearning/model/notification_model.dart';

final elearningNotificationServiceProvider =
    Provider<ElearningNotificationService>(
      (ref) => ElearningNotificationService(),
    );

class ElearningNotificationState {
  final List<ElearningNotificationModel> notifications;
  const ElearningNotificationState({required this.notifications});

  ElearningNotificationState copyWith({
    List<ElearningNotificationModel>? notifications,
  }) {
    return ElearningNotificationState(
      notifications: notifications ?? this.notifications,
    );
  }
}

class ElearningNotificationNotifier
    extends StateNotifier<ElearningNotificationState> {
  final ElearningNotificationService service;
  Timer? _timer;

  static final Set<String> _seenIds = {};
  static final List<String> _enrollmentMessages = [];

  ElearningNotificationNotifier(this.service)
    : super(const ElearningNotificationState(notifications: []));

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    const androidChannel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    await refresh();
    _startPolling();
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    try {
      final newList = await service.getNotifications();

      final cutoff = DateTime.now().subtract(const Duration(minutes: 5));

      final newItems = newList.where(
        (n) =>
            !_seenIds.contains(n.id) &&
            !n.isRead &&
            n.createdAt.isAfter(cutoff),
      );

      for (final n in newItems) {
        _seenIds.add(n.id);
        _showSystemNotification(n);
      }

      if (_seenIds.length > 200) {
        final overflow = _seenIds.length - 200;
        _seenIds.removeAll(_seenIds.take(overflow).toList());
      }

      state = state.copyWith(notifications: newList);
    } catch (e) {
      developer.log('Notification refresh error: $e');
    }
  }

  void _showSystemNotification(ElearningNotificationModel n) {
    const groupKey = 'course_enrollment_group';

    _enrollmentMessages.add(n.message);

    final inboxStyle = InboxStyleInformation(
      _enrollmentMessages,
      contentTitle: 'Course Enrollments',
      summaryText:
          '${_enrollmentMessages.length} enrollment${_enrollmentMessages.length > 1 ? 's' : ''}',
    );

    // FIX: Include payload with courseId so tapping navigates to CourseDetailScreen
    final payload = jsonEncode({
      'type': 'elearning',
      'courseId': n.data.courseId,
      'id': n.id,
    });

    final androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.max,
      styleInformation: inboxStyle,
      groupKey: groupKey,
      setAsGroupSummary: false,
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      icon: '@mipmap/ic_launcher',
    );

    _plugin.show(
      groupKey.hashCode,
      n.title,
      n.message,
      NotificationDetails(android: androidDetails),
      payload: payload, // ← FIX: was missing
    );

    final summaryDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.max,
      groupKey: groupKey,
      setAsGroupSummary: true,
      styleInformation: InboxStyleInformation(
        _enrollmentMessages,
        summaryText:
            '${_enrollmentMessages.length} enrollment${_enrollmentMessages.length > 1 ? 's' : ''}',
      ),
    );

    _plugin.show(
      0,
      'Course Enrollments',
      '${_enrollmentMessages.length} new enrollment${_enrollmentMessages.length > 1 ? 's' : ''}',
      NotificationDetails(android: summaryDetails),
    );

    developer.log(
      'Notification shown: ${n.title} | type: ${n.notificationType} | course: ${n.data.courseId}',
    );
  }
}

final elearningNotificationListProvider = StateNotifierProvider<
  ElearningNotificationNotifier,
  ElearningNotificationState
>((ref) {
  final service = ref.watch(elearningNotificationServiceProvider);
  final notifier = ElearningNotificationNotifier(service);
  notifier.init();
  return notifier;
});

final elearningUnreadCountProvider = Provider<int>((ref) {
  final state = ref.watch(elearningNotificationListProvider);
  return state.notifications.where((n) => !n.isRead).length;
});

final elearningMarkAsReadProvider = Provider.family((
  ref,
  String notificationId,
) async {
  await ref
      .read(elearningNotificationServiceProvider)
      .markAsRead(notificationId);
  await ref.read(elearningNotificationListProvider.notifier).refresh();
});

final elearningMarkAllAsReadProvider = Provider((ref) {
  final service = ref.watch(elearningNotificationServiceProvider);
  return () async {
    await service.markAllAsRead();
    await ref.read(elearningNotificationListProvider.notifier).refresh();
  };
});