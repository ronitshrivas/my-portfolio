import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/Authorization/Login.dart';
import 'package:innovator/Innovator/constant/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Theme constants
// ─────────────────────────────────────────────────────────────────────────────

const Color _kOrange = Color.fromRGBO(244, 135, 6, 1);
const Color _kOrangeLight = Color.fromRGBO(244, 135, 6, 0.12);

// ─────────────────────────────────────────────────────────────────────────────
// RepostApiService
// ─────────────────────────────────────────────────────────────────────────────

class RepostApiService {
  static const String _baseUrl = 'http://36.253.137.34:8005';

  static Map<String, String> _headers() {
    final token = AppData().accessToken ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> repost({
    required String postId,
    required String content,
    required BuildContext context,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/posts/$postId/repost/');
    developer.log('[Repost] POST $uri');
    final response = await http
        .post(uri, headers: _headers(), body: jsonEncode({'content': content}))
        .timeout(const Duration(seconds: 30));
    developer.log('[Repost] ${response.statusCode} — ${response.body}');
    if (response.statusCode == 401) {
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
          (_) => false,
        );
      }
      throw Exception('Authentication required');
    }
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    final body =
        response.body.isNotEmpty
            ? jsonDecode(response.body) as Map<String, dynamic>
            : <String, dynamic>{};
    throw Exception(
      body['message']?.toString() ??
          'Failed to repost (${response.statusCode})',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// showRepostSheet — call from anywhere to open the sheet
// ─────────────────────────────────────────────────────────────────────────────

void showRepostSheet({
  required BuildContext context,
  required String postId,
  required String originalAuthorName,
  required String originalContent,
  String? originalAuthorAvatar,
  VoidCallback? onViewReposts,
  void Function(Map<String, dynamic>)? onRepostSuccess,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (_) => RepostSheet(
          postId: postId,
          originalAuthorName: originalAuthorName,
          originalContent: originalContent,
          originalAuthorAvatar: originalAuthorAvatar,
          onRepostSuccess: onRepostSuccess,
        ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// RepostButton — PUBLIC widget for the action bar in Inner_HomePage.dart
// ─────────────────────────────────────────────────────────────────────────────

class RepostButton extends StatefulWidget {
  final String postId;
  final String authorName;
  final String content;
  final String? authorAvatar;
  final VoidCallback? onViewReposts;

  const RepostButton({
    Key? key,
    required this.postId,
    required this.authorName,
    required this.content,
    this.authorAvatar,
    this.onViewReposts,
  }) : super(key: key);

  @override
  State<RepostButton> createState() => _RepostButtonState();
}

class _RepostButtonState extends State<RepostButton>
    with SingleTickerProviderStateMixin {
  bool _justReposted = false;
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
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
        setState(() => _justReposted = true);
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
            _justReposted ? 'Reposted' : 'Repost',
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

// ─────────────────────────────────────────────────────────────────────────────
// RepostSheet — the bottom sheet widget
// ─────────────────────────────────────────────────────────────────────────────

class RepostSheet extends StatefulWidget {
  final String postId;
  final String originalAuthorName;
  final String originalContent;
  final String? originalAuthorAvatar;
  final void Function(Map<String, dynamic> data)? onRepostSuccess;

  const RepostSheet({
    Key? key,
    required this.postId,
    required this.originalAuthorName,
    required this.originalContent,
    this.originalAuthorAvatar,
    this.onRepostSuccess,
  }) : super(key: key);

  @override
  State<RepostSheet> createState() => _RepostSheetState();
}

class _RepostSheetState extends State<RepostSheet>
    with SingleTickerProviderStateMixin {
  final TextEditingController _captionController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _captionController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final data = await RepostApiService.repost(
        postId: widget.postId,
        content: _captionController.text.trim(),
        context: context,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onRepostSuccess?.call(data);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.repeat, color: AppColors.whitecolor, size: 18),
                SizedBox(width: 10),
                Text(
                  'Reposted successfully!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      developer.log('[Repost] error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.whitecolor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: bottomPadding + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: _kOrangeLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.repeat, color: _kOrange, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Repost',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'InterThin',
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _captionController,
              maxLines: 3,
              maxLength: 300,
              autofocus: true,
              style: const TextStyle(
                fontSize: 15,
                fontFamily: 'InterThin',
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Add your thoughts (optional)…',
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontFamily: 'InterThin',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  borderSide: BorderSide(color: _kOrange, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                counterStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage:
                        (widget.originalAuthorAvatar?.isNotEmpty ?? false)
                            ? NetworkImage(widget.originalAuthorAvatar!)
                            : null,
                    child:
                        (widget.originalAuthorAvatar?.isNotEmpty ?? false)
                            ? null
                            : Text(
                              widget.originalAuthorName.isNotEmpty
                                  ? widget.originalAuthorName[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.whitecolor,
                              ),
                            ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                widget.originalAuthorName,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  fontFamily: 'InterThin',
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _kOrangeLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Original',
                                style: TextStyle(
                                  color: _kOrange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.originalContent,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            height: 1.4,
                            fontFamily: 'InterThin',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'InterThin',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kOrange,
                      foregroundColor: AppColors.whitecolor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      disabledBackgroundColor: const Color.fromRGBO(
                        244,
                        135,
                        6,
                        0.5,
                      ),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.whitecolor,
                              ),
                            )
                            : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.repeat, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Repost Now',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    fontFamily: 'InterThin',
                                  ),
                                ),
                              ],
                            ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
