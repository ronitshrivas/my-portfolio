// import 'dart:async';
// import 'dart:developer' as developer;
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:innovator/ecommerce/api_calling_service/notification_service.dart';
// import 'package:innovator/ecommerce/model/notification_model.dart';

// final ecommerceNotificationServiceProvider =
//     Provider<EcommerceNotificationService>(
//       (ref) => EcommerceNotificationService(),
//     );

// class EcommerceNotificationState {
//   final List<EcommerceNotificationModel> notifications;
//   const EcommerceNotificationState({required this.notifications});

//   EcommerceNotificationState copyWith({
//     List<EcommerceNotificationModel>? notifications,
//   }) {
//     return EcommerceNotificationState(
//       notifications: notifications ?? this.notifications,
//     );
//   }
// }

// class EcommerceNotificcationNotifier
//     extends StateNotifier<EcommerceNotificationState> {
//   final EcommerceNotificationService service;
//   Timer? _timer;

//   static final Set<String> _seenIds = {};
//   static final List<String> _ecommerceMessages = [];

//   EcommerceNotificcationNotifier(this.service)
//     : super(const EcommerceNotificationState(notifications: []));

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

//   void _showSystemNotification(EcommerceNotificationModel n) {
//     const groupKey = 'product_group';

//     _ecommerceMessages.add(n.message);

//     final inboxStyle = InboxStyleInformation(
//       _ecommerceMessages,
//       contentTitle: 'Product Notifications',
//       summaryText:
//           '${_ecommerceMessages.length} notification${_ecommerceMessages.length > 1 ? 's' : ''}',
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
//         _ecommerceMessages,
//         summaryText:
//             '${_ecommerceMessages.length} notification${_ecommerceMessages.length > 1 ? 's' : ''}',
//       ),
//     );

//     _plugin.show(
//       0,
//       'Product Notifications',
//       '${_ecommerceMessages.length} new notification${_ecommerceMessages.length > 1 ? 's' : ''}',
//       NotificationDetails(android: summaryDetails),
//     );

//     developer.log(
//       'Notification shown: ${n.title} | type: ${n.notificationType} | product: ${n.data.productId}| category: ${n.data.categroy}  ',
//     );
//   }
// }

// final ecommerceNotificationListProvider = StateNotifierProvider<
//   EcommerceNotificcationNotifier,
//   EcommerceNotificationState
// >((ref) {
//   final service = ref.watch(ecommerceNotificationServiceProvider);
//   final notifier = EcommerceNotificcationNotifier(service);
//   notifier.init();
//   return notifier;
// });

// final ecommerceUnreadCountProvider = Provider<int>((ref) {
//   final state = ref.watch(ecommerceNotificationListProvider);
//   return state.notifications.where((n) => !n.isRead).length;
// });

// final ecommerceMarkAsReadProvider = Provider.family((
//   ref,
//   String notificationId,
// ) async {
//   await ref
//       .read(ecommerceNotificationServiceProvider)
//       .markAsRead(notificationId);
//   await ref.read(ecommerceNotificationListProvider.notifier).refresh();
// });

// final ecommerceMarkAllAsReadProvider = Provider((ref) {
//   final service = ref.watch(ecommerceNotificationServiceProvider);
//   return () async {
//     await service.markAllAsRead();
//     await ref.read(ecommerceNotificationListProvider.notifier).refresh();
//   };
// });



// lib/ecommerce/provider/notificationProvider.dart
import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/ecommerce/api_calling_service/notification_service.dart';
import 'package:innovator/ecommerce/model/notification_model.dart';

final ecommerceNotificationServiceProvider =
    Provider<EcommerceNotificationService>(
      (ref) => EcommerceNotificationService(),
    );

class EcommerceNotificationState {
  final List<EcommerceNotificationModel> notifications;
  const EcommerceNotificationState({required this.notifications});

  EcommerceNotificationState copyWith({
    List<EcommerceNotificationModel>? notifications,
  }) {
    return EcommerceNotificationState(
      notifications: notifications ?? this.notifications,
    );
  }
}

class EcommerceNotificcationNotifier
    extends StateNotifier<EcommerceNotificationState> {
  final EcommerceNotificationService service;
  Timer? _timer;

  static final Set<String> _seenIds = {};
  static final List<String> _ecommerceMessages = [];

  EcommerceNotificcationNotifier(this.service)
    : super(const EcommerceNotificationState(notifications: []));

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

  void _showSystemNotification(EcommerceNotificationModel n) {
    const groupKey = 'product_group';

    _ecommerceMessages.add(n.message);

    final inboxStyle = InboxStyleInformation(
      _ecommerceMessages,
      contentTitle: 'Product Notifications',
      summaryText:
          '${_ecommerceMessages.length} notification${_ecommerceMessages.length > 1 ? 's' : ''}',
    );

    // FIX: Include payload with productId so tapping navigates to ProductDetailPage
    final payload = jsonEncode({
      'type': 'ecommerce',
      'productId': n.data.productId,
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
        _ecommerceMessages,
        summaryText:
            '${_ecommerceMessages.length} notification${_ecommerceMessages.length > 1 ? 's' : ''}',
      ),
    );

    _plugin.show(
      0,
      'Product Notifications',
      '${_ecommerceMessages.length} new notification${_ecommerceMessages.length > 1 ? 's' : ''}',
      NotificationDetails(android: summaryDetails),
    );

    developer.log(
      'Notification shown: ${n.title} | type: ${n.notificationType} | product: ${n.data.productId} | category: ${n.data.categroy}',
    );
  }
}

final ecommerceNotificationListProvider = StateNotifierProvider<
  EcommerceNotificcationNotifier,
  EcommerceNotificationState
>((ref) {
  final service = ref.watch(ecommerceNotificationServiceProvider);
  final notifier = EcommerceNotificcationNotifier(service);
  notifier.init();
  return notifier;
});

final ecommerceUnreadCountProvider = Provider<int>((ref) {
  final state = ref.watch(ecommerceNotificationListProvider);
  return state.notifications.where((n) => !n.isRead).length;
});

final ecommerceMarkAsReadProvider = Provider.family((
  ref,
  String notificationId,
) async {
  await ref
      .read(ecommerceNotificationServiceProvider)
      .markAsRead(notificationId);
  await ref.read(ecommerceNotificationListProvider.notifier).refresh();
});

final ecommerceMarkAllAsReadProvider = Provider((ref) {
  final service = ref.watch(ecommerceNotificationServiceProvider);
  return () async {
    await service.markAllAsRead();
    await ref.read(ecommerceNotificationListProvider.notifier).refresh();
  };
});