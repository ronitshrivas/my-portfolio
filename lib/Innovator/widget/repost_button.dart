import 'package:flutter/material.dart';

import 'package:innovator/Innovator/screens/Feed/Repost/repost_sheet.dart';

class RepostButton extends StatefulWidget {
  final String postId;
  final String authorName;
  final String content;
  final String? authorAvatar;
  final VoidCallback? onViewReposts;
  final int initialRepostCount;

  const RepostButton({
    Key? key,
    required this.postId,
    required this.authorName,
    required this.content,
    this.authorAvatar,
    this.onViewReposts,
    this.initialRepostCount = 0,
  }) : super(key: key);

  @override
  State<RepostButton> createState() => _RepostButtonState();
}

class _RepostButtonState extends State<RepostButton>
    with SingleTickerProviderStateMixin {
  bool _justReposted = false;
  late int _repostCount; // ← local count state
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _repostCount = widget.initialRepostCount; // ← seed from parent
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(RepostButton old) {
    super.didUpdateWidget(old);
    // Sync if the parent feed refreshes with a new count
    if (old.initialRepostCount != widget.initialRepostCount) {
      _repostCount = widget.initialRepostCount;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onIconTap() {
    showRepostSheet(
      context: context,
      postId: widget.postId,
      originalAuthorName: widget.authorName,
      originalContent: widget.content,
      originalAuthorAvatar: widget.authorAvatar,
      onRepostSuccess: (_) {
        if (!mounted) return;
        setState(() {
          _justReposted = true;
          _repostCount++; // ← increment immediately on success
        });
        _ctrl.forward(from: 0);
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _justReposted = false);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color color =
        _justReposted ? Colors.green.shade600 : Colors.grey.shade800;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _onIconTap,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Icon(
              _justReposted ? Icons.repeat_on_rounded : Icons.repeat_rounded,
              color: color,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: _justReposted ? null : (widget.onViewReposts ?? _onIconTap),
          child: Text(
            // ← Show count when > 0, else show label
            _repostCount > 0
                ? '$_repostCount ${_justReposted ? "Reposted" : "Reposts"}'
                : (_justReposted ? 'Reposted' : 'Repost'),
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 11.0,
            ),
          ),
        ),
      ],
    );
  }
}
