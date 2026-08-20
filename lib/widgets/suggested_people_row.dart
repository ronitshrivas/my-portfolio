import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/innovator/data/models/profile_models.dart';
import 'package:innovator/innovator/providers/innovator_providers.dart';
import '../profile_page.dart';
import '../theme/brand_colors.dart';
import 'cached_feed_image.dart';

const _ink = BrandColors.ink;
/// Horizontal "Suggested for you" people-to-follow row. Hidden entirely when
/// there are no suggestions. Each card follows / dismisses independently.
class SuggestedPeopleRow extends ConsumerWidget {
  const SuggestedPeopleRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(suggestedPeopleProvider);
    final people = state.valueOrNull ?? const <SuggestedUser>[];
    // Hide the whole section while loading-empty, on error, or when empty.
    if (people.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Text(
            'Suggested for you',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: _ink,
              letterSpacing: -.2,
            ),
          ),
        ),
        SizedBox(
          height: 214,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: people.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final person = people[i];
              return _SuggestedCard(
                person: person,
                onFollow: () => ref
                    .read(suggestedPeopleProvider.notifier)
                    .toggleFollow(person.id),
                onDismiss: () => ref
                    .read(suggestedPeopleProvider.notifier)
                    .dismiss(person.id),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SuggestedCard extends StatelessWidget {
  const _SuggestedCard({
    required this.person,
    required this.onFollow,
    required this.onDismiss,
  });

  final SuggestedUser person;
  final VoidCallback onFollow;
  final VoidCallback onDismiss;

  void _openProfile(BuildContext context) {
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
    final letter =
        person.displayName.replaceAll('@', '').trim().isEmpty
            ? '?'
            : person.displayName.replaceAll('@', '').trim()[0].toUpperCase();
    final avatar = person.avatar?.trim();

    return GestureDetector(
      onTap: () => _openProfile(context),
      child: Container(
        width: 158,
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withValues(alpha: .7),
          border: Border.all(color: _ink.withValues(alpha: .08)),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 6),
                Container(
                  width: 56,
                  height: 56,
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
                          width: 56,
                          height: 56,
                          memCacheWidth: 128,
                          errorWidget: _LetterAvatar(letter: letter),
                        )
                      : _LetterAvatar(letter: letter),
                ),
                const SizedBox(height: 10),
                Text(
                  person.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                if ((person.occupation ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    person.occupation!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: _ink.withValues(alpha: .6),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  person.reason?.trim().isNotEmpty == true
                      ? person.reason!.trim()
                      : (person.mutualCount > 0
                          ? '${person.mutualCount} mutual'
                          : 'Suggested for you'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.5,
                    height: 1.25,
                    color: _ink.withValues(alpha: .45),
                  ),
                ),
                const Spacer(),
                _FollowButton(person: person, onTap: onFollow),
              ],
            ),
            Positioned(
              top: -4,
              right: -4,
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onDismiss();
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: _ink.withValues(alpha: .4),
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

class _LetterAvatar extends StatelessWidget {
  const _LetterAvatar({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: _ink,
        ),
      ),
    );
  }
}

class _FollowButton extends StatelessWidget {
  const _FollowButton({required this.person, required this.onTap});

  final SuggestedUser person;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final actioned = person.isFollowing || person.isPending;
    final label = person.isPending
        ? 'Requested'
        : (person.isFollowing ? 'Following' : 'Follow');
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: double.infinity,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: actioned
              ? Colors.white.withValues(alpha: .7)
              : BrandColors.secondarySurface,
          border: Border.all(
            color: actioned
                ? _ink.withValues(alpha: .18)
                : Colors.white.withValues(alpha: .85),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: actioned ? _ink : Colors.white,
          ),
        ),
      ),
    );
  }
}