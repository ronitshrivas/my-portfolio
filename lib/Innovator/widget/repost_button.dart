import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/constant/api_constants.dart';
import 'package:innovator/Innovator/screens/Feed/Repost/repost_list_screen.dart';
import 'package:innovator/Innovator/screens/Feed/Repost/repost_sheet.dart';

class RepostButton extends StatefulWidget {
  final String postId;
  final String authorName;
  final String content;
  final String? authorAvatar;
  final VoidCallback? onViewReposts;

  const RepostButton({
    required this.postId,
    required this.authorName,
    required this.content,
    this.authorAvatar,
    this.onViewReposts,
  });

  @override
  State<RepostButton> createState() => _RepostButtonState();
}

class _RepostButtonState extends State<RepostButton>
    with SingleTickerProviderStateMixin {
  bool _justReposted = false;
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  int _repostCount = 0;
  bool _isLoadingCount = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    _fetchRepostCount();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _fetchRepostCount() async {
    if (!mounted) return;
    setState(() => _isLoadingCount = true);

    try {
      final token = AppData().accessToken ?? '';
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final uri = Uri.parse(
        '${ApiConstants.fetchreporstCount}${widget.postId}/reposts-list/',
      );
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        List<dynamic> rawList = [];

        if (decoded is List) {
          rawList = decoded;
        } else if (decoded is Map) {
          rawList =
              decoded['results'] as List<dynamic>? ??
              decoded['data'] as List<dynamic>? ??
              [];
        }

        if (mounted) {
          setState(() => _repostCount = rawList.length);
        }
      }
    } catch (e) {
      developer.log('[RepostButton] Error fetching count: $e');
    } finally {
      if (mounted) setState(() => _isLoadingCount = false);
    }
  }

  void _onTap() {
    showRepostSheet(
      context: context,
      postId: widget.postId,
      originalAuthorName: widget.authorName,
      originalContent: widget.content,
      originalAuthorAvatar: widget.authorAvatar,
      onRepostSuccess: (_) {
        if (mounted) {
          setState(() {
            _justReposted = true;
            _repostCount += 1; // Increment count after successful repost
          });
          _ctrl.forward(from: 0);
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => _justReposted = false);
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _justReposted ? Colors.green.shade600 : Colors.grey.shade800;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Icon — tap to repost
        GestureDetector(
          onTap: _onTap,
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

        // Count + Label — tap to view reposts list
        GestureDetector(
          onTap: _justReposted ? null : widget.onViewReposts ?? _onTap,
          child: Text(
            _isLoadingCount
                ? '...'
                : _repostCount > 0
                ? '$_repostCount Repost'
                : (_justReposted ? 'Reposted' : 'Repost'),
            style: TextStyle(
              //fontWeight: FontWeight.w600,
              color: color,
              fontSize: 11.5,
            ),
          ),
        ),
      ],
    );
  }
}
