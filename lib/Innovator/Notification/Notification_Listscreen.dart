import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/Innovator/provider/notifcation_list_screen_provider.dart';
import 'package:innovator/Innovator/ui/ui.dart';
import 'package:innovator/Innovator/screens/chatrrom/screen/chatscreen.dart';
import 'package:innovator/ecommerce/screens/Shop/Shop_Page.dart';
import 'package:innovator/innovator_home.dart';
import 'package:innovator/Innovator/screens/show_Specific_Profile/Show_Specific_Profile.dart';
import 'package:innovator/main.dart';
import 'package:intl/intl.dart';
import 'package:innovator/Innovator/screens/Feed/post_detail_screen.dart';

class NotificationListScreen extends ConsumerStatefulWidget {
  const NotificationListScreen({super.key});

  @override
  ConsumerState<NotificationListScreen> createState() =>
      _NotificationListScreenState();
}

class _NotificationListScreenState extends ConsumerState<NotificationListScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  String _selectedFilter = 'all';

  late AnimationController _headerAnimationController;
  late Animation<Offset> _headerSlideAnimation;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOutBack,
      ),
    );
    _headerAnimationController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    final state = ref.read(notificationProvider);
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        state.hasMore &&
        !state.isLoadingMore) {
      ref.read(notificationProvider.notifier).fetchMoreNotifications();
    }
  }

  void _navigateToNotificationDetails(NotificationModel notification) {
    if (!notification.isRead) {
      ref.read(notificationProvider.notifier).markAsRead(notification.id);
    }

    final type = notification.type.toLowerCase();
    final title = (notification.title ?? '').toLowerCase();
    final message = notification.message.toLowerCase();
    final isReelRelated =
        message.contains('your reel') || title.contains('reel');

    switch (type) {
      case 'system':
        if (notification.relatedPostId != null) {
          _navigateToSpecificFeedPost(
            notification.relatedPostId!,
            action: isReelRelated ? 'reel' : 'post',
          );
        } else if (notification.senderId != null) {
          _navigateToProfile(notification.senderId!);
        }
        break;

      case 'like':
        if (notification.relatedPostId != null) {
          _navigateToSpecificFeedPost(
            notification.relatedPostId!,
            action: 'like',
          );
        } else if (notification.senderId != null) {
          _navigateToProfile(notification.senderId!);
        }
        break;

      case 'comment':
      case 'comment_reply':
        if (notification.relatedPostId != null) {
          _navigateToSpecificFeedPost(
            notification.relatedPostId!,
            action: 'comment',
          );
        } else if (notification.senderId != null) {
          _navigateToProfile(notification.senderId!);
        }
        break;

      case 'repost':
        if (notification.relatedPostId != null) {
          _navigateToSpecificFeedPost(
            notification.relatedPostId!,
            action: 'share',
          );
        } else if (notification.senderId != null) {
          _navigateToProfile(notification.senderId!);
        }
        break;

      case 'message':
      case 'chat_message':
      case 'new_message':
        _navigateToChat(notification);
        break;

      case 'follow':
      case 'friend_request':
        if (notification.senderId != null) {
          _navigateToProfile(notification.senderId!);
        }
        break;

      case 'shop':
        Navigator.push(context, MaterialPageRoute(builder: (_) => ShopPage()));
        break;

      default:
        debugPrint('⚠️ Unhandled notification type: ${notification.type}');
        break;
    }
  }

  void _navigateToSpecificFeedPost(String contentId, {String? action}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => NewFeedPostDetailScreen(
              postId: contentId,
              highlightAction: action,
            ),
      ),
    );
  }

  void _navigateToChat(NotificationModel notification) {
    if (notification.senderId == null || notification.senderId!.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ChatScreen(
              otherUserId: notification.senderId!,
              otherUserName: notification.senderUsername ?? 'Unknown',
              otherUserAvatar: notification.senderAvatar ?? '',
              isOnline: false,
            ),
      ),
    );
  }

  void _navigateToProfile(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SpecificUserProfilePage(userId: userId),
      ),
    );
  }

  List<NotificationModel> _filterNotifications(List<NotificationModel> all) {
    switch (_selectedFilter) {
      case 'unread':
        return all.where((n) => !n.isRead).toList();
      case 'messages':
        return all
            .where(
              (n) => [
                'message',
                'chat_message',
                'new_message',
              ].contains(n.type.toLowerCase()),
            )
            .toList();
      case 'interactions':
        return all
            .where(
              (n) => [
                'like',
                'comment',
                'comment_reply',
                'share',
                'mention',
                'system',
                'repost',
              ].contains(n.type.toLowerCase()),
            )
            .toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch provider — rebuild whenever notifications change.
    final state = ref.watch(notificationProvider);
    final displayed = _filterNotifications(state.notifications);

    return Material(
      child: Scaffold(
        backgroundColor: BrandColors.canvas,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          centerTitle: true,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Notifications', style: TextStyle(color: Colors.black87)),
              if (state.unreadCount > 0) ...[
                _UnreadBadge(count: state.unreadCount),
              ],
            ],
          ),
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          ),
          actions: [
            PopupMenuButton<String>(
              iconColor: Colors.black87,
              color: Colors.white,
              itemBuilder:
                  (_) => [
                    const PopupMenuItem(
                      value: 'mark_all_read',
                      child: Text('Mark all as read'),
                    ),
                    const PopupMenuItem(
                      value: 'refresh',
                      child: Text('Refresh'),
                    ),
                  ],
              onSelected: (value) {
                switch (value) {
                  case 'mark_all_read':
                    _markAllAsRead(state);
                    break;
                  case 'refresh':
                    HapticFeedback.mediumImpact();
                    ref
                        .read(notificationProvider.notifier)
                        .fetchNotifications();
                    break;
                }
              },
            ),
          ],
        ),
        body: Column(
          children: [
            _buildFilterChips(),
            Expanded(
              child:
                  state.isLoading
                      ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            BrandColors.secondarySurface,
                          ),
                        ),
                      )
                      : displayed.isEmpty
                      ? _buildEmptyState()
                      : _buildNotificationList(displayed, state),
            ),
          ],
        ),
      ),
    );
  }

  void _markAllAsRead(NotificationState state) {
    final unreadCount = state.unreadCount;
    if (unreadCount == 0) {
      _showInfoSnackbar('No unread notifications to mark');
      return;
    }
    // Provider marks all read → badge drops to 0 instantly in FloatingMenu
    ref.read(notificationProvider.notifier).markAllAsRead();
    _showSuccessSnackbar('All notifications marked as read');
  }

  // ── Filter chips ──────────────────────────────────────────────────────────

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', 'all'),
            _buildFilterChip('Unread', 'unread'),
            _buildFilterChip('Messages', 'messages'),
            _buildFilterChip('Interactions', 'interactions'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilter = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? BrandColors.secondarySurface : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? BrandColors.secondarySurface : Colors.grey.shade300,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withAlpha(40),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationList(
    List<NotificationModel> displayed,
    NotificationState state,
  ) {
    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: displayed.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const Divider(height: 0, indent: 72),
      itemBuilder: (context, index) {
        if (index == displayed.length) {
          return _buildLoadMoreIndicator(state);
        }
        return _buildNotificationTile(displayed[index]);
      },
    );
  }

  Widget _buildNotificationTile(NotificationModel notification) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dismissible(
      key: Key(notification.id),
      background: _buildDismissBackground(
        Colors.blue,
        Icons.mark_email_read,
        'Mark as read',
        MainAxisAlignment.start,
      ),
      secondaryBackground: _buildDismissBackground(
        Colors.red,
        Icons.delete,
        'Delete',
        MainAxisAlignment.end,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          if (!notification.isRead) {
            // Provider call → badge updates in FloatingMenu immediately
            ref.read(notificationProvider.notifier).markAsRead(notification.id);
          }
          return false; // don't dismiss the tile
        } else {
          return await _showDeleteConfirmation();
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          ref
              .read(notificationProvider.notifier)
              .deleteNotification(notification.id);
        }
      },
      child: ListTile(
        tileColor:
            notification.isRead ? null : colorScheme.primary.withAlpha(13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: colorScheme.primaryContainer,
              backgroundImage:
                  (notification.senderAvatar != null &&
                          notification.senderAvatar!.isNotEmpty)
                      ? NetworkImage(notification.senderAvatar!)
                      : null,
              child:
                  (notification.senderAvatar == null ||
                          notification.senderAvatar!.isEmpty)
                      ? Icon(
                        _getNotificationIcon(notification.type),
                        color: colorScheme.primary,
                        size: 20,
                      )
                      : null,
            ),
            // Unread dot on avatar
            if (!notification.isRead)
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
          notification.title?.isNotEmpty == true
              ? notification.title!
              : _getNotificationTypeLabel(notification.type),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            if (notification.senderUsername?.isNotEmpty == true)
              Text(
                notification.senderUsername!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            Text(
              notification.message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _timeAgo(notification.createdAt),
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
        onTap: () {
          HapticFeedback.lightImpact();
          _navigateToNotificationDetails(notification);
        },
      ),
    );
  }

  Widget _buildDismissBackground(
    Color color,
    IconData icon,
    String label,
    MainAxisAlignment alignment,
  ) {
    return Container(
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: alignment,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
            _selectedFilter == 'all'
                ? 'No notifications yet'
                : 'No $_selectedFilter notifications',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            _selectedFilter == 'all'
                ? "When you get notifications, they'll show up here"
                : 'Try switching to a different filter',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreIndicator(NotificationState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child:
            state.isLoadingMore
                ? const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(BrandColors.secondarySurface),
                )
                : ElevatedButton(
                  onPressed:
                      () =>
                          ref
                              .read(notificationProvider.notifier)
                              .fetchMoreNotifications(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: BrandColors.secondarySurface,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text('Load more'),
                ),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Delete Notification'),
            content: const Text(
              'Are you sure you want to delete this notification?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  void _showSuccessSnackbar(String message) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  void _showInfoSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _timeAgo(String createdAt) {
    final date = DateTime.parse(createdAt).toLocal();
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(date);
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'message':
      case 'chat_message':
      case 'new_message':
        return Icons.chat_bubble_outline;
      case 'comment':
        return Icons.mode_comment_outlined;
      case 'comment_reply':
        return Icons.reply_outlined;
      case 'like':
        return Icons.favorite_outline;
      case 'system':
        return Icons.notifications_outlined;
      case 'repost':
        return Icons.repeat;
      case 'friend_request':
        return Icons.person_add_outlined;
      case 'mention':
        return Icons.alternate_email;
      case 'share':
        return Icons.share_outlined;
      case 'follow':
        return Icons.person_add_alt_1_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _getNotificationTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'message':
      case 'chat_message':
      case 'new_message':
        return 'Message';
      case 'comment':
        return 'Comment';
      case 'comment_reply':
        return 'Reply';
      case 'like':
        return 'Reaction';
      case 'system':
        return 'New Activity';
      case 'repost':
        return 'Share';
      case 'friend_request':
        return 'Friend Request';
      case 'mention':
        return 'Mention';
      case 'share':
        return 'Share';
      case 'follow':
        return 'Follow';
      default:
        return type;
    }
  }
}

class _UnreadBadge extends StatelessWidget {
  final int count;
  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class NotificationModel {
  final String id;
  final String? userId;
  final String? senderId;
  final String? senderUsername;
  final String? senderAvatar;
  final String type;
  final String? title;
  final String message;
  final String? relatedPostId;
  final bool isRead;
  final String createdAt;

  const NotificationModel({
    required this.id,
    this.userId,
    this.senderId,
    this.senderUsername,
    this.senderAvatar,
    required this.type,
    this.title,
    required this.message,
    this.relatedPostId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user'] as String?,
      senderId: json['sender'] as String?,
      senderUsername: json['sender_username'] as String?,
      senderAvatar: json['sender_avatar'] as String?,
      type: json['type'] as String,
      title: json['title'] as String?,
      message: json['message'] as String,
      relatedPostId: json['related_post_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] as String,
    );
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? senderId,
    String? senderUsername,
    String? senderAvatar,
    String? type,
    String? title,
    String? message,
    String? relatedPostId,
    bool? isRead,
    String? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      senderId: senderId ?? this.senderId,
      senderUsername: senderUsername ?? this.senderUsername,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      relatedPostId: relatedPostId ?? this.relatedPostId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
