import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:innovator/KMS/core/constants/app_style.dart';
 import 'package:innovator/KMS/screens/constant_screen/custom_scroll.dart';

// ─── Models ─────────────────────────────────────────────────────────────────

class StudentAttendanceRecord {
  final String date;
  final String subject;
  final String teacherName;
  final bool isPresent;
  final String className;
  const StudentAttendanceRecord({
    required this.date,
    required this.subject,
    required this.teacherName,
    required this.isPresent,
    required this.className,
  });
}

class StudentAttendanceStats {
  final int totalDays;
  final int presentDays;
  final int absentDays;
  final double attendancePercentage;
  final String studentName;
  final String className;
  final String rollNo;
  const StudentAttendanceStats({
    required this.totalDays,
    required this.presentDays,
    required this.absentDays,
    required this.attendancePercentage,
    required this.studentName,
    required this.className,
    required this.rollNo,
  });
}

// ─── Providers ───────────────────────────────────────────────────────────────

final studentAttendanceStatsProvider = FutureProvider<StudentAttendanceStats>((ref) async {
  await Future.delayed(const Duration(milliseconds: 700));
  return const StudentAttendanceStats(
    totalDays: 55,
    presentDays: 48,
    absentDays: 7,
    attendancePercentage: 87.3,
    studentName: 'Aarav Sharma',
    className: 'Class 8',
    rollNo: '05',
  );
});

final studentAttendanceRecordsProvider = FutureProvider<List<StudentAttendanceRecord>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 600));
  return const [
    StudentAttendanceRecord(date: '10 Mar 2026', subject: 'Mathematics', teacherName: 'Ramesh Thapa', isPresent: true, className: 'Class 8'),
    StudentAttendanceRecord(date: '9 Mar 2026', subject: 'Science', teacherName: 'Sunita Karki', isPresent: true, className: 'Class 8'),
    StudentAttendanceRecord(date: '8 Mar 2026', subject: 'Mathematics', teacherName: 'Ramesh Thapa', isPresent: false, className: 'Class 8'),
    StudentAttendanceRecord(date: '7 Mar 2026', subject: 'English', teacherName: 'Bijay Rai', isPresent: true, className: 'Class 8'),
    StudentAttendanceRecord(date: '6 Mar 2026', subject: 'Mathematics', teacherName: 'Ramesh Thapa', isPresent: true, className: 'Class 8'),
    StudentAttendanceRecord(date: '5 Mar 2026', subject: 'Science', teacherName: 'Sunita Karki', isPresent: false, className: 'Class 8'),
    StudentAttendanceRecord(date: '4 Mar 2026', subject: 'English', teacherName: 'Bijay Rai', isPresent: true, className: 'Class 8'),
    StudentAttendanceRecord(date: '3 Mar 2026', subject: 'Mathematics', teacherName: 'Ramesh Thapa', isPresent: true, className: 'Class 8'),
  ];
});

 
class StudentDashboardScreen extends ConsumerWidget {
  const StudentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(studentAttendanceStatsProvider);
    final recordsAsync = ref.watch(studentAttendanceRecordsProvider);

    return Scaffold( 
      backgroundColor: AppStyle.primaryColor,
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFFF5F7FA),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
        ),
        child: CustomScrolling(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ── Student Info + Attendance Card ──
              statsAsync.when(
                loading: () => _StatsSkeleton(),
                error: (_, __) => const SizedBox(),
                data: (stats) => _AttendanceHeroCard(stats: stats),
              ),

              const SizedBox(height: 24),

              // ── Filter bar ──
              Row(
                children: [
                  const Text('Attendance Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Inter', color: Colors.black87)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.filter_list_rounded, size: 15, color: AppStyle.primaryColor),
                        const SizedBox(width: 5),
                        Text('This Month', style: TextStyle(fontSize: 12, color: AppStyle.primaryColor, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Records List ──
              recordsAsync.when(
                loading: () => const Center(child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                )),
                error: (_, __) => const SizedBox(),
                data: (records) => Column(
                  children: records.map((r) => _AttendanceLogTile(record: r)).toList(),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Hero Attendance Card ─────────────────────────────────────────────────────

class _AttendanceHeroCard extends StatelessWidget {
  final StudentAttendanceStats stats;
  const _AttendanceHeroCard({required this.stats});

  Color get _statusColor {
    if (stats.attendancePercentage >= 85) return Colors.green;
    if (stats.attendancePercentage >= 70) return Colors.orange;
    return Colors.red;
  }

  String get _statusLabel {
    if (stats.attendancePercentage >= 85) return 'Excellent';
    if (stats.attendancePercentage >= 70) return 'Average';
    return 'Poor';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppStyle.primaryColor, AppStyle.primaryColor.withValues(alpha: 0.80)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppStyle.primaryColor.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Student info ──
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                  ),
                  child: Center(
                    child: Text(stats.studentName[0], style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stats.studentName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Inter')),
                      Text('${stats.className}  ·  Roll No: ${stats.rollNo}', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12, fontFamily: 'Inter')),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Text(_statusLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Inter')),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // ── Percentage display ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${stats.attendancePercentage.toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('Attendance Rate', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontFamily: 'Inter')),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Progress Bar ──
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: stats.attendancePercentage / 100,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
              ),
            ),

            const SizedBox(height: 18),

            // ── Stats row ──
            Row(
              children: [
                Expanded(child: _miniStat('Total Days', '${stats.totalDays}', Colors.white)),
                _divider(),
                Expanded(child: _miniStat('Present', '${stats.presentDays}', Colors.greenAccent)),
                _divider(),
                Expanded(child: _miniStat('Absent', '${stats.absentDays}', Colors.redAccent)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontFamily: 'Inter')),
      ],
    );
  }

  Widget _divider() => Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.2));
}

// ─── Attendance Log Tile ──────────────────────────────────────────────────────

class _AttendanceLogTile extends StatelessWidget {
  final StudentAttendanceRecord record;
  const _AttendanceLogTile({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: record.isPresent ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.15),
          width: 1.2,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: record.isPresent ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                record.isPresent ? Icons.check_rounded : Icons.close_rounded,
                color: record.isPresent ? Colors.green.shade600 : Colors.red.shade400,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.subject, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, fontFamily: 'Inter', color: Colors.black87)),
                  const SizedBox(height: 3),
                  Text(record.teacherName, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontFamily: 'Inter')),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(record.date, style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontFamily: 'Inter')),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: record.isPresent ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    record.isPresent ? 'Present' : 'Absent',
                    style: TextStyle(fontSize: 11, color: record.isPresent ? Colors.green.shade700 : Colors.red.shade500, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
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

// ─── Skeleton ────────────────────────────────────────────────────────────────

class _StatsSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(24)),
    );
  }
}