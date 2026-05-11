import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/model/teacher_model/teacher_profile_model.dart';
import 'package:innovator/KMS/provider/teacher_provider.dart';

class TeacherReviewsScreen extends ConsumerWidget {
  const TeacherReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(teacherProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),
      body: RefreshIndicator(
        color: AppStyle.primaryColor,
        onRefresh: () async {
          ref.invalidate(teacherProfileProvider);
          await ref.read(teacherProfileProvider.future);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: AppStyle.primaryColor,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: profileAsync.when(
                  loading: () => const HeaderSkeleton(),
                  error: (_, __) => const HeaderSkeleton(),
                  data: (profile) => RatingHeader(rating: profile.rating),
                ),
              ),
              title: const Text(
                'My Reviews',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
            ),

            profileAsync.when(
              loading:
                  () => SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppStyle.primaryColor,
                      ),
                    ),
                  ),
              error:
                  (e, _) => SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 52,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Could not load reviews',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              data: (profile) {
                final rating = profile.rating;

                if (rating.totalRatings == 0) {
                  return const SliverFillRemaining(child: EmptyRatings());
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      StarBreakdownCard(rating: rating),
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Text(
                            'School Reviews',
                            style: AppStyle.heading2.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamily: AppStyle.fontFamilySecondary,
                              fontSize: 17,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppStyle.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${rating.schools.length}',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                                color: AppStyle.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      ...rating.schools.map(
                        (school) => SchoolRatingCard(school: school),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class RatingHeader extends StatelessWidget {
  final TeacherRating rating;
  const RatingHeader({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppStyle.primaryColor,
            AppStyle.primaryColor.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Text(
              rating.averageRating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w900,
                fontFamily: 'Inter',
                color: Colors.white,
                height: 1,
              ),
            ),
            const SizedBox(height: 8),
            LargeStarRow(rating: rating.averageRating),
            const SizedBox(height: 8),
            Text(
              '${rating.totalRatings} review${rating.totalRatings == 1 ? '' : 's'} '
              'across ${rating.schools.length} school${rating.schools.length == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 13,
                fontFamily: 'Inter',
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StarBreakdownCard extends StatelessWidget {
  final TeacherRating rating;
  const StarBreakdownCard({required this.rating});

  @override
  Widget build(BuildContext context) {
    final Map<int, int> starCounts = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final school in rating.schools) {
      final star = school.averageRating.round().clamp(1, 5);
      starCounts[star] = (starCounts[star] ?? 0) + school.ratingsCount;
    }
    final int maxCount = starCounts.values.fold(0, (a, b) => a > b ? a : b);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                rating.averageRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Inter',
                  color: Colors.black87,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              LargeStarRow(rating: rating.averageRating, size: 16),
              const SizedBox(height: 4),
              Text(
                '${rating.totalRatings} total',
                style: TextStyle(
                  fontSize: 11,
                  fontFamily: 'Inter',
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          const VerticalDivider(width: 1),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children:
                  [5, 4, 3, 2, 1].map((star) {
                    final count = starCounts[star] ?? 0;
                    final pct = maxCount == 0 ? 0.0 : count / maxCount;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Text(
                            '$star',
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'Inter',
                              color: Colors.black54,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.star_rounded,
                            size: 11,
                            color: Color(0xffF8BD00),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 7,
                                backgroundColor: Colors.grey.shade100,
                                color: AppStyle.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 18,
                            child: Text(
                              '$count',
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'Inter',
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class SchoolRatingCard extends StatelessWidget {
  final TeacherSchoolRating school;
  const SchoolRatingCard({required this.school});

  @override
  Widget build(BuildContext context) {
    final latest = school.latestRating;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppStyle.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    color: AppStyle.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        school.schoolName,

                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,

                          fontFamily: 'Inter',
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${school.ratingsCount} review${school.ratingsCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'Inter',
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                // School average badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      school.averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Inter',
                        color: Colors.black87,
                      ),
                    ),
                    MiniStarRow(rating: school.averageRating),
                  ],
                ),
              ],
            ),
          ),
          if (latest != null) ...[
            Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xffF8BD00,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Latest Review',
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            color: Color(0xffC9930A),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatMonthYear(latest.month, latest.year),
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'Inter',
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppStyle.primaryColor.withValues(
                          alpha: 0.12,
                        ),
                        child: Text(
                          latest.coordinatorName.isNotEmpty
                              ? latest.coordinatorName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Inter',
                            color: AppStyle.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              latest.coordinatorName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Inter',
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'Coordinator · ${_formatDate(latest.createdAt)}',
                              style: TextStyle(
                                fontSize: 10,
                                fontFamily: 'Inter',
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _ratingColor(
                            latest.rating,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: _ratingColor(latest.rating),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              latest.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Inter',
                                color: _ratingColor(latest.rating),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (latest.review != null &&
                      latest.review!.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Text(
                        '"${latest.review}"',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontFamily: 'Inter',
                          color: Colors.grey.shade700,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ] else ...[
            Divider(height: 1, thickness: 1, color: Colors.grey.shade100),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Text(
                'No reviews submitted yet for this school.',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'Inter',
                  color: Colors.grey.shade400,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _ratingColor(double rating) {
    if (rating >= 4.5) return Colors.green.shade600;
    if (rating >= 3.5) return AppStyle.primaryColor;
    if (rating >= 2.5) return const Color(0xffF8BD00);
    return Colors.red.shade400;
  }

  String _formatMonthYear(int month, int year) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[month - 1]} $year';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}

class EmptyRatings extends StatelessWidget {
  const EmptyRatings();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_outline_rounded,
            size: 72,
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 16),
          Text(
            'No Reviews Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Reviews from coordinators will appear here.',
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Inter',
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

class HeaderSkeleton extends StatelessWidget {
  const HeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppStyle.primaryColor,
            AppStyle.primaryColor.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            Container(
              width: 80,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: 120,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LargeStarRow extends StatelessWidget {
  final double rating;
  final double size;
  const LargeStarRow({required this.rating, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final fill = (rating - i).clamp(0.0, 1.0);
        return Icon(
          fill >= 1.0
              ? Icons.star_rounded
              : fill >= 0.5
              ? Icons.star_half_rounded
              : Icons.star_outline_rounded,
          color: const Color(0xffF8BD00),
          size: size,
        );
      }),
    );
  }
}

class MiniStarRow extends StatelessWidget {
  final double rating;
  const MiniStarRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final fill = (rating - i).clamp(0.0, 1.0);
        return Icon(
          fill >= 1.0
              ? Icons.star_rounded
              : fill >= 0.5
              ? Icons.star_half_rounded
              : Icons.star_outline_rounded,
          color: const Color(0xffF8BD00),
          size: 12,
        );
      }),
    );
  }
}
