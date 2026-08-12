import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/api_response.dart';
import 'package:innovator/innovator/data/models/feed_models.dart';
import 'package:innovator/innovator/data/sources/feed_api.dart';
import 'theme/brand_colors.dart';
import 'widgets/fast_glass.dart';
import 'widgets/news_feed_section.dart';

const _ink = BrandColors.ink;

/// Where a notification should land when opened.
enum NotificationDestination { feed, chat, elearning, shop, profile }

enum _NotifFilter { all, unread, activity, learning }

enum _NotifKind { like, message, course, order, tip, follow, collaboration }

/// Maps the backend notification `type` string to a UI kind.
_NotifKind _kindFromType(String? type) {
  switch ((type ?? '').toLowerCase()) {
    case 'like':
    case 'reaction':
      return _NotifKind.like;
    case 'comment':
    case 'reply':
      return _NotifKind.like; // comment/reply also open the related post
    case 'message':
    case 'chat':
      return _NotifKind.message;
    case 'follow':
      return _NotifKind.follow;
    case 'collaboration':
    case 'collab':
      return _NotifKind.collaboration;
    case 'course':
      return _NotifKind.course;
    case 'order':
      return _NotifKind.order;
    default:
      return _NotifKind.tip;
  }
}

class _AppNotification {
  _AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.time,
    required this.unread,
    this.relatedPostId,
  });

  final String id;
  final _NotifKind kind;
  final String title;
  final String body;
  final String time;
  bool unread;

  /// Post this notification refers to (for like/comment → open that post).
  final String? relatedPostId;

  factory _AppNotification.fromApi(FeedNotification n) {
    return _AppNotification(
      id: n.id,
      kind: _kindFromType(n.type),
      title: (n.senderUsername?.trim().isNotEmpty == true)
          ? n.senderUsername!.trim()
          : (n.title?.trim().isNotEmpty == true ? n.title!.trim() : 'Innovator'),
      body: n.message?.trim().isNotEmpty == true
          ? n.message!.trim()
          : (n.title ?? ''),
      time: formatFeedTime(n.createdAt),
      unread: !n.isRead,
      relatedPostId: n.relatedPostId,
    );
  }

  NotificationDestination get destination => switch (kind) {
        _NotifKind.like => NotificationDestination.feed,
        _NotifKind.message => NotificationDestination.chat,
        _NotifKind.course => NotificationDestination.elearning,
        _NotifKind.order => NotificationDestination.shop,
        _NotifKind.tip => NotificationDestination.profile,
        _NotifKind.follow => NotificationDestination.profile,
        _NotifKind.collaboration => NotificationDestination.profile,
      };

  /// Professional outlined icons matched to each notification area.
  IconData get icon => switch (kind) {
        _NotifKind.like => Icons.favorite_border_rounded,
        _NotifKind.message => Icons.chat_bubble_outline_rounded,
        _NotifKind.course => Icons.school_outlined,
        _NotifKind.order => Icons.storefront_outlined,
        _NotifKind.tip => Icons.person_outline_rounded,
        _NotifKind.follow => Icons.person_add_alt_1_outlined,
        _NotifKind.collaboration => Icons.groups_outlined,
      };
}

/// Full-page liquid notifications experience inside the dashboard shell.
class NotificationsSection extends StatefulWidget {
  const NotificationsSection({
    super.key,
    this.contentPadding = EdgeInsets.zero,
    this.onOpen,
  });

  final EdgeInsets contentPadding;

  /// Opens the related product area (feed, chat, shop, etc.).
  final ValueChanged<NotificationDestination>? onOpen;

  @override
  State<NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<NotificationsSection> {
  _NotifFilter _filter = _NotifFilter.all;

  final _feedApi = FeedApi();
  final List<_AppNotification> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _feedApi.notifications();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(list.map(_AppNotification.fromApi));
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load notifications';
        _loading = false;
      });
    }
  }

  int get _unreadCount => _items.where((n) => n.unread).length;

  List<_AppNotification> get _visible {
    switch (_filter) {
      case _NotifFilter.all:
        return _items;
      case _NotifFilter.unread:
        return _items.where((n) => n.unread).toList();
      case _NotifFilter.activity:
        return _items
            .where(
              (n) =>
                  n.kind == _NotifKind.like ||
                  n.kind == _NotifKind.message ||
                  n.kind == _NotifKind.follow ||
                  n.kind == _NotifKind.collaboration,
            )
            .toList();
      case _NotifFilter.learning:
        return _items
            .where(
              (n) =>
                  n.kind == _NotifKind.course ||
                  n.kind == _NotifKind.tip ||
                  n.kind == _NotifKind.order,
            )
            .toList();
    }
  }

  void _markAllRead() {
    HapticFeedback.mediumImpact();
    unawaited(() async {
      try {
        await _feedApi.markAllNotificationsRead();
      } catch (_) {}
    }());
    setState(() {
      for (final n in _items) {
        n.unread = false;
      }
    });
  }

  void _open(_AppNotification item) {
    HapticFeedback.selectionClick();
    if (item.unread) {
      setState(() => item.unread = false);
      unawaited(_markRead(item.id));
    }

    // Like / comment notifications open the specific post they refer to.
    final postId = item.relatedPostId?.trim();
    if (postId != null && postId.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SinglePostPage(postId: postId)),
      );
      return;
    }
    widget.onOpen?.call(item.destination);
  }

  Future<void> _markRead(String id) async {
    try {
      await _feedApi.markNotificationRead(id);
    } catch (_) {}
  }

  void _dismiss(_AppNotification item) {
    HapticFeedback.lightImpact();
    setState(() => _items.removeWhere((n) => n.id == item.id));
    unawaited(() async {
      try {
        await _feedApi.deleteNotification(item.id);
      } catch (_) {}
    }());
  }

  @override
  Widget build(BuildContext context) {
    final padding = widget.contentPadding;

    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
    }
    if (_error != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final visible = _visible;
    final empty = visible.isEmpty;
    // Filter + (empty state | rows) + optional footer tip.
    final itemCount = 1 + (empty ? 1 : visible.length + 1);

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        20,
        padding.top + 6,
        20,
        padding.bottom + 8,
      ),
      cacheExtent: 480,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      addSemanticIndexes: false,
      physics: const ClampingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _FilterBar(
              selected: _filter,
              onChanged: (f) {
                HapticFeedback.selectionClick();
                setState(() => _filter = f);
              },
              onMarkAllRead: _unreadCount == 0 ? null : _markAllRead,
            ),
          );
        }

        if (empty) {
          return const _EmptyState();
        }

        final rowIndex = index - 1;
        if (rowIndex == visible.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: Text(
                'Swipe left to clear · Tap to open',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _ink.withValues(alpha: .4),
                ),
              ),
            ),
          );
        }

        final item = visible[rowIndex];
        return Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => _dismiss(item),
          background: const _DismissBackground(),
          child: Column(
            children: [
              _NotificationCard(
                item: item,
                onTap: () => _open(item),
              ),
              if (rowIndex != visible.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: _ink.withValues(alpha: .06),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.onChanged,
    this.onMarkAllRead,
  });

  final _NotifFilter selected;
  final ValueChanged<_NotifFilter> onChanged;
  final VoidCallback? onMarkAllRead;

  static const _options = [
    (_NotifFilter.all, 'All'),
    (_NotifFilter.unread, 'Unread'),
    (_NotifFilter.activity, 'Activity'),
    (_NotifFilter.learning, 'Learning'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final option in _options) ...[
                  _FilterChip(
                    label: option.$2,
                    selected: selected == option.$1,
                    onTap: () => onChanged(option.$1),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
        if (onMarkAllRead != null) ...[
          const SizedBox(width: 4),
          FastTap(
            onTap: onMarkAllRead!,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withValues(alpha: .45),
                border: Border.all(color: Colors.white.withValues(alpha: .9)),
              ),
              child: Text(
                'Mark as read',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _ink.withValues(alpha: .75),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);
    return FastTap(
      onTap: onTap,
      borderRadius: radius,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: radius,
          color: selected
              ? BrandColors.secondarySurface.withValues(alpha: .92)
              : Colors.white.withValues(alpha: .4),
          border: Border.all(
            color: selected
                ? BrandColors.accent.withValues(alpha: .4)
                : Colors.white.withValues(alpha: .85),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : _ink.withValues(alpha: .7),
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.onTap,
  });

  final _AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FastTap(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IconOrb(icon: item.icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: item.unread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: _ink,
                            letterSpacing: -.15,
                          ),
                        ),
                      ),
                      Text(
                        item.time,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: _ink.withValues(alpha: .38),
                        ),
                      ),
                      if (item.unread) ...[
                        const SizedBox(width: 7),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: BrandColors.accent,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: _ink.withValues(
                        alpha: item.unread ? .62 : .5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: _ink.withValues(alpha: .28),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconOrb extends StatelessWidget {
  const _IconOrb({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _ink.withValues(alpha: .06),
        border: Border.all(color: _ink.withValues(alpha: .08)),
      ),
      child: Icon(
        icon,
        size: 20,
        color: _ink.withValues(alpha: .72),
      ),
    );
  }
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 18),
      child: Icon(
        Icons.delete_outline_rounded,
        color: const Color(0xFFC0392B).withValues(alpha: .75),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return FastGlass(
      borderRadius: BorderRadius.circular(24),
      opacity: .4,
      padding: const EdgeInsets.fromLTRB(22, 36, 22, 36),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: BrandColors.accent.withValues(alpha: .14),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              size: 28,
              color: BrandColors.accent,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No notifications here',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try another filter or check back soon.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: _ink.withValues(alpha: .48),
            ),
          ),
        ],
      ),
    );
  }
}
