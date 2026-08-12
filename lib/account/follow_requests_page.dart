import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:innovator/models/api_response.dart';
import 'package:innovator/innovator/data/models/profile_models.dart';
import 'package:innovator/innovator/data/sources/profile_api.dart';
import '../theme/brand_colors.dart';
import '../widgets/animated_blob_background.dart';
import '../widgets/cached_feed_image.dart';
import '../widgets/fast_glass.dart';
import 'account_widgets.dart';

const _ink = BrandColors.ink;

/// Pending follow requests sent to me, each with Accept / Reject.
class FollowRequestsPage extends StatefulWidget {
  const FollowRequestsPage({super.key});

  @override
  State<FollowRequestsPage> createState() => FollowRequestsPageState();
}

class FollowRequestsPageState extends State<FollowRequestsPage> {
  final _profileApi = ProfileApi();
  List<ProfileListUser> _requests = const [];
  bool _loading = true;

  /// Ids currently being accepted/rejected — their buttons stay disabled.
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _profileApi.followRequests();
      if (!mounted) return;
      setState(() {
        _requests = list;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _act(ProfileListUser user, bool accept) async {
    if (_busyIds.contains(user.id)) return;
    setState(() => _busyIds.add(user.id));
    HapticFeedback.selectionClick();
    try {
      if (accept) {
        await _profileApi.acceptFollowRequest(user.id);
      } else {
        await _profileApi.rejectFollowRequest(user.id);
      }
      if (!mounted) return;
      setState(() => _requests = _requests.where((r) => r.id != user.id).toList());
    } on ApiException catch (e) {
      if (mounted) accountToast(context, e.message);
    } catch (_) {
      if (mounted) accountToast(context, 'Something went wrong');
    } finally {
      if (mounted) setState(() => _busyIds.remove(user.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: BrandColors.canvas,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AnimatedBlobBackground(animate: false),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                AccountHeader(
                  title: 'Follow requests',
                  onBack: () => Navigator.of(context).pop(),
                ),
                if (_loading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                  )
                else if (_requests.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        'No pending requests.',
                        style: TextStyle(color: _ink.withValues(alpha: .5)),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(16, 6, 16, bottom + 24),
                      itemCount: _requests.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final user = _requests[i];
                        return _RequestRow(
                          user: user,
                          busy: _busyIds.contains(user.id),
                          onAccept: () => _act(user, true),
                          onReject: () => _act(user, false),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({
    required this.user,
    required this.busy,
    required this.onAccept,
    required this.onReject,
  });

  final ProfileListUser user;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final letter = user.displayName.isEmpty ? '?' : user.displayName[0];
    final avatar = user.avatar?.trim();
    return FastGlass(
      borderRadius: BorderRadius.circular(18),
      opacity: .42,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: BrandColors.secondarySurface.withValues(alpha: .3),
            ),
            child: (avatar != null && avatar.isNotEmpty)
                ? CachedFeedImage(
                    url: avatar,
                    fit: BoxFit.cover,
                    width: 44,
                    height: 44,
                    memCacheWidth: 100,
                    errorWidget: Text(
                      letter.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                  )
                : Text(
                    letter.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _ink,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                Builder(
                  builder: (context) {
                    final occupation = user.occupation?.trim();
                    final subtitle = (occupation != null && occupation.isNotEmpty)
                        ? occupation
                        : ((user.username ?? '').isNotEmpty
                            ? '@${user.username}'
                            : '');
                    if (subtitle.isEmpty) return const SizedBox.shrink();
                    return Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: _ink.withValues(alpha: .5),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _MiniButton(
            label: 'Accept',
            filled: true,
            busy: busy,
            onTap: onAccept,
          ),
          const SizedBox(width: 8),
          _MiniButton(
            label: 'Reject',
            filled: false,
            busy: busy,
            onTap: onReject,
          ),
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.label,
    required this.filled,
    required this.busy,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FastTap(
      onTap: busy ? () {} : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: busy ? .5 : 1,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: filled
                ? BrandColors.secondarySurface
                : Colors.white.withValues(alpha: .55),
            border: filled
                ? null
                : Border.all(color: Colors.white.withValues(alpha: .9)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: filled ? Colors.white : _ink.withValues(alpha: .8),
            ),
          ),
        ),
      ),
    );
  }
}
