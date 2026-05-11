// import 'dart:async';
// import 'dart:developer' as developer;
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:innovator/KMS/api_calling_services.dart/notification_service.dart';
// import 'package:innovator/KMS/model/notification_model.dart';

// final kmsNotificationServiceProvider =
//     Provider<KMSNotificationService>(
//       (ref) => KMSNotificationService(),
//     );

// class KMSNotificationState {
//   final List<KMSNotificationModel> notifications;
//   const KMSNotificationState({required this.notifications});

//   KMSNotificationState copyWith({
//     List<KMSNotificationModel>? notifications,
//   }) {
//     return KMSNotificationState(
//       notifications: notifications ?? this.notifications,
//     );
//   }
// }

// class KMSNotificationNotifier
//     extends StateNotifier<KMSNotificationState> {
//   final KMSNotificationService service;
//   Timer? _timer;

//   static final Set<String> _seenIds = {};
//   static final List<String> _kmsMessages = [];

//   KMSNotificationNotifier(this.service)
//     : super(const KMSNotificationState(notifications: []));

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

//   void _showSystemNotification(KMSNotificationModel n) {
//     const groupKey = 'kms_group';

//     _kmsMessages.add(n.message);

//     final inboxStyle = InboxStyleInformation(
//       _kmsMessages,
//       contentTitle: 'KMS Notifications',
//       summaryText:
//           '${_kmsMessages.length} notification${_kmsMessages.length > 1 ? 's' : ''}',
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
//         _kmsMessages,
//         summaryText:
//             '${_kmsMessages.length} notification${_kmsMessages.length > 1 ? 's' : ''}',
//       ),
//     );

//     _plugin.show(
//       0,
//       'KMS Notifications',
//       '${_kmsMessages.length} new notification${_kmsMessages.length > 1 ? 's' : ''}',
//       NotificationDetails(android: summaryDetails),
//     );

//     developer.log(
//       'Notification shown: ${n.title} | type: ${n.notificationType} | classroom: ${n.data.classroomId}| school: ${n.data.schoolId}  ',
//     );
//   }
// }

// final kmsNotificationListProvider = StateNotifierProvider<
//   KMSNotificationNotifier,
//   KMSNotificationState
// >((ref) {
//   final service = ref.watch(kmsNotificationServiceProvider);
//   final notifier = KMSNotificationNotifier(service);
//   notifier.init();
//   return notifier;
// });

// final kmsUnreadCountProvider = Provider<int>((ref) {
//   final state = ref.watch(kmsNotificationListProvider);
//   return state.notifications.where((n) => !n.isRead).length;
// });

// final kmsMarkAsReadProvider = Provider.family((
//   ref,
//   String notificationId,
// ) async {
//   await ref
//       .read(kmsNotificationServiceProvider)
//       .markAsRead(notificationId);
//   await ref.read(kmsNotificationListProvider.notifier).refresh();
// });

// final kmsMarkAllAsReadProvider = Provider((ref) {
//   final service = ref.watch(kmsNotificationServiceProvider);
//   return () async {
//     await service.markAllAsRead();
//     await ref.read(kmsNotificationListProvider.notifier).refresh();
//   };
// });

import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/api_calling_services.dart/notification_service.dart';
import 'package:innovator/KMS/model/notification_model.dart';

// ─── Service Provider ──────────────────────────────────────────────────────

final kmsNotificationServiceProvider = Provider<KMSNotificationService>(
  (ref) => KMSNotificationService(),
);

// ─── State ─────────────────────────────────────────────────────────────────

class KMSNotificationState {
  final List<KMSNotificationModel> notifications;

  const KMSNotificationState({required this.notifications});

  KMSNotificationState copyWith({List<KMSNotificationModel>? notifications}) {
    return KMSNotificationState(
      notifications: notifications ?? this.notifications,
    );
  }
}

// ─── Notifier ──────────────────────────────────────────────────────────────

class KMSNotificationNotifier extends StateNotifier<KMSNotificationState> {
  final KMSNotificationService service;

  Timer? _timer;

  static final Set<String> _seenIds = {};
  static final List<String> _kmsMessages = [];

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  KMSNotificationNotifier(this.service)
    : super(const KMSNotificationState(notifications: []));

  // ── Init ────────────────────────────────────────────────────────────────

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

    // await _plugin
    //     .resolvePlatformSpecificImplementation;
    //         AndroidFlutterLocalNotificationsPlugin>()
    //     ?.createNotificationChannel(androidChannel);

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    await refresh();
    _startPolling();
  }

  // ── Polling ─────────────────────────────────────────────────────────────

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── Refresh ─────────────────────────────────────────────────────────────

  Future<void> refresh() async {
    try {
      final List<KMSNotificationModel> newList =
          await service.getNotifications();

      final DateTime cutoff = DateTime.now().subtract(
        const Duration(minutes: 5),
      );

      final Iterable<KMSNotificationModel> newItems = newList.where(
        (KMSNotificationModel n) =>
            !_seenIds.contains(n.id) &&
            !n.isRead &&
            n.createdAt.isAfter(cutoff),
      );

      for (final KMSNotificationModel n in newItems) {
        _seenIds.add(n.id);
        _showSystemNotification(n);
      }

      if (_seenIds.length > 200) {
        final int overflow = _seenIds.length - 200;
        _seenIds.removeAll(_seenIds.take(overflow).toList());
      }

      state = state.copyWith(notifications: newList);
    } catch (e, st) {
      developer.log('Notification refresh error: $e', stackTrace: st);
    }
  }

  // ── Show Notification ────────────────────────────────────────────────────

  void _showSystemNotification(KMSNotificationModel n) {
    const String groupKey = 'kms_group';

    _kmsMessages.add(n.message);

    final int count = _kmsMessages.length;
    final String suffix = count > 1 ? 's' : '';

    final InboxStyleInformation inboxStyle = InboxStyleInformation(
      List<String>.from(_kmsMessages),
      contentTitle: 'KMS Notifications',
      summaryText: '$count notification$suffix',
    );

    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
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
    );

    final AndroidNotificationDetails summaryDetails =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          importance: Importance.max,
          priority: Priority.max,
          groupKey: groupKey,
          setAsGroupSummary: true,
          styleInformation: InboxStyleInformation(
            List<String>.from(_kmsMessages),
            summaryText: '$count notification$suffix',
          ),
        );

    _plugin.show(
      0,
      'KMS Notifications',
      '$count new notification$suffix',
      NotificationDetails(android: summaryDetails),
    );

    // ── Role-aware log ─────────────────────────────────────────────────────
    final String dataLog = switch (n.data) {
      TeacherNotificationData(
        :final String schoolId,
        :final String classroomId,
      ) =>
        'school: $schoolId | classroom: $classroomId',
      CoordinatorNotificationData(
        :final String teacherId,
        :final String attendanceId,
      ) =>
        'teacher: $teacherId | attendance: $attendanceId',
      StudentNotificationData(:final String attendanceId) =>
        'attendance: $attendanceId',
    };

    developer.log(
      'Notification shown: ${n.title} | type: ${n.notificationType} | $dataLog',
    );
  }
}

// ─── Providers ─────────────────────────────────────────────────────────────

final StateNotifierProvider<KMSNotificationNotifier, KMSNotificationState>
kmsNotificationListProvider =
    StateNotifierProvider<KMSNotificationNotifier, KMSNotificationState>((
      Ref ref,
    ) {
      final KMSNotificationService service = ref.watch(
        kmsNotificationServiceProvider,
      );
      final KMSNotificationNotifier notifier = KMSNotificationNotifier(service);
      notifier.init();
      return notifier;
    });

final Provider<int> kmsUnreadCountProvider = Provider<int>((Ref ref) {
  final KMSNotificationState state = ref.watch(kmsNotificationListProvider);
  return state.notifications
      .where((KMSNotificationModel n) => !n.isRead)
      .length;
});

final Provider<Future<void> Function()> kmsMarkAllAsReadProvider =
    Provider<Future<void> Function()>((Ref ref) {
      final KMSNotificationService service = ref.watch(
        kmsNotificationServiceProvider,
      );
      return () async {
        await service.markAllAsRead();
        await ref.read(kmsNotificationListProvider.notifier).refresh();
      };
    });

final ProviderFamily<Future<void>, String> kmsMarkAsReadProvider =
    Provider.family<Future<void>, String>((
      Ref ref,
      String notificationId,
    ) async {
      await ref.read(kmsNotificationServiceProvider).markAsRead(notificationId);
      await ref.read(kmsNotificationListProvider.notifier).refresh();
    });
