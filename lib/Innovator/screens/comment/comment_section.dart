 
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:innovator/Innovator/App_data/App_data.dart';
import 'package:innovator/Innovator/constant/app_colors.dart';
import 'package:innovator/Innovator/hive/feed_cache_service.dart';
import 'package:innovator/Innovator/models/comment_Model.dart';
import 'package:innovator/Innovator/screens/comment/comment_services.dart';
import 'package:innovator/Innovator/utils/triangle_tool_tip.dart';

class CommentSection extends StatefulWidget {
  final String contentId; // = postId in new API
  // final VoidCallback? onCommentAdded;
  final bool isReel;
  final void Function(int delta)? onCommentCountChanged;
  

  // const CommentSection({Key? key, required this.contentId, this.onCommentAdded})
  //   : super(key: key);

  const CommentSection({
    Key? key,
    required this.contentId,
    this.onCommentCountChanged,
    this.isReel = false,
  }) : super(key: key);

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  final CommentService _service = CommentService();
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<Comment> _comments = [];
  bool _isLoading = false;
  bool _isSending = false;
  int _page = 0;
  bool _hasMore = true;

  // Edit state
  String? _editingCommentId;
  bool _editingIsReply =
      false; // ← track whether the comment being edited is a reply

  // Reply state
  String? _replyToCommentId;
  String? _replyToUsername;

  // Which comments have their replies expanded
  final Set<String> _expandedReplies = {};

  // Loaded replies keyed by commentId
  final Map<String, List<Comment>> _replies = {};
  final Set<String> _loadingReplies = {};

  String? get _myUsername => AppData().currentUser?['username']?.toString();

  // ── Lifecycle ──────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadComments();
    _scrollCtrl.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent &&
        !_isLoading &&
        _hasMore) {
      _loadMore();
    }
  }

  // ── Data ───────────────────────────────────────────────────────────────────
  Future<void> _loadComments({bool refresh = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      if (refresh) {
        _page = 0;
        _hasMore = true;
      }
      // final loaded = await _service.getComments(widget.contentId, page: _page);
      final loaded =
          widget.isReel
              ? await _service.getReelComments(widget.contentId, page: _page)
              : await _service.getComments(widget.contentId, page: _page);
      setState(() {
        if (refresh) _comments.clear();
        _comments.addAll(loaded);
        _page++;
        _hasMore = loaded.length >= 10;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      // _err('Failed to load comments');
    }
  }

  Future<void> _loadMore() => _loadComments();

  Future<void> _toggleReplies(String commentId) async {
    if (_expandedReplies.contains(commentId)) {
      setState(() => _expandedReplies.remove(commentId));
      return;
    }

    setState(() {
      _expandedReplies.add(commentId);
      _loadingReplies.add(commentId);
    });

    try {
      final replies = await _service.getReplies(commentId);
      if (mounted) {
        setState(() {
          _replies[commentId] = replies;
          _loadingReplies.remove(commentId);
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingReplies.remove(commentId));
    }
  }

  Future<void> _submit() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      if (_editingCommentId != null) {
        final Comment updated;
        if (_editingIsReply) {
          updated = await _service.updateReply(
            replyId: _editingCommentId!,
            content: text,
          );
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
            final idx = _comments.indexWhere((c) => c.id == _editingCommentId);
            if (idx != -1) _comments[idx] = updated;
          });
        }
        // _ok('${_editingIsReply ? 'Reply' : 'Comment'} updated');
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
        widget.onCommentCountChanged?.call(1);
        FeedCacheService.instance.updateCommentCount(widget.contentId, 1);
        // _ok('Reply posted');
      } else {
        // ← single routing decision based on isReel
        final comment =
            widget.isReel
                ? await _service.addCommentReel(
                  postId: widget.contentId,
                  content: text,
                )
                : await _service.addComment(
                  postId: widget.contentId,
                  content: text,
                );
        setState(() => _comments.insert(0, comment));
        widget.onCommentCountChanged?.call(1);
        FeedCacheService.instance.updateCommentCount(widget.contentId, -1);
        //_ok('Comment posted');
      }
    } catch (e) {
      //_err('Failed: $e');
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
            backgroundColor: Colors.white,
            title: const Text('Delete Comment'),
            content: const Text(
              'Are you sure you want to delete this comment?',
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
    if (ok != true) return;

    try {
      if (comment.isReply) {
        await _service.deleteReply(comment.id);
      } else {
        await _service.deleteComment(comment.id);
      }

      setState(() {
        _comments.removeWhere((c) => c.id == comment.id);

        for (final key in _replies.keys) {
          _replies[key]?.removeWhere((r) => r.id == comment.id);

          if (_replies[key]?.isEmpty == true) {
            _expandedReplies.remove(key);
          }
        }
      });

      widget.onCommentCountChanged?.call(-1);
      // _ok('Comment deleted');
    } catch (e) {
      // _err('Failed to delete');
    }
  }

  void _startEdit(Comment comment, {required bool isReply}) {
    setState(() {
      _editingCommentId = comment.id;
      _editingIsReply = isReply;
      _replyToCommentId = null;
      _replyToUsername = null;
      _inputCtrl.text = comment.content;
    });
    _focusNode.requestFocus();
  }

  void _startReply(Comment comment) {
    setState(() {
      _replyToCommentId = comment.id;
      _replyToUsername = comment.username;
      _editingCommentId = null;
      _editingIsReply = false;
      _inputCtrl.clear();
    });
    _focusNode.requestFocus();
  }

  void _cancelAction() {
    setState(() {
      _editingCommentId = null;
      _editingIsReply = false;
      _replyToCommentId = null;
      _replyToUsername = null;
      _inputCtrl.clear();
    });
    _focusNode.unfocus();
  }

  // ── Snackbars ─────────────────────────────────────────────────────────────

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Input bar ──────────────────────────────────────────────────────
        _buildInputBar(),

        // ── Action hint (editing / replying) ──────────────────────────────
        if (_editingCommentId != null || _replyToCommentId != null)
          _buildActionHint(),

        // ── Comments list ──────────────────────────────────────────────────
        Container(
          constraints: BoxConstraints(
            maxHeight: 320,
            minWidth: MediaQuery.of(context).size.width,
          ),
          child:
              _isLoading && _comments.isEmpty
                  ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                  : _comments.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                    controller: _scrollCtrl,
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: _comments.length + (_hasMore ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i == _comments.length) {
                        return _hasMore
                            ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: Center(child: CircularProgressIndicator()),
                            )
                            : const SizedBox.shrink();
                      }
                      return _buildCommentTile(_comments[i]);
                    },
                  ),
        ),
      ],
    );
  }

  // ── Input bar ──────────────────────────────────────────────────────────────
  Widget _buildInputBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color.fromRGBO(244, 135, 6, 0.15),
            child: Text(
              (_myUsername?.isNotEmpty == true ? _myUsername![0] : '?')
                  .toUpperCase(),
              style: const TextStyle(
                color: Color.fromRGBO(244, 135, 6, 1),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Text field
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
                        : 'Add a comment…',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(
                    color: Color.fromRGBO(244, 135, 6, 1),
                    width: 1.5,
                  ),
                ),
                suffixIcon:
                    _editingCommentId != null || _replyToCommentId != null
                        ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: _cancelAction,
                          color: Colors.grey,
                        )
                        : null,
              ),
            ),
          ),
          const SizedBox(width: 4),

          // Send button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child:
                _isSending
                    ? const SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : IconButton(
                      key: const ValueKey('send'),
                      icon: Icon(
                        _editingCommentId != null
                            ? Icons.check_circle_outline
                            : Icons.send_rounded,
                        color: const Color.fromRGBO(244, 135, 6, 1),
                      ),
                      // onPressed: _submitReel,
                      onPressed: _submit,
                    ),
          ),
        ],
      ),
    );
  }

  // ── Action hint strip ──────────────────────────────────────────────────────
  Widget _buildActionHint() {
    final isEditing = _editingCommentId != null;
    return Padding(
      padding: const EdgeInsets.only(left: 52, bottom: 4),
      child: Row(
        children: [
          Icon(
            isEditing ? Icons.edit : Icons.reply,
            size: 12,
            color: const Color.fromRGBO(244, 135, 6, 1),
          ),
          const SizedBox(width: 4),
          Text(
            isEditing
                ? 'Editing ${_editingIsReply ? 'reply' : 'comment'}'
                : 'Replying to @$_replyToUsername',
            style: const TextStyle(
              fontSize: 11,
              color: Color.fromRGBO(244, 135, 6, 1),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Text(
          'No comments yet. Be the first!',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ),
    );
  }

  // ── Single comment tile ────────────────────────────────────────────────────
  Widget _buildCommentTile(Comment comment, {bool isReply = false}) {
    final isOwn = _myUsername != null && _myUsername == comment.username;
    final avatarUrl = comment.avatar;
    final replies = _replies[comment.id] ?? [];
    final isExpanded = _expandedReplies.contains(comment.id);
    final loadingReplies = _loadingReplies.contains(comment.id);

    return Padding(
      padding: EdgeInsets.only(
        left: isReply ? 44 : 8,
        right: 8,
        top: 4,
        bottom: isReply ? 0 : 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: isReply ? 14 : 18,
            backgroundColor: const Color.fromRGBO(244, 135, 6, 0.12),
            backgroundImage:
                avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
            child:
                avatarUrl == null || avatarUrl.isEmpty
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
                // Bubble
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
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),

                // Action row below bubble
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
                          onTap: () => _startReply(comment),
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
                        ArrowPopupMenu(
                          child: const Icon(
                            Icons.more_horiz,
                            color: Colors.grey,
                          ),
                          arrowPosition: ArrowPosition.leftCenter,
                          arrowColor: Colors.grey,
                          backgroundColor: Colors.white,
                          menuWidth: 140,
                          items: [
                            ArrowMenuItem(
                              label: 'Edit',
                              icon: Icons.edit_outlined,
                              onTap:
                                  () => _startEdit(comment, isReply: isReply),
                            ),
                            ArrowMenuItem(
                              label: 'Delete',
                              icon: Icons.delete_outlined,
                              textColor: Colors.red,
                              iconColor: Colors.red,
                              onTap: () => _delete(comment),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                if (!isReply &&
                    (loadingReplies || replies.isNotEmpty || isExpanded))
                  GestureDetector(
                    onTap: () => _toggleReplies(comment.id),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4, top: 4),
                      child:
                          loadingReplies
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
                                    color: const Color.fromRGBO(244, 135, 6, 1),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    isExpanded
                                        ? 'Hide replies (${replies.length})'
                                        : 'View ${replies.length} repl${replies.length == 1 ? 'y' : 'ies'}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color.fromRGBO(244, 135, 6, 1),
                                    ),
                                  ),
                                ],
                              ),
                    ),
                  ),
                // Replies
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
