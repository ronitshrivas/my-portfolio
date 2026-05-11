import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:innovator/Innovator/constant/app_colors.dart';
import 'package:innovator/Innovator/models/Feed_Content_Model.dart';

const _kOrange = Color.fromRGBO(244, 135, 6, 1);
const _kOrangeLight = Color.fromRGBO(244, 135, 6, 0.10);
const _kGold = Color.fromRGBO(255, 204, 0, 1);

class SharedPostCard extends StatelessWidget {
  final SharedPostDetails details;

  final bool compact;

  const SharedPostCard({Key? key, required this.details, this.compact = false})
    : super(key: key);

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inDays > 365) return '${(d.inDays / 365).floor()}y ago';
    if (d.inDays > 30) return '${(d.inDays / 30).floor()}mo ago';
    if (d.inDays > 0) return '${d.inDays}d ago';
    if (d.inHours > 0) return '${d.inHours}h ago';
    if (d.inMinutes > 0) return '${d.inMinutes}m ago';
    return 'Just now';
  }

  Widget _avatar(String? url, String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    if (url == null || url.isEmpty) {
      return CircleAvatar(
        radius: 14,
        backgroundColor: Colors.grey.shade300,
        child: Text(
          initial,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.whitecolor,
          ),
        ),
      );
    }
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,
        width: 28,
        height: 28,
        fit: BoxFit.cover,
        placeholder:
            (_, __) => CircleAvatar(
              radius: 14,
              backgroundColor: Colors.grey.shade200,
              child: Text(
                initial,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ),
        errorWidget:
            (_, __, ___) => CircleAvatar(
              radius: 14,
              backgroundColor: Colors.grey.shade300,
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppColors.whitecolor,
                  fontSize: 11,
                ),
              ),
            ),
      ),
    );
  }

  // ── Media block ────────────────────────────────────────────────────────────

  Widget _buildMedia(BuildContext context) {
    final images =
        details.media.where((m) => m.isImage).map((m) => m.file).toList();
    final videos =
        details.media.where((m) => m.isVideo).map((m) => m.file).toList();

    if (images.isEmpty && videos.isEmpty) return const SizedBox.shrink();

    // Video thumbnail (play icon overlay)
    if (images.isEmpty && videos.isNotEmpty) {
      return _VideoThumb(url: videos.first);
    }

    // Single image
    if (images.length == 1) {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        child: CachedNetworkImage(
          imageUrl: images.first,
          width: double.infinity,
          fit: BoxFit.cover,
          placeholder:
              (_, __) => Container(
                height: 160,
                color: Colors.grey.shade200,
                child: Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: Image.asset(
                      'animation/IdeaBulb.gif',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
          errorWidget:
              (_, __, ___) => Container(
                height: 120,
                color: Colors.grey.shade200,
                child: const Icon(Icons.broken_image_outlined, size: 36),
              ),
        ),
      );
    }

    // 2-image side by side
    if (images.length == 2) {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(child: _GridThumb(url: images[0])),
            const SizedBox(width: 2),
            Expanded(child: _GridThumb(url: images[1])),
          ],
        ),
      );
    }

    // 3+ images — first full width, rest in row with +N overlay
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
      ),
      child: Column(
        children: [
          _GridThumb(url: images[0], height: 140),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(child: _GridThumb(url: images[1], height: 80)),
              const SizedBox(width: 2),
              Expanded(
                child: Stack(
                  children: [
                    _GridThumb(url: images[2], height: 80),
                    if (images.length > 3)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(120),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '+${images.length - 3}',
                            style: const TextStyle(
                              color: AppColors.whitecolor,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasMedia = details.hasMedia;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                // Repost icon badge
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kOrange, _kGold],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.repeat_rounded,
                    color: AppColors.whitecolor,
                    size: 10,
                  ),
                ),
                const SizedBox(width: 6),

                // Avatar
                _avatar(details.avatar, details.username),
                const SizedBox(width: 8),

                // Name + time
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        details.fullName.isNotEmpty
                            ? details.fullName
                            : details.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          fontFamily: 'InterThin',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '@${details.username} · ${_timeAgo(details.createdAt)}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                          fontFamily: 'InterThin',
                        ),
                      ),
                    ],
                  ),
                ),

                // "Original" chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _kOrangeLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Original',
                    style: TextStyle(
                      color: _kOrange,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'InterThin',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Content text ─────────────────────────────────────────────────
          if (details.content.isNotEmpty)
            Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, hasMedia ? 8 : 12),
              child: Text(
                details.content,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  color: Colors.grey.shade800,
                  height: 1.45,
                  fontFamily: 'InterThin',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // ── Media ──────────────────────────────────────────────────────
          if (hasMedia) _buildMedia(context),
        ],
      ),
    );
  }
}

class _GridThumb extends StatelessWidget {
  final String url;
  final double height;
  const _GridThumb({required this.url, this.height = 120});

  @override
  Widget build(BuildContext context) => CachedNetworkImage(
    imageUrl: url,
    height: height,
    width: double.infinity,
    fit: BoxFit.cover,
    placeholder:
        (_, __) => Container(
          height: height,
          color: Colors.grey.shade200,
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: Image.asset('animation/IdeaBulb.gif', fit: BoxFit.contain),
            ),
          ),
        ),
    errorWidget:
        (_, __, ___) => Container(
          height: height,
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image_outlined, size: 28),
        ),
  );
}

class _VideoThumb extends StatelessWidget {
  final String url;
  const _VideoThumb({required this.url});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: const BorderRadius.only(
      bottomLeft: Radius.circular(12),
      bottomRight: Radius.circular(12),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(height: 160, color: Colors.black, width: double.infinity),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(140),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.play_arrow_rounded,
            color: AppColors.whitecolor,
            size: 34,
          ),
        ),
        Positioned(
          bottom: 10,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.videocam_rounded,
                  color: AppColors.whitecolor,
                  size: 12,
                ),
                SizedBox(width: 4),
                Text(
                  'Video',
                  style: TextStyle(
                    color: AppColors.whitecolor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
