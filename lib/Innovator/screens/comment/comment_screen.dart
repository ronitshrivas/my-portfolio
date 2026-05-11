// CommentScreen.dart  (standalone full-page comments screen)
// Updated for http://36.253.137.34:8005

import 'package:flutter/material.dart';
import 'package:innovator/Innovator/constant/app_colors.dart';
import 'package:innovator/Innovator/models/comment_Model.dart';
import 'package:innovator/Innovator/screens/comment/comment_services.dart';
import 'package:innovator/Innovator/App_data/App_data.dart';

class CommentScreen extends StatefulWidget {
  final String postId;

  const CommentScreen({Key? key, required this.postId}) : super(key: key);

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  final CommentService _service = CommentService();
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<Comment> _comments = [];
  bool _isLoading = true;
  bool _isSending = false;

  String? _editingCommentId;
  bool _editingIsReply =
      false; // ← track whether the comment being edited is a reply
  String? _replyToCommentId;
  String? _replyToUsername;
  final Set<String> _expandedReplies = {};
  final Map<String, List<Comment>> _replies = {};
  final Set<String> _loadingReplies = {};

  String? get _myUsername => AppData().currentUser?['username']?.toString();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final comments = await _service.getComments(widget.postId);
      if (mounted)
        setState(() {
          _comments = comments;
          _isLoading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _isSending) return;
    setState(() => _isSending = true);

    try {
      if (_editingCommentId != null) {
        // ── Route to the correct endpoint based on whether it's a reply ──
        final Comment updated;
        if (_editingIsReply) {
          updated = await _service.updateReply(
            replyId: _editingCommentId!,
            content: text,
          );
          // Update inside the replies map
          setState(() {
            for (final key in _replies.keys) {
              final idx = _replies[key]?.indexWhere(
                (r) => r.id == _editingCommentId,
              );
              if (idx != null && idx != -1) {
                _replies[key]![idx] = updated;
                break;
              }
            }
          });
        } else {
          updated = await _service.updateComment(
            commentId: _editingCommentId!,
            content: text,
          );
          setState(() {
            final i = _comments.indexWhere((c) => c.id == _editingCommentId);
            if (i != -1) _comments[i] = updated;
          });
        }
      } else if (_replyToCommentId != null) {
        final reply = await _service.addReply(
          parentCommentId: _replyToCommentId!,
          content: text,
        );
        setState(() {
          _replies[_replyToCommentId!] = [
            ...(_replies[_replyToCommentId!] ?? []),
            reply,
          ];
          _expandedReplies.add(_replyToCommentId!);
        });
      } else {
        final comment = await _service.addComment(
          postId: widget.postId,
          content: text,
        );
        setState(() => _comments.insert(0, comment));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to post')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _editingCommentId = null;
          _editingIsReply = false;
          _replyToCommentId = null;
          _replyToUsername = null;
        });
        _inputCtrl.clear();
        _focusNode.unfocus();
      }
    }
  }

  Future<void> _delete(Comment comment) async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Delete Comment'),
            content: const Text('Delete this comment?'),
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
    if (ok != true) return;

    // ── Route to the correct delete endpoint ──────────────────────────────
    if (comment.isReply) {
      await _service.deleteReply(comment.id);
    } else {
      await _service.deleteComment(comment.id);
    }

    setState(() {
      _comments.removeWhere((c) => c.id == comment.id);
      for (final k in _replies.keys) {
        _replies[k]?.removeWhere((r) => r.id == comment.id);
      }
    });
  }

  Future<void> _toggleReplies(String commentId) async {
    if (_expandedReplies.contains(commentId)) {
      setState(() => _expandedReplies.remove(commentId));
      return;
    }
    setState(() {
      _expandedReplies.add(commentId);
      _loadingReplies.add(commentId);
    });
    final replies = await _service.getReplies(commentId);
    if (mounted) {
      setState(() {
        _replies[commentId] = replies;
        _loadingReplies.remove(commentId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whitecolor,
      appBar: AppBar(
        title: const Text('Comments'),
        backgroundColor: const Color.fromRGBO(244, 135, 6, 1),
        foregroundColor: AppColors.whitecolor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _comments.isEmpty
                    ? const Center(
                      child: Text(
                        'No comments yet. Be the first!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _comments.length,
                      itemBuilder: (_, i) => _buildCommentTile(_comments[i]),
                    ),
          ),

          // Action hint
          if (_editingCommentId != null || _replyToCommentId != null)
            Container(
              color: const Color.fromRGBO(244, 135, 6, 0.08),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Icon(
                    _editingCommentId != null ? Icons.edit : Icons.reply,
                    size: 14,
                    color: const Color.fromRGBO(244, 135, 6, 1),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _editingCommentId != null
                        ? 'Editing ${_editingIsReply ? 'reply' : 'comment'}'
                        : 'Replying to @$_replyToUsername',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color.fromRGBO(244, 135, 6, 1),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _editingCommentId = null;
                        _editingIsReply = false;
                        _replyToCommentId = null;
                        _replyToUsername = null;
                        _inputCtrl.clear();
                      });
                    },
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

          // Input bar
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.whitecolor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      focusNode: _focusNode,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        hintText:
                            _replyToUsername != null
                                ? 'Reply to @$_replyToUsername…'
                                : _editingCommentId != null
                                ? 'Edit your ${_editingIsReply ? 'reply' : 'comment'}…'
                                : 'Write a comment…',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(
                            color: Color.fromRGBO(244, 135, 6, 1),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isSending
                      ? const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : IconButton(
                        icon: Icon(
                          _editingCommentId != null
                              ? Icons.check_circle_outline
                              : Icons.send_rounded,
                          color: const Color.fromRGBO(244, 135, 6, 1),
                        ),
                        onPressed: _submit,
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentTile(Comment comment, {bool isReply = false}) {
    final isOwn = _myUsername != null && _myUsername == comment.username;
    final replies = _replies[comment.id] ?? [];
    final isExpanded = _expandedReplies.contains(comment.id);
    final loadingR = _loadingReplies.contains(comment.id);

    return Padding(
      padding: EdgeInsets.only(
        left: isReply ? 56 : 12,
        right: 12,
        top: 6,
        bottom: 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: isReply ? 14 : 18,
            backgroundColor: const Color.fromRGBO(244, 135, 6, 0.12),
            backgroundImage:
                (comment.avatar?.isNotEmpty == true)
                    ? NetworkImage(comment.avatar!)
                    : null,
            child:
                (comment.avatar == null || comment.avatar!.isEmpty)
                    ? Text(
                      comment.username.isNotEmpty
                          ? comment.username[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: isReply ? 11 : 13,
                        color: const Color.fromRGBO(244, 135, 6, 1),
                        fontWeight: FontWeight.bold,
                      ),
                    )
                    : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '@${comment.username}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        comment.content,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 4),
                  child: Row(
                    children: [
                      Text(
                        _timeAgo(comment.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      if (!isReply) ...[
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _replyToCommentId = comment.id;
                              _replyToUsername = comment.username;
                              _editingCommentId = null;
                              _editingIsReply = false;
                              _inputCtrl.clear();
                            });
                            _focusNode.requestFocus();
                          },
                          child: const Text(
                            'Reply',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color.fromRGBO(244, 135, 6, 1),
                            ),
                          ),
                        ),
                      ],
                      if (isOwn) ...[
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _editingCommentId = comment.id;
                              _editingIsReply = isReply; // ← set flag
                              _replyToCommentId = null;
                              _inputCtrl.text = comment.content;
                            });
                            _focusNode.requestFocus();
                          },
                          child: const Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.blueGrey,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _delete(comment), // ← pass full comment
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isReply)
                  GestureDetector(
                    onTap: () => _toggleReplies(comment.id),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4, top: 4),
                      child:
                          loadingR
                              ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isExpanded
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                    size: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    isExpanded
                                        ? 'Hide replies'
                                        : replies.isNotEmpty
                                        ? 'View ${replies.length} repl${replies.length == 1 ? 'y' : 'ies'}'
                                        : 'View replies',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),
                if (!isReply && isExpanded)
                  Column(
                    children:
                        replies
                            .map((r) => _buildCommentTile(r, isReply: true))
                            .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inDays > 365) return '${(d.inDays / 365).floor()}y';
    if (d.inDays > 30) return '${(d.inDays / 30).floor()}mo';
    if (d.inDays > 0) return '${d.inDays}d';
    if (d.inHours > 0) return '${d.inHours}h';
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    return 'now';
  }
}
