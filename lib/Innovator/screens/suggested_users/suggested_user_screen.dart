import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/Innovator/screens/Follow/follow-Service.dart';
import 'package:innovator/Innovator/screens/Follow/follow_Button.dart';
import 'package:innovator/Innovator/screens/show_Specific_Profile/Show_Specific_Profile.dart';

import 'package:innovator/Innovator/screens/suggested_users/model/suggested_users_model.dart';
import 'package:innovator/Innovator/screens/suggested_users/provider/suggested_provider.dart';

class _P {
  static const bg = Color(0xFFF8F8F8);
  static const card = Colors.white;
  static const border = Color(0xFFEEEEEE);
  static const orange = Color(0xFFFF6B00);
  static const orangeLight = Color(0xFFFF9A3C);
  static const textPrimary = Color(0xFF1A1A2E);
  static const textMuted = Color(0xFF9E9E9E);
  static const mutualBg = Color(0xFFFFF3E8);
  static const shimmer1 = Color(0xFFF0F0F0);
  static const shimmer2 = Color(0xFFE4E4E4);
  static const errorRed = Color(0xFFE53935);
}

class SuggestedUsersSection extends ConsumerWidget {
  const SuggestedUsersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(suggestProvider);

    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          const Divider(height: 1, thickness: 1, color: _P.border),
          _Header(onRefresh: () => ref.invalidate(suggestProvider)),
          const SizedBox(height: 12),
          Expanded(
            child: async.when(
              loading: () => const _ShimmerRow(),
              error:
                  (e, _) => _ErrorState(
                    message: e.toString().replaceFirst('Exception: ', ''),
                    onRetry: () => ref.invalidate(suggestProvider),
                  ),
              data:
                  (response) =>
                      response.suggestions.isEmpty
                          ? const _EmptyState()
                          : _UserList(users: response.suggestions),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onRefresh;
  const _Header({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 4, 0),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_P.orange, _P.orangeLight],
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'People You May Know',
            style: TextStyle(
              color: _P.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            color: _P.textMuted,
            splashRadius: 16,
          ),
        ],
      ),
    );
  }
}

class _UserList extends StatelessWidget {
  final List<SuggestedUser> users;
  const _UserList({required this.users});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: false,
        physics: AlwaysScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
          childAspectRatio: 0.7,
        ),
        itemCount: users.length,
        itemBuilder:
            (context, i) =>
                _AnimatedCard(index: i, child: _UserCard(user: users[i])),
      ),
    );
  }
}

class _AnimatedCard extends StatefulWidget {
  final int index;
  final Widget child;
  const _AnimatedCard({required this.index, required this.child});

  @override
  State<_AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<_AnimatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fade,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}

class _UserCard extends StatefulWidget {
  final SuggestedUser user;
  const _UserCard({required this.user});

  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> {
  late bool _isFollowing;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.user.isFollowing;
    _checkLocalFollowStatus();
  }

  Future<void> _checkLocalFollowStatus() async {
    final status = await FollowService.checkFollowStatus(widget.user.username);
    if (mounted && status != _isFollowing) {
      setState(() => _isFollowing = status);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _P.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _P.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => SpecificUserProfilePage(userId: widget.user.userId),
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 2),
            _Avatar(user: widget.user),

            const SizedBox(height: 10),
            Text(
              widget.user.displayName,
              style: const TextStyle(
                color: _P.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),

            if (widget.user.mutualCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _P.mutualBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.people_rounded,
                      size: 10,
                      color: _P.orange,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '${widget.user.mutualCount} mutual',
                      style: const TextStyle(
                        color: _P.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            const Spacer(),
            FollowButton(
              targetUserId: widget.user.userId,
              initialFollowStatus: _isFollowing,
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final SuggestedUser user;
  const _Avatar({required this.user});

  String get _initials {
    final parts = user.displayName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return user.displayName.isNotEmpty
        ? user.displayName[0].toUpperCase()
        : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [_P.orange, _P.orangeLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Color(0x33FF6B00), blurRadius: 10, spreadRadius: 1),
        ],
      ),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: Colors.white,
        backgroundImage: user.hasAvatar ? NetworkImage(user.avatar!) : null,
        child:
            user.hasAvatar
                ? null
                : Text(
                  _initials,
                  style: const TextStyle(
                    color: _P.orange,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
      ),
    );
  }
}

class _ShimmerRow extends StatefulWidget {
  const _ShimmerRow();
  @override
  State<_ShimmerRow> createState() => _ShimmerRowState();
}

class _ShimmerRowState extends State<_ShimmerRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 195,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder:
            (_, __) => AnimatedBuilder(
              animation: _ctrl,
              builder:
                  (_, __) => Container(
                    width: 138,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Color.lerp(_P.shimmer1, _P.shimmer2, _ctrl.value),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _P.border),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _P.shimmer2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 11,
                          width: 80,
                          decoration: BoxDecoration(
                            color: _P.shimmer2,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 9,
                          width: 55,
                          decoration: BoxDecoration(
                            color: _P.shimmer2,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          height: 34,
                          decoration: BoxDecoration(
                            color: _P.shimmer2,
                            borderRadius: BorderRadius.circular(10),
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

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: _P.errorRed, size: 28),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(color: _P.textMuted, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [_P.orange, _P.orangeLight],
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _P.mutualBg,
              ),
              child: const Icon(
                Icons.person_search_rounded,
                color: _P.orange,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No suggestions right now',
              style: TextStyle(color: _P.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
