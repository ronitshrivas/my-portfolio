import 'package:flutter/material.dart';
import 'package:innovator/Innovator/constant/app_colors.dart';
import 'package:innovator/Innovator/screens/Follow/follow-Service.dart';

class FollowButton extends StatefulWidget {
  final String targetUserId;
  final String? targetUserEmail;
  final VoidCallback? onFollowSuccess;
  final VoidCallback? onUnfollowSuccess;
  final bool initialFollowStatus;
  final double? size;
  final ScaffoldMessengerState? rootMessenger;

  const FollowButton({
    Key? key,
    required this.targetUserId,
    this.targetUserEmail,
    this.onFollowSuccess,
    this.onUnfollowSuccess,
    this.initialFollowStatus = false,
    this.size,
    this.rootMessenger,
  }) : super(key: key);

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton>
    with SingleTickerProviderStateMixin {
  late bool _isFollowing;

  bool _isBusy = false;

  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.initialFollowStatus;
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.88,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _scaleCtrl;
  }

  @override
  void didUpdateWidget(FollowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFollowStatus != widget.initialFollowStatus) {
      setState(() => _isFollowing = widget.initialFollowStatus);
    }
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  ScaffoldMessengerState get _messenger =>
      widget.rootMessenger ?? ScaffoldMessenger.of(context);

  Future<void> _handleTap() async {
    if (_isBusy) return;
    _isBusy = true;

    await _scaleCtrl.reverse();
    _scaleCtrl.forward();

    final wasFollowing = _isFollowing;
    setState(() => _isFollowing = !wasFollowing);

    if (!wasFollowing) {
      widget.onFollowSuccess?.call();
    } else {
      widget.onUnfollowSuccess?.call();
    }

    try {
      if (!wasFollowing) {
        await FollowService.sendFollowRequest(widget.targetUserId);
      } else {
        await FollowService.unfollowUser(widget.targetUserId);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isFollowing = wasFollowing);

      if (!wasFollowing) {
        widget.onUnfollowSuccess?.call();
      } else {
        widget.onFollowSuccess?.call();
      }

      _showError(e.toString());
    } finally {
      _isBusy = false;
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    _messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            msg.replaceFirst('Exception: ', ''),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: _isFollowing ? Colors.transparent : Colors.blue.shade600,
            border: Border.all(
              color: _isFollowing ? Colors.green : Colors.blue.shade600,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder:
                (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
            child: Row(
              key: ValueKey(_isFollowing),
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isFollowing ? Icons.check : Icons.person_add,
                  size: 14,
                  color: _isFollowing ? Colors.green : AppColors.whitecolor,
                ),
                const SizedBox(width: 4),
                Text(
                  _isFollowing ? 'Following' : 'Follow',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _isFollowing ? Colors.green : AppColors.whitecolor,
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
