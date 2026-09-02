import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'models/api_response.dart';
import 'package:innovator/core/config/api_config.dart';
import 'package:innovator/innovator/data/models/chat_models.dart';
import 'services/chat_socket.dart';
import 'services/auth_session.dart';
import 'package:innovator/innovator/data/sources/chat_api.dart';
import 'theme/brand_colors.dart';
import 'package:innovator/innovator/data/models/profile_models.dart';
import 'package:innovator/innovator/data/sources/profile_api.dart';
import 'widgets/cached_feed_image.dart';
import 'widgets/liquid_pressable.dart';
import 'widgets/wave_fill_painter.dart';

const _ink = BrandColors.ink;
const _muted = BrandColors.muted;
const _online = Color(0xFF17A275);

const _avatarPalettes = <List<Color>>[
  [Color(0xFF4C1D95), Color(0xFF7C3AED)],
  [Color(0xFF1E3A8A), Color(0xFF2563EB)],
  [Color(0xFF0F766E), Color(0xFF14B8A6)],
  [Color(0xFF92400E), Color(0xFFB45309)],
  [Color(0xFF9F1239), Color(0xFFE11D48)],
  [Color(0xFF0369A1), Color(0xFF38BDF8)],
  [Color(0xFF047857), Color(0xFF34D399)],
  [Color(0xFF6D28D9), Color(0xFFA78BFA)],
];

List<Color> _colorsFor(String seed) {
  final i = seed.hashCode.abs() % _avatarPalettes.length;
  return _avatarPalettes[i];
}

String _formatChatTime(DateTime? dt) {
  if (dt == null) return '';
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inHours < 1) return '${diff.inMinutes}m';
  if (diff.inDays < 1) return '${diff.inHours}h';
  if (diff.inDays < 7) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[dt.weekday - 1];
  }
  return '${dt.day}/${dt.month}';
}

String _formatBubbleTime(DateTime? dt) {
  if (dt == null) return '';
  final local = dt.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

class _Conversation {
  _Conversation({
    required this.id,
    required this.name,
    required this.role,
    required this.preview,
    required this.time,
    required this.colors,
    this.peerUserId,
    this.avatarUrl,
    this.unread = 0,
    this.isOnline = false,
  });

  final String id;
  final String name;
  final String role;
  final String preview;
  final String time;
  final List<Color> colors;
  final String? peerUserId;
  final String? avatarUrl;
  int unread;
  final bool isOnline;

  factory _Conversation.fromApi(ChatConversation c) {
    final me = AuthSession.instance.userId;
    final peer = c.peerOf(me);
    final name = peer?.username?.trim().isNotEmpty == true
        ? peer!.username!.trim()
        : 'Chat';
    final preview = c.lastMessage?.content?.trim().isNotEmpty == true
        ? c.lastMessage!.content!.trim()
        : 'No messages yet';
    return _Conversation(
      id: c.id,
      name: name,
      role: 'Direct',
      preview: preview,
      time: _formatChatTime(c.lastMessage?.createdAt ?? c.createdAt),
      colors: _colorsFor(peer?.userId ?? c.id),
      peerUserId: peer?.userId,
      avatarUrl: _resolveChatAvatar(peer?.avatar),
      unread: c.unreadCount,
    );
  }
}

/// Chat peers' avatars live on the profile service (8011). Prefix relative
/// paths and rewrite wrong-host / wrong-port absolute URLs so they resolve.
String? _resolveChatAvatar(String? path) {
  final raw = path?.trim();
  if (raw == null || raw.isEmpty) return null;
  const host = ApiConfig.profileBaseUrl; // http://36.253.137.34:8011
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    final uri = Uri.tryParse(raw);
    if (uri != null &&
        (uri.host == 'localhost' ||
            (uri.host == '36.253.137.34' && uri.port != 8011))) {
      final tail = uri.path.startsWith('/') ? uri.path : '/${uri.path}';
      return '$host$tail';
    }
    return raw;
  }
  return '$host${raw.startsWith('/') ? '' : '/'}$raw';
}

enum _AutoDelete { never, hours24 }

class _Msg {
  _Msg(
    this.text, {
    required this.mine,
    required this.time,
    String? id,
    this.createdAt,
    this.isRead = false,
    this.mediaUrl,
    this.replyToId,
    this.replyPreview,
    this.replyAuthor,
    this.isDeleted = false,
    this.pending = false,
  }) : id = id ?? UniqueKey().toString();

  final String id;
  String text;
  final bool mine;
  final String time;
  final DateTime? createdAt;

  /// Whether the other participant has read this (my) message → blue tick.
  bool isRead;
  final String? mediaUrl;
  final String? replyToId;

  /// Quoted preview of the replied-to message (text + author).
  final String? replyPreview;
  final String? replyAuthor;
  bool isDeleted;

  /// True while an optimistic message is still being sent.
  final bool pending;

  bool get hasImage => (mediaUrl ?? '').isNotEmpty;
  _AutoDelete autoDelete = _AutoDelete.never;

  factory _Msg.fromApi(ChatMessage m) {
    final me = AuthSession.instance.userId;
    return _Msg(
      m.content?.trim().isNotEmpty == true ? m.content!.trim() : '',
      id: m.id,
      mine: m.senderId == me,
      time: _formatBubbleTime(m.createdAt),
      createdAt: m.createdAt,
      isRead: m.isRead,
      mediaUrl: m.mediaUrl,
      replyToId: m.replyToId,
      replyPreview: m.replyTo?.content,
      replyAuthor: m.replyTo?.senderUsername,
      isDeleted: m.isDeleted,
    );
  }
}

/// Chat as an in-shell section. The conversation list and the open
/// thread melt into each other; bubbles carry liquid inside them, the
/// send orb is a droplet full of ink, and every touch springs.
class ChatSection extends StatefulWidget {
  const ChatSection({
    super.key,
    this.contentPadding = EdgeInsets.zero,
    this.onThreadActive,
  });

  /// Clearances from the shell so content stays clear of the docked bar.
  final EdgeInsets contentPadding;

  /// Fired with true when a conversation thread opens and false when it closes,
  /// so the shell can hide the nav bar while the user is chatting.
  final ValueChanged<bool>? onThreadActive;

  @override
  State<ChatSection> createState() => _ChatSectionState();
}

class _ChatSectionState extends State<ChatSection>
    with TickerProviderStateMixin {
  final _composer = TextEditingController();
  final _composerFocus = FocusNode();
  final _listSearch = TextEditingController();
  final _listSearchFocus = FocusNode();
  String _listQuery = '';

  final _chatApi = ChatApi();
  final _profileApi = ProfileApi();
  final List<_Conversation> _conversations = [];
  final Map<String, List<_Msg>> _messages = {};

  _Conversation? _open;
  bool _loadingList = true;
  bool _loadingThread = false;
  bool _sending = false;
  String? _listError;
  int _sendCount = 0;

  /// Message currently being replied to, if any (shows a banner over composer).
  _Msg? _replyTarget;

  /// Message currently being edited, if any (composer switches to edit mode).
  _Msg? _editTarget;

  /// Unread count captured when a conversation is opened, used to place the
  /// "Unread messages" divider. Cleared once the thread has been seen.
  int _openUnreadCount = 0;

  /// Pending auto-delete timers keyed by message id.
  final Map<String, Timer> _autoDeleteTimers = {};

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  /// Continuous phase shared by every liquid surface in the chat.
  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  StreamSubscription<Map<String, dynamic>>? _socketSub;
  StreamSubscription<Map<String, dynamic>>? _readSub;

  void initState() {
    super.initState();
    _loadConversations();
    // Realtime: connect the chat socket and append incoming messages live.
    ChatSocket.instance.connect();
    _socketSub = ChatSocket.instance.messages.listen(_onSocketMessage);
    _readSub = ChatSocket.instance.reads.listen(_onSocketRead);
  }

  /// The other participant read the conversation — flip my sent messages to
  /// "read" so the ticks turn blue instantly.
  void _onSocketRead(Map<String, dynamic> data) {
    if (!mounted) return;
    final convId = (data['conversation_id'] ?? '').toString();
    final readerId = (data['reader_id'] ?? '').toString();
    if (convId.isEmpty) return;
    // Ignore my own read events; only the peer reading my messages matters.
    if (readerId == AuthSession.instance.userId) return;
    final list = _messages[convId];
    if (list == null || list.isEmpty) return;
    setState(() {
      for (final m in list) {
        if (m.mine) m.isRead = true;
      }
    });
  }

  /// A message arrived over the socket. Append it to its conversation (unless
  /// it's my own echo already shown), and refresh the list preview.
  /// Converts a possibly PascalCase map (from the WebSocket DTO) into the
  /// snake_case keys the REST models parse. Passes snake_case through unchanged.
  Map<String, dynamic> _normalizeChatKeys(Map<String, dynamic> input) {
    String toSnake(String key) {
      if (!key.contains(RegExp('[A-Z]'))) return key; // already snake/lower
      final buffer = StringBuffer();
      for (var i = 0; i < key.length; i++) {
        final ch = key[i];
        if (ch.toUpperCase() == ch && ch.toLowerCase() != ch) {
          if (i > 0) buffer.write('_');
          buffer.write(ch.toLowerCase());
        } else {
          buffer.write(ch);
        }
      }
      return buffer.toString();
    }

    final out = <String, dynamic>{};
    input.forEach((key, value) {
      final normalized = toSnake(key);
      if (value is Map<String, dynamic>) {
        out[normalized] = _normalizeChatKeys(value);
      } else {
        out[normalized] = value;
      }
    });
    return out;
  }

  void _onSocketMessage(Map<String, dynamic> data) {
    if (!mounted) return;
    try {
      // The WebSocket DTO arrives PascalCase (Id, ConversationId, Content…),
      // but ChatMessage.fromJson expects snake_case like the REST API. Normalize
      // so realtime frames parse into real fields instead of empty ones.
      final incoming = ChatMessage.fromJson(_normalizeChatKeys(data));
      final convId = incoming.conversationId;
      if (convId.isEmpty) return;
      final me = AuthSession.instance.userId;
      // My own sends are already shown optimistically; skip echoes.
      if (incoming.senderId == me) return;

      final list = _messages.putIfAbsent(convId, () => <_Msg>[]);
      if (list.any((m) => m.id == incoming.id)) return; // dedupe
      setState(() {
        list.add(_Msg.fromApi(incoming));
        // Bump the conversation preview/time in the list.
        final idx = _conversations.indexWhere((c) => c.id == convId);
        if (idx >= 0) {
          final c = _conversations[idx];
          _conversations[idx] = _Conversation(
            id: c.id,
            name: c.name,
            role: c.role,
            preview: incoming.content?.trim().isNotEmpty == true
                ? incoming.content!.trim()
                : 'Sent a photo',
            time: 'now',
            colors: c.colors,
            peerUserId: c.peerUserId,
            avatarUrl: c.avatarUrl,
            unread: _open?.id == convId ? 0 : c.unread + 1,
          );
        }
      });
      // If this conversation is open, mark it read on the server.
      if (_open?.id == convId) {
        unawaited(() async {
          try {
            await _chatApi.markRead(convId);
          } catch (_) {}
        }());
      }
    } catch (_) {
      // Ignore malformed socket payloads.
    }
  }

  Future<void> _loadConversations() async {
    if (!AuthSession.instance.isSignedIn) {
      setState(() {
        _loadingList = false;
        _listError = 'Sign in to load chats';
        _conversations.clear();
      });
      return;
    }
    setState(() {
      _loadingList = true;
      _listError = null;
    });
    try {
      final remote = await _chatApi.listConversations();
      if (!mounted) return;
      setState(() {
        _conversations
          ..clear()
          ..addAll(remote.map(_Conversation.fromApi));
        _loadingList = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingList = false;
        _listError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingList = false;
        _listError = 'Could not load chats';
      });
    }
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _readSub?.cancel();
    for (final timer in _autoDeleteTimers.values) {
      timer.cancel();
    }
    _composer.dispose();
    _composerFocus.dispose();
    _listSearch.dispose();
    _listSearchFocus.dispose();
    _entrance.dispose();
    _wave.dispose();
    super.dispose();
  }

  List<_Conversation> get _filteredConversations {
    final q = _listQuery.toLowerCase();
    if (q.isEmpty) return _conversations;
    return _conversations
        .where(
          (c) =>
              c.name.toLowerCase().contains(q) ||
              c.preview.toLowerCase().contains(q) ||
              c.role.toLowerCase().contains(q),
        )
        .toList();
  }

  List<_Conversation> get _recentChats =>
      _conversations.where((c) => c.isOnline || c.unread > 0).toList();

  void _cancelAutoDelete(String messageId) {
    _autoDeleteTimers.remove(messageId)?.cancel();
  }

  void _scheduleAutoDelete(_Msg message) {
    _cancelAutoDelete(message.id);
    // Demo timing: 24h would be too long to feel — use 24s as a stand-in
    // so the liquid delete is visible in the same session. Swap to
    // Duration(hours: 24) for production.
    _autoDeleteTimers[message.id] = Timer(const Duration(seconds: 24), () {
      if (!mounted) return;
      _removeMessage(message.id);
    });
  }

  void _removeMessage(String messageId) {
    _cancelAutoDelete(messageId);
    if (!mounted) return;
    setState(() {
      for (final list in _messages.values) {
        list.removeWhere((m) => m.id == messageId);
      }
    });
    // Best-effort remote delete (local already updated for snappy UI).
    unawaited(() async {
      try {
        await _chatApi.deleteMessage(messageId);
      } catch (_) {
        if (mounted) _liquidToast('Could not delete on server');
      }
    }());
  }

  void _setAutoDelete(_Msg message, _AutoDelete mode) {
    setState(() => message.autoDelete = mode);
    if (mode == _AutoDelete.hours24) {
      _scheduleAutoDelete(message);
      _liquidToast('Auto delete in 24 hours');
    } else {
      _cancelAutoDelete(message.id);
      _liquidToast('Auto delete off');
    }
  }

  void _liquidToast(String label) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(milliseconds: 1600),
        content: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: [
                  BrandColors.secondarySurface.withValues(alpha: .95),
                  BrandColors.secondarySurface.withValues(alpha: .92),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: .28)),
              boxShadow: [
                BoxShadow(
                  color: _ink.withValues(alpha: .22),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openMessageMenu(_Msg message, BuildContext anchor) async {
    HapticFeedback.selectionClick();
    final box = anchor.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final origin = box.localToGlobal(Offset.zero);
    final anchorRect = origin & box.size;

    final action = await Navigator.of(context).push<_MessageMenuAction>(
      _LiquidPopoverRoute(
        anchorRect: anchorRect,
        selected: message.autoDelete,
        mine: message.mine,
        canEdit: message.mine && !message.hasImage && !message.isDeleted,
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _MessageMenuAction.reply:
        _startReply(message);
      case _MessageMenuAction.edit:
        _startEdit(message);
      case _MessageMenuAction.autoDelete24h:
        _setAutoDelete(message, _AutoDelete.hours24);
      case _MessageMenuAction.never:
        _setAutoDelete(message, _AutoDelete.never);
      case _MessageMenuAction.delete:
        HapticFeedback.mediumImpact();
        _removeMessage(message.id);
        _liquidToast('Message deleted');
    }
  }

  Widget _stagger({required int index, required Widget child}) {
    final start = (index * .09).clamp(0.0, .6);
    final animation = CurvedAnimation(
      parent: _entrance,
      curve: Interval(
        start,
        (start + .45).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .06),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  Future<void> _openConversation(_Conversation conversation) async {
    HapticFeedback.selectionClick();
    final cached = _messages[conversation.id];
    setState(() {
      _open = conversation;
      _openUnreadCount = conversation.unread;
      conversation.unread = 0;
      _loadingThread = cached == null;
    });
    widget.onThreadActive?.call(true);
    try {
      final remote = await _chatApi.listMessages(conversation.id);
      unawaited(() async {
        try {
          await _chatApi.markRead(conversation.id);
        } catch (_) {}
      }());
      if (!mounted || _open?.id != conversation.id) return;
      // The API returns newest-first (paginated). Reverse to chronological
      // order (oldest → newest) so the thread reads top-to-bottom and new
      // messages land at the bottom.
      final mapped = remote
          .where((m) => !m.isDeleted)
          .map(_Msg.fromApi)
          .toList()
          .reversed
          .toList();
      setState(() {
        _messages[conversation.id] = mapped;
        _loadingThread = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loadingThread = false);
      if (cached == null) _liquidToast(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingThread = false);
      if (cached == null) _liquidToast('Could not load messages');
    }
  }

  void _closeConversation() {
    HapticFeedback.selectionClick();
    _composerFocus.unfocus();
    setState(() {
      _open = null;
      _loadingThread = false;
    });
    widget.onThreadActive?.call(false);
    // List already reflects local unread=0; skip full refetch on every back.
  }

  Future<void> _deliverMessage(
    _Conversation open,
    String text, {
    String? mediaUrl,
    String? replyToId,
  }) async {
    if (_sending) return;
    setState(() {
      _composer.clear();
      _sending = true;
      _sendCount++;
    });
    HapticFeedback.mediumImpact();

    try {
      final sent = await _chatApi.sendMessage(
        open.id,
        content: text.isEmpty ? ' ' : text,
        messageType: mediaUrl != null ? 'image' : 'text',
        mediaUrl: mediaUrl,
        replyToId: replyToId,
      );
      if (!mounted || _open?.id != open.id) return;
      final msg = _Msg.fromApi(sent);
      setState(() {
        final list = _messages.putIfAbsent(open.id, () => <_Msg>[]);
        list.add(msg);
        _sending = false;
        final preview = mediaUrl != null && text.trim().isEmpty ? 'Photo' : text;
        final idx = _conversations.indexWhere((c) => c.id == open.id);
        if (idx >= 0) {
          _conversations[idx] = _Conversation(
            id: open.id,
            name: open.name,
            role: open.role,
            preview: preview,
            time: 'now',
            colors: open.colors,
            peerUserId: open.peerUserId,
            unread: 0,
            isOnline: open.isOnline,
          );
          if (_open?.id == open.id) _open = _conversations[idx];
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      _liquidToast(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      _liquidToast('Could not send message');
    }
  }

  void _send() {
    final open = _open;
    final text = _composer.text.trim();
    if (open == null) {
      HapticFeedback.selectionClick();
      return;
    }
    if (_editTarget != null) {
      if (text.isEmpty) {
        HapticFeedback.selectionClick();
        return;
      }
      unawaited(_commitEdit(_editTarget!, text));
      return;
    }
    if (text.isEmpty) {
      HapticFeedback.selectionClick();
      return;
    }
    final replyId = _replyTarget?.id;
    setState(() => _replyTarget = null);
    unawaited(_deliverMessage(open, text, replyToId: replyId));
  }

  Future<void> _pickAndSendImage() async {
    final open = _open;
    if (open == null || _sending) return;
    HapticFeedback.selectionClick();
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
      );
      if (picked == null) return;
      setState(() => _sending = true);
      final url = await _chatApi.uploadMedia(picked.path);
      if (!mounted || _open?.id != open.id) {
        setState(() => _sending = false);
        return;
      }
      final caption = _composer.text.trim();
      final replyId = _replyTarget?.id;
      setState(() {
        _sending = false;
        _replyTarget = null;
      });
      await _deliverMessage(open, caption, mediaUrl: url, replyToId: replyId);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _sending = false);
        _liquidToast(e.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _sending = false);
        _liquidToast('Could not send photo');
      }
    }
  }

  Future<void> _commitEdit(_Msg message, String text) async {
    final previous = message.text;
    setState(() {
      _editTarget = null;
      _composer.clear();
      message.text = text;
    });
    try {
      await _chatApi.updateMessage(message.id, content: text);
      if (mounted) _liquidToast('Message edited');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => message.text = previous);
      _liquidToast(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => message.text = previous);
      _liquidToast('Could not edit message');
    }
  }

  void _startReply(_Msg message) {
    HapticFeedback.selectionClick();
    setState(() {
      _replyTarget = message;
      _editTarget = null;
    });
    _composerFocus.requestFocus();
  }

  void _startEdit(_Msg message) {
    HapticFeedback.selectionClick();
    setState(() {
      _editTarget = message;
      _replyTarget = null;
      _composer.text = message.text;
      _composer.selection = TextSelection.fromPosition(
        TextPosition(offset: _composer.text.length),
      );
    });
    _composerFocus.requestFocus();
  }

  void _cancelComposerContext() {
    setState(() {
      _replyTarget = null;
      if (_editTarget != null) _composer.clear();
      _editTarget = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(.04, 0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: _open == null ? _buildList() : _buildThread(_open!),
    );
  }

  // ------------------------------------------------------------------ list

  Widget _buildList() {
    final padding = widget.contentPadding;
    final chats = _filteredConversations;
    return RefreshIndicator(
      color: BrandColors.secondarySurface,
      onRefresh: _loadConversations,
      child: ListView(
        key: const ValueKey('conversations'),
        physics: const AlwaysScrollableScrollPhysics(
          parent: ClampingScrollPhysics(),
        ),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding:
            EdgeInsets.fromLTRB(20, padding.top + 8, 20, padding.bottom + 6),
        children: [
          _stagger(
            index: 0,
            child: _ChatListSearchBar(
              controller: _listSearch,
              focusNode: _listSearchFocus,
              wave: _wave,
              onChanged: (value) => setState(() => _listQuery = value.trim()),
              onClear: () {
                _listSearch.clear();
                _listSearchFocus.requestFocus();
                setState(() => _listQuery = '');
              },
            ),
          ),
          const SizedBox(height: 14),
          _stagger(
            index: 1,
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Messages',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                      letterSpacing: -.1,
                    ),
                  ),
                ),
                LiquidPressable(
                  onTap: _showNewFriendsSheet,
                  borderRadius: BorderRadius.circular(999),
                  rippleColor: _ink,
                  intensity: .7,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: BrandColors.secondarySurface.withValues(alpha: .92),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_add_alt_1_rounded,
                            size: 14, color: Colors.white),
                        SizedBox(width: 5),
                        Text(
                          'New friends',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (_loadingList)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            )
          else if (_listError != null)
            Padding(
              padding: const EdgeInsets.only(top: 36),
              child: Column(
                children: [
                  Text(
                    _listError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13.5, color: _muted),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _loadConversations,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (chats.isEmpty)
            _stagger(
              index: 2,
              child: Padding(
                padding: const EdgeInsets.only(top: 36),
                child: Center(
                  child: Text(
                    _listQuery.isEmpty
                        ? 'No conversations yet.\nTap New friends to start.'
                        : 'No chats for “$_listQuery”',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: _muted),
                  ),
                ),
              ),
            )
          else ...[
            if (_recentChats.isNotEmpty) ...[
              _stagger(
                index: 2,
                child: _AvatarRail(
                  title: 'Recent',
                  wave: _wave,
                  people: [
                    for (final c in _recentChats)
                      _RailPerson(
                        c.name,
                        c.colors,
                        isOnline: c.isOnline,
                        avatarUrl: c.avatarUrl,
                      ),
                  ],
                  onTapName: (name) {
                    final match = _conversations.where((c) => c.name == name);
                    if (match.isNotEmpty) _openConversation(match.first);
                  },
                ),
              ),
              const SizedBox(height: 14),
            ],
            for (var i = 0; i < chats.length; i++)
              _stagger(
                index: 3 + i,
                child: _ConversationTile(
                  conversation: chats[i],
                  wave: _wave,
                  phaseShift: i * .9,
                  onTap: () => _openConversation(chats[i]),
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// Opens (or reuses) a chat with the given user, then shows the thread.
  Future<void> _startChatWith({
    required String userId,
    String? username,
    String? avatar,
  }) async {
    if (userId.isEmpty) return;
    try {
      final conv = await _chatApi.createConversation(
        participantUserId: userId,
        participantUsername: username,
        participantAvatar: avatar,
      );
      if (!mounted) return;
      final local = _Conversation.fromApi(conv);
      setState(() {
        _conversations.removeWhere((c) => c.id == local.id);
        _conversations.insert(0, local);
        _messages.putIfAbsent(local.id, () => []);
      });
      await _openConversation(local);
    } on ApiException catch (e) {
      if (mounted) _liquidToast(e.message);
    } catch (_) {
      if (mounted) _liquidToast('Could not start chat');
    }
  }

  /// "New friends": shows the user's followers so they can start a chat.
  Future<void> _showNewFriendsSheet() async {
    HapticFeedback.selectionClick();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NewFriendsSheet(
        profileApi: _profileApi,
        onPick: (user) {
          Navigator.pop(ctx);
          _startChatWith(
            userId: user.id,
            username: user.username,
            avatar: user.avatar,
          );
        },
      ),
    );
  }

  Future<void> _legacyNewChatSheet() async {
    HapticFeedback.selectionClick();
    final usernameCtrl = TextEditingController();
    final userIdCtrl = TextEditingController();
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
          ),
          child: Material(
            color: Colors.white.withValues(alpha: .94),
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Start a chat',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter the peer’s auth user ID (UUID) and optional username.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: _ink.withValues(alpha: .5),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: userIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'User ID (required)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: usernameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Username (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: BrandColors.secondarySurface,
                    ),
                    child: const Text('Create'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    final userId = userIdCtrl.text.trim();
    final username = usernameCtrl.text.trim();
    usernameCtrl.dispose();
    userIdCtrl.dispose();
    if (created != true || userId.isEmpty) return;

    try {
      final conv = await _chatApi.createConversation(
        participantUserId: userId,
        participantUsername: username.isEmpty ? null : username,
      );
      if (!mounted) return;
      final local = _Conversation.fromApi(conv);
      setState(() {
        _conversations.removeWhere((c) => c.id == local.id);
        _conversations.insert(0, local);
        _messages[local.id] = [];
      });
      await _openConversation(local);
    } on ApiException catch (e) {
      if (mounted) _liquidToast(e.message);
    } catch (_) {
      if (mounted) _liquidToast('Could not create chat');
    }
  }

  // ---------------------------------------------------------------- thread

  Widget _buildThread(_Conversation conversation) {
    final padding = widget.contentPadding;
    final messages = _messages[conversation.id] ?? const <_Msg>[];
    // When a thread is open the composer should hug the keyboard / bottom edge,
    // not the nav-bar-reserved space the list padding carries. Use the real
    // safe-area inset so there's no large gap above the keyboard.
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;
    return Padding(
      key: ValueKey('thread-${conversation.id}'),
      padding: EdgeInsets.fromLTRB(20, padding.top + 8, 20, safeBottom + 6),
      child: Column(
        children: [
          _ThreadHeader(
            conversation: conversation,
            wave: _wave,
            onBack: _closeConversation,
            onMore: (anchor) async {
              HapticFeedback.selectionClick();
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete conversation?'),
                  content: const Text(
                    'This removes the chat from your list on the server.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true) await _deleteConversation(conversation);
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _loadingThread
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final messageIndex = messages.length - 1 - index;
                      final message = messages[messageIndex];
                      final showUnread = _openUnreadCount > 0 &&
                          _openUnreadCount <= messages.length &&
                          messageIndex ==
                              messages.length - _openUnreadCount;
                      final bubble = _Bubble(
                        key: ValueKey(message.id),
                        message: message,
                        wave: _wave,
                        onMore: (anchor) => _openMessageMenu(message, anchor),
                      );
                      if (!showUnread) return bubble;
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _UnreadDivider(count: _openUnreadCount),
                          bubble,
                        ],
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10),
          _buildComposer(),
        ],
      ),
    );
  }

  Future<void> _deleteConversation(_Conversation conversation) async {
    try {
      await _chatApi.deleteConversation(conversation.id);
      if (!mounted) return;
      setState(() {
        _conversations.removeWhere((c) => c.id == conversation.id);
        _messages.remove(conversation.id);
        if (_open?.id == conversation.id) _open = null;
      });
      _liquidToast('Conversation deleted');
    } on ApiException catch (e) {
      if (mounted) _liquidToast(e.message);
    } catch (_) {
      if (mounted) _liquidToast('Could not delete conversation');
    }
  }

  Widget _buildComposer() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_replyTarget != null || _editTarget != null)
          _ComposerContextBanner(
            editing: _editTarget != null,
            author: _replyTarget?.mine == true
                ? 'You'
                : (_open?.name ?? 'Reply'),
            preview: (_editTarget ?? _replyTarget)?.text ?? '',
            isPhoto: (_editTarget ?? _replyTarget)?.hasImage ?? false,
            onCancel: _cancelComposerContext,
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _ComposerAttachButton(
              enabled: !_sending,
              onTap: _pickAndSendImage,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: AnimatedBuilder(
                animation: Listenable.merge([_wave, _composerFocus]),
                builder: (context, _) {
                  final focused = _composerFocus.hasFocus;
                  return Container(
                    constraints: const BoxConstraints(minHeight: 52),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: focused ? .7 : .56),
                          Colors.white.withValues(alpha: focused ? .42 : .3),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: focused ? 1 : .85,
                        ),
                        width: 1.2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: Stack(
                        children: [
                          // Liquid pooled along the bottom of the pill,
                          // rising a little while you type.
                          Positioned.fill(
                            child: CustomPaint(
                              painter: WaveFillPainter(
                                phase: _wave.value * 2 * pi,
                                fill: focused ? .2 : .1,
                                color: _ink.withValues(alpha: .05),
                                amplitude: 3,
                                frequency: 1.6,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 15,
                            ),
                            child: TextField(
                              controller: _composer,
                              focusNode: _composerFocus,
                              minLines: 1,
                              maxLines: 4,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _send(),
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w500,
                                color: _ink,
                                height: 1.35,
                              ),
                              cursorColor: _ink,
                              decoration: const InputDecoration(
                                isCollapsed: true,
                                border: InputBorder.none,
                                hintText: 'Message…',
                                hintStyle: TextStyle(
                                  fontSize: 14,
                                  color: _muted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Send orb — liquid press only, no flying drop.
        TweenAnimationBuilder<double>(
          key: ValueKey(_sendCount),
          tween: Tween(begin: _sendCount == 0 ? 1 : .92, end: 1),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          builder: (context, t, child) =>
              Transform.scale(scale: t, child: child),
          child: Tooltip(
            message: 'Send',
            child: LiquidPressable(
              onTap: _send,
              borderRadius: BorderRadius.circular(26),
              rippleColor: Colors.white,
              intensity: 1.15,
              child: AnimatedBuilder(
                animation: _wave,
                builder: (context, _) => Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .5),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .95),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _ink.withValues(alpha: .18),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(
                          painter: WaveFillPainter(
                            phase: _wave.value * 2 * pi + 1.2,
                            fill: .95,
                            color: _ink.withValues(alpha: .28),
                            amplitude: 4,
                            frequency: 1.3,
                          ),
                        ),
                        CustomPaint(
                          painter: WaveFillPainter(
                            phase: _wave.value * 2 * pi,
                            fill: .82,
                            color: const Color(
                              0xFF15181F,
                            ).withValues(alpha: .93),
                            amplitude: 3.4,
                            frequency: 1.5,
                          ),
                        ),
                        const Center(
                          child: Icon(
                            Icons.water_drop_rounded,
                            size: 22,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
          ],
        ),
      ],
    );
  }
}

// -------------------------------------------------------------- list chrome

class _RailPerson {
  const _RailPerson(
    this.name,
    this.colors, {
    this.isOnline = false,
    this.avatarUrl,
  });

  final String name;
  final List<Color> colors;
  final bool isOnline;
  final String? avatarUrl;
}

/// Top search pill for the chat list — liquid pools inside while focused.
class _ChatListSearchBar extends StatelessWidget {
  const _ChatListSearchBar({
    required this.controller,
    required this.focusNode,
    required this.wave,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final AnimationController wave;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([wave, focusNode]),
      builder: (context, _) {
        final focused = focusNode.hasFocus;
        final hasText = controller.text.isNotEmpty;
        return ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: focused ? .68 : .48),
                    Colors.white.withValues(alpha: focused ? .38 : .22),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: focused ? .95 : .55),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _ink.withValues(alpha: focused ? .1 : .04),
                    blurRadius: focused ? 18 : 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: WaveFillPainter(
                      phase: wave.value * 2 * pi,
                      fill: focused ? .18 : .08,
                      color: _ink.withValues(alpha: .045),
                      amplitude: 2.8,
                      frequency: 1.5,
                    ),
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 16),
                      Icon(
                        Icons.search_rounded,
                        size: 22,
                        color: _ink.withValues(alpha: .55),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          onChanged: onChanged,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: _ink,
                          ),
                          cursorColor: _ink,
                          decoration: const InputDecoration(
                            isCollapsed: true,
                            border: InputBorder.none,
                            hintText: 'Search chats & people…',
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: _muted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      AnimatedScale(
                        scale: hasText ? 1 : 0,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutBack,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: LiquidPressable(
                            onTap: onClear,
                            borderRadius: BorderRadius.circular(14),
                            rippleColor: Colors.white,
                            intensity: 1.1,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _ink.withValues(alpha: .88),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Horizontal rail of liquid profile circles with a floating title.
class _AvatarRail extends StatelessWidget {
  const _AvatarRail({
    required this.title,
    required this.wave,
    required this.people,
    required this.onTapName,
  });

  final String title;
  final AnimationController wave;
  final List<_RailPerson> people;
  final ValueChanged<String> onTapName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedBuilder(
          animation: wave,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, sin(wave.value * 2 * pi) * 2),
            child: child,
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: _ink,
              letterSpacing: -.1,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: people.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final person = people[index];
              return _PersonCircle(
                person: person,
                wave: wave,
                phaseShift: index * .7,
                onTap: () => onTapName(person.name),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PersonCircle extends StatelessWidget {
  const _PersonCircle({
    required this.person,
    required this.wave,
    required this.phaseShift,
    required this.onTap,
  });

  final _RailPerson person;
  final AnimationController wave;
  final double phaseShift;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LiquidPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      rippleColor: Colors.white,
      intensity: 1.15,
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            AnimatedBuilder(
              animation: wave,
              builder: (context, child) => Transform.translate(
                offset: Offset(0, sin(wave.value * 2 * pi + phaseShift) * 2.4),
                child: child,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: person.colors,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: person.colors.last.withValues(alpha: .28),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AnimatedBuilder(
                            animation: wave,
                            builder: (context, _) => CustomPaint(
                              painter: WaveFillPainter(
                                phase: wave.value * 2 * pi + phaseShift,
                                fill: .28,
                                color: Colors.white.withValues(alpha: .14),
                                amplitude: 3,
                                frequency: 1.4,
                              ),
                            ),
                          ),
                          Center(
                            child: Text(
                              person.name.isEmpty ? '?' : person.name[0],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (person.avatarUrl != null &&
                              person.avatarUrl!.isNotEmpty)
                            CachedFeedImage(
                              url: person.avatarUrl!,
                              fit: BoxFit.cover,
                              width: 58,
                              height: 58,
                              memCacheWidth: 128,
                              memCacheHeight: 128,
                              errorWidget: const SizedBox.shrink(),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (person.isOnline)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: AnimatedBuilder(
                        animation: wave,
                        builder: (context, _) => Transform.scale(
                          scale:
                              1 + .12 * sin(wave.value * 2 * pi + phaseShift),
                          child: Container(
                            width: 13,
                            height: 13,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _online,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              person.name.split(' ').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _ink.withValues(alpha: .75),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------- list tile

/// Borderless chat row — clean typography, liquid squash on every tap.
class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.wave,
    required this.phaseShift,
    required this.onTap,
  });

  final _Conversation conversation;
  final AnimationController wave;
  final double phaseShift;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LiquidPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      rippleColor: _ink,
      intensity: 1.05,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 11),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: conversation.colors,
                    ),
                  ),
                  child: ClipOval(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AnimatedBuilder(
                          animation: wave,
                          builder: (context, _) => CustomPaint(
                            painter: WaveFillPainter(
                              phase: wave.value * 2 * pi + phaseShift,
                              fill: .22,
                              color: Colors.white.withValues(alpha: .12),
                              amplitude: 2.8,
                              frequency: 1.4,
                            ),
                          ),
                        ),
                        Center(
                          child: Text(
                            conversation.name.isEmpty
                                ? '?'
                                : conversation.name[0],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (conversation.avatarUrl != null &&
                            conversation.avatarUrl!.isNotEmpty)
                          CachedFeedImage(
                            url: conversation.avatarUrl!,
                            fit: BoxFit.cover,
                            width: 50,
                            height: 50,
                            memCacheWidth: 120,
                            memCacheHeight: 120,
                            errorWidget: const SizedBox.shrink(),
                          ),
                      ],
                    ),
                  ),
                ),
                if (conversation.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: AnimatedBuilder(
                      animation: wave,
                      builder: (context, _) => Transform.scale(
                        scale: 1 + .12 * sin(wave.value * 2 * pi + phaseShift),
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _online,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                      letterSpacing: -.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    conversation.preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: conversation.unread > 0
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: conversation.unread > 0
                          ? _ink.withValues(alpha: .7)
                          : _muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  conversation.time,
                  style: const TextStyle(fontSize: 11, color: _muted),
                ),
                const SizedBox(height: 6),
                if (conversation.unread > 0)
                  AnimatedBuilder(
                    animation: wave,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(
                        0,
                        sin(wave.value * 2 * pi + phaseShift) * 1.6,
                      ),
                      child: child,
                    ),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            BrandColors.secondarySurface,
                            BrandColors.secondarySurface,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${conversation.unread}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- header

class _ThreadHeader extends StatelessWidget {
  const _ThreadHeader({
    required this.conversation,
    required this.wave,
    required this.onBack,
    required this.onMore,
  });

  final _Conversation conversation;
  final AnimationController wave;
  final VoidCallback onBack;
  final ValueChanged<BuildContext> onMore;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: .62),
                Colors.white.withValues(alpha: .34),
              ],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: .9)),
          ),
          child: Row(
            children: [
              LiquidPressable(
                onTap: onBack,
                borderRadius: BorderRadius.circular(16),
                rippleColor: _ink,
                intensity: .9,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .65),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .95),
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    size: 18,
                    color: _ink,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 40,
                height: 40,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: conversation.colors,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .8),
                    width: 1.5,
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: Text(
                        conversation.name.isEmpty ? '?' : conversation.name[0],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (conversation.avatarUrl != null &&
                        conversation.avatarUrl!.isNotEmpty)
                      CachedFeedImage(
                        url: conversation.avatarUrl!,
                        fit: BoxFit.cover,
                        width: 40,
                        height: 40,
                        memCacheWidth: 96,
                        memCacheHeight: 96,
                        errorWidget: const SizedBox.shrink(),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      conversation.isOnline ? 'Online' : conversation.role,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: conversation.isOnline ? _online : _muted,
                      ),
                    ),
                  ],
                ),
              ),
              LiquidPressable(
                onTap: () => HapticFeedback.selectionClick(),
                borderRadius: BorderRadius.circular(16),
                rippleColor: _ink,
                intensity: .9,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .65),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .95),
                    ),
                  ),
                  child: const Icon(
                    Icons.videocam_rounded,
                    size: 18,
                    color: _ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              LiquidPressable(
                onTap: () => HapticFeedback.selectionClick(),
                borderRadius: BorderRadius.circular(16),
                rippleColor: _ink,
                intensity: .9,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: .65),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .95),
                    ),
                  ),
                  child: const Icon(Icons.call_rounded, size: 17, color: _ink),
                ),
              ),
              const SizedBox(width: 8),
              // Liquid 3-dot — opens a small popover just below.
              Builder(
                builder: (buttonContext) => LiquidPressable(
                  onTap: () => onMore(buttonContext),
                  borderRadius: BorderRadius.circular(16),
                  rippleColor: _ink,
                  intensity: 1.1,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: .65),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: .95),
                      ),
                    ),
                    child: const Icon(
                      Icons.more_horiz_rounded,
                      size: 20,
                      color: _ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------- bubble

/// A message bubble that lands with an elastic pop. Outgoing bubbles are
/// dark glass with liquid sloshing along their base; incoming ones are
/// frosted white. A liquid 3-dot sits beside every bubble.
class _Bubble extends StatelessWidget {
  const _Bubble({
    super.key,
    required this.message,
    required this.wave,
    required this.onMore,
  });

  final _Msg message;
  final AnimationController wave;
  final ValueChanged<BuildContext> onMore;

  @override
  Widget build(BuildContext context) {
    final mine = message.mine;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(mine ? 20 : 6),
      bottomRight: Radius.circular(mine ? 6 : 20),
    );

    final moreButton = Builder(
      builder: (buttonContext) => LiquidPressable(
        onTap: () => onMore(buttonContext),
        borderRadius: BorderRadius.circular(14),
        rippleColor: _ink,
        intensity: 1.05,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: .55),
            border: Border.all(color: Colors.white.withValues(alpha: .9)),
          ),
          child: Icon(
            Icons.more_horiz_rounded,
            size: 16,
            color: _ink.withValues(alpha: .55),
          ),
        ),
      ),
    );

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Transform.translate(
        offset: Offset(0, 6 * (1 - t.clamp(0, 1))),
        child: Transform.scale(
          scale: (.94 + .06 * t).clamp(0, 1),
          alignment: mine ? Alignment.bottomRight : Alignment.bottomLeft,
          child: Opacity(opacity: t.clamp(0, 1), child: child),
        ),
      ),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (mine) ...[moreButton, const SizedBox(width: 6)],
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 268),
                child: LiquidPressable(
                  onTap: () => onMore(context),
                  borderRadius: radius,
                  rippleColor: mine ? Colors.white : _ink,
                  intensity: .55,
                  child: ClipRRect(
                    borderRadius: radius,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(15, 10, 15, 8),
                        decoration: BoxDecoration(
                          borderRadius: radius,
                          gradient: mine
                              ? LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    const Color(
                                      0xFF2A2F3E,
                                    ).withValues(alpha: .96),
                                    const Color(
                                      0xFF15181F,
                                    ).withValues(alpha: .93),
                                  ],
                                )
                              : LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withValues(alpha: .72),
                                    Colors.white.withValues(alpha: .44),
                                  ],
                                ),
                          border: Border.all(
                            color: Colors.white.withValues(
                              alpha: mine ? .3 : .9,
                            ),
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: AnimatedBuilder(
                                animation: wave,
                                builder: (context, _) => CustomPaint(
                                  painter: WaveFillPainter(
                                    phase:
                                        wave.value * 2 * pi +
                                        message.text.length,
                                    fill: .22,
                                    color: (mine ? Colors.white : _ink)
                                        .withValues(alpha: .05),
                                    amplitude: 2.5,
                                    frequency: 1.4,
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (message.replyPreview != null ||
                                    message.replyAuthor != null)
                                  _ReplyQuote(message: message),
                                if (message.hasImage)
                                  _BubbleImage(
                                    url: message.mediaUrl!,
                                    mine: mine,
                                  ),
                                if (message.isDeleted)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.block_rounded,
                                        size: 13,
                                        color: (mine ? Colors.white : _muted)
                                            .withValues(alpha: .55),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Message deleted',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontStyle: FontStyle.italic,
                                          fontWeight: FontWeight.w500,
                                          color: (mine ? Colors.white : _muted)
                                              .withValues(alpha: .7),
                                        ),
                                      ),
                                    ],
                                  )
                                else if (message.text.isNotEmpty)
                                  Text(
                                    message.text,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      height: 1.35,
                                      fontWeight: FontWeight.w500,
                                      color: mine ? Colors.white : _ink,
                                    ),
                                  ),
                                const SizedBox(height: 3),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      message.time,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        color: (mine ? Colors.white : _muted)
                                            .withValues(alpha: mine ? .55 : 1),
                                      ),
                                    ),
                                    if (mine && !message.isDeleted) ...[
                                      const SizedBox(width: 5),
                                      _ReadTicks(
                                        pending: message.pending,
                                        read: message.isRead,
                                      ),
                                    ],
                                    if (message.autoDelete ==
                                        _AutoDelete.hours24) ...[
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.timer_outlined,
                                        size: 11,
                                        color: (mine ? Colors.white : _ink)
                                            .withValues(alpha: .45),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (!mine) ...[const SizedBox(width: 6), moreButton],
            ],
          ),
        ),
      ),
    );
  }
}

/// WhatsApp-style delivery ticks for messages I sent: a clock while pending,
/// a single grey tick once delivered, and a double blue tick once read.
class _ReadTicks extends StatelessWidget {
  const _ReadTicks({required this.pending, required this.read});

  final bool pending;
  final bool read;

  @override
  Widget build(BuildContext context) {
    if (pending) {
      return Icon(
        Icons.schedule_rounded,
        size: 12,
        color: Colors.white.withValues(alpha: .55),
      );
    }
    final color = read
        ? const Color(0xFF53BDEB)
        : Colors.white.withValues(alpha: .55);
    return Icon(read ? Icons.done_all_rounded : Icons.done_rounded,
        size: 14, color: color);
  }
}

/// Quoted preview of the message being replied to, shown inside the bubble.
class _ReplyQuote extends StatelessWidget {
  const _ReplyQuote({required this.message});

  final _Msg message;

  @override
  Widget build(BuildContext context) {
    final mine = message.mine;
    final onDark = mine ? Colors.white : _ink;
    final author = message.replyAuthor?.trim();
    final preview = message.replyPreview?.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(9, 6, 10, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: onDark.withValues(alpha: mine ? .12 : .06),
        border: Border(
          left: BorderSide(color: onDark.withValues(alpha: .45), width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (author != null && author.isNotEmpty)
            Text(
              author,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: onDark.withValues(alpha: .85),
              ),
            ),
          Text(
            preview == null || preview.isEmpty ? 'Photo' : preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              color: onDark.withValues(alpha: .7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline image attachment inside a message bubble.
class _BubbleImage extends StatelessWidget {
  const _BubbleImage({required this.url, required this.mine});

  final String url;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 260),
        child: CachedFeedImage(
          url: url,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// Banner above the composer showing the message being replied to or edited,
/// with a cancel button.
class _ComposerContextBanner extends StatelessWidget {
  const _ComposerContextBanner({
    required this.editing,
    required this.author,
    required this.preview,
    required this.isPhoto,
    required this.onCancel,
  });

  final bool editing;
  final String author;
  final String preview;
  final bool isPhoto;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final text = preview.trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withValues(alpha: .55),
              border: Border(
                left: BorderSide(
                  color: BrandColors.secondarySurface.withValues(alpha: .8),
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  editing ? Icons.edit_rounded : Icons.reply_rounded,
                  size: 16,
                  color: BrandColors.secondarySurface,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        editing ? 'Editing message' : 'Replying to $author',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: BrandColors.secondarySurface,
                        ),
                      ),
                      Text(
                        text.isEmpty && isPhoto ? 'Photo' : text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: _muted),
                      ),
                    ],
                  ),
                ),
                LiquidPressable(
                  onTap: onCancel,
                  borderRadius: BorderRadius.circular(20),
                  rippleColor: _ink,
                  intensity: 1.05,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: _ink.withValues(alpha: .55),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Round liquid button that opens the gallery to attach a photo.
class _ComposerAttachButton extends StatelessWidget {
  const _ComposerAttachButton({
    required this.enabled,
    required this.onTap,
  });

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : .5,
      child: LiquidPressable(
        onTap: enabled ? onTap : () {},
        borderRadius: BorderRadius.circular(26),
        rippleColor: _ink,
        intensity: 1.1,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: .5),
            border: Border.all(
              color: Colors.white.withValues(alpha: .95),
              width: 1.2,
            ),
          ),
          child: Icon(
            Icons.add_photo_alternate_outlined,
            size: 22,
            color: _ink.withValues(alpha: .7),
          ),
        ),
      ),
    );
  }
}

/// The "Unread messages" divider WhatsApp shows above the first unread message.
class _UnreadDivider extends StatelessWidget {
  const _UnreadDivider({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: BrandColors.secondarySurface.withValues(alpha: .25),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              count > 0 ? '$count unread messages' : 'Unread messages',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: .3,
                color: BrandColors.secondarySurface,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: BrandColors.secondarySurface.withValues(alpha: .25),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------- message menu

enum _MessageMenuAction { reply, edit, autoDelete24h, never, delete }

/// Tiny liquid card that wells up just under the 3-dot anchor.
class _LiquidPopoverRoute extends PopupRoute<_MessageMenuAction> {
  _LiquidPopoverRoute({
    required this.anchorRect,
    required this.selected,
    required this.mine,
    required this.canEdit,
  });

  final Rect anchorRect;
  final _AutoDelete selected;
  final bool mine;
  final bool canEdit;

  @override
  Color? get barrierColor => _ink.withValues(alpha: .12);

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 340);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _MessageOptionsPopover(
      anchorRect: anchorRect,
      selected: selected,
      mine: mine,
      canEdit: canEdit,
      animation: animation,
    );
  }
}

class _MessageOptionsPopover extends StatefulWidget {
  const _MessageOptionsPopover({
    required this.anchorRect,
    required this.selected,
    required this.mine,
    required this.canEdit,
    required this.animation,
  });

  final Rect anchorRect;
  final _AutoDelete selected;
  final bool mine;
  final bool canEdit;
  final Animation<double> animation;

  @override
  State<_MessageOptionsPopover> createState() => _MessageOptionsPopoverState();
}

class _MessageOptionsPopoverState extends State<_MessageOptionsPopover>
    with SingleTickerProviderStateMixin {
  static const _width = 240.0;

  /// Height scales with the number of visible tiles (each tile ≈ 52px).
  double get _height {
    var tiles = 4; // reply + auto-delete + never + delete
    if (widget.canEdit) tiles += 1;
    return 16 + tiles * 52.0;
  }

  late final AnimationController _wave = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);

    var left = widget.anchorRect.center.dx - _width / 2;
    left = left.clamp(12.0, size.width - _width - 12);

    // Prefer opening just below the 3-dots; flip above if near the bottom.
    var top = widget.anchorRect.bottom + 8;
    final maxTop = size.height - padding.bottom - _height - 12;
    final openAbove = top > maxTop;
    if (openAbove) {
      top = widget.anchorRect.top - _height - 8;
    }
    top = top.clamp(padding.top + 8, maxTop);

    final curved = CurvedAnimation(
      parent: widget.animation,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            width: _width,
            child: FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: .86, end: 1).animate(curved),
                alignment: openAbove
                    ? Alignment.bottomCenter
                    : Alignment.topCenter,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: AnimatedBuilder(
                      animation: _wave,
                      builder: (context, child) => Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: .88),
                              Colors.white.withValues(alpha: .58),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: .95),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _ink.withValues(alpha: .18),
                              blurRadius: 22,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: WaveFillPainter(
                                  phase: _wave.value * 2 * pi,
                                  fill: .12,
                                  color: _ink.withValues(alpha: .04),
                                  amplitude: 2.4,
                                  frequency: 1.5,
                                ),
                              ),
                            ),
                            child!,
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _PopoverTile(
                              wave: _wave,
                              icon: Icons.reply_rounded,
                              label: 'Reply',
                              onTap: () => Navigator.of(
                                context,
                              ).pop(_MessageMenuAction.reply),
                            ),
                            const SizedBox(height: 4),
                            if (widget.canEdit) ...[
                              _PopoverTile(
                                wave: _wave,
                                icon: Icons.edit_outlined,
                                label: 'Edit',
                                onTap: () => Navigator.of(
                                  context,
                                ).pop(_MessageMenuAction.edit),
                              ),
                              const SizedBox(height: 4),
                            ],
                            _PopoverTile(
                              wave: _wave,
                              icon: Icons.timer_outlined,
                              label: 'Auto delete after 24 hour',
                              selected: widget.selected == _AutoDelete.hours24,
                              onTap: () => Navigator.of(
                                context,
                              ).pop(_MessageMenuAction.autoDelete24h),
                            ),
                            const SizedBox(height: 4),
                            _PopoverTile(
                              wave: _wave,
                              icon: Icons.all_inclusive_rounded,
                              label: 'Never',
                              selected: widget.selected == _AutoDelete.never,
                              onTap: () => Navigator.of(
                                context,
                              ).pop(_MessageMenuAction.never),
                            ),
                            const SizedBox(height: 4),
                            _PopoverTile(
                              wave: _wave,
                              icon: Icons.delete_outline_rounded,
                              label: 'Delete message',
                              destructive: true,
                              onTap: () => Navigator.of(
                                context,
                              ).pop(_MessageMenuAction.delete),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PopoverTile extends StatelessWidget {
  const _PopoverTile({
    required this.wave,
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.destructive = false,
  });

  final AnimationController wave;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final accent = destructive ? const Color(0xFFC0392B) : _ink;

    return LiquidPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      rippleColor: destructive ? accent : (selected ? Colors.white : _ink),
      intensity: 1.2,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: selected ? 1 : 0),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
        builder: (context, t, _) => AnimatedBuilder(
          animation: wave,
          builder: (context, _) {
            final labelColor = destructive
                ? accent
                : Color.lerp(_ink, Colors.white, ((t - .3) / .45).clamp(0, 1))!;
            return Container(
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withValues(alpha: .42),
                border: Border.all(
                  color: destructive
                      ? accent.withValues(alpha: .22)
                      : Color.lerp(
                          Colors.white.withValues(alpha: .7),
                          Colors.white.withValues(alpha: .3),
                          t,
                        )!,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (!destructive)
                      Positioned.fill(
                        child: CustomPaint(
                          painter: WaveFillPainter(
                            phase: wave.value * 2 * pi,
                            fill: t * 1.1,
                            color: const Color(
                              0xFF15181F,
                            ).withValues(alpha: .93),
                            amplitude: 2.5,
                            frequency: 1.5,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Matching side rails keep icon + label optically centered
                          // whether or not the checkmark is showing.
                          const SizedBox(width: 18),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Icon(
                                      icon,
                                      size: 16,
                                      color: destructive
                                          ? accent
                                          : (selected
                                                ? labelColor
                                                : _ink.withValues(alpha: .7)),
                                    ),
                                    const SizedBox(width: 7),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth:
                                            (constraints.maxWidth - 23)
                                                .clamp(0, double.infinity),
                                      ),
                                      child: Text(
                                        label,
                                        maxLines: 1,
                                        softWrap: false,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: -.1,
                                          height: 1,
                                          color: labelColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          SizedBox(
                            width: 18,
                            child: selected && !destructive
                                ? Icon(
                                    Icons.check_rounded,
                                    size: 15,
                                    color: labelColor,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// "New friends" picker — lists the signed-in user's followers so they can
/// start a chat. Tapping a person opens/creates a conversation with them.
class _NewFriendsSheet extends StatefulWidget {
  const _NewFriendsSheet({required this.profileApi, required this.onPick});

  final ProfileApi profileApi;
  final ValueChanged<ProfileListUser> onPick;

  @override
  State<_NewFriendsSheet> createState() => _NewFriendsSheetState();
}

class _NewFriendsSheetState extends State<_NewFriendsSheet> {
  List<ProfileListUser> _people = const [];
  bool _loading = true;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final list = await widget.profileApi.followers();
      if (!mounted) return;
      setState(() {
        _people = list;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<ProfileListUser> get _filtered {
    if (_query.isEmpty) return _people;
    final q = _query.toLowerCase();
    return _people
        .where((u) =>
            u.displayName.toLowerCase().contains(q) ||
            (u.username ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.sizeOf(context).height * .7;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Material(
            color: Colors.white.withValues(alpha: .96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 42,
                    height: 4.5,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _ink.withValues(alpha: .18),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(22, 16, 22, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'New friends',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          setState(() => _query = value.trim()),
                      textInputAction: TextInputAction.search,
                      style: const TextStyle(fontSize: 15, color: _ink),
                      decoration: InputDecoration(
                        hintText: 'Search friends…',
                        hintStyle:
                            TextStyle(color: _ink.withValues(alpha: .4)),
                        prefixIcon:
                            Icon(Icons.search, color: _ink.withValues(alpha: .5)),
                        suffixIcon: _query.isEmpty
                            ? null
                            : IconButton(
                                icon: Icon(Icons.close,
                                    color: _ink.withValues(alpha: .5)),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              ),
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        filled: true,
                        fillColor: _ink.withValues(alpha: .05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: _loading
                        ? const Padding(
                            padding: EdgeInsets.all(36),
                            child: Center(
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.4),
                            ),
                          )
                        : _filtered.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(28),
                                child: Text(
                                  _query.isEmpty
                                      ? 'No followers yet.'
                                      : 'No friends match “$_query”.',
                                  style: TextStyle(
                                    color: _ink.withValues(alpha: .5),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                padding:
                                    const EdgeInsets.fromLTRB(12, 4, 12, 16),
                                itemCount: _filtered.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 4),
                                itemBuilder: (context, i) {
                                  final user = _filtered[i];
                                  return _FriendRow(
                                    user: user,
                                    onTap: () => widget.onPick(user),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FriendRow extends StatelessWidget {
  const _FriendRow({required this.user, required this.onTap});

  final ProfileListUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final letter =
        user.displayName.isEmpty ? '?' : user.displayName[0].toUpperCase();
    final colors = _colorsFor(user.id.isNotEmpty ? user.id : user.displayName);
    final avatar = user.avatar?.trim();
    return LiquidPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      rippleColor: _ink,
      intensity: .6,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
              ),
              child: (avatar != null && avatar.isNotEmpty)
                  ? CachedFeedImage(
                      url: avatar,
                      fit: BoxFit.cover,
                      width: 44,
                      height: 44,
                      memCacheWidth: 100,
                      errorWidget: Text(
                        letter,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : Text(
                      letter,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  if ((user.username ?? '').isNotEmpty)
                    Text(
                      '@${user.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: _ink.withValues(alpha: .5),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 20,
              color: _ink.withValues(alpha: .5),
            ),
          ],
        ),
      ),
    );
  }
}
