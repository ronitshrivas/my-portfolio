import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
import 'package:innovator/KMS/model/student_model/student_attendance_model.dart';
import 'package:innovator/KMS/provider/student_provider/student_provider.dart';
import 'package:innovator/KMS/screens/constant_screen/custom_scroll.dart';

//  Filter options

enum _DateFilter { all, thisWeek, thisMonth, lastMonth }

extension _DateFilterLabel on _DateFilter {
  String get label {
    switch (this) {
      case _DateFilter.all:
        return 'All';
      case _DateFilter.thisWeek:
        return 'This Week';
      case _DateFilter.thisMonth:
        return 'This Month';
      case _DateFilter.lastMonth:
        return 'Last Month';
    }
  }
}

//  Screen

class StudentAttendanceScreen extends ConsumerStatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  ConsumerState<StudentAttendanceScreen> createState() =>
      _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState
    extends ConsumerState<StudentAttendanceScreen> {
  _DateFilter _selectedFilter = _DateFilter.all;

  bool _isRefreshing = false;

  List<StudentAttendanceModel> _applyFilter(List<StudentAttendanceModel> list) {
    if (_selectedFilter == _DateFilter.all) return list;

    final now = DateTime.now();
    return list.where((a) {
      final date = DateTime.tryParse(a.date);
      if (date == null) return false;

      switch (_selectedFilter) {
        case _DateFilter.thisWeek:
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final start = DateTime(
            startOfWeek.year,
            startOfWeek.month,
            startOfWeek.day,
          );
          return !date.isBefore(start);
        case _DateFilter.thisMonth:
          return date.year == now.year && date.month == now.month;
        case _DateFilter.lastMonth:
          final lastMonth = DateTime(now.year, now.month - 1);
          return date.year == lastMonth.year && date.month == lastMonth.month;
        case _DateFilter.all:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final attendanceAsync = ref.watch(studentAttendanceProvider);

    final isLoading = attendanceAsync.isLoading || _isRefreshing;

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _isRefreshing = true);
        ref.invalidate(studentAttendanceProvider);
        await ref
            .read(studentAttendanceProvider.future)
            .catchError((_, __) => <StudentAttendanceModel>[]);
        if (mounted) setState(() => _isRefreshing = false);
      },
      child: CustomScrolling(
        child: attendanceAsync.when(
          //  Loading
          loading: () => _AttendanceSkeleton(),

          //  Error
          error:
              (err, _) => _ErrorView(
                message: 'Failed to load attendance.',
                onRetry: () => ref.invalidate(studentAttendanceProvider),
              ),

          //  Data
          data: (list) {
            if (list.isEmpty && !isLoading) {
              return const _EmptyView(message: 'No attendance records found.');
            }

            final filtered = _applyFilter(list);

            final total = list.length;
            final presentCount =
                list
                    .where(
                      (a) =>
                          a.status == 'present' ||
                          a.status == 'present_with_homework',
                    )
                    .length;
            final absentCount = list.where((a) => a.status == 'absent').length;
            final rate = total > 0 ? (presentCount / total * 100).round() : 0;

            final studentName = list.isNotEmpty ? list.first.studentName : '';

            return Skeletonizer(
              enabled: isLoading,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //  Student name header
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppStyle.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.person_outline,
                          color: AppStyle.primaryColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),

                          Text(
                            list.isNotEmpty ? list.first.classroomName : '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  //  Summary card
                  _SummaryCard(
                    total: total,
                    present: presentCount,
                    absent: absentCount,
                    rate: rate,
                  ),
                  SizedBox(height: 20),

                  //  Date filter chips
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter by date',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        children:
                            _DateFilter.values.map((f) {
                              final isSelected = _selectedFilter == f;
                              return GestureDetector(
                                onTap:
                                    () => setState(() => _selectedFilter = f),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? AppStyle.primaryColor
                                            : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? AppStyle.primaryColor
                                              : Colors.grey.shade300,
                                    ),
                                    boxShadow:
                                        isSelected
                                            ? [
                                              BoxShadow(
                                                color: AppStyle.primaryColor
                                                    .withValues(alpha: 0.25),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                            : [],
                                  ),
                                  child: Text(
                                    f.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  //  Records count
                  Center(
                    child: Text(
                      '${filtered.length} record${filtered.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  //  Attendance list
                  filtered.isEmpty
                      ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: _EmptyView(
                          message: 'No records for this period.',
                        ),
                      )
                      : ListView.builder(
                        itemCount: filtered.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder:
                            (context, index) =>
                                _AttendanceCard(record: filtered[index]),
                      ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

//  Skeleton (used on initial load)

class _AttendanceSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //  Student name header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppStyle.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_outline, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Bone replaces this text
                    Container(width: 140, height: 16, color: Colors.white),
                    const SizedBox(height: 4),
                    Container(width: 90, height: 11, color: Colors.white),
                  ],
                ),
              ],
            ),
          ),

          //  Summary card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            decoration: BoxDecoration(
              color: AppStyle.primaryColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (i) {
                return Column(
                  children: [
                    Container(width: 18, height: 18, color: Colors.white),
                    const SizedBox(height: 6),
                    Container(width: 32, height: 20, color: Colors.white),
                    const SizedBox(height: 3),
                    Container(width: 48, height: 10, color: Colors.white),
                  ],
                );
              }),
            ),
          ),

          //  Filter chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Wrap(
              spacing: 8,
              children: List.generate(4, (_) {
                return Container(
                  width: 80,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }),
            ),
          ),

          //  Skeleton attendance cards
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              children: List.generate(5, (_) => _SkeletonAttendanceCard()),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonAttendanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top accent bar
          Container(
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Icon placeholder
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 110,
                            height: 14,
                            color: Colors.grey.shade200,
                          ),
                          const SizedBox(height: 5),
                          Container(
                            width: 80,
                            height: 11,
                            color: Colors.grey.shade200,
                          ),
                        ],
                      ),
                    ),
                    // Status badge placeholder
                    Container(
                      width: 70,
                      height: 26,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Classroom row
                Container(width: 120, height: 11, color: Colors.grey.shade200),
                const SizedBox(height: 10),
                // Approved chip
                Container(
                  width: 88,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
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

//  Summary Card

class _SummaryCard extends StatelessWidget {
  final int total;
  final int present;
  final int absent;
  final int rate;

  const _SummaryCard({
    required this.total,
    required this.present,
    required this.absent,
    required this.rate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: BoxDecoration(
        color: AppStyle.primaryColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppStyle.primaryColor.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _SummaryItem(
            label: 'Total Days',
            value: '$total',
            icon: Icons.calendar_month_outlined,
          ),
          _VerticalDivider(),
          _SummaryItem(
            label: 'Present',
            value: '$present',
            icon: Icons.check_circle_outline,
          ),
          _VerticalDivider(),
          _SummaryItem(
            label: 'Absent',
            value: '$absent',
            icon: Icons.cancel_outlined,
          ),
          _VerticalDivider(),
          _SummaryItem(
            label: 'Rate',
            value: '$rate%',
            icon: Icons.bar_chart_rounded,
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(height: 44, width: 1, color: Colors.white24);
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 10),
        ),
      ],
    );
  }
}

//  Attendance Card

class _AttendanceCard extends StatelessWidget {
  final StudentAttendanceModel record;

  const _AttendanceCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final config = _statusConfig(record.status);
    final isApproved = record.approved == 'APPROVED';
    final approvedColor = isApproved ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //  Colored top accent bar
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: config.color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //  Row 1: icon + date + status badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: config.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(config.icon, color: config.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(record.date),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            record.studentName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: config.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        config.label,
                        style: TextStyle(
                          color: config.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),

                //  Row 2: classroom
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      Icon(
                        Icons.class_outlined,
                        size: 13,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        record.classroomName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),

                //  Notes
                if (record.notes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.notes_outlined,
                          size: 14,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            record.notes,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                //  Approved chip
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: approvedColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: approvedColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isApproved
                            ? Icons.verified_outlined
                            : Icons.pending_outlined,
                        size: 13,
                        color: approvedColor,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isApproved ? 'Approved' : 'Pending',
                        style: TextStyle(
                          fontSize: 11,
                          color: approvedColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final d = DateTime.parse(dateStr);
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
      return '${months[d.month - 1]} ${d.day}, ${d.year}';
    } catch (_) {
      return dateStr;
    }
  }

  _StatusConfig _statusConfig(String status) {
    switch (status) {
      case 'present':
        return _StatusConfig(
          label: 'Present',
          color: Colors.green,
          icon: Icons.check_circle_outline,
        );
      case 'present_with_homework':
        return _StatusConfig(
          label: 'Present + HW',
          color: Colors.blue,
          icon: Icons.menu_book_outlined,
        );
      case 'absent':
        return _StatusConfig(
          label: 'Absent',
          color: Colors.red,
          icon: Icons.cancel_outlined,
        );
      default:
        return _StatusConfig(
          label: status,
          color: Colors.grey,
          icon: Icons.help_outline,
        );
    }
  }
}

class _StatusConfig {
  final String label;
  final Color color;
  final IconData icon;
  _StatusConfig({required this.label, required this.color, required this.icon});
}

//  Helpers

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: Colors.grey, fontSize: 15),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyle.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;

  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.event_busy_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
