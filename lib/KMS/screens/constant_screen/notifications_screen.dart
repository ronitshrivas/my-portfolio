import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/Innovator/widget/Custom_refresh_Indicator.dart';
import 'package:innovator/KMS/model/notification_model.dart';
import 'package:innovator/KMS/provider/notificationProvider.dart'; 

class KMSNotificationScreen extends ConsumerStatefulWidget {
  const KMSNotificationScreen({super.key});

  @override
  ConsumerState<KMSNotificationScreen> createState() =>
      _KMSNotificationScreenState();
}

class _KMSNotificationScreenState
    extends ConsumerState<KMSNotificationScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(kmsNotificationListProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kmsNotificationListProvider);
    final notifications = state.notifications;

    return Material(
      child: CustomRefreshIndicator(
        onRefresh:
            () =>
                ref.read(kmsNotificationListProvider.notifier).refresh(),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.white,
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
                    ref.read(kmsMarkAllAsReadProvider)();
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
  final List<KMSNotificationModel> notifications;

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
  final KMSNotificationModel notification;

  @override
  ConsumerState<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends ConsumerState<_NotificationTile> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      tileColor:
          widget.notification.isRead ? null : colorScheme.primary.withAlpha(13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              _iconForType(widget.notification.data.type),
              color: colorScheme.primary,
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
              widget.notification.isRead ? FontWeight.normal : FontWeight.w600,
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
      onTap: () {
        ref.read(kmsMarkAsReadProvider(widget.notification.id));
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder:
        //         (_) => ProductDetailPage(productId: widget.notification.data.productId),
        //   ),
        // );
      },
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
