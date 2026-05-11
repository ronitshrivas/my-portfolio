import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:innovator/Innovator/constant/app_colors.dart';
import 'package:innovator/Innovator/screens/Likes/Content-Like-Service.dart';
import 'package:innovator/Innovator/screens/Likes/hive_reaction_queue.dart';
import 'dart:developer' as developer;

class LikeButton extends StatefulWidget {
  final String contentId;
  final bool initialLikeStatus;
  final ContentLikeService likeService;
  final Function(bool)? onLikeToggled;
  final String? initialReactionType;
  final bool showLabel;
  final int initialCount;
  final bool isReel;

  const LikeButton({
    Key? key,
    required this.contentId,
    required this.initialLikeStatus,
    required this.likeService,
    this.onLikeToggled,
    this.initialReactionType,
    this.showLabel = false,
    this.initialCount = 0,
    this.isReel = false,
  }) : super(key: key);

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton>
    with SingleTickerProviderStateMixin {
  ReactionType? _currentReaction;
  bool _isApiInFlight = false;
  bool _isSyncing = false; // true only while flush() is actively calling API

  late int _count;

  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();

    HiveReactionQueue.instance.setService(widget.likeService);

    if (widget.initialLikeStatus) {
      _currentReaction =
          widget.initialReactionType != null
              ? ReactionTypeExtension.fromValue(widget.initialReactionType) ??
                  ReactionType.like
              : ReactionType.like;
    } else {
      _currentReaction = null;
    }

    _count = widget.initialCount;

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _bounceAnim = TweenSequence([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.45)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.45, end: 0.88)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.88, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
    ]).animate(_bounceCtrl);

    // Register to receive flush results from HiveReactionQueue
    HiveReactionQueue.instance.addListener(widget.contentId, _onSyncResult);
  }

  @override
  void dispose() {
    HiveReactionQueue.instance.removeListener(widget.contentId);
    _removeOverlay();
    _bounceCtrl.dispose();
    super.dispose();
  }

  // ── Called by HiveReactionQueue after flushing this post ──────────────────
  void _onSyncResult(
    String contentId,
    bool succeeded,
    ReactionType? reactionType,   // what was attempted
    ReactionType? previousType,   // what was there BEFORE the offline action
  ) {
    if (!mounted) return;

    if (succeeded) {
      // API accepted the queued reaction — UI is already showing the right
      // state (optimistic), just clear the syncing spinner
      setState(() {
        _isSyncing = false;
        _currentReaction = reactionType; // confirm final state
      });
      developer.log(
        '[LikeButton] ✓ Sync confirmed for ${widget.contentId}',
      );
    } else {
      // API rejected (4xx) or 5xx — revert to previous state immediately
      // WITHOUT requiring a page refresh
      setState(() {
        _isSyncing = false;

        final hadReactionBefore = previousType != null;
        final hasReactionNow = _currentReaction != null;

        if (hasReactionNow && !hadReactionBefore) {
          // User added a reaction offline but API rejected it → remove it
          _count = (_count - 1).clamp(0, 999999);
        } else if (!hasReactionNow && hadReactionBefore) {
          // User removed a reaction offline but API rejected it → restore it
          _count = _count + 1;
        }

        // Revert to the state before the offline action
        _currentReaction = previousType;
      });

      // Notify parent so the feed list count also updates
      widget.onLikeToggled?.call(_currentReaction != null);

      developer.log(
        '[LikeButton] ✗ Sync failed for ${widget.contentId} — '
        'reverted to previousType=${previousType?.name}',
      );
    }
  }

  // ── Connectivity ──────────────────────────────────────────────────────────
  Future<bool> _isOnline() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return results.any(
        (r) =>
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.ethernet,
      );
    } catch (_) {
      return false;
    }
  }

  // ── Tap / long-press ──────────────────────────────────────────────────────
  Future<void> _handleTap() async {
    if (_isApiInFlight || _isSyncing) return;
    _removeOverlay();
    await _applyReaction(_currentReaction != null ? null : ReactionType.like);
  }

  void _handleLongPress() {
    if (_isSyncing) return;
    HapticFeedback.mediumImpact();
    if (_overlayEntry != null) {
      _removeOverlay();
      return;
    }
    _showReactionPicker();
  }

  // ── Core reaction logic ───────────────────────────────────────────────────
  Future<void> _applyReaction(ReactionType? type) async {
    if (_isApiInFlight) return;

    final previous = _currentReaction; // snapshot BEFORE change

    // Optimistic update — full opacity, looks same as online like
    _updateLocalState(type, previous);
    widget.onLikeToggled?.call(_currentReaction != null);
    _isApiInFlight = true;

    try {
      final online = await _isOnline();

      if (!online) {
        // Offline → queue silently. UI already shows the optimistic state.
        // Store `previous` so we can revert if the API later rejects it.
        developer.log('[LikeButton] Offline → queuing ${widget.contentId}');
        await HiveReactionQueue.instance.enqueue(
          contentId: widget.contentId,
          type: type,
          isReel: widget.isReel,
          previousType: previous, // ← key: needed for revert on failure
        );
        return;
      }

      // ── Online path ──────────────────────────────────────────────────────
      ReactionResult result;
      if (type == null) {
        // Removing reaction
        result = widget.isReel
            ? await widget.likeService.reactReel(
                widget.contentId,
                previous ?? ReactionType.like,
              )
            : await widget.likeService.reactPost(
                widget.contentId,
                previous ?? ReactionType.like,
              );
      } else {
        result = widget.isReel
            ? await widget.likeService.reactReel(widget.contentId, type)
            : await widget.likeService.reactPost(widget.contentId, type);
      }

      if (result.success) {
        if (type != null && result.reactionType != null && mounted) {
          setState(() => _currentReaction = result.reactionType);
        }
        // Remove any previously queued entry
        await HiveReactionQueue.instance.dequeue(widget.contentId);
        developer.log('[LikeButton] ✓ API confirmed ${widget.contentId}');
      } else {
        // 5xx — revert immediately (don't queue, this was an online attempt)
        developer.log('[LikeButton] 5xx → reverting ${widget.contentId}');
        _revertState(previous, type);
      }
    } on NonRetryableException catch (e) {
      // 4xx — revert immediately, don't queue
      developer.log(
        '[LikeButton] Non-retryable (${e.statusCode}) → reverting '
        '${widget.contentId}',
      );
      _revertState(previous, type);
      await HiveReactionQueue.instance.dequeue(widget.contentId);
    } catch (e) {
      // Network error during an ONLINE attempt → queue for retry
      developer.log('[LikeButton] Network error → queuing: $e');
      await HiveReactionQueue.instance.enqueue(
        contentId: widget.contentId,
        type: type,
        isReel: widget.isReel,
        previousType: previous,
      );
    } finally {
      if (mounted) setState(() => _isApiInFlight = false);
    }
  }

  /// Revert to [previous] state, undoing what [attempted] did to the count.
  void _revertState(ReactionType? previous, ReactionType? attempted) {
    if (!mounted) return;
    setState(() {
      // Undo the optimistic count change
      if (attempted != null && previous == null) {
        // We added a reaction → undo the +1
        _count = (_count - 1).clamp(0, 999999);
      } else if (attempted == null && previous != null) {
        // We removed a reaction → undo the -1
        _count = _count + 1;
      }
      _currentReaction = previous;
    });
    widget.onLikeToggled?.call(_currentReaction != null);
  }

  void _updateLocalState(ReactionType? newType, ReactionType? previous) {
    if (!mounted) return;
    setState(() {
      if (newType != null && previous == null) {
        _count++;
      } else if (newType == null && previous != null) {
        _count = (_count - 1).clamp(0, 999999);
      }
      _currentReaction = newType;
    });
    _bounceCtrl.forward(from: 0);
  }

  // ── Overlay ───────────────────────────────────────────────────────────────
  void _showReactionPicker() {
    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (_) => _ReactionPickerOverlay(
        layerLink: _layerLink,
        onSelect: (type) {
          _removeOverlay();
          _applyReaction(type);
        },
        onDismiss: _removeOverlay,
        currentReaction: _currentReaction,
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final reaction = _currentReaction;
    final hasReaction = reaction != null;
    final emoji = hasReaction ? reaction.emoji : null;
    final label = hasReaction ? reaction.label : 'Like';
    // Always full opacity — no fading for offline/pending reactions
    final iconColor =
        hasReaction ? _reactionColor(reaction) : Colors.grey.shade700;

    return CompositedTransformTarget(
      link: _layerLink,
      child: GestureDetector(
        onTap: _handleTap,
        onLongPress: _handleLongPress,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _bounceAnim,
          builder: (context, child) =>
              Transform.scale(scale: _bounceAnim.value, child: child),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Always full opacity — looks identical online or offline
                    emoji != null
                        ? Text(
                            emoji,
                            style: TextStyle(fontSize: 22, color: iconColor),
                          )
                        : Icon(
                            Icons.thumb_up_alt_outlined,
                            color: iconColor,
                            size: 22,
                          ),

                    // Tiny spinner only while actively syncing to API
                    if (_isSyncing)
                      Positioned(
                        top: -3,
                        right: -3,
                        child: SizedBox(
                          width: 8,
                          height: 8,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: iconColor,
                          ),
                        ),
                      ),
                  ],
                ),

                if (widget.showLabel) ...[
                  const SizedBox(width: 5),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: iconColor,
                    ),
                    child: Text(
                      widget.showLabel && _count > 0
                          ? '$label · $_count'
                          : label,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _reactionColor(ReactionType r) {
    switch (r) {
      case ReactionType.like:
        return const Color(0xFF0A66C2);
      case ReactionType.love:
        return Colors.red.shade500;
      case ReactionType.haha:
        return Colors.amber.shade600;
      case ReactionType.wow:
        return Colors.amber.shade700;
      case ReactionType.sad:
        return Colors.amber.shade700;
      case ReactionType.angry:
        return Colors.orange.shade700;
      case ReactionType.dislike:
        return Colors.grey.shade600;
      case ReactionType.celebrate:
        return Colors.deepOrange.shade500;
    }
  }
}

// ── Reaction picker overlay ───────────────────────────────────────────────────

class _ReactionPickerOverlay extends StatefulWidget {
  final LayerLink layerLink;
  final void Function(ReactionType) onSelect;
  final VoidCallback onDismiss;
  final ReactionType? currentReaction;

  const _ReactionPickerOverlay({
    required this.layerLink,
    required this.onSelect,
    required this.onDismiss,
    this.currentReaction,
  });

  @override
  State<_ReactionPickerOverlay> createState() => _ReactionPickerOverlayState();
}

class _ReactionPickerOverlayState extends State<_ReactionPickerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;
  ReactionType? _hovered;

  static const _reactions = ReactionType.values;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: widget.onDismiss,
            behavior: HitTestBehavior.translucent,
            child: Container(color: Colors.transparent),
          ),
        ),
        CompositedTransformFollower(
          link: widget.layerLink,
          showWhenUnlinked: false,
          offset: const Offset(-16, -58),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ScaleTransition(
              scale: _scaleAnim,
              alignment: Alignment.bottomLeft,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.whitecolor,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _reactions.map(_buildReactionItem).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReactionItem(ReactionType r) {
    final isActive = widget.currentReaction == r;
    final isHovered = _hovered == r;
    final targetScale = isHovered ? 1.5 : (isActive ? 1.15 : 1.0);
    final targetY = isHovered ? -10.0 : (isActive ? -3.0 : 0.0);

    return GestureDetector(
      onTap: () => widget.onSelect(r),
      onTapDown: (_) => setState(() => _hovered = r),
      onTapCancel: () => setState(() => _hovered = null),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: targetScale),
        duration: const Duration(milliseconds: 280),
        curve: Curves.elasticOut,
        builder: (_, scale, child) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: targetY),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          builder: (_, dy, __) => Transform.translate(
            offset: Offset(0, dy),
            child: Transform.scale(scale: scale, child: child),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Text(
                r.emoji,
                style: TextStyle(
                  fontSize: isActive ? 20 : 18,
                  inherit: false,
                ),
              ),
              if (isHovered)
                Positioned(
                  bottom: 30,
                  left: -10,
                  right: -10,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        r.label,
                        style: const TextStyle(
                          color: AppColors.whitecolor,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
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