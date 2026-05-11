import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/model/coordinator_model/coordinator_teacher_response_model.dart';
import 'package:innovator/KMS/model/coordinator_model/teacher_notes_model.dart';
import 'package:innovator/KMS/provider/coordinator_provider.dart';
import 'package:innovator/KMS/screens/constant_screen/custom_scroll.dart';
import 'package:innovator/KMS/screens/coordinator/coordinator_attendance_approval_screen.dart';
import 'package:innovator/KMS/screens/coordinator/coordinator_shared_widget.dart';
import 'package:innovator/KMS/screens/coordinator/coordinator_teacher_notes_screen.dart';

final attendanceFilterProvider = StateProvider<String>((ref) => 'ALL');

class CoordinatorDashboardScreen extends ConsumerWidget {
  const CoordinatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(coordinatorAttendanceProvider);
    final sessionsAsync = ref.watch(teacherSessionsProvider);

    return RefreshIndicator(
      onRefresh:
          () => Future.wait([
            ref.refresh(coordinatorAttendanceProvider.future),
            ref.refresh(teacherSessionsProvider.future),
          ]),
      child: CustomScrolling(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Stats grid
            attendanceAsync.when(
              loading: () => _StatsGridSkeleton(),
              error: (_, __) => _buildStatsGrid(null),
              data: (data) => _buildStatsGrid(data),
            ),

            const SizedBox(height: 28),

            //    Teacher Attendance
            _SectionHeader(
              title: 'Teacher Attendance',
              onViewAll:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => const CoordinatorAttendanceApprovalScreen(),
                    ),
                  ),
              onRefresh: () => ref.refresh(coordinatorAttendanceProvider),
              color: AppStyle.primaryColor,
            ),
            const SizedBox(height: 14),

            attendanceAsync.when(
              loading:
                  () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  ),
              error: (e, _) => CoordinatorErrorBox(error: e),
              data: (data) {
                if (data.attendances.isEmpty) {
                  return const CoordinatorEmptyState(
                    icon: Icons.how_to_reg_rounded,
                    message: 'No attendance records',
                  );
                }
                final preview = data.attendances.take(3).toList();
                return Column(
                  children: [
                    ...preview.map(
                      (item) => _AttendancePreviewTile(
                        item: item,
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => CoordinatorAttendanceDetailScreen(
                                      item: item,
                                    ),
                              ),
                            ),
                      ),
                    ),
                    if (data.total > 3)
                      _ViewMoreButton(
                        label: 'View all ${data.total} records',
                        color: AppStyle.primaryColor,
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) =>
                                        const CoordinatorAttendanceApprovalScreen(),
                              ),
                            ),
                      ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // Teaching Logs
            _SectionHeader(
              title: 'Teaching Logs',
              onViewAll:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CoordinatorSessionsScreen(),
                    ),
                  ),
              onRefresh: () => ref.refresh(teacherSessionsProvider),
              color: AppStyle.primaryColor,
            ),
            const SizedBox(height: 14),

            sessionsAsync.when(
              loading:
                  () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  ),
              error: (e, _) => CoordinatorErrorBox(error: e),
              data: (data) {
                if (data.sessions!.isEmpty) {
                  return const CoordinatorEmptyState(
                    icon: Icons.menu_book_rounded,
                    message: 'No teaching logs yet',
                  );
                }
                final preview = data.sessions!.take(3).toList();
                return Column(
                  children: [
                    ...preview.map(
                      (s) => _SessionPreviewTile(
                        session: s,
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => CoordinatorSessionDetailScreen(
                                      session: s,
                                    ),
                              ),
                            ),
                      ),
                    ),
                    if (data.totalSessions! > 3)
                      _ViewMoreButton(
                        label: 'View all ${data.totalSessions} logs',
                        color: const Color(0xFF7C3AED),
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => const CoordinatorSessionsScreen(),
                              ),
                            ),
                      ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(CoordinatorAttendanceResponse? data) {
    final total = data?.total ?? 0;
    final pending = data?.pending ?? 0;
    final approved =
        data != null ? data.attendances.where((a) => a.isApproved).length : 0;
    final rejected =
        data != null ? data.attendances.where((a) => a.isRejected).length : 0;

    return GridView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      children: [
        _StatCard(
          label: 'Total',
          value: '$total',
          icon: Icons.calendar_today_rounded,
          color: AppStyle.primaryColor,
        ),
        _StatCard(
          label: 'Pending',
          value: '$pending',
          icon: Icons.pending_actions_rounded,
          color: const Color(0xFFE85D04),
          hasBadge: pending > 0,
        ),
        _StatCard(
          label: 'Approved',
          value: '$approved',
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF059669),
        ),
        _StatCard(
          label: 'Rejected',
          value: '$rejected',
          icon: Icons.cancel_rounded,
          color: Colors.red,
        ),
      ],
    );
  }
}

// Section header

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onViewAll;
  final VoidCallback onRefresh;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.onViewAll,
    required this.onRefresh,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'Inter',
            color: Colors.black87,
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: onViewAll,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'View All →',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRefresh,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.refresh_rounded, size: 16, color: color),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// Attendance preview tile (no buttons)

class _AttendancePreviewTile extends StatelessWidget {
  final CoordinatorAttendanceModel item;
  final VoidCallback onTap;

  const _AttendancePreviewTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPending = item.status == 'PENDING';
    final isApproved = item.status == 'APPROVED';

    final statusColor =
        isPending
            ? const Color(0xFFE85D04)
            : isApproved
            ? const Color(0xFF059669)
            : Colors.red;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppStyle.primaryColor.withValues(alpha: 0.1),
              child: Text(
                item.teacherName[0],
                style: TextStyle(
                  color: AppStyle.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.teacherName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      fontFamily: 'Inter',
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    item.schoolName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.date.day}/${item.date.month}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(
                      fontSize: 10,
                      color: statusColor,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Colors.grey.shade300,
            ),
          ],
        ),
      ),
    );
  }
}

// Session preview tile (no buttons)

class _SessionPreviewTile extends StatelessWidget {
  final TeacherSessionModel session;
  final VoidCallback onTap;

  const _SessionPreviewTile({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: AppStyle.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.teacherName ?? 'Unknown Teacher',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      fontFamily: 'Inter',
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    session.notes ?? 'No notes available',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontFamily: 'Inter',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  session.date != null
                      ? '${DateTime.parse(session.date!).day}/${DateTime.parse(session.date!).month}'
                      : 'No Date',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// View more button

class _ViewMoreButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ViewMoreButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

// Shared stat card & skeleton

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool hasBadge;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.hasBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                if (hasBadge)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    fontFamily: 'Inter',
                    color: Colors.black87,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGridSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.6,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      children: List.generate(
        4,
        (_) => Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
