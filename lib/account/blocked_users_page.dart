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

/// Lists users I've blocked, each with an Unblock button.
class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => BlockedUsersPageState();
}

class BlockedUsersPageState extends State<BlockedUsersPage> {
  final _profileApi = ProfileApi();
  List<ProfileListUser> _blocked = const [];
  bool _loading = true;
  final Set<String> _busyIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _profileApi.blockedList();
      if (!mounted) return;
      setState(() {
        _blocked = list;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _unblock(ProfileListUser user) async {
    if (_busyIds.contains(user.id)) return;
    setState(() => _busyIds.add(user.id));
    HapticFeedback.selectionClick();
    try {
      await _profileApi.unblock(user.id);
      if (!mounted) return;
      setState(() => _blocked = _blocked.where((u) => u.id != user.id).toList());
    } on ApiException catch (e) {
      if (mounted) accountToast(context, e.message);
    } catch (_) {
      if (mounted) accountToast(context, 'Could not unblock');
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
                  title: 'Blocked users',
                  onBack: () => Navigator.of(context).pop(),
                ),
                if (_loading)
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                  )
                else if (_blocked.isEmpty)
                  Expanded(
                    child: Center(
                      child: Text(
                        'You have not blocked anyone.',
                        style: TextStyle(color: _ink.withValues(alpha: .5)),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(16, 6, 16, bottom + 24),
                      itemCount: _blocked.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final user = _blocked[i];
                        return _BlockedRow(
                          user: user,
                          busy: _busyIds.contains(user.id),
                          onUnblock: () => _unblock(user),
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

class _BlockedRow extends StatelessWidget {
  const _BlockedRow({
    required this.user,
    required this.busy,
    required this.onUnblock,
  });

  final ProfileListUser user;
  final bool busy;
  final VoidCallback onUnblock;

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
          const SizedBox(width: 8),
          FastTap(
            onTap: busy ? () {} : onUnblock,
            borderRadius: BorderRadius.circular(12),
            child: Opacity(
              opacity: busy ? .5 : 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white.withValues(alpha: .55),
                  border: Border.all(color: Colors.white.withValues(alpha: .9)),
                ),
                child: Text(
                  'Unblock',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _ink.withValues(alpha: .8),
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
