import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:innovator/innovator/data/models/profile_models.dart';
import 'package:innovator/innovator/providers/innovator_providers.dart';
import 'profile_page.dart';
import 'services/avatar_colors.dart';
import 'theme/brand_colors.dart';
import 'widgets/cached_feed_image.dart';
import 'widgets/liquid_pressable.dart';

const _ink = BrandColors.ink;

/// "Find friends" — a searchable people directory to connect with, styled with
/// the app's liquid water-glass surfaces and brand palette.
class FindFriendsPage extends ConsumerStatefulWidget {
  const FindFriendsPage({super.key});

  @override
  ConsumerState<FindFriendsPage> createState() => _FindFriendsPageState();
}

class _FindFriendsPageState extends ConsumerState<FindFriendsPage> {
  final _searchController = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >=
        _scroll.position.maxScrollExtent - 320) {
      ref.read(findFriendsProvider.notifier).loadMore();
    }
  }

  void _openProfile(FindFriend person) {
    if (person.id.isEmpty) return;
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AuthorProfilePage(
          name: person.displayName,
          authUserId: person.id,
          username: person.username,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(findFriendsProvider);
    final notifier = ref.read(findFriendsProvider.notifier);

    return Scaffold(
      backgroundColor: BrandColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              controller: _searchController,
              onBack: () => Navigator.of(context).maybePop(),
              onChanged: notifier.search,
              onClear: () {
                _searchController.clear();
                notifier.search('');
              },
              showClear: _searchController.text.isNotEmpty,
            ),
            Expanded(
              child: _buildBody(state, notifier),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(FindFriendsState state, FindFriendsNotifier notifier) {
    if (state.loading && state.people.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
    }
    if (state.error != null && state.people.isEmpty) {
      return _EmptyState(
        icon: Icons.wifi_off_rounded,
        message: state.error!,
        actionLabel: 'Retry',
        onAction: notifier.refresh,
      );
    }
    if (state.people.isEmpty) {
      return _EmptyState(
        icon: Icons.person_search_rounded,
        message: state.query.isEmpty
            ? 'No people to show yet.'
            : 'No one matches “${state.query}”.',
      );
    }

    return RefreshIndicator(
      color: BrandColors.secondarySurface,
      onRefresh: notifier.refresh,
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
        itemCount: state.people.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          if (i >= state.people.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              ),
            );
          }
          final person = state.people[i];
          return _FriendCard(
            person: person,
            onTap: () => _openProfile(person),
            onFollow: () => notifier.toggleFollow(person.id),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.controller,
    required this.onBack,
    required this.onChanged,
    required this.onClear,
    required this.showClear,
  });

  final TextEditingController controller;
  final VoidCallback onBack;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool showClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
      child: Row(
        children: [
          _GlassCircleButton(icon: Icons.arrow_back_rounded, onTap: onBack),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .55),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .6),
                    ),
                  ),
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    textInputAction: TextInputAction.search,
                    style: const TextStyle(fontSize: 15, color: _ink),
                    decoration: InputDecoration(
                      hintText: 'Find friends…',
                      hintStyle:
                          TextStyle(color: _ink.withValues(alpha: .42)),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: _ink.withValues(alpha: .5),
                      ),
                      suffixIcon: showClear
                          ? IconButton(
                              icon: Icon(
                                Icons.close_rounded,
                                color: _ink.withValues(alpha: .5),
                              ),
                              onPressed: onClear,
                            )
                          : null,
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                      border: InputBorder.none,
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

class _GlassCircleButton extends StatelessWidget {
  const _GlassCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LiquidPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      rippleColor: _ink,
      intensity: .6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .55),
              border: Border.all(color: Colors.white.withValues(alpha: .6)),
            ),
            child: Icon(icon, size: 20, color: _ink.withValues(alpha: .8)),
          ),
        ),
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.person,
    required this.onTap,
    required this.onFollow,
  });

  final FindFriend person;
  final VoidCallback onTap;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) {
    final colors = AvatarColors.gradientFor(
      person.id.isNotEmpty ? person.id : person.username,
    );
    final letter = AvatarColors.letterFor(person.displayName);
    final avatar = person.avatar?.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: LiquidPressable(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          rippleColor: _ink,
          intensity: .5,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: .6)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
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
                          width: 52,
                          height: 52,
                          memCacheWidth: 120,
                          errorWidget: _LetterGlyph(letter: letter),
                        )
                      : _LetterGlyph(letter: letter),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        person.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                          letterSpacing: -.2,
                        ),
                      ),
                      if (person.username.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          '@${person.username}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: _ink.withValues(alpha: .5),
                          ),
                        ),
                      ],
                      if ((person.headline ?? '').isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          person.headline!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: _ink.withValues(alpha: .62),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _FollowButton(person: person, onTap: onFollow),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LetterGlyph extends StatelessWidget {
  const _LetterGlyph({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.person, required this.onTap});

  final FindFriend person;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final following = person.isFollowing;
    final pending = person.isPending;

    final label = pending
        ? 'Requested'
        : following
            ? 'Following'
            : 'Follow';

    // Filled accent for "Follow", quiet glass for the connected states.
    final filled = !following && !pending;

    return LiquidPressable(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      rippleColor: filled ? Colors.white : _ink,
      intensity: .6,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: filled
              ? BrandColors.secondarySurface
              : Colors.white.withValues(alpha: .5),
          border: Border.all(
            color: filled
                ? BrandColors.secondarySurface
                : _ink.withValues(alpha: .18),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: filled ? Colors.white : _ink.withValues(alpha: .8),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 46, color: _ink.withValues(alpha: .28)),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                color: _ink.withValues(alpha: .55),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              LiquidPressable(
                onTap: onAction!,
                borderRadius: BorderRadius.circular(14),
                rippleColor: Colors.white,
                intensity: .6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  decoration: BoxDecoration(
                    color: BrandColors.secondarySurface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
